#ABSTRACT: Playwright sub classes.
#PODNAME: Playwright::ModuleList
# You should not use this directly; use Playwright instead.

package Playwright::ModuleList;
$Playwright::ModuleList::VERSION = '1.460';
use strict;
use warnings;

use Playwright::CDPSession;
use Playwright::Selectors;
use Playwright::PlaywrightException;
use Playwright::APIRequest;
use Playwright::AndroidInput;
use Playwright::Mouse;
use Playwright::FormData;
use Playwright::Download;
use Playwright::Error;
use Playwright::GenericAssertions;
use Playwright::AndroidWebView;
use Playwright::Worker;
use Playwright::WebSocket;
use Playwright::BrowserType;
use Playwright::AndroidSocket;
use Playwright::Electron;
use Playwright::ElectronApplication;
use Playwright::JSHandle;
use Playwright::PageAssertions;
use Playwright::TimeoutError;
use Playwright::Coverage;
use Playwright::Locator;
use Playwright::Response;
use Playwright::FrameLocator;
use Playwright::Clock;
use Playwright::Route;
use Playwright::Android;
use Playwright::CDPSessionEvent;
use Playwright::Touchscreen;
use Playwright::Video;
use Playwright::Frame;
use Playwright::AndroidDevice;
use Playwright::Accessibility;
use Playwright::ElementHandle;
use Playwright::Browser;
use Playwright::SnapshotAssertions;
use Playwright::Logger;
use Playwright::ConsoleMessage;
use Playwright::Keyboard;
use Playwright::APIResponseAssertions;
use Playwright::Tracing;
use Playwright::FileChooser;
use Playwright::LocatorAssertions;
use Playwright::Page;
use Playwright::RequestOptions;
use Playwright::APIResponse;
use Playwright::Dialog;
use Playwright::WebError;
use Playwright::BrowserContext;
use Playwright::BrowserServer;
use Playwright::PlaywrightAssertions;
use Playwright::WebSocketFrame;
use Playwright::APIRequestContext;
use Playwright::Request;
use Playwright::Mouse;
use Playwright::Keyboard;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Playwright::ModuleList - Playwright sub classes.

=head1 VERSION

version 1.460

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
