# ABSTRACT: Automatically generated class for Playwright::Request
# PODNAME: Playwright::Request

# These classes used to be generated at runtime, but are now generated when the module is built.
# Don't send patches against these modules, they will be ignored.
# See generate_perl_modules.pl in the repository for generating this.

use strict;
use warnings;

package Playwright::Request;
$Playwright::Request::VERSION = '1.531';
use parent 'Playwright::Base';

sub new {
    my ( $self, %options ) = @_;
    $options{type} = 'Request';
    return $self->SUPER::new(%options);
}

sub spec {
    return $Playwright::spec->{'Request'}{members};
}

sub redirectedTo {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'redirectedTo',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub postDataJSON {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'postDataJSON',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub resourceType {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'resourceType',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub method {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'method',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub isNavigationRequest {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'isNavigationRequest',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub serviceWorker {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'serviceWorker',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub redirectedFrom {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'redirectedFrom',
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

sub headersArray {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'headersArray',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub timing {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'timing',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub postDataBuffer {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'postDataBuffer',
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

sub headers {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'headers',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub failure {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'failure',
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

sub response {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'response',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub sizes {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'sizes',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub postData {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'postData',
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

Playwright::Request - Automatically generated class for Playwright::Request

=head1 VERSION

version 1.531

=head1 CONSTRUCTOR

=head2 new(%options)

You shouldn't have to call this directly.
Instead it should be returned to you as the result of calls on Playwright objects, or objects it returns.

=head1 METHODS

=head2 redirectedTo(@args)

Execute the Request::redirectedTo playwright routine.

See L<https://playwright.dev/docs/api/class-Request#Request-redirectedTo> for more information.

=head2 postDataJSON(@args)

Execute the Request::postDataJSON playwright routine.

See L<https://playwright.dev/docs/api/class-Request#Request-postDataJSON> for more information.

=head2 resourceType(@args)

Execute the Request::resourceType playwright routine.

See L<https://playwright.dev/docs/api/class-Request#Request-resourceType> for more information.

=head2 method(@args)

Execute the Request::method playwright routine.

See L<https://playwright.dev/docs/api/class-Request#Request-method> for more information.

=head2 isNavigationRequest(@args)

Execute the Request::isNavigationRequest playwright routine.

See L<https://playwright.dev/docs/api/class-Request#Request-isNavigationRequest> for more information.

=head2 serviceWorker(@args)

Execute the Request::serviceWorker playwright routine.

See L<https://playwright.dev/docs/api/class-Request#Request-serviceWorker> for more information.

=head2 redirectedFrom(@args)

Execute the Request::redirectedFrom playwright routine.

See L<https://playwright.dev/docs/api/class-Request#Request-redirectedFrom> for more information.

=head2 frame(@args)

Execute the Request::frame playwright routine.

See L<https://playwright.dev/docs/api/class-Request#Request-frame> for more information.

=head2 headersArray(@args)

Execute the Request::headersArray playwright routine.

See L<https://playwright.dev/docs/api/class-Request#Request-headersArray> for more information.

=head2 timing(@args)

Execute the Request::timing playwright routine.

See L<https://playwright.dev/docs/api/class-Request#Request-timing> for more information.

=head2 postDataBuffer(@args)

Execute the Request::postDataBuffer playwright routine.

See L<https://playwright.dev/docs/api/class-Request#Request-postDataBuffer> for more information.

=head2 url(@args)

Execute the Request::url playwright routine.

See L<https://playwright.dev/docs/api/class-Request#Request-url> for more information.

=head2 headers(@args)

Execute the Request::headers playwright routine.

See L<https://playwright.dev/docs/api/class-Request#Request-headers> for more information.

=head2 failure(@args)

Execute the Request::failure playwright routine.

See L<https://playwright.dev/docs/api/class-Request#Request-failure> for more information.

=head2 allHeaders(@args)

Execute the Request::allHeaders playwright routine.

See L<https://playwright.dev/docs/api/class-Request#Request-allHeaders> for more information.

=head2 response(@args)

Execute the Request::response playwright routine.

See L<https://playwright.dev/docs/api/class-Request#Request-response> for more information.

=head2 sizes(@args)

Execute the Request::sizes playwright routine.

See L<https://playwright.dev/docs/api/class-Request#Request-sizes> for more information.

=head2 postData(@args)

Execute the Request::postData playwright routine.

See L<https://playwright.dev/docs/api/class-Request#Request-postData> for more information.

=head2 headerValue(@args)

Execute the Request::headerValue playwright routine.

See L<https://playwright.dev/docs/api/class-Request#Request-headerValue> for more information.

=head2 on(@args)

Execute the Request::on playwright routine.

See L<https://playwright.dev/docs/api/class-Request#Request-on> for more information.

=head2 evaluate(@args)

Execute the Request::evaluate playwright routine.

See L<https://playwright.dev/docs/api/class-Request#Request-evaluate> for more information.

=head2 evaluateHandle(@args)

Execute the Request::evaluateHandle playwright routine.

See L<https://playwright.dev/docs/api/class-Request#Request-evaluateHandle> for more information.

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
