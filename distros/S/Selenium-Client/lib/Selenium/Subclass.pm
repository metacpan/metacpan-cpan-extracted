package Selenium::Subclass;
$Selenium::Subclass::VERSION = '2.01';
#ABSTRACT: Generic template for Selenium sugar subclasses like Selenium::Session

use strict;
use warnings;

use v5.28;

no warnings 'experimental';
use feature qw/signatures/;


sub new ( $class, $parent, $data ) {
    my %lowkey;
    @lowkey{ map { lc $_ } keys(%$data) } = values(%$data);
    $lowkey{parent} = $parent;

    my $self = bless( \%lowkey, $class );

    $self->_build_subs($class);

    # Make sure this is set so we can expose it for use it in various other calls by end-users
    if ( $self->{sortfield} eq 'element-6066-11e4-a52e-4f735466cecf' ) {
        $self->{sortfield} = 'elementid';
        $self->{elementid} = delete $self->{'element-6066-11e4-a52e-4f735466cecf'};
    }

    return $self;
}

sub _request ( $self, $method, %params ) {

    #XXX BAD SPEC AUTHOR, BAD!
    if ( $self->{sortfield} eq 'elementid' ) {

        # Ensure element childs don't think they are their parent
        $self->{to_inject}{elementid} = $self->{elementid};
    }

    # Inject our sortField param, and anything else we need to
    $params{ $self->{sortfield} } = $self->{ $self->{sortfield} };
    my $inject = $self->{to_inject};
    @params{ keys(%$inject) } = values(%$inject) if ref $inject eq 'HASH';

    # and ensure it is injected into child object requests
    # This is primarily to ensure that the session ID trickles down correctly.
    # Some also need the element ID to trickle down.
    # However, in the case of getting child elements, we wish to specifically prevent that, and do so above.
    $params{inject} = $self->{sortfield};

    $self->{callback}->( $self, $method, %params ) if $self->{callback};

    return $self->{parent}->_request( $method, %params );
}

sub DESTROY ($self) {
    return                             if ${^GLOBAL_PHASE} eq 'DESTRUCT';
    $self->{destroy_callback}->($self) if $self->{destroy_callback};
}

#TODO filter spec so we don't need parent anymore, and can have a catalog() method
sub _build_subs ( $self, $class ) {

    #Filter everything out which doesn't have {sortField} in URI
    my $k = lc( $self->{sortfield} );

    #XXX deranged field name
    $k = 'elementid' if $self->{sortfield} eq 'element-6066-11e4-a52e-4f735466cecf';

    foreach my $sub ( keys( %{ $self->{parent}{spec} } ) ) {
        next unless $self->{parent}{spec}{$sub}{uri} =~ m/{\Q$k\E}/;
        Sub::Install::install_sub(
            {
                code => sub {
                    my $self = shift;
                    return $self->_request( $sub, @_ );
                },
                as   => $sub,
                into => $class,
            }
        ) unless $class->can($sub);
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Selenium::Subclass - Generic template for Selenium sugar subclasses like Selenium::Session

=head1 VERSION

version 2.01

=head1 CONSTRUCTOR

=head2 $class->new($parent Selenium::Client, $data HASHREF)

You should probably not use this directly; objects should be created as part of normal operation.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Selenium::Client|Selenium::Client>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/troglodyne-internet-widgets/selenium-client-perl/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2024 Troglodyne LLC


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
