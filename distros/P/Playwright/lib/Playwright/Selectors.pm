# ABSTRACT: Automatically generated class for Playwright::Selectors
# PODNAME: Playwright::Selectors

# These classes used to be generated at runtime, but are now generated when the module is built.
# Don't send patches against these modules, they will be ignored.
# See generate_perl_modules.pl in the repository for generating this.

use strict;
use warnings;

package Playwright::Selectors;
$Playwright::Selectors::VERSION = '1.531';
use parent 'Playwright::Base';

sub new {
    my ( $self, %options ) = @_;
    $options{type} = 'Selectors';
    return $self->SUPER::new(%options);
}

sub spec {
    return $Playwright::spec->{'Selectors'}{members};
}

sub register {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'register',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub setTestIdAttribute {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'setTestIdAttribute',
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

Playwright::Selectors - Automatically generated class for Playwright::Selectors

=head1 VERSION

version 1.531

=head1 CONSTRUCTOR

=head2 new(%options)

You shouldn't have to call this directly.
Instead it should be returned to you as the result of calls on Playwright objects, or objects it returns.

=head1 METHODS

=head2 register(@args)

Execute the Selectors::register playwright routine.

See L<https://playwright.dev/docs/api/class-Selectors#Selectors-register> for more information.

=head2 setTestIdAttribute(@args)

Execute the Selectors::setTestIdAttribute playwright routine.

See L<https://playwright.dev/docs/api/class-Selectors#Selectors-setTestIdAttribute> for more information.

=head2 on(@args)

Execute the Selectors::on playwright routine.

See L<https://playwright.dev/docs/api/class-Selectors#Selectors-on> for more information.

=head2 evaluate(@args)

Execute the Selectors::evaluate playwright routine.

See L<https://playwright.dev/docs/api/class-Selectors#Selectors-evaluate> for more information.

=head2 evaluateHandle(@args)

Execute the Selectors::evaluateHandle playwright routine.

See L<https://playwright.dev/docs/api/class-Selectors#Selectors-evaluateHandle> for more information.

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
