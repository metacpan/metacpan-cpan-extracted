# ABSTRACT: Automatically generated class for Playwright::FrameLocator
# PODNAME: Playwright::FrameLocator

# These classes used to be generated at runtime, but are now generated when the module is built.
# Don't send patches against these modules, they will be ignored.
# See generate_perl_modules.pl in the repository for generating this.

use strict;
use warnings;

package Playwright::FrameLocator;
$Playwright::FrameLocator::VERSION = '1.531';
use parent 'Playwright::Base';

sub new {
    my ( $self, %options ) = @_;
    $options{type} = 'FrameLocator';
    return $self->SUPER::new(%options);
}

sub spec {
    return $Playwright::spec->{'FrameLocator'}{members};
}

sub frameLocator {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'frameLocator',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub getByTestId {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'getByTestId',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub getByLabel {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'getByLabel',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub getByText {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'getByText',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub getByTitle {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'getByTitle',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub getByAltText {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'getByAltText',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub getByPlaceholder {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'getByPlaceholder',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub owner {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'owner',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub nth {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'nth',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub first {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'first',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub getByRole {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'getByRole',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub last {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'last',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub locator {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'locator',
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

Playwright::FrameLocator - Automatically generated class for Playwright::FrameLocator

=head1 VERSION

version 1.531

=head1 CONSTRUCTOR

=head2 new(%options)

You shouldn't have to call this directly.
Instead it should be returned to you as the result of calls on Playwright objects, or objects it returns.

=head1 METHODS

=head2 frameLocator(@args)

Execute the FrameLocator::frameLocator playwright routine.

See L<https://playwright.dev/docs/api/class-FrameLocator#FrameLocator-frameLocator> for more information.

=head2 getByTestId(@args)

Execute the FrameLocator::getByTestId playwright routine.

See L<https://playwright.dev/docs/api/class-FrameLocator#FrameLocator-getByTestId> for more information.

=head2 getByLabel(@args)

Execute the FrameLocator::getByLabel playwright routine.

See L<https://playwright.dev/docs/api/class-FrameLocator#FrameLocator-getByLabel> for more information.

=head2 getByText(@args)

Execute the FrameLocator::getByText playwright routine.

See L<https://playwright.dev/docs/api/class-FrameLocator#FrameLocator-getByText> for more information.

=head2 getByTitle(@args)

Execute the FrameLocator::getByTitle playwright routine.

See L<https://playwright.dev/docs/api/class-FrameLocator#FrameLocator-getByTitle> for more information.

=head2 getByAltText(@args)

Execute the FrameLocator::getByAltText playwright routine.

See L<https://playwright.dev/docs/api/class-FrameLocator#FrameLocator-getByAltText> for more information.

=head2 getByPlaceholder(@args)

Execute the FrameLocator::getByPlaceholder playwright routine.

See L<https://playwright.dev/docs/api/class-FrameLocator#FrameLocator-getByPlaceholder> for more information.

=head2 owner(@args)

Execute the FrameLocator::owner playwright routine.

See L<https://playwright.dev/docs/api/class-FrameLocator#FrameLocator-owner> for more information.

=head2 nth(@args)

Execute the FrameLocator::nth playwright routine.

See L<https://playwright.dev/docs/api/class-FrameLocator#FrameLocator-nth> for more information.

=head2 first(@args)

Execute the FrameLocator::first playwright routine.

See L<https://playwright.dev/docs/api/class-FrameLocator#FrameLocator-first> for more information.

=head2 getByRole(@args)

Execute the FrameLocator::getByRole playwright routine.

See L<https://playwright.dev/docs/api/class-FrameLocator#FrameLocator-getByRole> for more information.

=head2 last(@args)

Execute the FrameLocator::last playwright routine.

See L<https://playwright.dev/docs/api/class-FrameLocator#FrameLocator-last> for more information.

=head2 locator(@args)

Execute the FrameLocator::locator playwright routine.

See L<https://playwright.dev/docs/api/class-FrameLocator#FrameLocator-locator> for more information.

=head2 on(@args)

Execute the FrameLocator::on playwright routine.

See L<https://playwright.dev/docs/api/class-FrameLocator#FrameLocator-on> for more information.

=head2 evaluate(@args)

Execute the FrameLocator::evaluate playwright routine.

See L<https://playwright.dev/docs/api/class-FrameLocator#FrameLocator-evaluate> for more information.

=head2 evaluateHandle(@args)

Execute the FrameLocator::evaluateHandle playwright routine.

See L<https://playwright.dev/docs/api/class-FrameLocator#FrameLocator-evaluateHandle> for more information.

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
