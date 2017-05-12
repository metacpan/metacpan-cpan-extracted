####################
#
# PhotoIndex.pm,v 1.20 2002/07/10 23:04:16 myneid Exp
#
# xTODO:
#	add writing of sizes of images to index file
#	add ability for user defined files to ignore
#	add ability to define thumbnail size
##################
package Apache::PhotoIndex;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Apache::Constants qw(:common OPT_INDEXES DECLINE_CMD REDIRECT DIR_MAGIC_TYPE);
#use Image::Magick;
use Imager;
use Apache;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '1.20';


sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined Apache::PhotoIndex macro $constname";
	}
    }
    no strict 'refs';
    *$AUTOLOAD = sub () { $val };
    goto &$AUTOLOAD;
}

bootstrap Apache::PhotoIndex $VERSION;

# Preloaded methods go here.
sub handler($)
{
	my $r = shift;

	if($r->args eq 'edit_photos')
	{
		edit_photos($r);
	}
	elsif($r->args eq 'save_index')
	{
		save_index($r);
	}
	elsif($r->content_type and ($r->content_type eq DIR_MAGIC_TYPE or $r->uri =~ /index.html/))
	{
		directory_listing($r,0);
	}
	elsif($r->content_type and $r->content_type eq 'text/photo')
	{
		individual_page($r);
	}
	else
	{
		return DECLINED;
	}
}

