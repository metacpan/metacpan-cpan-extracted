package Selenium::Driver::Auto;
$Selenium::Driver::Auto::VERSION = '2.01';
#ABSTRACT: Automatically choose the best driver available for your browser choice

use strict;
use warnings;

use Carp qw{confess};
use File::Which;

# Abstract: Automatically figure out which driver you want


sub build_spawn_opts {

    # Uses object call syntax
    my ( undef, $object ) = @_;

    if ( $object->{browser} eq 'firefox' ) {
        require Selenium::Driver::Gecko;
        return Selenium::Driver::Gecko->build_spawn_opts($object);
    }
    elsif ( $object->{browser} eq 'chrome' ) {
        require Selenium::Driver::Chrome;
        return Selenium::Driver::Chrome->build_spawn_opts($object);
    }
    elsif ( $object->{browser} eq 'MicrosoftEdge' ) {
        require Selenium::Driver::Edge;
        return Selenium::Driver::Edge->build_spawn_opts($object);
    }
    elsif ( $object->{browser} eq 'safari' ) {
        require Selenium::Driver::Safari;
        return Selenium::Driver::Safari->build_spawn_opts($object);
    }
    require Selenium::Driver::SeleniumHQ::Jar;
    return Selenium::Driver::SeleniumHQ::Jar->build_spawn_opts($object);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Selenium::Driver::Auto - Automatically choose the best driver available for your browser choice

=head1 VERSION

version 2.01

=head1 SUBROUTINES

=head2 build_spawn_opts($class,$object)

Builds a command string which can run the driver binary.
All driver classes must build this.

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
