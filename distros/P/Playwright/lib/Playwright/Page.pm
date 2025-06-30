# ABSTRACT: Automatically generated class for Playwright::Page
# PODNAME: Playwright::Page

# These classes used to be generated at runtime, but are now generated when the module is built.
# Don't send patches against these modules, they will be ignored.
# See generate_perl_modules.pl in the repository for generating this.

use strict;
use warnings;

package Playwright::Page;
$Playwright::Page::VERSION = '1.531';
use parent 'Playwright::Base';

sub new {
    my ( $self, %options ) = @_;
    $options{type} = 'Page';
    return $self->SUPER::new(%options);
}

sub spec {
    return $Playwright::spec->{'Page'}{members};
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

sub select {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => '$',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub isClosed {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'isClosed',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub frameAttached {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'frameAttached',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub inputValue {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'inputValue',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub title {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'title',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub click {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'click',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub selectMulti {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => '$$',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub setChecked {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'setChecked',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub addStyleTag {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'addStyleTag',
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

sub content {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'content',
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

sub getByTestId {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'getByTestId',
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

sub emulateMedia {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'emulateMedia',
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

sub exposeBinding {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'exposeBinding',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub waitForPopup {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'waitForPopup',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub innerText {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'innerText',
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

sub fileChooser {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'fileChooser',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub textContent {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'textContent',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub innerHTML {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'innerHTML',
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

sub dragAndDrop {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'dragAndDrop',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub video {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'video',
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

sub goBack {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'goBack',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub uncheck {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'uncheck',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub getAttribute {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'getAttribute',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub waitForTimeout {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'waitForTimeout',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub touchscreen {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'touchscreen',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub workers {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'workers',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub evalMulti {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => '$$eval',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub eval {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => '$eval',
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

sub focus {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'focus',
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

sub waitForClose {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'waitForClose',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub goForward {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'goForward',
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

sub accessibility {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'accessibility',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub pause {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'pause',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub frameByUrl {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'frameByUrl',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub waitForDownload {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'waitForDownload',
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

sub close {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'close',
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

sub routeFromHAR {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'routeFromHAR',
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

sub unrouteAll {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'unrouteAll',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub keyboard {
    my ($self) = @_;
    return Playwright::Keyboard->new(
        handle => $self,
        parent => $self,
        id     => $self->{guid},
    );
}

sub waitForResponse {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'waitForResponse',
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

sub crash {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'crash',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub onceDialog {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'onceDialog',
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

sub getByTitle {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'getByTitle',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub type {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'type',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub mainFrame {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'mainFrame',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub addScriptTag {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'addScriptTag',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub isDisabled {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'isDisabled',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub DOMContentLoaded {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'DOMContentLoaded',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub frames {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'frames',
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

sub pdf {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'pdf',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub waitForSelector {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'waitForSelector',
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

sub waitForWebSocket {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'waitForWebSocket',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub viewportSize {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'viewportSize',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub goto {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'goto',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub setViewportSize {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'setViewportSize',
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

sub setContent {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'setContent',
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

sub frame {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'frame',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub isVisible {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'isVisible',
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

sub waitForRequest {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'waitForRequest',
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

sub tap {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'tap',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub waitForNavigation {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'waitForNavigation',
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

sub setInputFiles {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'setInputFiles',
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

sub waitForFunction {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'waitForFunction',
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

sub isEditable {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'isEditable',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub worker {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'worker',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub load {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'load',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub isEnabled {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'isEnabled',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub pageError {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'pageError',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub waitForWorker {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'waitForWorker',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub coverage {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'coverage',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub check {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'check',
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

sub screenshot {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'screenshot',
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

sub dispatchEvent {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'dispatchEvent',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub addLocatorHandler {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'addLocatorHandler',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub mouse {
    my ($self) = @_;
    return Playwright::Mouse->new(
        handle => $self,
        parent => $self,
        id     => $self->{guid},
    );
}

sub opener {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'opener',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub bringToFront {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'bringToFront',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub dblclick {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'dblclick',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub removeLocatorHandler {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'removeLocatorHandler',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub waitForRequestFinished {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'waitForRequestFinished',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub isHidden {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'isHidden',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub isChecked {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'isChecked',
        object  => $self->{guid},
        type    => $self->{type}
    );
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

sub locator {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'locator',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub hover {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'hover',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub webSocket {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'webSocket',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub download {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'download',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub selectOption {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'selectOption',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub frameNavigated {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'frameNavigated',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub popup {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'popup',
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

sub reload {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'reload',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub requestGC {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'requestGC',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub waitForFileChooser {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'waitForFileChooser',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub frameDetached {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'frameDetached',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub waitForURL {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'waitForURL',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub waitForLoadState {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'waitForLoadState',
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

Playwright::Page - Automatically generated class for Playwright::Page

=head1 VERSION

version 1.531

=head1 CONSTRUCTOR

=head2 new(%options)

You shouldn't have to call this directly.
Instead it should be returned to you as the result of calls on Playwright objects, or objects it returns.

=head1 METHODS

=head2 url(@args)

Execute the Page::url playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-url> for more information.

=head2 select(@args)

Execute the Page::select playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-$> for more information.

=head2 isClosed(@args)

Execute the Page::isClosed playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-isClosed> for more information.

=head2 frameAttached(@args)

Execute the Page::frameAttached playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-frameAttached> for more information.

=head2 inputValue(@args)

Execute the Page::inputValue playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-inputValue> for more information.

=head2 title(@args)

Execute the Page::title playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-title> for more information.

=head2 click(@args)

Execute the Page::click playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-click> for more information.

=head2 selectMulti(@args)

Execute the Page::selectMulti playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-$$> for more information.

=head2 setChecked(@args)

Execute the Page::setChecked playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-setChecked> for more information.

=head2 addStyleTag(@args)

Execute the Page::addStyleTag playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-addStyleTag> for more information.

=head2 evaluateHandle(@args)

Execute the Page::evaluateHandle playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-evaluateHandle> for more information.

=head2 content(@args)

Execute the Page::content playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-content> for more information.

=head2 getByText(@args)

Execute the Page::getByText playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-getByText> for more information.

=head2 getByTestId(@args)

Execute the Page::getByTestId playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-getByTestId> for more information.

=head2 waitForConsoleMessage(@args)

Execute the Page::waitForConsoleMessage playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-waitForConsoleMessage> for more information.

=head2 emulateMedia(@args)

Execute the Page::emulateMedia playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-emulateMedia> for more information.

=head2 unroute(@args)

Execute the Page::unroute playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-unroute> for more information.

=head2 exposeBinding(@args)

Execute the Page::exposeBinding playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-exposeBinding> for more information.

=head2 waitForPopup(@args)

Execute the Page::waitForPopup playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-waitForPopup> for more information.

=head2 innerText(@args)

Execute the Page::innerText playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-innerText> for more information.

=head2 clock(@args)

Execute the Page::clock playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-clock> for more information.

=head2 fileChooser(@args)

Execute the Page::fileChooser playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-fileChooser> for more information.

=head2 textContent(@args)

Execute the Page::textContent playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-textContent> for more information.

=head2 innerHTML(@args)

Execute the Page::innerHTML playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-innerHTML> for more information.

=head2 getByAltText(@args)

Execute the Page::getByAltText playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-getByAltText> for more information.

=head2 dragAndDrop(@args)

Execute the Page::dragAndDrop playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-dragAndDrop> for more information.

=head2 video(@args)

Execute the Page::video playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-video> for more information.

=head2 getByLabel(@args)

Execute the Page::getByLabel playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-getByLabel> for more information.

=head2 goBack(@args)

Execute the Page::goBack playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-goBack> for more information.

=head2 uncheck(@args)

Execute the Page::uncheck playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-uncheck> for more information.

=head2 getAttribute(@args)

Execute the Page::getAttribute playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-getAttribute> for more information.

=head2 waitForTimeout(@args)

Execute the Page::waitForTimeout playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-waitForTimeout> for more information.

=head2 touchscreen(@args)

Execute the Page::touchscreen playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-touchscreen> for more information.

=head2 workers(@args)

Execute the Page::workers playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-workers> for more information.

=head2 evalMulti(@args)

Execute the Page::evalMulti playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-$$eval> for more information.

=head2 eval(@args)

Execute the Page::eval playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-$eval> for more information.

=head2 console(@args)

Execute the Page::console playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-console> for more information.

=head2 focus(@args)

Execute the Page::focus playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-focus> for more information.

=head2 fill(@args)

Execute the Page::fill playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-fill> for more information.

=head2 press(@args)

Execute the Page::press playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-press> for more information.

=head2 waitForClose(@args)

Execute the Page::waitForClose playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-waitForClose> for more information.

=head2 goForward(@args)

Execute the Page::goForward playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-goForward> for more information.

=head2 response(@args)

Execute the Page::response playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-response> for more information.

=head2 accessibility(@args)

Execute the Page::accessibility playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-accessibility> for more information.

=head2 pause(@args)

Execute the Page::pause playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-pause> for more information.

=head2 frameByUrl(@args)

Execute the Page::frameByUrl playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-frameByUrl> for more information.

=head2 waitForDownload(@args)

Execute the Page::waitForDownload playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-waitForDownload> for more information.

=head2 waitForCondition(@args)

Execute the Page::waitForCondition playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-waitForCondition> for more information.

=head2 close(@args)

Execute the Page::close playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-close> for more information.

=head2 route(@args)

Execute the Page::route playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-route> for more information.

=head2 routeFromHAR(@args)

Execute the Page::routeFromHAR playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-routeFromHAR> for more information.

=head2 context(@args)

Execute the Page::context playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-context> for more information.

=head2 unrouteAll(@args)

Execute the Page::unrouteAll playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-unrouteAll> for more information.

=head2 keyboard()

Returns a Playwright::Keyboard object.

=head2 waitForResponse(@args)

Execute the Page::waitForResponse playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-waitForResponse> for more information.

=head2 requestFinished(@args)

Execute the Page::requestFinished playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-requestFinished> for more information.

=head2 crash(@args)

Execute the Page::crash playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-crash> for more information.

=head2 onceDialog(@args)

Execute the Page::onceDialog playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-onceDialog> for more information.

=head2 routeWebSocket(@args)

Execute the Page::routeWebSocket playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-routeWebSocket> for more information.

=head2 getByTitle(@args)

Execute the Page::getByTitle playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-getByTitle> for more information.

=head2 type(@args)

Execute the Page::type playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-type> for more information.

=head2 mainFrame(@args)

Execute the Page::mainFrame playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-mainFrame> for more information.

=head2 addScriptTag(@args)

Execute the Page::addScriptTag playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-addScriptTag> for more information.

=head2 isDisabled(@args)

Execute the Page::isDisabled playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-isDisabled> for more information.

=head2 DOMContentLoaded(@args)

Execute the Page::DOMContentLoaded playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-DOMContentLoaded> for more information.

=head2 frames(@args)

Execute the Page::frames playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-frames> for more information.

=head2 evaluate(@args)

Execute the Page::evaluate playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-evaluate> for more information.

=head2 pdf(@args)

Execute the Page::pdf playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-pdf> for more information.

=head2 waitForSelector(@args)

Execute the Page::waitForSelector playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-waitForSelector> for more information.

=head2 addInitScript(@args)

Execute the Page::addInitScript playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-addInitScript> for more information.

=head2 waitForWebSocket(@args)

Execute the Page::waitForWebSocket playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-waitForWebSocket> for more information.

=head2 viewportSize(@args)

Execute the Page::viewportSize playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-viewportSize> for more information.

=head2 goto(@args)

Execute the Page::goto playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-goto> for more information.

=head2 setViewportSize(@args)

Execute the Page::setViewportSize playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-setViewportSize> for more information.

=head2 request(@args)

Execute the Page::request playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-request> for more information.

=head2 setContent(@args)

Execute the Page::setContent playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-setContent> for more information.

=head2 getByRole(@args)

Execute the Page::getByRole playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-getByRole> for more information.

=head2 frame(@args)

Execute the Page::frame playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-frame> for more information.

=head2 isVisible(@args)

Execute the Page::isVisible playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-isVisible> for more information.

=head2 dialog(@args)

Execute the Page::dialog playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-dialog> for more information.

=head2 waitForRequest(@args)

Execute the Page::waitForRequest playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-waitForRequest> for more information.

=head2 setDefaultTimeout(@args)

Execute the Page::setDefaultTimeout playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-setDefaultTimeout> for more information.

=head2 tap(@args)

Execute the Page::tap playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-tap> for more information.

=head2 waitForNavigation(@args)

Execute the Page::waitForNavigation playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-waitForNavigation> for more information.

=head2 waitForEvent(@args)

Execute the Page::waitForEvent playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-waitForEvent> for more information.

=head2 setInputFiles(@args)

Execute the Page::setInputFiles playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-setInputFiles> for more information.

=head2 exposeFunction(@args)

Execute the Page::exposeFunction playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-exposeFunction> for more information.

=head2 removeAllListeners(@args)

Execute the Page::removeAllListeners playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-removeAllListeners> for more information.

=head2 setExtraHTTPHeaders(@args)

Execute the Page::setExtraHTTPHeaders playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-setExtraHTTPHeaders> for more information.

=head2 waitForFunction(@args)

Execute the Page::waitForFunction playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-waitForFunction> for more information.

=head2 waitForEvent2(@args)

Execute the Page::waitForEvent2 playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-waitForEvent2> for more information.

=head2 isEditable(@args)

Execute the Page::isEditable playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-isEditable> for more information.

=head2 worker(@args)

Execute the Page::worker playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-worker> for more information.

=head2 load(@args)

Execute the Page::load playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-load> for more information.

=head2 isEnabled(@args)

Execute the Page::isEnabled playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-isEnabled> for more information.

=head2 pageError(@args)

Execute the Page::pageError playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-pageError> for more information.

=head2 waitForWorker(@args)

Execute the Page::waitForWorker playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-waitForWorker> for more information.

=head2 coverage(@args)

Execute the Page::coverage playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-coverage> for more information.

=head2 check(@args)

Execute the Page::check playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-check> for more information.

=head2 setDefaultNavigationTimeout(@args)

Execute the Page::setDefaultNavigationTimeout playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-setDefaultNavigationTimeout> for more information.

=head2 screenshot(@args)

Execute the Page::screenshot playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-screenshot> for more information.

=head2 getByPlaceholder(@args)

Execute the Page::getByPlaceholder playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-getByPlaceholder> for more information.

=head2 dispatchEvent(@args)

Execute the Page::dispatchEvent playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-dispatchEvent> for more information.

=head2 addLocatorHandler(@args)

Execute the Page::addLocatorHandler playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-addLocatorHandler> for more information.

=head2 mouse()

Returns a Playwright::Mouse object.

=head2 opener(@args)

Execute the Page::opener playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-opener> for more information.

=head2 bringToFront(@args)

Execute the Page::bringToFront playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-bringToFront> for more information.

=head2 dblclick(@args)

Execute the Page::dblclick playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-dblclick> for more information.

=head2 removeLocatorHandler(@args)

Execute the Page::removeLocatorHandler playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-removeLocatorHandler> for more information.

=head2 waitForRequestFinished(@args)

Execute the Page::waitForRequestFinished playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-waitForRequestFinished> for more information.

=head2 isHidden(@args)

Execute the Page::isHidden playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-isHidden> for more information.

=head2 isChecked(@args)

Execute the Page::isChecked playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-isChecked> for more information.

=head2 frameLocator(@args)

Execute the Page::frameLocator playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-frameLocator> for more information.

=head2 locator(@args)

Execute the Page::locator playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-locator> for more information.

=head2 hover(@args)

Execute the Page::hover playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-hover> for more information.

=head2 webSocket(@args)

Execute the Page::webSocket playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-webSocket> for more information.

=head2 download(@args)

Execute the Page::download playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-download> for more information.

=head2 selectOption(@args)

Execute the Page::selectOption playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-selectOption> for more information.

=head2 frameNavigated(@args)

Execute the Page::frameNavigated playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-frameNavigated> for more information.

=head2 popup(@args)

Execute the Page::popup playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-popup> for more information.

=head2 requestFailed(@args)

Execute the Page::requestFailed playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-requestFailed> for more information.

=head2 reload(@args)

Execute the Page::reload playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-reload> for more information.

=head2 requestGC(@args)

Execute the Page::requestGC playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-requestGC> for more information.

=head2 waitForFileChooser(@args)

Execute the Page::waitForFileChooser playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-waitForFileChooser> for more information.

=head2 frameDetached(@args)

Execute the Page::frameDetached playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-frameDetached> for more information.

=head2 waitForURL(@args)

Execute the Page::waitForURL playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-waitForURL> for more information.

=head2 waitForLoadState(@args)

Execute the Page::waitForLoadState playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-waitForLoadState> for more information.

=head2 on(@args)

Execute the Page::on playwright routine.

See L<https://playwright.dev/docs/api/class-Page#Page-on> for more information.

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
