# ABSTRACT: Automatically generated class for Playwright::FetchRequest
# PODNAME: Playwright::FetchRequest

# These classes used to be generated at runtime, but are now generated when the module is built.
# Don't send patches against these modules, they will be ignored.
# See generate_perl_modules.pl in the repository for generating this.

use strict;
use warnings;

package Playwright::FetchRequest;
$Playwright::FetchRequest::VERSION = '0.016';
use parent 'Playwright::Base';

sub new {
    my ( $self, %options ) = @_;
    $options{type} = 'FetchRequest';
    return $self->SUPER::new(%options);
}

sub post {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'post',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub dispose {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'dispose',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub fetch {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'fetch',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub storageState {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'storageState',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub get {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'get',
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

Playwright::FetchRequest - Automatically generated class for Playwright::FetchRequest

=head1 VERSION

version 0.016

=head1 CONSTRUCTOR

=head2 new(%options)

You shouldn't have to call this directly.
Instead it should be returned to you as the result of calls on Playwright objects, or objects it returns.

=head1 METHODS

=head2 post(@args)

Execute the FetchRequest::post playwright routine.

See L<https://playwright.dev/api/class-FetchRequest#FetchRequest-post> for more information.

=head2 dispose(@args)

Execute the FetchRequest::dispose playwright routine.

See L<https://playwright.dev/api/class-FetchRequest#FetchRequest-dispose> for more information.

=head2 fetch(@args)

Execute the FetchRequest::fetch playwright routine.

See L<https://playwright.dev/api/class-FetchRequest#FetchRequest-fetch> for more information.

=head2 storageState(@args)

Execute the FetchRequest::storageState playwright routine.

See L<https://playwright.dev/api/class-FetchRequest#FetchRequest-storageState> for more information.

=head2 get(@args)

Execute the FetchRequest::get playwright routine.

See L<https://playwright.dev/api/class-FetchRequest#FetchRequest-get> for more information.

=head2 on(@args)

Execute the FetchRequest::on playwright routine.

See L<https://playwright.dev/api/class-FetchRequest#FetchRequest-on> for more information.

=head2 evaluate(@args)

Execute the FetchRequest::evaluate playwright routine.

See L<https://playwright.dev/api/class-FetchRequest#FetchRequest-evaluate> for more information.

=head2 evaluateHandle(@args)

Execute the FetchRequest::evaluateHandle playwright routine.

See L<https://playwright.dev/api/class-FetchRequest#FetchRequest-evaluateHandle> for more information.

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
