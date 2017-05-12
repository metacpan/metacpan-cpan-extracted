#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

use Module::Metadata::CoreList;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
 \%option,
 'dir_name=s',
 'file_name=s',
 'help',
 'perl_version=s',
 'report_type=s',
) )
{
	pod2usage(1) if ($option{'help'});

	exit Module::Metadata::CoreList -> new(%option) -> run;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

cc.corelist.pl - Cross-check pre-reqs in Build.PL/Makefile.PL with Module::CoreList

=head1 SYNOPSIS

cc.corelist.pl [options]

	Options:
	-dir_name dirName
	-file_name Build.PL or Makefile.PL
	-help
	-perl_version version
	-report_type html or text

All switches can be reduced to a single letter.

Exit value: 0.

=head1 OPTIONS

=over 4

=item o -dir_name dirName

Specify the name of the directory in which to look for Build.PL and/or Makefile.PL.

These 2 files are searched for in alphabetical order.

Default: '.'.

=item o -file_name Build.PL or Makefile.PL

Specify the name of the file to process, if you don't want the program to search as
explained under -dir_name.

Default: ''.

=item o -help

Print help and exit.

=item o -perl_version version

Specify the version number of Perl to use to access data in Module::CoreList.

Perl V 5.10.1 must be written as 5.010001, and V 5.12.1 as 5.012001.

Default: ''.

=item o -report_type html or text

Specify the output report type:

=over 4

=item o html

Use htdocs/assets/templates/module/metadata/corelist/web.page.tx as the HTML
template, and write the report to STDOUT.

=item o text

Write the report to STDOUT.

=back

=back

=cut
