#!/usr/bin/perl
# $Id: pmd_cgidepend.plx 6570 2006-06-27 15:01:04Z timbo $

### YOU MAY NEED TO EDIT THE SHEBANG LINE!

use strict;

### EDIT THIS LINE - You may need to point this at some special lib directory
use lib qw(/home/piers/src/dependency/lib);

### EDIT THIS LINE - New versions of GD do not support GIF
### Set this to 'GIF' or 'PNG' depending on what your GD can handle
### This program will try to override this if the CGI parameter 'format' is given: this
### value is used when no guess can be made
use constant DEFAULT_FORMAT => 'PNG';

### EDIT THIS - set it to the URL of the stylesheet you want to use
use constant STYLESHEET_LOC => '/depend.css';

### EDIT THIS OPTIONALLY - this value will be prepended to the incoming 'datafile' parameter, allowing you to restrict it to a single directory
use constant DATADIR => '';

### EDIT THIS OPTIONALLY - if true then we'll print a clientside imagemap/make SVGs clickable. if false, no imagemap
use constant DOES_IMAGEMAP => 1;

### EDIT THIS OPTIONALLY - set to 'object' or 'embed'. the default way of embedding an SVG image into the page. Apparently we _should_ use object but many browsers can't handle that
use constant HOW_EMBED => 'object';

use CGI;
use Module::Dependency::Info;
use Module::Dependency::Grapher;

use vars qw/$VERSION $cgi %MIMELUT/;

($VERSION) = ('$Revision: 6570 $' =~ /([\d\.]+)/ );
$cgi = new CGI;
%MIMELUT = (
	'GIF' => 'image/gif',
	'PNG' => 'image/png',
	'JPG' => 'image/jpeg',
	'SVG' => 'image/svg+xml',
);

eval {
	# no parameters... print the usage
	unless ( $cgi->param('go') ) {
		print CGI::header('text/plain');
		require Pod::Text;
		Pod::Text::pod2text($0);
		die("NORMALEXIT");
	}
	
	my $datafile = $cgi->param('datafile');
	my $allscripts = $cgi->param('allscripts');
	my $re = $cgi->param('re');
	my $xre = $cgi->param('xre');
	my $seed;
	unless ( $allscripts) {
		$seed = $cgi->param('seed') || die("There must be a 'seed' specified");
	}
	my $kind = $cgi->param('kind') || 'both';
	my $embed = $cgi->param('embed');
	my $format = $cgi->param('format') || DEFAULT_FORMAT;
	$format =~ s/\W//g;
	$format = uc($format);
	my $howembed = lc($cgi->param('howembed')) || HOW_EMBED;
	
	if ($datafile) {
		die("Unlikely characters in filename") if ($datafile =~ m/[^\w\/\:\.-]/);
		die("Unlikely looking filename") if ($datafile =~ m/\.\./);
		Module::Dependency::Grapher::setIndex( DATADIR . $datafile );
	}

	# what modules/scripts will be included
	my @objlist;
	my $objliststr;
	my $plural = '';
	
	if ( $allscripts ) {
		@objlist = @{ Module::Dependency::Info::allScripts() };
		$plural = 's';
		$objliststr = 'All Scripts';
	} else {
		if (index($seed, ',') > -1) {
			@objlist = split(/,\s*/, $seed);
			$plural = 's';
			$objliststr = join(', ', @objlist);
		} else {
			@objlist = $objliststr = $seed;
		}
	}
	
	my $title;
	if ($kind == 'both') {
		$title = "Parent + child dependencies for package$plural $objliststr";
	} elsif ($kind == 'parent') {
		$title = "Parent dependencies for package$plural $objliststr";
	} else {
		$title = "Dependencies for package$plural $objliststr";
	}

	my $scripturl = $ENV{SCRIPT_URL} || $ENV{SCRIPT_NAME};
	my $cgi_this_time = "$scripturl?go=1&amp;kind=$kind&amp;format=$format&amp;datafile=$datafile&amp;allscripts=$allscripts&amp;re=$re&amp;xre=$xre&amp;howembed=$howembed";

	if ( $embed == 1 ) {
		print CGI::header( $MIMELUT{$format} );
		
		my @imopts;
		if (DOES_IMAGEMAP) { @imopts = ('HrefFormat', "$cgi_this_time&amp;seed=%s"); }
		my @args = ( $kind, \@objlist, '-', {Title => $title, Format => $format, IncludeRegex => $re, ExcludeRegex => $xre, @imopts} );

		if ($format eq 'SVG') {
			Module::Dependency::Grapher::makeSvg( @args );
		} else {
			Module::Dependency::Grapher::makeImage( @args );
		}
	} else {
		print CGI::header('text/html');
		if ( $embed == 0 ) {
			my $title = $seed || 'all scripts';
			print qq(<html>\n<head><title>Dependencies for $title</title>\n<link rel="stylesheet" href=") . STYLESHEET_LOC . qq(" type="text/css">\n</head>\n<body>\n);
		}
		
		print qq(<h1>Dependency Information for $seed</h1><hr />\n<h2>Plot of relationships</h2>\n);

		if ($format eq 'SVG') {
			if ($howembed eq 'object') {
				print qq(<object type="image/svg+xml" data="$cgi_this_time&amp;seed=$seed&amp;embed=1" name="dependsvg" width="95%"></object>\n);
			} else {
				print qq(<embed type="image/svg+xml" src="$cgi_this_time&amp;seed=$seed&amp;embed=1" width="95%" name="dependsvg" pluginspage="http://www.adobe.com/svg/viewer/install/" />\n);
			}
		} else {
			print qq(<img src="$cgi_this_time&amp;seed=$seed&amp;embed=1" alt="Dependency tree image (client-side imagemap)" ) . ( DOES_IMAGEMAP ? 'usemap="#dependence" ' : '' ) . qq(/>\n);
		}
		print qq(<p>Alternatively, you can <a href="$cgi_this_time&amp;seed=$seed&amp;embed=1" alt="Graphical dependency tree for $title" target="_blank">view this dependency tree in a new window</a>.</p>\n);
		
		my @imopts;
		if (DOES_IMAGEMAP && $format ne 'SVG') { @imopts = ('ImageMap', 'print', 'HrefFormat', "$cgi_this_time&amp;seed=%s"); }
		Module::Dependency::Grapher::makeHtml( $kind, \@objlist, '-', {Title => $title, NoVersion => 1, NoLegend => 1, IncludeRegex => $re, ExcludeRegex => $xre, @imopts});

		unless ( $allscripts ) {
			foreach ( @objlist ) {
				print "\n<hr />\n";
				my $obj = Module::Dependency::Info::getItem( $_ ) || do {print("<h2>No such item *$_* in database</h2>\n"); next;};
				
				print "<h2>Textual information for $_</h2>\n<dl>\n<dt>Direct Dependencies</dt>\n";
				if (exists($obj->{'depends_on'})) {
					print "<dd>", join(', ', sort(@{$obj->{'depends_on'}})), "</dd>\n";
				} else {
					print "<dd>none</dd>\n";
				}

				print "<dt>Direct Parent Dependencies</dt>\n";
				if (exists($obj->{'depended_upon_by'})) {
					print "<dd>", join(', ', sort(@{$obj->{'depended_upon_by'}})), "</dd>";
				} else {
					print "<dd>none</dd>\n";
				}		
				print "<dt>Full Filesystem Path</dt>\n";
				print "<dd>$obj->{'filename'}</dd>\n</dl>\n";
			}
		}
		html_foot();
		if ( $embed == 0 ) { print qq(</body></html>\n); }

	}
};
if ($@ && $@ !~ /NORMALEXIT/) {
	print CGI::header('text/plain');
	print "Error encountered! The error was: $@";
}

