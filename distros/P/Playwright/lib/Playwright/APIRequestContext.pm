# ABSTRACT: Automatically generated class for Playwright::APIRequestContext
# PODNAME: Playwright::APIRequestContext

# These classes used to be generated at runtime, but are now generated when the module is built.
# Don't send patches against these modules, they will be ignored.
# See generate_perl_modules.pl in the repository for generating this.

use strict;
use warnings;

package Playwright::APIRequestContext;
$Playwright::APIRequestContext::VERSION = '1.531';
use parent 'Playwright::Base';

sub new {
    my ( $self, %options ) = @_;
    $options{type} = 'APIRequestContext';
    return $self->SUPER::new(%options);
}

sub spec {
    return $Playwright::spec->{'APIRequestContext'}{members};
}

sub put {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'put',
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

sub dispose {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'dispose',
        object  => $self->{guid},
        type    => $self->{type}
    );
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

sub createFormData {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'createFormData',
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

sub patch {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'patch',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub delete {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'delete',
        object  => $self->{guid},
        type    => $self->{type}
    );
}

sub head {
    my $self = shift;
    return $self->_api_request(
        args    => [@_],
        command => 'head',
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

Playwright::APIRequestContext - Automatically generated class for Playwright::APIRequestContext

=head1 VERSION

version 1.531

=head1 CONSTRUCTOR

=head2 new(%options)

You shouldn't have to call this directly.
Instead it should be returned to you as the result of calls on Playwright objects, or objects it returns.

=head1 METHODS

=head2 put(@args)

Execute the APIRequestContext::put playwright routine.

See L<https://playwright.dev/docs/api/class-APIRequestContext#APIRequestContext-put> for more information.

=head2 storageState(@args)

Execute the APIRequestContext::storageState playwright routine.

See L<https://playwright.dev/docs/api/class-APIRequestContext#APIRequestContext-storageState> for more information.

=head2 dispose(@args)

Execute the APIRequestContext::dispose playwright routine.

See L<https://playwright.dev/docs/api/class-APIRequestContext#APIRequestContext-dispose> for more information.

=head2 post(@args)

Execute the APIRequestContext::post playwright routine.

See L<https://playwright.dev/docs/api/class-APIRequestContext#APIRequestContext-post> for more information.

=head2 createFormData(@args)

Execute the APIRequestContext::createFormData playwright routine.

See L<https://playwright.dev/docs/api/class-APIRequestContext#APIRequestContext-createFormData> for more information.

=head2 get(@args)

Execute the APIRequestContext::get playwright routine.

See L<https://playwright.dev/docs/api/class-APIRequestContext#APIRequestContext-get> for more information.

=head2 patch(@args)

Execute the APIRequestContext::patch playwright routine.

See L<https://playwright.dev/docs/api/class-APIRequestContext#APIRequestContext-patch> for more information.

=head2 delete(@args)

Execute the APIRequestContext::delete playwright routine.

See L<https://playwright.dev/docs/api/class-APIRequestContext#APIRequestContext-delete> for more information.

=head2 head(@args)

Execute the APIRequestContext::head playwright routine.

See L<https://playwright.dev/docs/api/class-APIRequestContext#APIRequestContext-head> for more information.

=head2 fetch(@args)

Execute the APIRequestContext::fetch playwright routine.

See L<https://playwright.dev/docs/api/class-APIRequestContext#APIRequestContext-fetch> for more information.

=head2 on(@args)

Execute the APIRequestContext::on playwright routine.

See L<https://playwright.dev/docs/api/class-APIRequestContext#APIRequestContext-on> for more information.

=head2 evaluate(@args)

Execute the APIRequestContext::evaluate playwright routine.

See L<https://playwright.dev/docs/api/class-APIRequestContext#APIRequestContext-evaluate> for more information.

=head2 evaluateHandle(@args)

Execute the APIRequestContext::evaluateHandle playwright routine.

See L<https://playwright.dev/docs/api/class-APIRequestContext#APIRequestContext-evaluateHandle> for more information.

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
