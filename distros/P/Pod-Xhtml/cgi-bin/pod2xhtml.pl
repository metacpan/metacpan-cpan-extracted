#!/usr/local/bin/perl

use strict;
use CGI;
use Pod::Xhtml;

#Inputs
my @css = CGI::param('css');
my $file = (CGI::param('file') =~ m|^([\w\-/]+\.\w+)$|)[0]; #Only allow sensibly named files (no ../ etc)
my $module = (CGI::param('module') =~ m|^([\w:]+)$|)[0];    #Only allow sensible module names
my $docroot = $ENV{DOCROOT} || $ENV{DOCUMENT_ROOT};

#Deduce filename
if(defined $module)
{
	$file = $module;
	$file =~ s|::|/|g;
 MODULESEARCH:
	foreach my $inc_path (@INC)
	{
		foreach my $ext (qw(pm pod)) {
			my $candidate = "$inc_path/$file.$ext";
			if(-f $candidate) {
				$file = $candidate;
				last MODULESEARCH;
			}
		}
	}
}
elsif(defined $file)
{
	$file = $docroot.$file;
}
elsif(defined $ENV{PATH_TRANSLATED})
{
	$file = $ENV{PATH_TRANSLATED};
}

#Render
print CGI::header();
if(not defined $file)
{
	print "No recognisable filename\n";
}
elsif(not -f $file)
{
	print "$file does not exist\n";
}
else
{
	#Render the XHTML
	my $link_parser = new LinkResolver(\@css);
	my $parser = new Pod::Xhtml(StringMode => 1, LinkParser => $link_parser);
	$parser->addHeadText(qq[<link rel="stylesheet" href="$_"/>\n]) for @css;
	$parser->parse_from_file($file);
	print $parser->asString();
}

#
# Subclass Pod::Hyperlink to create self-referring links
#

package LinkResolver;
use Pod::ParseUtils;
use base qw(Pod::Hyperlink);

sub new
{
	my $class = shift;
	my $css = shift;
	my $self = $class->SUPER::new();
	$self->{css} = $css;
	return $self;
}

sub node
{
	my $self = shift;
	if($self->SUPER::type() eq 'page')
	{
		my $url = "?module=".$self->SUPER::page();
		$url.=";css=".$_ for @{$self->{css}};
		return $url;
	}
	$self->SUPER::node(@_);
}

sub text
{
	my $self = shift;
	return $self->SUPER::page() if($self->SUPER::type() eq 'page');
	$self->SUPER::text(@_);
}

sub type
{
	my $self = shift;
	return "hyperlink" if($self->SUPER::type() eq 'page');
	$self->SUPER::type(@_);
}

1;

=head1 NAME

pod2xhtml - CGI to display POD as XHTML

=head1 SYNOPSIS

	http://localhost/cgi-bin/pod2xhtml.pl?file=/cgi-bin/pod2xhtml.pl
	http://localhost/cgi-bin/pod2xhtml.pl?module=Pod::Xhtml

=head1 DESCRIPTION

Displays POD of scripts within the web server's document root and modules within @INC.
If you keep your CGIs in a directory parallel to your web content, you can use the $DOCROOT environment variable to allow this script access.
For example if your web server layout is:

	/var/wwwroot/www
	/var/wwwroot/cgi-bin

You can add:

	SetEnv DOCROOT /var/wwwroot

to your Apache config to allow the script access to all the files below /var/wwwroot.

=head1 CGI PARAMETERS

 css - URL of stylesheet to apply
 file - name of file relative to document root
 module - name of module in @INC

=head1 VERSION

$Revision: 1.8 $ on $Date: 2004/10/22 14:44:05 $ by $Author: simonf $

=head1 AUTHOR

John Alden E<lt>cpan _at_ bbc _dot_ co _dot_ ukE<gt>

=head1 COPYRIGHT

(c) BBC 2004. This program is free software; you can redistribute it and/or
modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=cut
