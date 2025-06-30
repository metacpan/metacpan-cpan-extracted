# ABSTRACT: Automatically generated class for Playwright::BrowserType
# PODNAME: Playwright::BrowserType

# These classes used to be generated at runtime, but are now generated when the module is built.
# Don't send patches against these modules, they will be ignored.
# See generate_perl_modules.pl in the repository for generating this.

use strict;
use warnings;

package Playwright::BrowserType;
$Playwright::BrowserType::VERSION = '1.531';
use parent 'Playwright::Base';

sub new {
    my ( $self, %options ) = @_;
    $options{type} = 'BrowserType';
    return $self->SUPER::new(%options);
}

sub spec {
    return $Playwright::spec->{'BrowserType'}{members};
}

sub launch {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'launch',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub connect {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'connect',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub launchPersistentContext {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'launchPersistentContext',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub launchServer {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'launchServer',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub name {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'name',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub executablePath {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'executablePath',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub connectOverCDP {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'connectOverCDP',
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

Playwright::BrowserType - Automatically generated class for Playwright::BrowserType

=head1 VERSION

version 1.531

=head1 CONSTRUCTOR

=head2 new(%options)

You shouldn't have to call this directly.
Instead it should be returned to you as the result of calls on Playwright objects, or objects it returns.

=head1 METHODS

=head2 launch(@args)

Execute the BrowserType::launch playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserType#BrowserType-launch> for more information.

=head2 connect(@args)

Execute the BrowserType::connect playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserType#BrowserType-connect> for more information.

=head2 launchPersistentContext(@args)

Execute the BrowserType::launchPersistentContext playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserType#BrowserType-launchPersistentContext> for more information.

=head2 launchServer(@args)

Execute the BrowserType::launchServer playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserType#BrowserType-launchServer> for more information.

=head2 name(@args)

Execute the BrowserType::name playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserType#BrowserType-name> for more information.

=head2 executablePath(@args)

Execute the BrowserType::executablePath playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserType#BrowserType-executablePath> for more information.

=head2 connectOverCDP(@args)

Execute the BrowserType::connectOverCDP playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserType#BrowserType-connectOverCDP> for more information.

=head2 on(@args)

Execute the BrowserType::on playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserType#BrowserType-on> for more information.

=head2 evaluate(@args)

Execute the BrowserType::evaluate playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserType#BrowserType-evaluate> for more information.

=head2 evaluateHandle(@args)

Execute the BrowserType::evaluateHandle playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserType#BrowserType-evaluateHandle> for more information.

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
