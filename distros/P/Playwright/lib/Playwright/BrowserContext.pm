# ABSTRACT: Automatically generated class for Playwright::BrowserContext
# PODNAME: Playwright::BrowserContext

# These classes used to be generated at runtime, but are now generated when the module is built.
# Don't send patches against these modules, they will be ignored.
# See generate_perl_modules.pl in the repository for generating this.

use strict;
use warnings;

package Playwright::BrowserContext;
$Playwright::BrowserContext::VERSION = '1.531';
use parent 'Playwright::Base';

sub new {
    my ( $self, %options ) = @_;
    $options{type} = 'BrowserContext';
    return $self->SUPER::new(%options);
}

sub spec {
    return $Playwright::spec->{'BrowserContext'}{members};
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

sub clearPermissions {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'clearPermissions',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub serviceWorkers {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'serviceWorkers',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub browser {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'browser',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub waitForConsoleMessage {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'waitForConsoleMessage',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub tracing {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'tracing',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub grantPermissions {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'grantPermissions',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub page {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'page',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub waitForPage {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'waitForPage',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub addInitScript {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'addInitScript',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub backgroundPage {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'backgroundPage',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub newPage {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'newPage',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub exposeFunction {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'exposeFunction',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub removeAllListeners {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'removeAllListeners',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub setExtraHTTPHeaders {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'setExtraHTTPHeaders',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub storageState {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'storageState',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub clearCookies {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'clearCookies',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub waitForEvent2 {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'waitForEvent2',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub webError {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'webError',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub exposeBinding {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'exposeBinding',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub unroute {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'unroute',
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

sub dialog {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'dialog',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub setDefaultTimeout {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'setDefaultTimeout',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub clock {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'clock',
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

sub console {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'console',
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

sub setOffline {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'setOffline',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub newCDPSession {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'newCDPSession',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub backgroundPages {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'backgroundPages',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub setGeolocation {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'setGeolocation',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub setDefaultNavigationTimeout {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'setDefaultNavigationTimeout',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub routeWebSocket {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'routeWebSocket',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub requestFailed {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'requestFailed',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub setHTTPCredentials {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'setHTTPCredentials',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub addCookies {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'addCookies',
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

sub waitForCondition {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'waitForCondition',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub routeFromHAR {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'routeFromHAR',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub route {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'route',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub unrouteAll {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'unrouteAll',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub cookies {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'cookies',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub requestFinished {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'requestFinished',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub pages {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'pages',
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

Playwright::BrowserContext - Automatically generated class for Playwright::BrowserContext

=head1 VERSION

version 1.531

=head1 CONSTRUCTOR

=head2 new(%options)

You shouldn't have to call this directly.
Instead it should be returned to you as the result of calls on Playwright objects, or objects it returns.

=head1 METHODS

=head2 request(@args)

Execute the BrowserContext::request playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-request> for more information.

=head2 clearPermissions(@args)

Execute the BrowserContext::clearPermissions playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-clearPermissions> for more information.

=head2 serviceWorkers(@args)

Execute the BrowserContext::serviceWorkers playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-serviceWorkers> for more information.

=head2 browser(@args)

Execute the BrowserContext::browser playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-browser> for more information.

=head2 waitForConsoleMessage(@args)

Execute the BrowserContext::waitForConsoleMessage playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-waitForConsoleMessage> for more information.

=head2 tracing(@args)

Execute the BrowserContext::tracing playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-tracing> for more information.

=head2 grantPermissions(@args)

Execute the BrowserContext::grantPermissions playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-grantPermissions> for more information.

=head2 page(@args)

Execute the BrowserContext::page playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-page> for more information.

=head2 waitForPage(@args)

Execute the BrowserContext::waitForPage playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-waitForPage> for more information.

=head2 addInitScript(@args)

Execute the BrowserContext::addInitScript playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-addInitScript> for more information.

=head2 backgroundPage(@args)

Execute the BrowserContext::backgroundPage playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-backgroundPage> for more information.

=head2 newPage(@args)

Execute the BrowserContext::newPage playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-newPage> for more information.

=head2 exposeFunction(@args)

Execute the BrowserContext::exposeFunction playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-exposeFunction> for more information.

=head2 removeAllListeners(@args)

Execute the BrowserContext::removeAllListeners playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-removeAllListeners> for more information.

=head2 setExtraHTTPHeaders(@args)

Execute the BrowserContext::setExtraHTTPHeaders playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-setExtraHTTPHeaders> for more information.

=head2 storageState(@args)

Execute the BrowserContext::storageState playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-storageState> for more information.

=head2 clearCookies(@args)

Execute the BrowserContext::clearCookies playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-clearCookies> for more information.

=head2 waitForEvent2(@args)

Execute the BrowserContext::waitForEvent2 playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-waitForEvent2> for more information.

=head2 webError(@args)

Execute the BrowserContext::webError playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-webError> for more information.

=head2 exposeBinding(@args)

Execute the BrowserContext::exposeBinding playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-exposeBinding> for more information.

=head2 unroute(@args)

Execute the BrowserContext::unroute playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-unroute> for more information.

=head2 serviceWorker(@args)

Execute the BrowserContext::serviceWorker playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-serviceWorker> for more information.

=head2 dialog(@args)

Execute the BrowserContext::dialog playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-dialog> for more information.

=head2 setDefaultTimeout(@args)

Execute the BrowserContext::setDefaultTimeout playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-setDefaultTimeout> for more information.

=head2 clock(@args)

Execute the BrowserContext::clock playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-clock> for more information.

=head2 waitForEvent(@args)

Execute the BrowserContext::waitForEvent playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-waitForEvent> for more information.

=head2 console(@args)

Execute the BrowserContext::console playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-console> for more information.

=head2 response(@args)

Execute the BrowserContext::response playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-response> for more information.

=head2 setOffline(@args)

Execute the BrowserContext::setOffline playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-setOffline> for more information.

=head2 newCDPSession(@args)

Execute the BrowserContext::newCDPSession playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-newCDPSession> for more information.

=head2 backgroundPages(@args)

Execute the BrowserContext::backgroundPages playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-backgroundPages> for more information.

=head2 setGeolocation(@args)

Execute the BrowserContext::setGeolocation playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-setGeolocation> for more information.

=head2 setDefaultNavigationTimeout(@args)

Execute the BrowserContext::setDefaultNavigationTimeout playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-setDefaultNavigationTimeout> for more information.

=head2 routeWebSocket(@args)

Execute the BrowserContext::routeWebSocket playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-routeWebSocket> for more information.

=head2 requestFailed(@args)

Execute the BrowserContext::requestFailed playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-requestFailed> for more information.

=head2 setHTTPCredentials(@args)

Execute the BrowserContext::setHTTPCredentials playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-setHTTPCredentials> for more information.

=head2 addCookies(@args)

Execute the BrowserContext::addCookies playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-addCookies> for more information.

=head2 close(@args)

Execute the BrowserContext::close playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-close> for more information.

=head2 waitForCondition(@args)

Execute the BrowserContext::waitForCondition playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-waitForCondition> for more information.

=head2 routeFromHAR(@args)

Execute the BrowserContext::routeFromHAR playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-routeFromHAR> for more information.

=head2 route(@args)

Execute the BrowserContext::route playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-route> for more information.

=head2 unrouteAll(@args)

Execute the BrowserContext::unrouteAll playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-unrouteAll> for more information.

=head2 cookies(@args)

Execute the BrowserContext::cookies playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-cookies> for more information.

=head2 requestFinished(@args)

Execute the BrowserContext::requestFinished playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-requestFinished> for more information.

=head2 pages(@args)

Execute the BrowserContext::pages playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-pages> for more information.

=head2 on(@args)

Execute the BrowserContext::on playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-on> for more information.

=head2 evaluate(@args)

Execute the BrowserContext::evaluate playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-evaluate> for more information.

=head2 evaluateHandle(@args)

Execute the BrowserContext::evaluateHandle playwright routine.

See L<https://playwright.dev/docs/api/class-BrowserContext#BrowserContext-evaluateHandle> for more information.

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