### END OF MAIN

sub esc {
	my $x = shift;
	$x =~ s/&/&amp;/g;
	$x =~ s/</&lt;/g;
	$x =~ s/>/&gt;/g;
	return $x;
}

sub html_foot {
	my $prog = $0;
	$prog =~ s|^.*/||;
	print qq(\n<hr />\n<p>$prog version $VERSION</p>\n);
}

__END__

=head1 NAME

cgidepend - display Module::Dependency info to your web browser

=head1 SYNOPSIS

Called without any/sufficient parameters you get this documentation returned.
	
These CGI parameters are recognized:

=over 4

=item go

Must be true - used to ensure we have been called correctly

=item embed

If 1, returns an image, if 0 returns the HTML, if 2 returns the HTML with no header/footer, suitable for including in another web page.

=item howembed

'object' (the default, set as a constant) or 'embed' - if using an SVG image, specify how you want the image embedded in the page.

=item format

Optionally, specifically ask for one kind of image format (default is 'PNG', but may be 
'GIF' or whatever your GD allows)

=item datafile

Optionally sets the data file location. The constant DATADIR (default is '') is prepended to this to restrict the files that can be used.

=item seed

Which item to start with, or...

=item allscripts

if true, use all the scripts in the database as seeds

=item kind

Which dependencies to plot - may be 'both' (the default) 'parent' or 'child'.

=item re

A regular expression - only show items matching this regex.

=item xre

A regular expression - do not show items matching this regex.

=back

=head1 DESCRIPTION

The original thought that created the Module::Dependency software came when browsing our
CVS repository. CVSWeb is installed to allow web browsing, and a tree of documentation is
made automatically. I thought it would be useful to see what a module depended upon, and
what depended upon it.

This CGI is an attempt at doing that. It can be called in 2 modes: one returns the HTML of
the page, and the other returns a PNG (or GIF) that the page embeds.

The HTML mode basically gives you all the dependency info for the item, and the image shows
it to you in an easy to understand way.

=head1 NOTES

This program can build a client-side imagemap which allows you to click on an item in the image and make that the
root of the dependency tree. If a robot, spider or similar web-crawling program finds your CGI it may decide to follow
all the links it can find, including those in the imagemap. Personally I don't find this a problem, but it's
just something to be aware of. You can disable the imagemap by setting the DOES_IMAGEMAP constant to zero.
This also disable clickable text in SVG images, if used.

If you want to change the default values of anything, edit this script and look at the top of the file.

=head1 VERSION

$Id: pmd_cgidepend.plx 6570 2006-06-27 15:01:04Z timbo $

=cut


