#!/usr/bin/env perl
## no critic (RequireUseWarnings, RequireUseStrict)
use Shell::Tools;

# this script is called from the test scripts to test getopts and pod2usage

# Tests for the Perl module Shell::Tools
# 
# Copyright (c) 2014 Hauke Daempfling (haukex@zero-g.net).
# 
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl 5 itself.
# 
# For more information see the "Perl Artistic License",
# which should have been distributed with your copy of Perl.
# Try the command "perldoc perlartistic" or see
# http://perldoc.perl.org/perlartistic.html .

=head1 SYNOPSIS

 test_opts_usage.pl [OPTIONS] FILENAME
 OPTIONS:
 -f       - foo
 -b BAR   - bar

=cut

our $VERSION = "0.123";

getopts('fb:', \my %opts) or pod2usage;
pod2usage("must specify a filename") unless @ARGV==1;

pod2usage("bad bar option") if $opts{b} && $opts{b}=~/err|fail/i;

print "Foo=", $opts{f} ? '1' : '0',
	", Bar=", $opts{b} ? $opts{b} : '(0)',
	", FN=", $ARGV[0];
