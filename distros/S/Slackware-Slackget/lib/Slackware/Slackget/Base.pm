package Slackware::Slackget::Base;

use warnings;
use strict;

require XML::Simple ;
require Slackware::Slackget::PackageList;
require Slackware::Slackget::Package;
require Slackware::Slackget::File;
require Slackware::Slackget::Media;
require Slackware::Slackget::MediaList ;
require Slackware::Slackget::Date ;


=head1 NAME

Slackware::Slackget::Base - A module which centralize some base methods usefull to slack-get

=head1 VERSION

Version 1.0.4

=cut

our $VERSION = '1.0.4';
eval 'use XML::Parser';
if($@) {
	warn("XML::Parser is not installed. XML processing operations will be very slow.\n");
} else {
	$XML::Simple::PREFERRED_PARSER='XML::Parser' ;
}


=head1 SYNOPSIS

This module centralize bases tasks like package directory compilation, etc. This class is mainly designed to be a wrapper so it can change a lot before the release.

    use Slackware::Slackget::Base;

    my $base = Slackware::Slackget::Base->new();
    my $packagelist = $base->compil_packages_directory('/var/log/packages/');
    $packagelist = $base->load_list_from_xml_file('installed.xml');

=cut

sub new
{
	my ($class,$config) = @_ ;
	return undef if(!defined($config) or ref($config) ne 'Slackware::Slackget::Config') ;
	my $self = {CONF => $config};
	bless($self,$class);
	return $self;
}

=head1 CONSTRUCTOR

=head2 new

Take no arguments.

	my $base = Slackware::Slackget::Base->new();

=head1 FUNCTIONS

=cut

=head2 ls

take a directory as argument and return an array wich contain all things in this directory.

	my @config_files = $base->ls('/etc/slack-get/') ;

=cut