sub individual_page($)
{
	my $r = shift;
	my %elements; #this will contain the elements to switch out in the html
	my $index = $r->args;
	my $previndex = int($index-1);
	my $nextindex = int($index+1);
	$r->send_http_header('text/html');
	
	#using index
	no strict 'refs';
	my @index = get_directory_index($r, $r->document_root, $r->uri);
	my $image = $index[$index]->{name};
	my $previmage = ($index == 1) ? 'index.html' : $index[$previndex]->{name};
	my($prevname, $prevext) = split(/\./,$previmage,2);
	my $nextimage = ($index == $#index) ? 'index.html' : $index[$nextindex]->{name};
	my($nextname, $nextext) = split(/\./,$nextimage,2);

	$elements{image} = "<img src=$image border=0><br>". $index[$index]->{description};	
	$elements{index} = "<a href=index.html> Return to Index</a>";
	if($previmage eq 'index.html')
	{
		my $icon = new Apache::Icon;
		my $img = $icon->default('^^DIRECTORY^^');
		$elements{back} = "<a href=index.html><img src=$img></a>";
	}
	else
	{
		$elements{back} = "<a href='$prevname.photo?$previndex'><img src='.thumbnails/$prevname-sm.$prevext'></a>";
	}
	if($nextimage eq 'index.html')
	{
		my $icon = new Apache::Icon;
		my $img = $icon->default('^^DIRECTORY^^');
		$elements{next} = "<a href=index.html><img src=$img ></a>";
	}
	else
	{
		$elements{next} = "<a href='$nextname.photo?$nextindex'><img src='.thumbnails/$nextname-sm.$nextext'></a>";
	}

	my $template = individual_template($r);
	$template =~ s/%%(\w+)%%/$elements{$1}/g;
	print $template;

}

sub get_directory_index($$$)
{
	my ($r, $documentroot, $uri) = @_;
	my @tmp;
	#$uri =~ s/\/(.*?).photo$/\//;
	if($uri =~ /.photo$/)
	{
		my @temp = split(/\//,$uri);
		$uri = '';
		for(my $i=0; $i<$#temp; $i++)
		{
			$uri .= "/$temp[$i]";
		}
	}

#commented out because this function is called in create_new_index_file() and was hence an infinate loop
#	if(!-e "$documentroot$uri/.index" || -z "$documentroot$uri/.index")
#	{
#		create_new_index_file($r, $documentroot, $uri);
#	}
	open(IDX, "<$documentroot$uri/.index") || warn "$documentroot$uri/.index $!";
	my $i=0;
	while(<IDX>)
	{
		chomp();
		# make sure that the 0 index is the title or blank
		if($i == 0 && /^Title /)
		{
			$tmp[$i] = $';
		}
		elsif($i ==0)
		{
			$i++;
		}

		if(!$tmp[$i])
		{
			($tmp[$i]->{name}, $tmp[$i]->{thumbnail_size}, $tmp[$i]->{size}, $tmp[$i]->{description}) = split(/ /, $_, 4);
		}
		$i++;
	}
	close IDX;

	return @tmp;
}

sub directory_listing($$)
{
	my $r = shift;
	my $edit_flag = shift;
	my $percent = .20;
	my $extension = "-sm";
	my $thumbnaildir = '.thumbnails';
	my $tableheader =  "<table border=0 cellpadding=5 cellspacing=5 align=center class=mainimagetable id=mainimagetable width=95%>\n";   

	my $uri = $r->uri;
	my $filename = $r->filename;
	my $documentroot = $r->document_root;
	my $pathinfo = $r->path_info;
      unless ($r->path_info){
                #Issue an external redirect if the dir isn't tailed with a '/'
                my $query = $r->args;
                $query = "?" . $query if  $query;
                $r->header_out(Location => "$uri/$query");
                return REDIRECT;
                }

	if($uri =~ /index.html/)
	{
		$uri =~ s/\/index.html//;
                $r->header_out(Location => "$uri");
                return REDIRECT;
	}


	my (@images, %elements);
	if(!-e "$documentroot$uri$thumbnaildir")
	{
		system("mkdir $documentroot$uri$thumbnaildir") ;
	}

	my $subr = $r->lookup_file($documentroot . $uri .  $_);
	my $icon = Apache::Icon->new($subr);
	my $img = $icon->default('^^DIRECTORY^^');

	$elements{formtag} = '<form method=POST action=?save_index>';

	#this index is only for the title but should be used for descriptions

        if(!-e "$documentroot$uri/.index")
        {
                create_new_index_file($r, $documentroot, $uri, @images);
        }

	my @index = get_directory_index($r, $documentroot, $uri);
	$elements{title} = $index[0] || 'Photo Gallery';
	if($edit_flag)
	{
		$elements{title} = "<input type=text name=title value='$elements{title}'";
	}

	$elements{directories} .= "<a href='..'><img src=$img border=0>Back one Directory</a><br>\n";

	opendir(DIR, "$documentroot$uri");
	foreach ( sort readdir(DIR))
	{
		next if /^\./ || /htaccess/ ;
		my $subr = $r->lookup_file($documentroot . $uri .  $_);
		if($subr->content_type eq DIR_MAGIC_TYPE)
		{
			my $img = $icon->default('^^DIRECTORY^^');
			#my $img = $icon->find || $icon->default;
			#i guess add it to a directory array
			$elements{directories} .= "<a href=$_><img src=$img border=0>$_  </a><br>\n";	
		}
		elsif($subr->content_type =~ /^image/)
		{
			push(@images, $_);
		}
		else
		{
			#add to default array
			my $img = $icon->find || $icon->default;
			$elements{others} .= "<a href=$_><img src=$img border=0>$_ </a><br>\n";	
		}

	}
	closedir(DIR);
	$elements{imagetable} = $tableheader;
	my $i=1;
	my $newindex=0;
	foreach(@images)
	{
		#strip ext, add -sm put back on something something
		$elements{imagetable} .= "<tr>" if($i%4 == 0);
		my($name, $ext) = split(/\./,$_,2);
		if(!-e "$documentroot$uri$thumbnaildir/$name-sm.$ext")
		{
			create_thumbnail("$documentroot$uri$name.$ext", "$documentroot$uri$thumbnaildir/$name-sm.$ext");
			# ok so this dir has changed and the index needs to be recreated
			$newindex=1;

		}
		$elements{imagetable} .= "<td><a href='$name.photo?$i'><img src='$thumbnaildir/$name-sm.$ext'>";
		$elements{imagetable} .= "<br>" . $index[$i]->{description} if !$edit_flag;	
		$elements{imagetable} .= "<br><input type=text value='" .$index[$i]->{description} . "' name='$i'>" if $edit_flag;	
		$elements{imagetable} .= "</a></td>\n";
		$i++;
		$elements{imagetable} .= "</tr>\n" if($i%4==0);
	}
	$elements{imagetable} .= "</table>";
	if($edit_flag)
	{
		$elements{imagetable} .= <<"EOP";
		<input type=submit>
EOP
	}
	if($newindex || !-e "$documentroot$uri/.index")
	{
		create_new_index_file($r, $documentroot, $uri, @images);
	}

	my $template = ($edit_flag) ? default_index_template($r) : index_template($r);
	$template =~ s/%%(.*?)%%/$elements{$1}/g;

	$r->send_http_header('text/html');
	print $template;

}

sub create_new_index_file($$$;\@)
{
	# creates the new index file for individual page browsing
	my ($r, $documentroot, $uri, @images) = @_;
	my @index = get_directory_index($r, $documentroot, $uri);
	if(!defined($images[0]))
	{
		#we need to get these images
		opendir(DIR, "$documentroot$uri");
		foreach ( sort readdir(DIR))
		{
			next if /^\./ || /htaccess/ ;
			my $subr = $r->lookup_file($documentroot . $uri .  $_);
			if($subr->content_type =~ /^image/)
			{
				push(@images, $_);
			}

		}
		closedir(DIR);

	}

	open(IDX, ">$documentroot$uri.index") || die $!;
	if($index[0])
	{
		print IDX "Title $index[0]\n";
	}
	my $i =1;
	foreach(@images)
	{
		my($name,$ext) = split(/\./,$_,2);
		#print IDX "$name.$ext\n";
		printf IDX "%s %s %s %s\n", $_, '-', '-', ($index[$i]->{description}) ? $index[$i]->{description} : '';

	}
	close IDX;

}


sub create_thumbnail($$)
{
	my($source_file, $dest_file) = @_;
	my $percent = 20;
	my  $image = Imager->new;
	$image->read(file=>$source_file) or die "readerror on \"$source_file\": ".$image->{ERRSTR}."\n";
	my %opts=(scalefactor=>$percent/100);
	my $thumb = $image->scale(%opts) or die "scaleerror on \"$source_file\": ".$image->{ERRSTR}."\n";
	$thumb->filter(type=>'autolevels');
	
	$thumb->write(file=>$dest_file) or die "writeerror on \"$source_file\": ".$image->{ERRSTR}."\n";

	undef $image;
}
sub create_thumbnail_imagemagick($$)
{
	my($source_file, $dest_file) = @_;
	my $percent = .20;
	my  $image = Image::Magick->new;
	$image->ReadImage($source_file);
	my ($width, $height) = $image->Get('base-columns', 'base-rows');
	my $newwidth = $width * $percent;
	my $newheight = $height * $percent;
	$image->Scale(width=>"$newwidth", height=>"$newheight");
	$image->Write($dest_file) ;
	undef $image;
}

sub individual_template($)
{
	my $r = shift;
	my $uri = $r->uri;
	my @temp = split(/\//,$uri);
	$uri = '';
	for(my $i=0; $i<$#temp; $i++)
	{
		$uri .= "/$temp[$i]";
	}
	$uri .= '/';
	my $return;

	if($r->dir_config('IndividualTemplate') && (-e $r->dir_config('IndividualTemplate')))
	{
		open(FILE, $r->dir_config('IndividualTemplate')) || die $r->dir_config('IndividualTemplate') . ": $!";
		while(<FILE>)
		{
			$return .= $_;
		}
		close FILE;	
	}
	elsif(-e $r->document_root . $uri . ".individualtemplate")
	{
		open(FILE, $r->document_root . $uri . '.individualtemplate') || die $r->document_root . $uri . ".individualtemplate: $!";
		while(<FILE>)
		{
			$return .= $_;
		}
		close FILE;	

	}
	else
	{
		$return = default_individual_template();
	}

	return $return;
}

sub index_template($)
{
	my $r = shift;
	my $return;
	if($r->dir_config('IndexTemplate') && -e $r->dir_config('IndexTemplate'))
	{
		open(FILE, $r->dir_config('IndexTemplate')) || die $r->dir_config('IndexTemplate') . ": $!";
		while(<FILE>)
		{
			$return .= $_;
		}
		close FILE;	
	}
	elsif(-e $r->document_root . $r->uri . '.indextemplate')
	{
		open(FILE, $r->document_root . $r->uri . '.indextemplate') || die $r->document_root . $r->uri . ".indextemplate: $!";
		while(<FILE>)
		{
			$return .= $_;
		}
		close FILE;	

	}
	else
	{
		$return = default_index_template();
	}

	return $return;
}


sub default_individual_template()
{
	my $template =<<"EOP";
<title>Photo Gallery</title>
<style type="text/css">
BODY {
	background-color : Black;
	color : #BFBFBF;
	font-family : Arial, Helvetica, sans-serif;
	font-size : 10pt;
}

A {
	color : #8F8F8F;
	font-family : Arial, Helvetica, sans-serif;
}

DIV.footer {
	font-size : 7pt;
	font-family : Tahoma, Arial, Helvetica, sans-serif;
}

TABLE {
	font-family : Arial, Helvetica, sans-serif;
	text-align : center;
	font-size : 10pt;
	color : #BFBFBF;
 }
 
 SPAN.normal {
 	font-family : Arial, Helvetica, sans-serif;
	text-align : center;
	font-size : 10pt;
	color : #BFBFBF;
  }
</style>
<body bgcolor=black>
<table border=0 align=center>
<tr><td>%%back%%</td><td>%%image%%</td><td>%%next%%</td></tr>
</table>
<center>%%index%%</center>
</body>
EOP

return $template;
}

sub default_index_template()
{
	my $template=<<"EOP";
<title>Photo Gallery Index</title>
<style type="text/css">
BODY {
	background-color : Black;
	color : #BFBFBF;
	font-family : Arial, Helvetica, sans-serif;
	font-size : 10pt;
}

A {
	color : #8F8F8F;
	font-family : Arial, Helvetica, sans-serif;
}

DIV.footer {
	font-size : 7pt;
	font-family : Tahoma, Arial, Helvetica, sans-serif;
}

DIV.header {
	font-size : 14pt;
	font-style: bold;
	font-family : Tahoma, Arial, Helvetica, sans-serif;
}
TABLE {
	font-family : Arial, Helvetica, sans-serif;
	text-align : center;
	font-size : 10pt;
	color : #BFBFBF;
 }
 
 SPAN.normal {
 	font-family : Arial, Helvetica, sans-serif;
	text-align : center;
	font-size : 10pt;
	color : #BFBFBF;
  }	
</style>
<body>
%%formtag%%
<div class="header" id="header">%%title%%</div>
<br><br>
<I>Directories</i><br>
%%directories%%
<hr>
<I>Images</i><br>
%%imagetable%%
<hr>
<I>Other Files</i><br>
%%others%%

</body>
EOP

}

sub edit_photos($)
{
	my $r = shift;
	directory_listing($r,1);
}

sub save_index($)
{
	my $r = shift;
	my %in = $r->content;
	my($documentroot, $uri) = ($r->document_root, $r->uri);
	my @index = get_directory_index($r, $documentroot, $uri);
	open(IDX, ">$documentroot$uri/.index") || warn "$documentroot$uri/.index $!";
	printf IDX "Title %s\n", ($in{'title'}) ? $in{'title'} : $index[0];
	for(my $i=1; $i<= $#index; $i++)
	{
		printf IDX "%s %s %s %s\n", $index[$i]->{name}, '-', '-', ($in{$i}) ? $in{$i} : $index[$i]->{description};
	}
	close IDX;

	directory_listing($r,0);

}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Apache::PhotoIndex - Perl extension for creating a Photo Gallery with mod_perl creating everything on the fly

=head1 SYNOPSIS

AddType text/photo .photo
SetHandler perl-script
PerlModule Apache::PhotoIndex
PerlHandler Apache::PhotoIndex

PerlModule Apache::Icon
PerlModule Imager

=head1 DESCRIPTION

This was written so that i could just upload my JPG's 	and the web server would do all of the work for me.
putting different template files in different directories to make different looks per directory if you want

=head1 USAGE

In your apache conf or .htaccess file put what is in the synopsys
Make sure that you have Imager installed, this can be instelled from cpan or found at http://www.eecs.umich.edu/~addi/perl/Imager/

The displayed pages are done by using templates that you may create your own template or use the default.
There are two different typs of templages and two ways to create your own template:

	Type 1. Index Template: This is the page displayed with the thumbnails on it
			a. if you create a file named .indextemplate in the directory with
			   the images PhotoIndex will use this file
			b. in your .htaccess or apache conf file place
			   PerlSetVar IndexTemplate '/var/photoindextemplate/mytemplate.html'


		Variables: In this page you can use the following variables for replacement 
			a. %%title%%
				this is the defined title for the gallery, default is Photo Album
			b. %%directories%%
				this is a listing of all subdirectories off of this directory
			c. %%imagetable%%
				this is the table that contains all of the thumbnails
			d. %%others%%
				this is a listing of links to the other files in this directory that
				are not images
			
	Type 2. Individual Template: This is the page displayed with one jpg on it and back and next thumbnails
			a. if you create a file named .individualtemplate in the directory with
			   the images PhotoIndex will use this file
			b. in your .htaccess or apache conf file place
			   PerlSetVar IndividualTemplate '/var/photoindextemplate/myindividualtemplate.html'
		
		Variables: In this page you can use the following variables for replacement 
			a. %%back%%
				this is the thumbnail and link going back one image
			b. %%next%%
				this is the thumbnail and link going forward one image
			c. %%image%%
				this is the big jpg with the description
	


Editing Descriptions:
	while looking at an index of images add ?edit_photos onto the end of the query string.
	BEWARE in this version i did not build it in to protect that so anyone could edit your photos
	unless you put it in to block it.
	The next version will have a protection for this

=head1 INSTALLATION

	perl Makefile.PL
	make
	make test
	make install

=head1 AUTHOR

tanguy@decourson.com (myneid)

=head1 SEE ALSO

perl(1), Imager.

=cut
