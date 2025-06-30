# ABSTRACT: Automatically generated class for Playwright::Mouse
# PODNAME: Playwright::Mouse

# These classes used to be generated at runtime, but are now generated when the module is built.
# Don't send patches against these modules, they will be ignored.
# See generate_perl_modules.pl in the repository for generating this.

use strict;
use warnings;

package Playwright::Mouse;
$Playwright::Mouse::VERSION = '1.531';
use parent 'Playwright::Base';

sub new {
    my ( $self, %options ) = @_;
    $options{type} = 'Mouse';
    return $self->SUPER::new(%options);
}

sub spec {
    return $Playwright::spec->{'Mouse'}{members};
}

sub wheel {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'wheel',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub down {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'down',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub up {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'up',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub move {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'move',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub dblclick {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'dblclick',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub click {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'click',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub on {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'on',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub evaluate {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'evaluate',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub evaluateHandle {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'evaluateHandle',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Playwright::Mouse - Automatically generated class for Playwright::Mouse

=head1 VERSION

version 1.531

=head1 CONSTRUCTOR

=head2 new(%options)

You shouldn't have to call this directly.
Instead it should be returned to you as the result of calls on Playwright objects, or objects it returns.

=head1 METHODS

=head2 wheel(@args)

Execute the Mouse::wheel playwright routine.

See L<https://playwright.dev/docs/api/class-Mouse#Mouse-wheel> for more information.

=head2 down(@args)

Execute the Mouse::down playwright routine.

See L<https://playwright.dev/docs/api/class-Mouse#Mouse-down> for more information.

=head2 up(@args)

Execute the Mouse::up playwright routine.

See L<https://playwright.dev/docs/api/class-Mouse#Mouse-up> for more information.

=head2 move(@args)

Execute the Mouse::move playwright routine.

See L<https://playwright.dev/docs/api/class-Mouse#Mouse-move> for more information.

=head2 dblclick(@args)

Execute the Mouse::dblclick playwright routine.

See L<https://playwright.dev/docs/api/class-Mouse#Mouse-dblclick> for more information.

=head2 click(@args)

Execute the Mouse::click playwright routine.

See L<https://playwright.dev/docs/api/class-Mouse#Mouse-click> for more information.

=head2 on(@args)

Execute the Mouse::on playwright routine.

See L<https://playwright.dev/docs/api/class-Mouse#Mouse-on> for more information.

=head2 evaluate(@args)

Execute the Mouse::evaluate playwright routine.

See L<https://playwright.dev/docs/api/class-Mouse#Mouse-evaluate> for more information.

=head2 evaluateHandle(@args)

Execute the Mouse::evaluateHandle playwright routine.

See L<https://playwright.dev/docs/api/class-Mouse#Mouse-evaluateHandle> for more information.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Playwright|Playwright>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/playwright-perl/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <teodesian@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2020 Troglodyne LLC


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
