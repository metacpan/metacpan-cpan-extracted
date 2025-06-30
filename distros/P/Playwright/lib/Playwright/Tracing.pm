# ABSTRACT: Automatically generated class for Playwright::Tracing
# PODNAME: Playwright::Tracing

# These classes used to be generated at runtime, but are now generated when the module is built.
# Don't send patches against these modules, they will be ignored.
# See generate_perl_modules.pl in the repository for generating this.

use strict;
use warnings;

package Playwright::Tracing;
$Playwright::Tracing::VERSION = '1.531';
use parent 'Playwright::Base';

sub new {
    my ( $self, %options ) = @_;
    $options{type} = 'Tracing';
    return $self->SUPER::new(%options);
}

sub spec {
    return $Playwright::spec->{'Tracing'}{members};
}

sub start {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'start',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub stop {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'stop',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub groupEnd {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'groupEnd',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub startChunk {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'startChunk',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub stopChunk {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'stopChunk',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub group {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'group',
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

Playwright::Tracing - Automatically generated class for Playwright::Tracing

=head1 VERSION

version 1.531

=head1 CONSTRUCTOR

=head2 new(%options)

You shouldn't have to call this directly.
Instead it should be returned to you as the result of calls on Playwright objects, or objects it returns.

=head1 METHODS

=head2 start(@args)

Execute the Tracing::start playwright routine.

See L<https://playwright.dev/docs/api/class-Tracing#Tracing-start> for more information.

=head2 stop(@args)

Execute the Tracing::stop playwright routine.

See L<https://playwright.dev/docs/api/class-Tracing#Tracing-stop> for more information.

=head2 groupEnd(@args)

Execute the Tracing::groupEnd playwright routine.

See L<https://playwright.dev/docs/api/class-Tracing#Tracing-groupEnd> for more information.

=head2 startChunk(@args)

Execute the Tracing::startChunk playwright routine.

See L<https://playwright.dev/docs/api/class-Tracing#Tracing-startChunk> for more information.

=head2 stopChunk(@args)

Execute the Tracing::stopChunk playwright routine.

See L<https://playwright.dev/docs/api/class-Tracing#Tracing-stopChunk> for more information.

=head2 group(@args)

Execute the Tracing::group playwright routine.

See L<https://playwright.dev/docs/api/class-Tracing#Tracing-group> for more information.

=head2 on(@args)

Execute the Tracing::on playwright routine.

See L<https://playwright.dev/docs/api/class-Tracing#Tracing-on> for more information.

=head2 evaluate(@args)

Execute the Tracing::evaluate playwright routine.

See L<https://playwright.dev/docs/api/class-Tracing#Tracing-evaluate> for more information.

=head2 evaluateHandle(@args)

Execute the Tracing::evaluateHandle playwright routine.

See L<https://playwright.dev/docs/api/class-Tracing#Tracing-evaluateHandle> for more information.

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
