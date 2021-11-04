# ABSTRACT: Automatically generated class for Playwright::LocatorAssertions
# PODNAME: Playwright::LocatorAssertions

# These classes used to be generated at runtime, but are now generated when the module is built.
# Don't send patches against these modules, they will be ignored.
# See generate_perl_modules.pl in the repository for generating this.

use strict;
use warnings;

package Playwright::LocatorAssertions;
$Playwright::LocatorAssertions::VERSION = '0.017';
use parent 'Playwright::Base';

sub new {
    my ( $self, %options ) = @_;
    $options{type} = 'LocatorAssertions';
    return $self->SUPER::new(%options);
}

sub spec {
    return $Playwright::spec->{'LocatorAssertions'}{members};
}

sub hasId {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'hasId',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub containsText {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'containsText',
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

sub isEmpty {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'isEmpty',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub hasCount {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'hasCount',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub hasAttribute {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'hasAttribute',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub hasCSS {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'hasCSS',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub hasClass {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'hasClass',
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

sub isChecked {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'isChecked',
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

sub isEnabled {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'isEnabled',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub hasText {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'hasText',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub hasJSProperty {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'hasJSProperty',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub hasValue {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'hasValue',
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

sub isFocused {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'isFocused',
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

version 0.017

=head1 CONSTRUCTOR

=head2 new(%options)

You shouldn't have to call this directly.
Instead it should be returned to you as the result of calls on Playwright objects, or objects it returns.

=head1 METHODS

=head2 hasId(@args)

Execute the LocatorAssertions::hasId playwright routine.

See L<https://playwright.dev/api/class-LocatorAssertions#LocatorAssertions-hasId> for more information.

=head2 containsText(@args)

Execute the LocatorAssertions::containsText playwright routine.

See L<https://playwright.dev/api/class-LocatorAssertions#LocatorAssertions-containsText> for more information.

=head2 isEditable(@args)

Execute the LocatorAssertions::isEditable playwright routine.

See L<https://playwright.dev/api/class-LocatorAssertions#LocatorAssertions-isEditable> for more information.

=head2 isEmpty(@args)

Execute the LocatorAssertions::isEmpty playwright routine.

See L<https://playwright.dev/api/class-LocatorAssertions#LocatorAssertions-isEmpty> for more information.

=head2 hasCount(@args)

Execute the LocatorAssertions::hasCount playwright routine.

See L<https://playwright.dev/api/class-LocatorAssertions#LocatorAssertions-hasCount> for more information.

=head2 hasAttribute(@args)

Execute the LocatorAssertions::hasAttribute playwright routine.

See L<https://playwright.dev/api/class-LocatorAssertions#LocatorAssertions-hasAttribute> for more information.

=head2 hasCSS(@args)

Execute the LocatorAssertions::hasCSS playwright routine.

See L<https://playwright.dev/api/class-LocatorAssertions#LocatorAssertions-hasCSS> for more information.

=head2 hasClass(@args)

Execute the LocatorAssertions::hasClass playwright routine.

See L<https://playwright.dev/api/class-LocatorAssertions#LocatorAssertions-hasClass> for more information.

=head2 not(@args)

Execute the LocatorAssertions::not playwright routine.

See L<https://playwright.dev/api/class-LocatorAssertions#LocatorAssertions-not> for more information.

=head2 isChecked(@args)

Execute the LocatorAssertions::isChecked playwright routine.

See L<https://playwright.dev/api/class-LocatorAssertions#LocatorAssertions-isChecked> for more information.

=head2 isHidden(@args)

Execute the LocatorAssertions::isHidden playwright routine.

See L<https://playwright.dev/api/class-LocatorAssertions#LocatorAssertions-isHidden> for more information.

=head2 isEnabled(@args)

Execute the LocatorAssertions::isEnabled playwright routine.

See L<https://playwright.dev/api/class-LocatorAssertions#LocatorAssertions-isEnabled> for more information.

=head2 hasText(@args)

Execute the LocatorAssertions::hasText playwright routine.

See L<https://playwright.dev/api/class-LocatorAssertions#LocatorAssertions-hasText> for more information.

=head2 hasJSProperty(@args)

Execute the LocatorAssertions::hasJSProperty playwright routine.

See L<https://playwright.dev/api/class-LocatorAssertions#LocatorAssertions-hasJSProperty> for more information.

=head2 hasValue(@args)

Execute the LocatorAssertions::hasValue playwright routine.

See L<https://playwright.dev/api/class-LocatorAssertions#LocatorAssertions-hasValue> for more information.

=head2 isDisabled(@args)

Execute the LocatorAssertions::isDisabled playwright routine.

See L<https://playwright.dev/api/class-LocatorAssertions#LocatorAssertions-isDisabled> for more information.

=head2 isFocused(@args)

Execute the LocatorAssertions::isFocused playwright routine.

See L<https://playwright.dev/api/class-LocatorAssertions#LocatorAssertions-isFocused> for more information.

=head2 isVisible(@args)

Execute the LocatorAssertions::isVisible playwright routine.

See L<https://playwright.dev/api/class-LocatorAssertions#LocatorAssertions-isVisible> for more information.

=head2 on(@args)

Execute the LocatorAssertions::on playwright routine.

See L<https://playwright.dev/api/class-LocatorAssertions#LocatorAssertions-on> for more information.

=head2 evaluate(@args)

Execute the LocatorAssertions::evaluate playwright routine.

See L<https://playwright.dev/api/class-LocatorAssertions#LocatorAssertions-evaluate> for more information.

=head2 evaluateHandle(@args)

Execute the LocatorAssertions::evaluateHandle playwright routine.

See L<https://playwright.dev/api/class-LocatorAssertions#LocatorAssertions-evaluateHandle> for more information.

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
