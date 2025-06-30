# ABSTRACT: Automatically generated class for Playwright::Response
# PODNAME: Playwright::Response

# These classes used to be generated at runtime, but are now generated when the module is built.
# Don't send patches against these modules, they will be ignored.
# See generate_perl_modules.pl in the repository for generating this.

use strict;
use warnings;

package Playwright::Response;
$Playwright::Response::VERSION = '1.531';
use parent 'Playwright::Base';

sub new {
    my ( $self, %options ) = @_;
    $options{type} = 'Response';
    return $self->SUPER::new(%options);
}

sub spec {
    return $Playwright::spec->{'Response'}{members};
}

sub serverAddr {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'serverAddr',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub headerValues {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'headerValues',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub securityDetails {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'securityDetails',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub headerValue {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'headerValue',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub status {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'status',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub body {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'body',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub json {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'json',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub allHeaders {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'allHeaders',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub fromServiceWorker {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'fromServiceWorker',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub request {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'request',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub headers {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'headers',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub url {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'url',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub finished {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'finished',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub headersArray {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'headersArray',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub frame {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'frame',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub statusText {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'statusText',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub text {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'text',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub ok {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'ok',
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

Playwright::Response - Automatically generated class for Playwright::Response

=head1 VERSION

version 1.531

=head1 CONSTRUCTOR

=head2 new(%options)

You shouldn't have to call this directly.
Instead it should be returned to you as the result of calls on Playwright objects, or objects it returns.

=head1 METHODS

=head2 serverAddr(@args)

Execute the Response::serverAddr playwright routine.

See L<https://playwright.dev/docs/api/class-Response#Response-serverAddr> for more information.

=head2 headerValues(@args)

Execute the Response::headerValues playwright routine.

See L<https://playwright.dev/docs/api/class-Response#Response-headerValues> for more information.

=head2 securityDetails(@args)

Execute the Response::securityDetails playwright routine.

See L<https://playwright.dev/docs/api/class-Response#Response-securityDetails> for more information.

=head2 headerValue(@args)

Execute the Response::headerValue playwright routine.

See L<https://playwright.dev/docs/api/class-Response#Response-headerValue> for more information.

=head2 status(@args)

Execute the Response::status playwright routine.

See L<https://playwright.dev/docs/api/class-Response#Response-status> for more information.

=head2 body(@args)

Execute the Response::body playwright routine.

See L<https://playwright.dev/docs/api/class-Response#Response-body> for more information.

=head2 json(@args)

Execute the Response::json playwright routine.

See L<https://playwright.dev/docs/api/class-Response#Response-json> for more information.

=head2 allHeaders(@args)

Execute the Response::allHeaders playwright routine.

See L<https://playwright.dev/docs/api/class-Response#Response-allHeaders> for more information.

=head2 fromServiceWorker(@args)

Execute the Response::fromServiceWorker playwright routine.

See L<https://playwright.dev/docs/api/class-Response#Response-fromServiceWorker> for more information.

=head2 request(@args)

Execute the Response::request playwright routine.

See L<https://playwright.dev/docs/api/class-Response#Response-request> for more information.

=head2 headers(@args)

Execute the Response::headers playwright routine.

See L<https://playwright.dev/docs/api/class-Response#Response-headers> for more information.

=head2 url(@args)

Execute the Response::url playwright routine.

See L<https://playwright.dev/docs/api/class-Response#Response-url> for more information.

=head2 finished(@args)

Execute the Response::finished playwright routine.

See L<https://playwright.dev/docs/api/class-Response#Response-finished> for more information.

=head2 headersArray(@args)

Execute the Response::headersArray playwright routine.

See L<https://playwright.dev/docs/api/class-Response#Response-headersArray> for more information.

=head2 frame(@args)

Execute the Response::frame playwright routine.

See L<https://playwright.dev/docs/api/class-Response#Response-frame> for more information.

=head2 statusText(@args)

Execute the Response::statusText playwright routine.

See L<https://playwright.dev/docs/api/class-Response#Response-statusText> for more information.

=head2 text(@args)

Execute the Response::text playwright routine.

See L<https://playwright.dev/docs/api/class-Response#Response-text> for more information.

=head2 ok(@args)

Execute the Response::ok playwright routine.

See L<https://playwright.dev/docs/api/class-Response#Response-ok> for more information.

=head2 on(@args)

Execute the Response::on playwright routine.

See L<https://playwright.dev/docs/api/class-Response#Response-on> for more information.

=head2 evaluate(@args)

Execute the Response::evaluate playwright routine.

See L<https://playwright.dev/docs/api/class-Response#Response-evaluate> for more information.

=head2 evaluateHandle(@args)

Execute the Response::evaluateHandle playwright routine.

See L<https://playwright.dev/docs/api/class-Response#Response-evaluateHandle> for more information.

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
