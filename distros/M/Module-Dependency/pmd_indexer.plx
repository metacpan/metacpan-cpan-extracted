#!/usr/bin/perl -w
# $Id: pmd_indexer.plx 6643 2006-07-12 20:23:31Z timbo $

use strict;
use Getopt::Std;
use Module::Dependency::Indexer;

use vars qw/$VERSION $opt_h $opt_t $opt_b $opt_o/;
$VERSION = (q$Revision: 6643 $ =~ /(\d+)/g)[0];

getopts('htbo:');
if ( $opt_h || !scalar(@ARGV) ) { usage(); }

*Module::Dependency::Indexer::TRACE = \*TRACE;

unless ($opt_b) { die("Use the -b option to make the index, -h for help"); }

Module::Dependency::Indexer::setIndex($opt_o) if $opt_o;
Module::Dependency::Indexer::makeIndex(@ARGV);

### END OF MAIN

sub usage {
    while (<DATA>) { last if / NAME/; }
    while (<DATA>) {
        last if / DESCRIPTION/;
        s/^\t//;
        s/^=head1 //;
        print;
    }
    exit;
}

sub TRACE {
    return unless $opt_t;
    LOG(@_);
}

sub LOG {
    my $msg = shift;
    print STDERR "> $msg\n";
}

__DATA__

=head1 NAME

pmd_indexer - make Module::Dependency index

=head1 SYNOPSIS

	pmd_indexer.plx [-h] [-t] [-o <datafile>] -b <directory> [<directory>...]

	-h Displays this help
	-t Displays trace messages
	-b Actually build the indexes
	-o the location of the datafile

	Followed by a list of directories that you want to index.

=head1 EXAMPLE

	pmd_indexer.plx -o ./unified.dat -t -b ~/src/dependency/

=head1 DESCRIPTION

Module::Dependency modules rely on a database of dependencies because creating the
index at every runtime is both expensive and unnecessary. This program
uses File::Find for every named directory and looks for .pl and .pm files, which it
then extracts dependency information from.

The default index file is $ENV{PERL_PMD_DB} or /var/tmp/dependence/unified.dat but
you can specify another using the -o option.

=head1 VERSION

$Id: pmd_indexer.plx 6643 2006-07-12 20:23:31Z timbo $

=cut


