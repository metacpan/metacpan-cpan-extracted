# ABSTRACT: Automatically generated class for Playwright::ElementHandle
# PODNAME: Playwright::ElementHandle

# These classes used to be generated at runtime, but are now generated when the module is built.
# Don't send patches against these modules, they will be ignored.
# See generate_perl_modules.pl in the repository for generating this.

use strict;
use warnings;

package Playwright::ElementHandle;
$Playwright::ElementHandle::VERSION = '1.531';
use parent 'Playwright::Base';

sub new {
    my ( $self, %options ) = @_;
    $options{type} = 'ElementHandle';
    return $self->SUPER::new(%options);
}

sub spec {
    return $Playwright::spec->{'ElementHandle'}{members};
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

sub isEditable {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'isEditable',
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

sub setInputFiles {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'setInputFiles',
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

sub tap {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'tap',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub contentFrame {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'contentFrame',
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

sub selectOption {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'selectOption',
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

sub ownerFrame {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'ownerFrame',
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

sub hover {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'hover',
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

sub boundingBox {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'boundingBox',
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

sub scrollIntoViewIfNeeded {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'scrollIntoViewIfNeeded',
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

sub dblclick {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'dblclick',
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

sub dispatchEvent {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'dispatchEvent',
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

sub check {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'check',
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

sub click {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'click',
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

sub waitForElementState {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'waitForElementState',
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

sub selectText {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'selectText',
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

sub getAttribute {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'getAttribute',
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

sub select {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => '$',
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

Playwright::ElementHandle - Automatically generated class for Playwright::ElementHandle

=head1 VERSION

version 1.531

=head1 CONSTRUCTOR

=head2 new(%options)

You shouldn't have to call this directly.
Instead it should be returned to you as the result of calls on Playwright objects, or objects it returns.

=head1 METHODS

=head2 isDisabled(@args)

Execute the ElementHandle::isDisabled playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-isDisabled> for more information.

=head2 isEditable(@args)

Execute the ElementHandle::isEditable playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-isEditable> for more information.

=head2 type(@args)

Execute the ElementHandle::type playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-type> for more information.

=head2 setInputFiles(@args)

Execute the ElementHandle::setInputFiles playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-setInputFiles> for more information.

=head2 innerHTML(@args)

Execute the ElementHandle::innerHTML playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-innerHTML> for more information.

=head2 tap(@args)

Execute the ElementHandle::tap playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-tap> for more information.

=head2 contentFrame(@args)

Execute the ElementHandle::contentFrame playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-contentFrame> for more information.

=head2 textContent(@args)

Execute the ElementHandle::textContent playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-textContent> for more information.

=head2 selectOption(@args)

Execute the ElementHandle::selectOption playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-selectOption> for more information.

=head2 innerText(@args)

Execute the ElementHandle::innerText playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-innerText> for more information.

=head2 ownerFrame(@args)

Execute the ElementHandle::ownerFrame playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-ownerFrame> for more information.

=head2 isVisible(@args)

Execute the ElementHandle::isVisible playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-isVisible> for more information.

=head2 hover(@args)

Execute the ElementHandle::hover playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-hover> for more information.

=head2 isHidden(@args)

Execute the ElementHandle::isHidden playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-isHidden> for more information.

=head2 boundingBox(@args)

Execute the ElementHandle::boundingBox playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-boundingBox> for more information.

=head2 isChecked(@args)

Execute the ElementHandle::isChecked playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-isChecked> for more information.

=head2 scrollIntoViewIfNeeded(@args)

Execute the ElementHandle::scrollIntoViewIfNeeded playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-scrollIntoViewIfNeeded> for more information.

=head2 focus(@args)

Execute the ElementHandle::focus playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-focus> for more information.

=head2 fill(@args)

Execute the ElementHandle::fill playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-fill> for more information.

=head2 dblclick(@args)

Execute the ElementHandle::dblclick playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-dblclick> for more information.

=head2 press(@args)

Execute the ElementHandle::press playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-press> for more information.

=head2 dispatchEvent(@args)

Execute the ElementHandle::dispatchEvent playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-dispatchEvent> for more information.

=head2 eval(@args)

Execute the ElementHandle::eval playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-$eval> for more information.

=head2 setChecked(@args)

Execute the ElementHandle::setChecked playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-setChecked> for more information.

=head2 selectMulti(@args)

Execute the ElementHandle::selectMulti playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-$$> for more information.

=head2 check(@args)

Execute the ElementHandle::check playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-check> for more information.

=head2 evalMulti(@args)

Execute the ElementHandle::evalMulti playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-$$eval> for more information.

=head2 click(@args)

Execute the ElementHandle::click playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-click> for more information.

=head2 screenshot(@args)

Execute the ElementHandle::screenshot playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-screenshot> for more information.

=head2 waitForElementState(@args)

Execute the ElementHandle::waitForElementState playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-waitForElementState> for more information.

=head2 isEnabled(@args)

Execute the ElementHandle::isEnabled playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-isEnabled> for more information.

=head2 selectText(@args)

Execute the ElementHandle::selectText playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-selectText> for more information.

=head2 inputValue(@args)

Execute the ElementHandle::inputValue playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-inputValue> for more information.

=head2 getAttribute(@args)

Execute the ElementHandle::getAttribute playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-getAttribute> for more information.

=head2 waitForSelector(@args)

Execute the ElementHandle::waitForSelector playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-waitForSelector> for more information.

=head2 select(@args)

Execute the ElementHandle::select playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-$> for more information.

=head2 uncheck(@args)

Execute the ElementHandle::uncheck playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-uncheck> for more information.

=head2 on(@args)

Execute the ElementHandle::on playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-on> for more information.

=head2 evaluate(@args)

Execute the ElementHandle::evaluate playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-evaluate> for more information.

=head2 evaluateHandle(@args)

Execute the ElementHandle::evaluateHandle playwright routine.

See L<https://playwright.dev/docs/api/class-ElementHandle#ElementHandle-evaluateHandle> for more information.

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
