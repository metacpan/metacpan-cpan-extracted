# ABSTRACT: Automatically generated class for Playwright::GenericAssertions
# PODNAME: Playwright::GenericAssertions

# These classes used to be generated at runtime, but are now generated when the module is built.
# Don't send patches against these modules, they will be ignored.
# See generate_perl_modules.pl in the repository for generating this.

use strict;
use warnings;

package Playwright::GenericAssertions;
$Playwright::GenericAssertions::VERSION = '1.531';
use parent 'Playwright::Base';

sub new {
    my ( $self, %options ) = @_;
    $options{type} = 'GenericAssertions';
    return $self->SUPER::new(%options);
}

sub spec {
    return $Playwright::spec->{'GenericAssertions'}{members};
}

sub toBeGreaterThanOrEqual {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toBeGreaterThanOrEqual',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub objectContaining {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'objectContaining',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toHaveProperty {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toHaveProperty',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub anything {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'anything',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub stringMatching {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'stringMatching',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toMatchObject {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toMatchObject',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toBeDefined {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toBeDefined',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toBeInstanceOf {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toBeInstanceOf',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toBeNaN {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toBeNaN',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toBeFalsy {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toBeFalsy',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub closeTo {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'closeTo',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toBeCloseTo {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toBeCloseTo',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toBeUndefined {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toBeUndefined',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toHaveLength {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toHaveLength',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toEqual {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toEqual',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub arrayContaining {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'arrayContaining',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toContain {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toContain',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toBeLessThanOrEqual {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toBeLessThanOrEqual',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toBeGreaterThan {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toBeGreaterThan',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub any {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'any',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toMatch {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toMatch',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toBeNull {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toBeNull',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toBeTruthy {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toBeTruthy',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toThrowError {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toThrowError',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toContainEqual {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toContainEqual',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toStrictEqual {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toStrictEqual',
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

sub toThrow {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toThrow',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toBeLessThan {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toBeLessThan',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub toBe {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'toBe',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub stringContaining {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'stringContaining',
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

Playwright::GenericAssertions - Automatically generated class for Playwright::GenericAssertions

=head1 VERSION

version 1.531

=head1 CONSTRUCTOR

=head2 new(%options)

You shouldn't have to call this directly.
Instead it should be returned to you as the result of calls on Playwright objects, or objects it returns.

=head1 METHODS

=head2 toBeGreaterThanOrEqual(@args)

Execute the GenericAssertions::toBeGreaterThanOrEqual playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-toBeGreaterThanOrEqual> for more information.

=head2 objectContaining(@args)

Execute the GenericAssertions::objectContaining playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-objectContaining> for more information.

=head2 toHaveProperty(@args)

Execute the GenericAssertions::toHaveProperty playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-toHaveProperty> for more information.

=head2 anything(@args)

Execute the GenericAssertions::anything playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-anything> for more information.

=head2 stringMatching(@args)

Execute the GenericAssertions::stringMatching playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-stringMatching> for more information.

=head2 toMatchObject(@args)

Execute the GenericAssertions::toMatchObject playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-toMatchObject> for more information.

=head2 toBeDefined(@args)

Execute the GenericAssertions::toBeDefined playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-toBeDefined> for more information.

=head2 toBeInstanceOf(@args)

Execute the GenericAssertions::toBeInstanceOf playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-toBeInstanceOf> for more information.

=head2 toBeNaN(@args)

Execute the GenericAssertions::toBeNaN playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-toBeNaN> for more information.

=head2 toBeFalsy(@args)

Execute the GenericAssertions::toBeFalsy playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-toBeFalsy> for more information.

=head2 closeTo(@args)

Execute the GenericAssertions::closeTo playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-closeTo> for more information.

=head2 toBeCloseTo(@args)

Execute the GenericAssertions::toBeCloseTo playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-toBeCloseTo> for more information.

=head2 toBeUndefined(@args)

Execute the GenericAssertions::toBeUndefined playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-toBeUndefined> for more information.

=head2 toHaveLength(@args)

Execute the GenericAssertions::toHaveLength playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-toHaveLength> for more information.

=head2 toEqual(@args)

Execute the GenericAssertions::toEqual playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-toEqual> for more information.

=head2 arrayContaining(@args)

Execute the GenericAssertions::arrayContaining playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-arrayContaining> for more information.

=head2 toContain(@args)

Execute the GenericAssertions::toContain playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-toContain> for more information.

=head2 toBeLessThanOrEqual(@args)

Execute the GenericAssertions::toBeLessThanOrEqual playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-toBeLessThanOrEqual> for more information.

=head2 toBeGreaterThan(@args)

Execute the GenericAssertions::toBeGreaterThan playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-toBeGreaterThan> for more information.

=head2 any(@args)

Execute the GenericAssertions::any playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-any> for more information.

=head2 toMatch(@args)

Execute the GenericAssertions::toMatch playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-toMatch> for more information.

=head2 toBeNull(@args)

Execute the GenericAssertions::toBeNull playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-toBeNull> for more information.

=head2 toBeTruthy(@args)

Execute the GenericAssertions::toBeTruthy playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-toBeTruthy> for more information.

=head2 toThrowError(@args)

Execute the GenericAssertions::toThrowError playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-toThrowError> for more information.

=head2 toContainEqual(@args)

Execute the GenericAssertions::toContainEqual playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-toContainEqual> for more information.

=head2 toStrictEqual(@args)

Execute the GenericAssertions::toStrictEqual playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-toStrictEqual> for more information.

=head2 not(@args)

Execute the GenericAssertions::not playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-not> for more information.

=head2 toThrow(@args)

Execute the GenericAssertions::toThrow playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-toThrow> for more information.

=head2 toBeLessThan(@args)

Execute the GenericAssertions::toBeLessThan playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-toBeLessThan> for more information.

=head2 toBe(@args)

Execute the GenericAssertions::toBe playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-toBe> for more information.

=head2 stringContaining(@args)

Execute the GenericAssertions::stringContaining playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-stringContaining> for more information.

=head2 on(@args)

Execute the GenericAssertions::on playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-on> for more information.

=head2 evaluate(@args)

Execute the GenericAssertions::evaluate playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-evaluate> for more information.

=head2 evaluateHandle(@args)

Execute the GenericAssertions::evaluateHandle playwright routine.

See L<https://playwright.dev/docs/api/class-GenericAssertions#GenericAssertions-evaluateHandle> for more information.

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