sub ls
{
	my $self = shift;
	my $dir = shift;
	if (! opendir( DIR, $dir) )
	{
		warn "unable to open $dir : $!.";
		return undef;
	}
	my @files = grep !/(?:^\.$)|(?:^\.\$)|(?:^\.\.)/, readdir DIR;
	closedir DIR;
	for(my $k=0; $k<=$#files;$k++)
	{
		if($files[$k] !~ /^(\.\.|\.)$/)
		{
			$files[$k] = $dir.'/'.$files[$k] ;
		}
	}
	return @files;
}

=head2 dir2files

take at leat one directory in argument and recursively follow all subdirectories. Return an array containing all files encounter but WITHOUT symblic links.

	my @config_files = $base->dir2files('/etc','/usr/local/etc', "/$ENV{HOME}/etc/") ;

=cut

sub dir2files
{
	my $self = shift;
	my @f_files = ();
	
	foreach my $a (@_)
	{
# 		print STDERR "[DEBUG] [dir2files] treating $a\n";
		unless(-d $a or -l $a)
		{
# 			print STDERR "\t[DEBUG] [dir2files] file $a is not a directory nor a symlink, pushing on files stack\n";
			push @f_files,$a;
		}
		else
		{
# 			print STDERR "\t[DEBUG] [dir2files] file $a is a directory or a symlink\n";
			unless(-l $a)
			{
# 				print STDERR "\t[DEBUG] [dir2files] file $a is a directory : recurse\n";
				@f_files = (@f_files,$self->dir2files($self->ls($a)));
			}
# 			else
# 			{
# 				print "\t[dir2files] $a is a symlink\n";
# 			}
		}
	}
	return @f_files;
}

=head2 compil_packages_directory

take a directory where are store installed packages files and return a Slackware::Slackget::PackageList object

	my $packagelist = $base->compil_packages_directory('/var/log/packages/');

=cut

sub compil_packages_directory
{
	my ($self,$dir,$packagelist) = @_;
# 	print STDERR "[DEBUG] [compil_packages_directory] getting the following packages list : \"$packagelist\"\n";
# 	print STDERR "[DEBUG] [compil_packages_directory] compiling directory \"$dir\"\n";
	my @files = $self->dir2files($dir);
	$|=1;
# 	print STDERR "[DEBUG] number of entry in files array : ",scalar(@files),"\n";
# 	print STDERR "[DEBUG] entry in \@files :\n",join "\n",@files,"\n";
	my $ref;
	if($packagelist)
	{
		my $tmp_packagelist = new Slackware::Slackget::PackageList('encoding'=>$self->{CONF}->{common}->{'file-encoding'});
		while (defined(my $p = $packagelist->Shift()))
		{
# 			print "treat : $p (",$p->get_id(),")\n";
# 			<STDIN>;
			if(defined($p) && -e $self->{CONF}->{common}->{'packages-history-dir'}.'/'.$p->get_id())
			{
# 				print "adding $p\n";
				$tmp_packagelist->add( $p );
			}
		}
		$tmp_packagelist->index_list ;
		$packagelist=$tmp_packagelist;
	}
# 	print join(' :: ', $packagelist->get_indexes());
	$packagelist = new Slackware::Slackget::PackageList('encoding'=>$self->{CONF}->{common}->{'file-encoding'}) unless($packagelist);
	if(scalar(@files) < 1){
		warn "The directory \"$dir\" is empty or contains no packages.\n" ;
		return $packagelist;
	}
# 	print STDERR "Slackware::Slackget::PackageList reference : $packagelist\n";
	my $pg_idx=0;
	my $mark = int(scalar(@files)/20);
	my $msg = "[slack-get] compiling $dir (1 mark = $mark packages) : [";
	printf($msg);
	print " "x20 ;
	my $pstr= '0 %';
	print "] $pstr";
	my $mark_idx=0;
	my $percent_idx=0;
	foreach (@files)
	{
# 		NOTE: The system call is very slow compared to the built-in regular expressions ;)
# 		$_ = `basename $_`;
# 		chomp;
		$_ =~ /^.*\/([^\/]*)$/;
		#my $file_md5 = `LC_ALL=C md5sum $_ | awk '{print \$1}'`;
		#chomp($file_md5);
# 		print "searching if $1 is already indexed in the list : ",$packagelist->get_indexed($_),"\n";
		if(!defined($packagelist->get_indexed($1)) )#or ($packagelist->get_indexed($_)->getValue('package-file-checksum') ne $file_md5))
		{
	# 		print STDERR "[DEBUG] in Slackware::Slackget::Base, method compil_packages_directory file-encoding=$self->{CONF}->{common}->{'file-encoding'}\n";
			my $sg_file = new Slackware::Slackget::File ($_,'file-encoding' => $self->{CONF}->{common}->{'file-encoding'}) ;
			die $! unless $sg_file;
			my @file = $sg_file->Get_file();
			
# 			print STDERR "[DEBUG] instanciate new package : \"$1\"\n";
			$ref->{$1}= new Slackware::Slackget::Package ($1);
			next unless($ref->{$1}) ;
	# 		print STDERR "[DEBUG] package reference is $ref->{$1}\n";
			my $pack = $ref->{$1};
			for(my $k=0;$k<=$#file;$k++)
			{
				# NOTE: trying to fix a bug reporting by Adi Spivak
				next if(!defined($file[$k]));
				if($file[$k] =~ /^PACKAGE NAME:\s+(.*)$/)
				{
					my $name = $1;
					unless(defined($pack->getValue('name')) or defined($pack->getValue('version')) or defined($pack->getValue('architecture')) or defined($pack->getValue('package-version')))
					{
	# 					print STDERR "[DEBUG] Package forced to be renamed.\n";
						$pack->_setId($name);
						$pack->fill_object_from_package_name();
					}
					
				}
				elsif($file[$k] =~ /^COMPRESSED PACKAGE SIZE:\s+(.*) K$/)
				{
	# 				print STDERR "[DEBUG] setting param 'compressed-size' to $1\n";
					$pack->set_value('compressed-size',$1);
				}
				elsif($file[$k] =~ /^UNCOMPRESSED PACKAGE SIZE:\s+(.*) K$/)
				{
	# 				print STDERR "[DEBUG] setting param 'uncompressed-size' to $1\n";
					$pack->set_value('uncompressed-size',$1);
				}
				elsif($file[$k] =~ /^PACKAGE LOCATION:\s+(.*) K$/)
				{
	# 				print STDERR "[DEBUG] setting param 'location' to $1\n";
					$pack->set_value('location',$1);
				}
				elsif($file[$k]=~/PACKAGE DESCRIPTION:/)
				{
					my $tmp = "";
					$k++;
					while($file[$k]!~/FILE LIST:/ or $file[$k]!~/\.\//)
					{
						# NOTE: this line was originally added to fix the bug reported by Adi Spivak but it doesn't work well
						last if(!defined($file[$k]) or $file[$k]=~ /^\.\//);
						$tmp .= "\t\t\t$file[$k]" if( $file[$k] !~ /FILE\s*LIST\s*:\s*/);
						$k++;
					}
	# 				print STDERR "[DEBUG] setting param 'description' to $tmp\n";
					$pack->set_value('description',"$tmp\n\t\t");
					### NOTE: On my system, with 586 packages installed the difference between with or without including the file list is very important
					### NOTE: with the file list the installed.xml file size is near 11 MB
					### NOTE: without the file list, the size is only 400 KB !!
					### NOTE: So I have decided that the file list is not include by default
					if(defined($self->{'include-file-list'}))
					{
						$pack->set_value('file-list',join("\t\t\t",@file[($k+1)..$#file])."\n\t\t");
					}
					last;	
				}
			}
	# 		print STDERR "[DEBUG] calling Slackware::Slackget::Package->clean_description() on package $pack\n";
			$pack->clean_description();
	# 		print STDERR "[DEBUG] calling Slackware::Slackget::Package->grab_info_from_description() on package $pack\n";
			$pack->grab_info_from_description();
# 			$pack->set_value('package-file-checksum',$file_md5);
	# 		print STDERR "[DEBUG] calling Slackware::Slackget::PackageList->add() on package $pack\n";
			$packagelist->add($pack);
			$sg_file->Close();
			
		}
# 		else
# 		{
# 			print STDERR "[DEBUG] package $_ skipped (already in cache)\n";
# 		}
		$pg_idx++;
		$percent_idx++;
		print "\b" x length($pstr);
		$pstr = $percent_idx/scalar(@files) * 100;
		$pstr =~ /^([^\.]+)/;
		$pstr = $1 ;
		$pstr .= " %";
		print $pstr;
		if($pg_idx == $mark)
		{
			$mark_idx++;
			print "\b"x (40 + length($msg));
			print $msg;
			print '#' x $mark_idx;
			print ' ' x (20 - $mark_idx);
			print "] $pstr";
			$pg_idx=0;
		}
	}
	print " (",scalar(@files)," packages examined)\n";
	return $packagelist;
}


=head2 load_installed_list_from_xml_file

Load the data for filling the list from an XML file. Return a Slackware::Slackget::PackageList. This method is design for reading a installed.xml file.

	$packagelist = $base->load_installed_list_from_xml_file('installed.xml');

=cut

sub load_installed_list_from_xml_file {
	my ($self,$file) = @_;
	my $package_list = new Slackware::Slackget::PackageList ;
	my $xml_in = XML::Simple::XMLin($file,KeyAttr => {'package' => 'id'});
	foreach my $pack_name (keys(%{$xml_in->{'package'}})){
		my $package = new Slackware::Slackget::Package ($pack_name);
		foreach my $key (keys(%{$xml_in->{'package'}->{$pack_name}})){
			$package->set_value($key,$xml_in->{'package'}->{$pack_name}->{$key}) ;
		}
		$package_list->add($package);
	}
	return $package_list;
}


=head2 load_packages_list_from_xml_file

Load the data for filling the list from an XML file. Return a hashref built on this model :

	my $hashref = {
		'key' => Slackware::Slackget::PackageList,
		...
	};

Ex:

	my $hashref = {
		'slackware' => blessed(Slackware::Slackget::PackageList),
		'slacky' => blessed(Slackware::Slackget::PackageList),
		'audioslack' => blessed(Slackware::Slackget::PackageList),
		'linuxpackages' => blessed(Slackware::Slackget::PackageList),
	};

This method is design for reading a packages.xml file.

	$hashref = $base->load_packages_list_from_xml_file('packages.xml');

=cut

sub load_packages_list_from_xml_file {
	my ($self,$file) = @_;
	my $ref = {};
	my $start = time();
	$|=1 ;
# 	print "[DEBUG Slackware::Slackget::Base->load_packages_list_from_xml_file()] Going to parse '$file'\n";
	print "[slack-get] loading packages list...";
	$XML::Simple::PREFERRED_PARSER='XML::Parser' ;
	my $xml_in = XML::Simple::XMLin($file,KeyAttr => {'package' => 'id'}, ForceArray => ['dependencies','dependency','required','suggested']);
	print "ok (loaded in ", time() - $start," sec.)\n";
# 	print "[DEBUG Slackware::Slackget::Base->load_packages_list_from_xml_file()] '$file' correctly parsed in ", time() - $start," sec.\n" ;
	foreach my $group (keys(%{$xml_in})){
		my $package_list = new Slackware::Slackget::PackageList ;
		foreach my $pack_name (keys(%{$xml_in->{$group}->{'package'}})){
			my $package = new Slackware::Slackget::Package ($pack_name);
			foreach my $key (keys(%{$xml_in->{$group}->{'package'}->{$pack_name}})){
				if($key eq 'date')
				{
					$package->set_value($key,Slackware::Slackget::Date->new(%{$xml_in->{$group}->{'package'}->{$pack_name}->{$key}}));
				}
				else
				{
					$package->set_value($key,$xml_in->{$group}->{'package'}->{$pack_name}->{$key}) ;
				}
				
			}
			$package_list->add($package);
		}
		$ref->{$group} = $package_list;
	}
	return $ref;
}


=head2 load_media_list_from_xml_file

Load a server list from a medias.xml file.

	$serverlist = $base->load_server_list_from_xml_file('servers.xml');

=cut

sub load_media_list_from_xml_file {
	my ($self,$file) = @_;
	print "[slack-get] loading media file : $file\n";
	my $server_list = new Slackware::Slackget::MediaList ;
	my $xml_in = XML::Simple::XMLin($file,KeyAttr => {'media' => 'id'});
#  	require Data::Dumper ;
#  	print Data::Dumper::Dumper($xml_in);
	foreach my $server_name (keys(%{$xml_in->{'media'}})){
		my $server = new Slackware::Slackget::Media ($server_name);
		$server->fill_object_from_xml( $xml_in->{media}->{$server_name} );
# 		$server->print_info ;print "\n\n";
		$server_list->add($server);
	}
	return $server_list;
}

=head2 load_server_list_from_xml_file

An allias for load_media_list_from_xml_file(). Given for backward compatibility

=cut

sub load_server_list_from_xml_file{
	my ($self,$file) = @_;
	$self->load_media_list_from_xml_file($file);
}


=head2 set_include_file_list

By default the file list is not include in the installed.xml for some size consideration (on my system including the file list into installed.xml make him grow 28 times ! It passed from 400 KB to 11 MB),

So you can use this method to include the file list into installed.xml. BE carefull, to use it BEFORE compil_packages_directory() !

	$base->set_include_file_list();
	$packagelist = $base->compil_packages_directory();

=cut

sub set_include_file_list{
	my $self = shift;
	$self->{'include-file-list'} = 1;
}

=head2 ldd

Like the UNIX command ldd. Do a ldd system call on a list of files and return an array of dependencies.

	my @dependecies = $base->ldd('/usr/bin/gcc', '/usr/bin/perl', '/bin/awk') ;

=cut

sub ldd
{
	my $self = shift ;
	my @dep = ();
	foreach (@_)
	{
		foreach my $l (`ldd $_`)
		{
			if($l=~ /^\s*([^\s]*)\s*=>.*/) # linux-gate.so.1 =>  (0xffffe000) : we only want linux-gate.so.1
			{
				push @dep,$1 ;
			}
		}
	}
	return @dep;
}

=head1 AUTHOR

DUPUIS Arnaud, C<< <a.dupuis@infinityperl.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-Slackware-Slackget@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Slackware-Slackget>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Slackware-Slackget


You can also look for information at:

=over 4

=item * Infinity Perl website

L<http://www.infinityperl.org/category/slack-get>

=item * slack-get specific website

L<http://slackget.infinityperl.org>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Slackware-Slackget>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Slackware-Slackget>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Slackware-Slackget>

=item * Search CPAN

L<http://search.cpan.org/dist/Slackware-Slackget>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 DUPUIS Arnaud, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Slackware::Slackget::Base
