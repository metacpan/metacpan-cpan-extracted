# ABSTRACT: Automatically generated class for Playwright::Frame
# PODNAME: Playwright::Frame

# These classes used to be generated at runtime, but are now generated when the module is built.
# Don't send patches against these modules, they will be ignored.
# See generate_perl_modules.pl in the repository for generating this.

use strict;
use warnings;

package Playwright::Frame;
$Playwright::Frame::VERSION = '1.531';
use parent 'Playwright::Base';

sub new {
    my ( $self, %options ) = @_;
    $options{type} = 'Frame';
    return $self->SUPER::new(%options);
}

sub spec {
    return $Playwright::spec->{'Frame'}{members};
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

sub getByRole {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'getByRole',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub isDetached {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'isDetached',
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

sub innerText {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'innerText',
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

sub innerHTML {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'innerHTML',
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

sub isEditable {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'isEditable',
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

sub getByLabel {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'getByLabel',
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

sub page {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'page',
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

sub url {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'url',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub frameElement {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'frameElement',
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

sub click {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'click',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub childFrames {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'childFrames',
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

sub getByText {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'getByText',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub parentFrame {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'parentFrame',
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

sub addStyleTag {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'addStyleTag',
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

sub selectMulti {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => '$$',
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

sub getByTestId {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'getByTestId',
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

sub locator {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'locator',
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

sub selectOption {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'selectOption',
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

sub waitForLoadState {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'waitForLoadState',
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

sub isDisabled {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'isDisabled',
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

sub uncheck {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'uncheck',
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

sub check {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'check',
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

sub press {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'press',
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

sub dispatchEvent {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'dispatchEvent',
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

sub eval {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => '$eval',
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

sub isHidden {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'isHidden',
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

Playwright::Frame - Automatically generated class for Playwright::Frame

=head1 VERSION

version 1.531

=head1 CONSTRUCTOR

=head2 new(%options)

You shouldn't have to call this directly.
Instead it should be returned to you as the result of calls on Playwright objects, or objects it returns.

=head1 METHODS

=head2 isVisible(@args)

Execute the Frame::isVisible playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-isVisible> for more information.

=head2 getByRole(@args)

Execute the Frame::getByRole playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-getByRole> for more information.

=head2 isDetached(@args)

Execute the Frame::isDetached playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-isDetached> for more information.

=head2 textContent(@args)

Execute the Frame::textContent playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-textContent> for more information.

=head2 tap(@args)

Execute the Frame::tap playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-tap> for more information.

=head2 waitForNavigation(@args)

Execute the Frame::waitForNavigation playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-waitForNavigation> for more information.

=head2 innerText(@args)

Execute the Frame::innerText playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-innerText> for more information.

=head2 getByAltText(@args)

Execute the Frame::getByAltText playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-getByAltText> for more information.

=head2 dragAndDrop(@args)

Execute the Frame::dragAndDrop playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-dragAndDrop> for more information.

=head2 innerHTML(@args)

Execute the Frame::innerHTML playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-innerHTML> for more information.

=head2 setInputFiles(@args)

Execute the Frame::setInputFiles playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-setInputFiles> for more information.

=head2 isEditable(@args)

Execute the Frame::isEditable playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-isEditable> for more information.

=head2 waitForFunction(@args)

Execute the Frame::waitForFunction playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-waitForFunction> for more information.

=head2 getByLabel(@args)

Execute the Frame::getByLabel playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-getByLabel> for more information.

=head2 waitForSelector(@args)

Execute the Frame::waitForSelector playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-waitForSelector> for more information.

=head2 page(@args)

Execute the Frame::page playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-page> for more information.

=head2 evaluate(@args)

Execute the Frame::evaluate playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-evaluate> for more information.

=head2 url(@args)

Execute the Frame::url playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-url> for more information.

=head2 frameElement(@args)

Execute the Frame::frameElement playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-frameElement> for more information.

=head2 select(@args)

Execute the Frame::select playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-$> for more information.

=head2 click(@args)

Execute the Frame::click playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-click> for more information.

=head2 childFrames(@args)

Execute the Frame::childFrames playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-childFrames> for more information.

=head2 goto(@args)

Execute the Frame::goto playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-goto> for more information.

=head2 inputValue(@args)

Execute the Frame::inputValue playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-inputValue> for more information.

=head2 title(@args)

Execute the Frame::title playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-title> for more information.

=head2 getByText(@args)

Execute the Frame::getByText playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-getByText> for more information.

=head2 parentFrame(@args)

Execute the Frame::parentFrame playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-parentFrame> for more information.

=head2 evaluateHandle(@args)

Execute the Frame::evaluateHandle playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-evaluateHandle> for more information.

=head2 content(@args)

Execute the Frame::content playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-content> for more information.

=head2 addStyleTag(@args)

Execute the Frame::addStyleTag playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-addStyleTag> for more information.

=head2 setChecked(@args)

Execute the Frame::setChecked playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-setChecked> for more information.

=head2 selectMulti(@args)

Execute the Frame::selectMulti playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-$$> for more information.

=head2 setContent(@args)

Execute the Frame::setContent playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-setContent> for more information.

=head2 getByTestId(@args)

Execute the Frame::getByTestId playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-getByTestId> for more information.

=head2 hover(@args)

Execute the Frame::hover playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-hover> for more information.

=head2 locator(@args)

Execute the Frame::locator playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-locator> for more information.

=head2 name(@args)

Execute the Frame::name playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-name> for more information.

=head2 selectOption(@args)

Execute the Frame::selectOption playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-selectOption> for more information.

=head2 getByTitle(@args)

Execute the Frame::getByTitle playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-getByTitle> for more information.

=head2 type(@args)

Execute the Frame::type playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-type> for more information.

=head2 waitForLoadState(@args)

Execute the Frame::waitForLoadState playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-waitForLoadState> for more information.

=head2 waitForURL(@args)

Execute the Frame::waitForURL playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-waitForURL> for more information.

=head2 isDisabled(@args)

Execute the Frame::isDisabled playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-isDisabled> for more information.

=head2 addScriptTag(@args)

Execute the Frame::addScriptTag playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-addScriptTag> for more information.

=head2 getAttribute(@args)

Execute the Frame::getAttribute playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-getAttribute> for more information.

=head2 waitForTimeout(@args)

Execute the Frame::waitForTimeout playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-waitForTimeout> for more information.

=head2 uncheck(@args)

Execute the Frame::uncheck playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-uncheck> for more information.

=head2 evalMulti(@args)

Execute the Frame::evalMulti playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-$$eval> for more information.

=head2 check(@args)

Execute the Frame::check playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-check> for more information.

=head2 isEnabled(@args)

Execute the Frame::isEnabled playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-isEnabled> for more information.

=head2 press(@args)

Execute the Frame::press playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-press> for more information.

=head2 dblclick(@args)

Execute the Frame::dblclick playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-dblclick> for more information.

=head2 focus(@args)

Execute the Frame::focus playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-focus> for more information.

=head2 fill(@args)

Execute the Frame::fill playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-fill> for more information.

=head2 dispatchEvent(@args)

Execute the Frame::dispatchEvent playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-dispatchEvent> for more information.

=head2 getByPlaceholder(@args)

Execute the Frame::getByPlaceholder playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-getByPlaceholder> for more information.

=head2 eval(@args)

Execute the Frame::eval playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-$eval> for more information.

=head2 isChecked(@args)

Execute the Frame::isChecked playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-isChecked> for more information.

=head2 frameLocator(@args)

Execute the Frame::frameLocator playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-frameLocator> for more information.

=head2 isHidden(@args)

Execute the Frame::isHidden playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-isHidden> for more information.

=head2 on(@args)

Execute the Frame::on playwright routine.

See L<https://playwright.dev/docs/api/class-Frame#Frame-on> for more information.

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
