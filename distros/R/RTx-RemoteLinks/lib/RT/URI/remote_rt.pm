use strict;
use warnings;

package RT::URI::remote_rt;
use base qw/RT::URI::base/;

=head1 NAME

RT::URI::remote_rt - Internal URIs for linking to tickets in configured remote RT instances

=head1 DESCRIPTION

This class should rarely be used directly, but via L<RT::URI> instead.

Represents, parses, and generates internal RT URIs such as:

    remote-rt://example.com/ticket/42
    example:42

=head1 METHODS

Much of the interface below is dictated by L<RT::URI> and L<RT::URI::base>.

=head2 Scheme

Returns the URI scheme for remote RT links (C<remote-rt>).  Regardless of the
custom schemes (aliases) accepted for input, the internal URIs always use this
scheme.

=cut

sub Scheme { "remote-rt" }

=head2 ParseURI URI

Primarily used by L<RT::URI> to set internal state.

Handles URIs like the following:

    remote-rt://example/ticket/42
    example:42

Returns true on success and false on failure.

=cut

sub ParseURI {
    my $self = shift;
    my $uri  = shift;

    # Find remote alias and ticket from URI
    if (   $uri =~ /^([\w.-]+):(\d+)$/i
        or $uri =~ m{^remote-rt://([\w.-]+)/ticket/(\d+)$}i) {
        $self->{alias}  = $1;
        $self->{ticket} = $2;
    } else {
        return;
    }

    # Map alias to canonicalized alias and remote URL base
    @$self{"alias", "remote_base"} = RTx::RemoteLinks->LookupRemote( $self->{alias} );

    # Canonicalize to our internal version of the URI
    $self->{uri} = $self->Scheme . "://" . $self->{alias} . "/ticket/" . $self->{ticket};

    unless ($self->{alias} and $self->{remote_base}) {
        RT->Logger->error("Unknown remote RT ($self->{alias}) in link '$uri'");
        return;
    }

    $self->{href} = sprintf '%s/Ticket/Display.html?id=%d',
        $self->{remote_base}, $self->{ticket};

    return 1;
}

=head2 AsString

Returns a description of this remote ticket using the configured alias

=cut

sub AsString {
    my $self = shift;
    return $self->loc('[_1] ticket #[_2]', $self->{alias}, $self->{ticket});
}

1;
