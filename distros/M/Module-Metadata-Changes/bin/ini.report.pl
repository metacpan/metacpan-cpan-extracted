#!/usr/bin/env perl
#
# Name:
#	ini.report.pl.
#
# Description:
#	Process old-style and new-style Changelog.ini files.

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Module::Metadata::Changes;

# --------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
 \%option,
 'convert',
 'help',
 'inFileName=s',
 'outFileName=s',
 'pathForHTML=s',
 'release=s',
 'table',
 'urlForCSS=s',
 'verbose',
 'webPage',
) )
{
	pod2usage(1) if ($option{'help'});

	exit Module::Metadata::Changes -> new(%option) -> run();
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

ini.report.pl - Process old-style and new-style Changelog.ini files

=head1 SYNOPSIS

ini.report.pl [options]

	Options:
	-convert
	-help
	-inFileName anInputFileName
	-outFileName anOutputFileName
	-pathForHTML aPathForHTML
	-release aVersionNumber
	-table
	-urlForCSS aURLForCSS
	-version
	-webPage

All switches can be reduced to a single letter.

Exit value: 0.

Typical switch combinations:

=over 4

=item o No switches

Produce a text report on all versions.

=item o -c

Convert C<Changes> to C<Changelog.ini>.

Use -c -i CHANGES to read a file called C<CHANGES>.

=item o -r 1.23

Produce a text report on a specific version.

Since -c is not used, -i defaults to C<Changelog.ini>.

=item o -t

Produce a HTML report on all versions.

The report will just be a HTML C<table>, with CSS for Deploy.Action and Deploy.Reason.

The table can be embedded in your own web page.

=item o -r 1.23 -t

Produce a HTML report on a specific version.

The report will just be a HTML C<table>, with CSS for Deploy.Action and Deploy.Reason.

The table can be embedded in your own web page.

=item o -w

Produce a HTML report on all versions.

The report will be a HTML C<page>, with CSS for Deploy.Action and Deploy.Reason.

=item o -r 1.23 -w

Produce a HTML report on a specific version.

The report will be a HTML C<page>, with CSS for Deploy.Action and Deploy.Reason.

=back

=head1 OPTIONS

=over 4

=item o -convert

This specifies that the program is to read an old-style C<Changes> file, and is to write a new-style
C<Changelog.ini> file.

When -convert is used, the default -inFileName is C<Changes>, and the default -outFileName is C<Changelog.ini>.

=item o -help

Print help and exit.

=item o -inFileName anInputFileName

The name of a file to be read.

When the -convert switch is used, -inFileName defaults to C<Changes>, and -outFileName
defaults to C<Changelog.ini>.

In the absence of -convert, -inFileName defaults to C<Changelog.ini>, and -outFileName
is not used.

=item o -outFileName anOutputFileName

The name of a file to be written.

=item o -pathForHTML aPathForHTML

The path to the HTML::Template-style templates used by the -table and -webPage switches.

Default: '/dev/shm/html/assets/templates/module/metadata/changes'.

=item o -release aVersionNumber

Report on a specific release/version.

If this switch is not used, all versions are reported on.

=item o -table

Output the report as a HTML table.

HTML is escaped using C<HTML::Entities::Interpolate>.

The table template is called C<ini.table.tmpl>.

=item o -urlForCSS aURLForCSS

The URL to insert into the web page, if using the -webPage switch,
which points to the CSS for the page.

Defaults to /assets/css/module/metadata/changes/ini.css.

=item o -verbose

Print verbose messages.

=item o -webPage

Output the report as a HTML page.

The page template is called C<ini.page.tmpl>.

This switch automatically activates the -table switch.

=back

=head1 DESCRIPTION

ini.report.pl processes old-style 'Changes' and new-style 'Changelog.ini' files.

=cut
