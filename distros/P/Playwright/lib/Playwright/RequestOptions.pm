# ABSTRACT: Automatically generated class for Playwright::RequestOptions
# PODNAME: Playwright::RequestOptions

# These classes used to be generated at runtime, but are now generated when the module is built.
# Don't send patches against these modules, they will be ignored.
# See generate_perl_modules.pl in the repository for generating this.

use strict;
use warnings;

package Playwright::RequestOptions;
$Playwright::RequestOptions::VERSION = '1.531';
use parent 'Playwright::Base';

sub new {
    my ( $self, %options ) = @_;
    $options{type} = 'RequestOptions';
    return $self->SUPER::new(%options);
}

sub spec {
    return $Playwright::spec->{'RequestOptions'}{members};
}

sub setFailOnStatusCode {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'setFailOnStatusCode',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub setQueryParam {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'setQueryParam',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub create {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'create',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub setForm {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'setForm',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub setIgnoreHTTPSErrors {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'setIgnoreHTTPSErrors',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub setMethod {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'setMethod',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub setMaxRetries {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'setMaxRetries',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub setMaxRedirects {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'setMaxRedirects',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub setTimeout {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'setTimeout',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub setData {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'setData',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub setMultipart {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'setMultipart',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub setHeader {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'setHeader',
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

Playwright::RequestOptions - Automatically generated class for Playwright::RequestOptions

=head1 VERSION

version 1.531

=head1 CONSTRUCTOR

=head2 new(%options)

You shouldn't have to call this directly.
Instead it should be returned to you as the result of calls on Playwright objects, or objects it returns.

=head1 METHODS

=head2 setFailOnStatusCode(@args)

Execute the RequestOptions::setFailOnStatusCode playwright routine.

See L<https://playwright.dev/docs/api/class-RequestOptions#RequestOptions-setFailOnStatusCode> for more information.

=head2 setQueryParam(@args)

Execute the RequestOptions::setQueryParam playwright routine.

See L<https://playwright.dev/docs/api/class-RequestOptions#RequestOptions-setQueryParam> for more information.

=head2 create(@args)

Execute the RequestOptions::create playwright routine.

See L<https://playwright.dev/docs/api/class-RequestOptions#RequestOptions-create> for more information.

=head2 setForm(@args)

Execute the RequestOptions::setForm playwright routine.

See L<https://playwright.dev/docs/api/class-RequestOptions#RequestOptions-setForm> for more information.

=head2 setIgnoreHTTPSErrors(@args)

Execute the RequestOptions::setIgnoreHTTPSErrors playwright routine.

See L<https://playwright.dev/docs/api/class-RequestOptions#RequestOptions-setIgnoreHTTPSErrors> for more information.

=head2 setMethod(@args)

Execute the RequestOptions::setMethod playwright routine.

See L<https://playwright.dev/docs/api/class-RequestOptions#RequestOptions-setMethod> for more information.

=head2 setMaxRetries(@args)

Execute the RequestOptions::setMaxRetries playwright routine.

See L<https://playwright.dev/docs/api/class-RequestOptions#RequestOptions-setMaxRetries> for more information.

=head2 setMaxRedirects(@args)

Execute the RequestOptions::setMaxRedirects playwright routine.

See L<https://playwright.dev/docs/api/class-RequestOptions#RequestOptions-setMaxRedirects> for more information.

=head2 setTimeout(@args)

Execute the RequestOptions::setTimeout playwright routine.

See L<https://playwright.dev/docs/api/class-RequestOptions#RequestOptions-setTimeout> for more information.

=head2 setData(@args)

Execute the RequestOptions::setData playwright routine.

See L<https://playwright.dev/docs/api/class-RequestOptions#RequestOptions-setData> for more information.

=head2 setMultipart(@args)

Execute the RequestOptions::setMultipart playwright routine.

See L<https://playwright.dev/docs/api/class-RequestOptions#RequestOptions-setMultipart> for more information.

=head2 setHeader(@args)

Execute the RequestOptions::setHeader playwright routine.

See L<https://playwright.dev/docs/api/class-RequestOptions#RequestOptions-setHeader> for more information.

=head2 on(@args)

Execute the RequestOptions::on playwright routine.

See L<https://playwright.dev/docs/api/class-RequestOptions#RequestOptions-on> for more information.

=head2 evaluate(@args)

Execute the RequestOptions::evaluate playwright routine.

See L<https://playwright.dev/docs/api/class-RequestOptions#RequestOptions-evaluate> for more information.

=head2 evaluateHandle(@args)

Execute the RequestOptions::evaluateHandle playwright routine.

See L<https://playwright.dev/docs/api/class-RequestOptions#RequestOptions-evaluateHandle> for more information.

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
