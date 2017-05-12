=head1 NAME

Test::DataDirs::Exporter - manage t/data and t/temp directories for your tests

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

Like the base class L<Test::DataDirs>, this is a convenience which
provides data directories from which to source information for your
tests, and temp directories you can write data.

Declare some temp and data directories you need in your test script as
below.  These are implicitly relative to C<< t/temp/<yourscriptname> >>
 and C<< t/data/<yourscriptname> >>.  Then you may refer to them
using the imported variables, and assume the dirs
exist and that the temp dirs have been (re-)created.

    # File: t/test-01.t
    use Test::DataDirs::Exporter (
        temp => [temp_stuff => 'actual-dir',
                 more_temp  => 'another-dir'],
        data => [data_stuff => 'actual-dir'],
    );

    print "My test data is checked into $data_stuff\n"
    print "below $data_dir\n"
    # Prints (except with absolute paths):
    # My test data is checked into t/data/test-01/actual-dir
    # below t/data/test-01

    print "I can write temp data into $temp_stuff\n"
    print "and $more_temp, "below $temp_dir\n"
    # Prints (except with absolute paths):
    # I can write temp data into t/temp/test-01/actual-dir
    # and t/temp/test-01/another-dir below t/data/test-01


=head1 DESCRIPTION

=cut

package Test::DataDirs::Exporter;
use strict;
use warnings;
use Test::DataDirs;
use Carp;
our @CARP_NOT = 'Test::DataDirs';

our $VERSION = '0.1.2'; # VERSION

sub import {
    my $package = shift;
    my $target = caller;

    my $dirs = Test::DataDirs->new(@_)->dirs;
    no strict 'refs'; ## no critic
    for my $name (keys %$dirs) {
        *{"${target}::$name"} = \$dirs->{$name};
    }
}

1;
