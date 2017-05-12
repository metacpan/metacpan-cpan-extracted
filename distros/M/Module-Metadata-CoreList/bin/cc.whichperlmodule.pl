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
 'help',
 'module_name=s',
 'perl_version=s',
) )
{
	pod2usage(1) if ($option{'help'});

	exit Module::Metadata::CoreList -> new(%option) -> check_perl_for_module;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

cc.whichperlmodule.pl - Search Module::CoreList for a module within a given version of Perl

=head1 SYNOPSIS

cc.whichperlmodule.pl [options]

	Options:
	-help
	-module_name NameOfModule
	-perl_version VersionOfPerl

All switches can be reduced to a single letter.

Exit value: 0.

=head1 OPTIONS

=over 4

=item o -help

Print help and exit.

=item o -module_name NameOfModule

Specify the name of the module to be searched for, for the given version of Perl.

Default: ''.

=item o -perl_version VersionOfPerl

Specify the version number of Perl to search.

Perl V 5.10.1 must be written as 5.010001, and V 5.12.1 as 5.012001.

Default: ''.

=back

=cut
