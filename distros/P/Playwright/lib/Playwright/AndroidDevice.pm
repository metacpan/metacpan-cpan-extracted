# ABSTRACT: Automatically generated class for Playwright::AndroidDevice
# PODNAME: Playwright::AndroidDevice

# These classes used to be generated at runtime, but are now generated when the module is built.
# Don't send patches against these modules, they will be ignored.
# See generate_perl_modules.pl in the repository for generating this.

use strict;
use warnings;

package Playwright::AndroidDevice;
$Playwright::AndroidDevice::VERSION = '1.531';
use parent 'Playwright::Base';

sub new {
    my ( $self, %options ) = @_;
    $options{type} = 'AndroidDevice';
    return $self->SUPER::new(%options);
}

sub spec {
    return $Playwright::spec->{'AndroidDevice'}{members};
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

sub setDefaultTimeout {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'setDefaultTimeout',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub push {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'push',
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

sub tap {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'tap',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub shell {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'shell',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub info {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'info',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub pinchClose {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'pinchClose',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub serial {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'serial',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub open {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'open',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub model {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'model',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub swipe {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'swipe',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub wait {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'wait',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub webViews {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'webViews',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub longTap {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'longTap',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub installApk {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'installApk',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub drag {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'drag',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub screenshot {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'screenshot',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub pinchOpen {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'pinchOpen',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub webView {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'webView',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub fill {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'fill',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub press {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'press',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub scroll {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'scroll',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub launchBrowser {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'launchBrowser',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub input {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'input',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub fling {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'fling',
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

Playwright::AndroidDevice - Automatically generated class for Playwright::AndroidDevice

=head1 VERSION

version 1.531

=head1 CONSTRUCTOR

=head2 new(%options)

You shouldn't have to call this directly.
Instead it should be returned to you as the result of calls on Playwright objects, or objects it returns.

=head1 METHODS

=head2 close(@args)

Execute the AndroidDevice::close playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-close> for more information.

=head2 setDefaultTimeout(@args)

Execute the AndroidDevice::setDefaultTimeout playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-setDefaultTimeout> for more information.

=head2 push(@args)

Execute the AndroidDevice::push playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-push> for more information.

=head2 waitForEvent(@args)

Execute the AndroidDevice::waitForEvent playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-waitForEvent> for more information.

=head2 tap(@args)

Execute the AndroidDevice::tap playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-tap> for more information.

=head2 shell(@args)

Execute the AndroidDevice::shell playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-shell> for more information.

=head2 info(@args)

Execute the AndroidDevice::info playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-info> for more information.

=head2 pinchClose(@args)

Execute the AndroidDevice::pinchClose playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-pinchClose> for more information.

=head2 serial(@args)

Execute the AndroidDevice::serial playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-serial> for more information.

=head2 open(@args)

Execute the AndroidDevice::open playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-open> for more information.

=head2 model(@args)

Execute the AndroidDevice::model playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-model> for more information.

=head2 swipe(@args)

Execute the AndroidDevice::swipe playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-swipe> for more information.

=head2 wait(@args)

Execute the AndroidDevice::wait playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-wait> for more information.

=head2 webViews(@args)

Execute the AndroidDevice::webViews playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-webViews> for more information.

=head2 longTap(@args)

Execute the AndroidDevice::longTap playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-longTap> for more information.

=head2 installApk(@args)

Execute the AndroidDevice::installApk playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-installApk> for more information.

=head2 drag(@args)

Execute the AndroidDevice::drag playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-drag> for more information.

=head2 screenshot(@args)

Execute the AndroidDevice::screenshot playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-screenshot> for more information.

=head2 pinchOpen(@args)

Execute the AndroidDevice::pinchOpen playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-pinchOpen> for more information.

=head2 webView(@args)

Execute the AndroidDevice::webView playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-webView> for more information.

=head2 fill(@args)

Execute the AndroidDevice::fill playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-fill> for more information.

=head2 press(@args)

Execute the AndroidDevice::press playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-press> for more information.

=head2 scroll(@args)

Execute the AndroidDevice::scroll playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-scroll> for more information.

=head2 launchBrowser(@args)

Execute the AndroidDevice::launchBrowser playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-launchBrowser> for more information.

=head2 input(@args)

Execute the AndroidDevice::input playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-input> for more information.

=head2 fling(@args)

Execute the AndroidDevice::fling playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-fling> for more information.

=head2 on(@args)

Execute the AndroidDevice::on playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-on> for more information.

=head2 evaluate(@args)

Execute the AndroidDevice::evaluate playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-evaluate> for more information.

=head2 evaluateHandle(@args)

Execute the AndroidDevice::evaluateHandle playwright routine.

See L<https://playwright.dev/docs/api/class-AndroidDevice#AndroidDevice-evaluateHandle> for more information.

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
