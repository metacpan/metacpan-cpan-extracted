
package Net::OBEX::Packet::Request::Base;

use strict;
use warnings;
use Carp;

our $VERSION = '1.001001'; # VERSION

sub new {
    my $class = shift;
    croak "Must have even number of arguments to new()"
        if @_ & 1;
    my %args = @_;
    $args{ +lc } = delete $args{ $_ } for keys %args;

    $args{headers} = []
        unless exists $args{headers};

    return bless \%args, $class;
}

sub headers {
    my $self = shift;
    if ( @_ ) {
        $self->{ headers } = shift;
    }
    return $self->{ headers };
}

sub raw {
    my $self = shift;
    if ( @_ ) {
        $self->{ raw } = shift;
    }
    return $self->{ raw };
}

1;

__END__


=head1 NAME

Net::OBEX::Packet::Request::Base - base class for OBEX request packet modules.

=head1 SYNOPSIS

    package Net::OBEX::Packet::Request::Some;

    use strict;
    use warnings;
    our $VERSION = '0.001';
    use Carp;

    use base 'Net::OBEX::Packet::Request::Base';

    sub make {
        my $self = shift;
        my $headers = join '', @{ $self->headers };

        # "\x00" is the opcode
        my $packet = "\x00" . pack( 'n', 3 + length $headers) . $headers;

        return $self->raw($packet);
    }

    1;

    __END__

=head1 DESCRIPTION

B<WARNING!!! This module is in an early alpha stage. It is recommended
that you use it only for testing.>

The module is a base class for OBEX request packet modules.

It defines a constructor (C<new()>), as well as
C<headers()> and C<raw()> accessors/mutators.

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/Net-OBEX>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/Net-OBEX/issues>

If you can't access GitHub, you can email your request
to C<bug-Net-OBEX at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut