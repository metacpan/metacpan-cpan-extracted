#!/usr/bin/perl

package Bin::build_selenium_spec;
$Bin::build_selenium_spec::VERSION = '2.01';
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

version 2.01

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

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Selenium::Client|Selenium::Client>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/troglodyne-internet-widgets/selenium-client-perl/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2024 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
