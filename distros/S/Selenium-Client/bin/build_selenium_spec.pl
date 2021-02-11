#!/usr/bin/perl

package Bin::build_selenium_spec;
$Bin::build_selenium_spec::VERSION = '1.02';
#ABSTRACT: Convenience script to fetch the selenium specification from WC3

use strict;
use warnings;

use v5.28;

no warnings 'experimental';
use feature qw/signatures/;

use Getopt::Long qw{GetOptionsFromArray};
use Pod::Usage;

use Selenium::Specification;

exit main(@ARGV) unless caller;

sub main(@args) {
    my %options;
    GetOptionsFromArray(\@args,
        'verbose' => \$options{verbose},
        'dir=s'   => \$options{dir},
        'force'   => \$options{force},
        'help'    => \$options{help},
    );
    return pod2usage(verbose => 2, noperldoc => 1) if $options{help};
    Selenium::Specification::fetch(%options);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bin::build_selenium_spec - Convenience script to fetch the selenium specification from WC3

=head1 VERSION

version 1.02

=head1 build_selenium_spec.pl

Fetches the latest versions of the Selenium specification(s) from the internet and stores them in

    ~/.selenium/specs

As a variety of JSON files.

=head1 USAGE

=head2 -h --help

Print this message

=head2 -v, --verbose

Print messages rather than being silent

=head2 -d --dir $DIR

Put the files in a different directory than the default.

=head2 -f --force

Force a re-fetch even if your copy is newer than that available online.
Use to correct corrupted specs.

=head1 AUTHOR

George S. Baugh <george@troglodyne.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by George S. Baugh.

This is free software, licensed under:

  The MIT (X11) License

=cut
