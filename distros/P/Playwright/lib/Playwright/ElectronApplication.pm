# ABSTRACT: Automatically generated class for Playwright::ElectronApplication
# PODNAME: Playwright::ElectronApplication

# These classes used to be generated at runtime, but are now generated when the module is built.
# Don't send patches against these modules, they will be ignored.
# See generate_perl_modules.pl in the repository for generating this.

use strict;
use warnings;

package Playwright::ElectronApplication;
$Playwright::ElectronApplication::VERSION = '1.531';
use parent 'Playwright::Base';

sub new {
    my ( $self, %options ) = @_;
    $options{type} = 'ElectronApplication';
    return $self->SUPER::new(%options);
}

sub spec {
    return $Playwright::spec->{'ElectronApplication'}{members};
}

sub windows {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'windows',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub console {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'console',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub firstWindow {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'firstWindow',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub window {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'window',
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

sub browserWindow {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'browserWindow',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub process {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'process',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub close {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'close',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub context {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'context',
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

sub waitForEvent {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'waitForEvent',
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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Playwright::ElectronApplication - Automatically generated class for Playwright::ElectronApplication

=head1 VERSION

version 1.531

=head1 CONSTRUCTOR

=head2 new(%options)

You shouldn't have to call this directly.
Instead it should be returned to you as the result of calls on Playwright objects, or objects it returns.

=head1 METHODS

=head2 windows(@args)

Execute the ElectronApplication::windows playwright routine.

See L<https://playwright.dev/docs/api/class-ElectronApplication#ElectronApplication-windows> for more information.

=head2 console(@args)

Execute the ElectronApplication::console playwright routine.

See L<https://playwright.dev/docs/api/class-ElectronApplication#ElectronApplication-console> for more information.

=head2 firstWindow(@args)

Execute the ElectronApplication::firstWindow playwright routine.

See L<https://playwright.dev/docs/api/class-ElectronApplication#ElectronApplication-firstWindow> for more information.

=head2 window(@args)

Execute the ElectronApplication::window playwright routine.

See L<https://playwright.dev/docs/api/class-ElectronApplication#ElectronApplication-window> for more information.

=head2 evaluateHandle(@args)

Execute the ElectronApplication::evaluateHandle playwright routine.

See L<https://playwright.dev/docs/api/class-ElectronApplication#ElectronApplication-evaluateHandle> for more information.

=head2 browserWindow(@args)

Execute the ElectronApplication::browserWindow playwright routine.

See L<https://playwright.dev/docs/api/class-ElectronApplication#ElectronApplication-browserWindow> for more information.

=head2 process(@args)

Execute the ElectronApplication::process playwright routine.

See L<https://playwright.dev/docs/api/class-ElectronApplication#ElectronApplication-process> for more information.

=head2 close(@args)

Execute the ElectronApplication::close playwright routine.

See L<https://playwright.dev/docs/api/class-ElectronApplication#ElectronApplication-close> for more information.

=head2 context(@args)

Execute the ElectronApplication::context playwright routine.

See L<https://playwright.dev/docs/api/class-ElectronApplication#ElectronApplication-context> for more information.

=head2 evaluate(@args)

Execute the ElectronApplication::evaluate playwright routine.

See L<https://playwright.dev/docs/api/class-ElectronApplication#ElectronApplication-evaluate> for more information.

=head2 waitForEvent(@args)

Execute the ElectronApplication::waitForEvent playwright routine.

See L<https://playwright.dev/docs/api/class-ElectronApplication#ElectronApplication-waitForEvent> for more information.

=head2 on(@args)

Execute the ElectronApplication::on playwright routine.

See L<https://playwright.dev/docs/api/class-ElectronApplication#ElectronApplication-on> for more information.

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
