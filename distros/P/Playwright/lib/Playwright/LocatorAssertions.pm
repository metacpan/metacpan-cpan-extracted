# ABSTRACT: Automatically generated class for Playwright::LocatorAssertions
# PODNAME: Playwright::LocatorAssertions

# These classes used to be generated at runtime, but are now generated when the module is built.
# Don't send patches against these modules, they will be ignored.
# See generate_perl_modules.pl in the repository for generating this.

use strict;
use warnings;

package Playwright::LocatorAssertions;
$Playwright::LocatorAssertions::VERSION = '1.531';
use parent 'Playwright::Base';

sub new {
    my ( $self, %options ) = @_;
    $options{type} = 'LocatorAssertions';
    return $self->SUPER::new(%options);
}

sub spec {
    return $Playwright::spec->{'LocatorAssertions'}{members};
}

sub toBeEmpty {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toBeEmpty',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub NotToHaveId {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'NotToHaveId',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub NotToBeEditable {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'NotToBeEditable',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub NotToHaveRole {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'NotToHaveRole',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toHaveJSProperty {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toHaveJSProperty',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub NotToHaveClass {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'NotToHaveClass',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub NotToBeAttached {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'NotToBeAttached',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toBeAttached {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toBeAttached',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toHaveRole {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toHaveRole',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub NotToHaveAttribute {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'NotToHaveAttribute',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub NotToHaveJSProperty {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'NotToHaveJSProperty',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toHaveScreenshot {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toHaveScreenshot',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toBeDisabled {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toBeDisabled',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub NotToBeVisible {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'NotToBeVisible',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub NotToHaveValue {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'NotToHaveValue',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub NotToBeEmpty {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'NotToBeEmpty',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub NotToHaveText {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'NotToHaveText',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub NotToHaveAccessibleDescription {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'NotToHaveAccessibleDescription',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toHaveValues {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toHaveValues',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub NotToHaveCSS {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'NotToHaveCSS',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub NotToBeInViewport {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'NotToBeInViewport',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub NotToMatchAriaSnapshot {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'NotToMatchAriaSnapshot',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toHaveAccessibleDescription {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toHaveAccessibleDescription',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub NotToBeFocused {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'NotToBeFocused',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toContainText {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toContainText',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub NotToHaveAccessibleName {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'NotToHaveAccessibleName',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toBeInViewport {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toBeInViewport',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toHaveAttribute {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toHaveAttribute',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toBeEditable {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toBeEditable',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toBeFocused {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toBeFocused',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toBeChecked {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toBeChecked',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toMatchAriaSnapshot {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toMatchAriaSnapshot',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub NotToBeDisabled {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'NotToBeDisabled',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub NotToBeHidden {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'NotToBeHidden',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toHaveValue {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toHaveValue',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toHaveCSS {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toHaveCSS',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toBeEnabled {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toBeEnabled',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toHaveId {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toHaveId',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub NotToBeChecked {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'NotToBeChecked',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toHaveClass {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toHaveClass',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toBeHidden {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toBeHidden',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toHaveText {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toHaveText',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toContainClass {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toContainClass',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub NotToBeEnabled {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'NotToBeEnabled',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toBeVisible {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toBeVisible',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toHaveAccessibleErrorMessage {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toHaveAccessibleErrorMessage',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toHaveCount {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toHaveCount',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub not {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'not',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub NotToContainClass {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'NotToContainClass',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub NotToHaveAccessibleErrorMessage {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'NotToHaveAccessibleErrorMessage',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub NotToContainText {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'NotToContainText',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub NotToHaveCount {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'NotToHaveCount',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toHaveAccessibleName {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toHaveAccessibleName',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub NotToHaveValues {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'NotToHaveValues',
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

Playwright::LocatorAssertions - Automatically generated class for Playwright::LocatorAssertions

=head1 VERSION

version 1.531

=head1 CONSTRUCTOR

=head2 new(%options)

You shouldn't have to call this directly.
Instead it should be returned to you as the result of calls on Playwright objects, or objects it returns.

=head1 METHODS

=head2 toBeEmpty(@args)

Execute the LocatorAssertions::toBeEmpty playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-toBeEmpty> for more information.

=head2 NotToHaveId(@args)

Execute the LocatorAssertions::NotToHaveId playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-NotToHaveId> for more information.

=head2 NotToBeEditable(@args)

Execute the LocatorAssertions::NotToBeEditable playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-NotToBeEditable> for more information.

=head2 NotToHaveRole(@args)

Execute the LocatorAssertions::NotToHaveRole playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-NotToHaveRole> for more information.

=head2 toHaveJSProperty(@args)

Execute the LocatorAssertions::toHaveJSProperty playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-toHaveJSProperty> for more information.

=head2 NotToHaveClass(@args)

Execute the LocatorAssertions::NotToHaveClass playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-NotToHaveClass> for more information.

=head2 NotToBeAttached(@args)

Execute the LocatorAssertions::NotToBeAttached playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-NotToBeAttached> for more information.

=head2 toBeAttached(@args)

Execute the LocatorAssertions::toBeAttached playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-toBeAttached> for more information.

=head2 toHaveRole(@args)

Execute the LocatorAssertions::toHaveRole playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-toHaveRole> for more information.

=head2 NotToHaveAttribute(@args)

Execute the LocatorAssertions::NotToHaveAttribute playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-NotToHaveAttribute> for more information.

=head2 NotToHaveJSProperty(@args)

Execute the LocatorAssertions::NotToHaveJSProperty playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-NotToHaveJSProperty> for more information.

=head2 toHaveScreenshot(@args)

Execute the LocatorAssertions::toHaveScreenshot playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-toHaveScreenshot> for more information.

=head2 toBeDisabled(@args)

Execute the LocatorAssertions::toBeDisabled playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-toBeDisabled> for more information.

=head2 NotToBeVisible(@args)

Execute the LocatorAssertions::NotToBeVisible playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-NotToBeVisible> for more information.

=head2 NotToHaveValue(@args)

Execute the LocatorAssertions::NotToHaveValue playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-NotToHaveValue> for more information.

=head2 NotToBeEmpty(@args)

Execute the LocatorAssertions::NotToBeEmpty playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-NotToBeEmpty> for more information.

=head2 NotToHaveText(@args)

Execute the LocatorAssertions::NotToHaveText playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-NotToHaveText> for more information.

=head2 NotToHaveAccessibleDescription(@args)

Execute the LocatorAssertions::NotToHaveAccessibleDescription playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-NotToHaveAccessibleDescription> for more information.

=head2 toHaveValues(@args)

Execute the LocatorAssertions::toHaveValues playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-toHaveValues> for more information.

=head2 NotToHaveCSS(@args)

Execute the LocatorAssertions::NotToHaveCSS playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-NotToHaveCSS> for more information.

=head2 NotToBeInViewport(@args)

Execute the LocatorAssertions::NotToBeInViewport playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-NotToBeInViewport> for more information.

=head2 NotToMatchAriaSnapshot(@args)

Execute the LocatorAssertions::NotToMatchAriaSnapshot playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-NotToMatchAriaSnapshot> for more information.

=head2 toHaveAccessibleDescription(@args)

Execute the LocatorAssertions::toHaveAccessibleDescription playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-toHaveAccessibleDescription> for more information.

=head2 NotToBeFocused(@args)

Execute the LocatorAssertions::NotToBeFocused playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-NotToBeFocused> for more information.

=head2 toContainText(@args)

Execute the LocatorAssertions::toContainText playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-toContainText> for more information.

=head2 NotToHaveAccessibleName(@args)

Execute the LocatorAssertions::NotToHaveAccessibleName playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-NotToHaveAccessibleName> for more information.

=head2 toBeInViewport(@args)

Execute the LocatorAssertions::toBeInViewport playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-toBeInViewport> for more information.

=head2 toHaveAttribute(@args)

Execute the LocatorAssertions::toHaveAttribute playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-toHaveAttribute> for more information.

=head2 toBeEditable(@args)

Execute the LocatorAssertions::toBeEditable playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-toBeEditable> for more information.

=head2 toBeFocused(@args)

Execute the LocatorAssertions::toBeFocused playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-toBeFocused> for more information.

=head2 toBeChecked(@args)

Execute the LocatorAssertions::toBeChecked playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-toBeChecked> for more information.

=head2 toMatchAriaSnapshot(@args)

Execute the LocatorAssertions::toMatchAriaSnapshot playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-toMatchAriaSnapshot> for more information.

=head2 NotToBeDisabled(@args)

Execute the LocatorAssertions::NotToBeDisabled playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-NotToBeDisabled> for more information.

=head2 NotToBeHidden(@args)

Execute the LocatorAssertions::NotToBeHidden playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-NotToBeHidden> for more information.

=head2 toHaveValue(@args)

Execute the LocatorAssertions::toHaveValue playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-toHaveValue> for more information.

=head2 toHaveCSS(@args)

Execute the LocatorAssertions::toHaveCSS playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-toHaveCSS> for more information.

=head2 toBeEnabled(@args)

Execute the LocatorAssertions::toBeEnabled playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-toBeEnabled> for more information.

=head2 toHaveId(@args)

Execute the LocatorAssertions::toHaveId playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-toHaveId> for more information.

=head2 NotToBeChecked(@args)

Execute the LocatorAssertions::NotToBeChecked playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-NotToBeChecked> for more information.

=head2 toHaveClass(@args)

Execute the LocatorAssertions::toHaveClass playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-toHaveClass> for more information.

=head2 toBeHidden(@args)

Execute the LocatorAssertions::toBeHidden playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-toBeHidden> for more information.

=head2 toHaveText(@args)

Execute the LocatorAssertions::toHaveText playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-toHaveText> for more information.

=head2 toContainClass(@args)

Execute the LocatorAssertions::toContainClass playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-toContainClass> for more information.

=head2 NotToBeEnabled(@args)

Execute the LocatorAssertions::NotToBeEnabled playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-NotToBeEnabled> for more information.

=head2 toBeVisible(@args)

Execute the LocatorAssertions::toBeVisible playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-toBeVisible> for more information.

=head2 toHaveAccessibleErrorMessage(@args)

Execute the LocatorAssertions::toHaveAccessibleErrorMessage playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-toHaveAccessibleErrorMessage> for more information.

=head2 toHaveCount(@args)

Execute the LocatorAssertions::toHaveCount playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-toHaveCount> for more information.

=head2 not(@args)

Execute the LocatorAssertions::not playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-not> for more information.

=head2 NotToContainClass(@args)

Execute the LocatorAssertions::NotToContainClass playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-NotToContainClass> for more information.

=head2 NotToHaveAccessibleErrorMessage(@args)

Execute the LocatorAssertions::NotToHaveAccessibleErrorMessage playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-NotToHaveAccessibleErrorMessage> for more information.

=head2 NotToContainText(@args)

Execute the LocatorAssertions::NotToContainText playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-NotToContainText> for more information.

=head2 NotToHaveCount(@args)

Execute the LocatorAssertions::NotToHaveCount playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-NotToHaveCount> for more information.

=head2 toHaveAccessibleName(@args)

Execute the LocatorAssertions::toHaveAccessibleName playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-toHaveAccessibleName> for more information.

=head2 NotToHaveValues(@args)

Execute the LocatorAssertions::NotToHaveValues playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-NotToHaveValues> for more information.

=head2 on(@args)

Execute the LocatorAssertions::on playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-on> for more information.

=head2 evaluate(@args)

Execute the LocatorAssertions::evaluate playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-evaluate> for more information.

=head2 evaluateHandle(@args)

Execute the LocatorAssertions::evaluateHandle playwright routine.

See L<https://playwright.dev/docs/api/class-LocatorAssertions#LocatorAssertions-evaluateHandle> for more information.

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
