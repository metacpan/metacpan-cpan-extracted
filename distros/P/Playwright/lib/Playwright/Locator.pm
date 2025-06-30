# ABSTRACT: Automatically generated class for Playwright::Locator
# PODNAME: Playwright::Locator

# These classes used to be generated at runtime, but are now generated when the module is built.
# Don't send patches against these modules, they will be ignored.
# See generate_perl_modules.pl in the repository for generating this.

use strict;
use warnings;

package Playwright::Locator;
$Playwright::Locator::VERSION = '1.531';
use parent 'Playwright::Base';

sub new {
    my ( $self, %options ) = @_;
    $options{type} = 'Locator';
    return $self->SUPER::new(%options);
}

sub spec {
    return $Playwright::spec->{'Locator'}{members};
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

sub getByAltText {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'getByAltText',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub waitFor {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'waitFor',
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

sub isEditable {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'isEditable',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub last {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'last',
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

sub highlight {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'highlight',
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

sub nth {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'nth',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub allInnerTexts {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'allInnerTexts',
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

sub tap {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'tap',
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

sub setChecked {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'setChecked',
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

sub getByText {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'getByText',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub ariaSnapshot {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'ariaSnapshot',
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

sub evaluateAll {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'evaluateAll',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub dragTo {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'dragTo',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub all {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'all',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub allTextContents {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'allTextContents',
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

sub page {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'page',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub pressSequentially {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'pressSequentially',
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

sub click {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'click',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub elementHandles {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'elementHandles',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub filter {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'filter',
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

sub isDisabled {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'isDisabled',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub or {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'or',
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

sub first {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'first',
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

sub contentFrame {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'contentFrame',
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

sub and {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'and',
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

sub describe {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'describe',
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

sub dblclick {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'dblclick',
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

sub blur {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'blur',
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

sub frameLocator {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'frameLocator',
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

sub elementHandle {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'elementHandle',
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

sub count {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'count',
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

sub clear {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'clear',
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

Playwright::Locator - Automatically generated class for Playwright::Locator

=head1 VERSION

version 1.531

=head1 CONSTRUCTOR

=head2 new(%options)

You shouldn't have to call this directly.
Instead it should be returned to you as the result of calls on Playwright objects, or objects it returns.

=head1 METHODS

=head2 setInputFiles(@args)

Execute the Locator::setInputFiles playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-setInputFiles> for more information.

=head2 innerHTML(@args)

Execute the Locator::innerHTML playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-innerHTML> for more information.

=head2 getByAltText(@args)

Execute the Locator::getByAltText playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-getByAltText> for more information.

=head2 waitFor(@args)

Execute the Locator::waitFor playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-waitFor> for more information.

=head2 getByLabel(@args)

Execute the Locator::getByLabel playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-getByLabel> for more information.

=head2 isEditable(@args)

Execute the Locator::isEditable playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-isEditable> for more information.

=head2 last(@args)

Execute the Locator::last playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-last> for more information.

=head2 getByRole(@args)

Execute the Locator::getByRole playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-getByRole> for more information.

=head2 highlight(@args)

Execute the Locator::highlight playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-highlight> for more information.

=head2 isVisible(@args)

Execute the Locator::isVisible playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-isVisible> for more information.

=head2 nth(@args)

Execute the Locator::nth playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-nth> for more information.

=head2 allInnerTexts(@args)

Execute the Locator::allInnerTexts playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-allInnerTexts> for more information.

=head2 innerText(@args)

Execute the Locator::innerText playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-innerText> for more information.

=head2 tap(@args)

Execute the Locator::tap playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-tap> for more information.

=head2 textContent(@args)

Execute the Locator::textContent playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-textContent> for more information.

=head2 setChecked(@args)

Execute the Locator::setChecked playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-setChecked> for more information.

=head2 evaluateHandle(@args)

Execute the Locator::evaluateHandle playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-evaluateHandle> for more information.

=head2 getByText(@args)

Execute the Locator::getByText playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-getByText> for more information.

=head2 ariaSnapshot(@args)

Execute the Locator::ariaSnapshot playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-ariaSnapshot> for more information.

=head2 getByTestId(@args)

Execute the Locator::getByTestId playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-getByTestId> for more information.

=head2 evaluateAll(@args)

Execute the Locator::evaluateAll playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-evaluateAll> for more information.

=head2 dragTo(@args)

Execute the Locator::dragTo playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-dragTo> for more information.

=head2 all(@args)

Execute the Locator::all playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-all> for more information.

=head2 allTextContents(@args)

Execute the Locator::allTextContents playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-allTextContents> for more information.

=head2 evaluate(@args)

Execute the Locator::evaluate playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-evaluate> for more information.

=head2 page(@args)

Execute the Locator::page playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-page> for more information.

=head2 pressSequentially(@args)

Execute the Locator::pressSequentially playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-pressSequentially> for more information.

=head2 inputValue(@args)

Execute the Locator::inputValue playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-inputValue> for more information.

=head2 click(@args)

Execute the Locator::click playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-click> for more information.

=head2 elementHandles(@args)

Execute the Locator::elementHandles playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-elementHandles> for more information.

=head2 filter(@args)

Execute the Locator::filter playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-filter> for more information.

=head2 getByTitle(@args)

Execute the Locator::getByTitle playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-getByTitle> for more information.

=head2 type(@args)

Execute the Locator::type playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-type> for more information.

=head2 isDisabled(@args)

Execute the Locator::isDisabled playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-isDisabled> for more information.

=head2 or(@args)

Execute the Locator::or playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-or> for more information.

=head2 locator(@args)

Execute the Locator::locator playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-locator> for more information.

=head2 hover(@args)

Execute the Locator::hover playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-hover> for more information.

=head2 first(@args)

Execute the Locator::first playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-first> for more information.

=head2 selectOption(@args)

Execute the Locator::selectOption playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-selectOption> for more information.

=head2 contentFrame(@args)

Execute the Locator::contentFrame playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-contentFrame> for more information.

=head2 getByPlaceholder(@args)

Execute the Locator::getByPlaceholder playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-getByPlaceholder> for more information.

=head2 dispatchEvent(@args)

Execute the Locator::dispatchEvent playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-dispatchEvent> for more information.

=head2 and(@args)

Execute the Locator::and playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-and> for more information.

=head2 focus(@args)

Execute the Locator::focus playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-focus> for more information.

=head2 describe(@args)

Execute the Locator::describe playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-describe> for more information.

=head2 fill(@args)

Execute the Locator::fill playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-fill> for more information.

=head2 press(@args)

Execute the Locator::press playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-press> for more information.

=head2 dblclick(@args)

Execute the Locator::dblclick playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-dblclick> for more information.

=head2 scrollIntoViewIfNeeded(@args)

Execute the Locator::scrollIntoViewIfNeeded playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-scrollIntoViewIfNeeded> for more information.

=head2 blur(@args)

Execute the Locator::blur playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-blur> for more information.

=head2 isHidden(@args)

Execute the Locator::isHidden playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-isHidden> for more information.

=head2 boundingBox(@args)

Execute the Locator::boundingBox playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-boundingBox> for more information.

=head2 isChecked(@args)

Execute the Locator::isChecked playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-isChecked> for more information.

=head2 frameLocator(@args)

Execute the Locator::frameLocator playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-frameLocator> for more information.

=head2 uncheck(@args)

Execute the Locator::uncheck playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-uncheck> for more information.

=head2 getAttribute(@args)

Execute the Locator::getAttribute playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-getAttribute> for more information.

=head2 elementHandle(@args)

Execute the Locator::elementHandle playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-elementHandle> for more information.

=head2 isEnabled(@args)

Execute the Locator::isEnabled playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-isEnabled> for more information.

=head2 selectText(@args)

Execute the Locator::selectText playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-selectText> for more information.

=head2 count(@args)

Execute the Locator::count playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-count> for more information.

=head2 check(@args)

Execute the Locator::check playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-check> for more information.

=head2 clear(@args)

Execute the Locator::clear playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-clear> for more information.

=head2 screenshot(@args)

Execute the Locator::screenshot playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-screenshot> for more information.

=head2 on(@args)

Execute the Locator::on playwright routine.

See L<https://playwright.dev/docs/api/class-Locator#Locator-on> for more information.

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
