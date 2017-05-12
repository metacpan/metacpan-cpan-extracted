package Net::Tshark::Field;
use strict;
use warnings;

our $VERSION = '0.04';

use List::MoreUtils qw(any all uniq after);
use List::Util qw(reduce);

use overload (
    q("") => sub {
        my $self = tied %{ $_[0] };
        $self->{__value};
    }
);

sub new
{
    my ($class, $field_data) = @_;
    return if (!defined $field_data);

    # Extract the value, and child nodes of this field
    my $value =
      (defined $field_data->{show})
      ? $field_data->{show}
      : $field_data->{showname};
    my @child_nodes =
      (@{ $field_data->{field} || [] }, @{ $field_data->{proto} || [] });

    # If this node has no children, we can just return a scalar
    return $value if (!@child_nodes);

    # If a field doesn't have a name, give it a name based on
    # its showname or show attribute.
    foreach (@child_nodes)
    {
        if (!defined $_->{name} || !length $_->{name})
        {
            $_->{name} =
              defined $_->{showname} && length($_->{showname}) ? $_->{showname}
              : defined $_->{show} ? $_->{show}
              :                      q();
        }
    }

    my $data = {
        show          => $field_data->{show},
        showname      => $field_data->{showname},
        name          => $field_data->{name},
        size          => $field_data->{size},
        value         => $field_data->{value},
        __value       => $value,
        __child_nodes => \@child_nodes,
    };

    # Tie a new hash to this package so we can access parts of the parsed
    # PDML using hash notation (e.g. $packet->{ip}). Note that the TIEHASH
    # subroutine does the actual construction of the object.
    my $self = {};
    tie %{$self}, $class, $data;
    return bless $self, $class;
}

sub fields
{
    my ($field) = @_;
    my $self = tied %{$field};
    return map { Net::Tshark::Field->new($_) } @{ $self->{__child_nodes} };
}

sub show
{
    my ($field) = @_;
    my $self = tied %{$field};
    return $self->{show};
}

sub showname
{
    my ($field) = @_;
    my $self = tied %{$field};
    return $self->{showname};
}

sub name
{
    my ($field) = @_;
    my $self = tied %{$field};
    return $self->{name};
}

sub size
{
    my ($field) = @_;
    my $self = tied %{$field};
    return $self->{size};
}

sub value
{
    my ($field) = @_;
    my $self = tied %{$field};
    return $self->{value};
}

sub hash
{
    my ($field) = @_;

    my %hash = %{$field};
    while (my ($key, $value) = each %hash)
    {
        if (ref $hash{$key})
        {
            my $sub_hash = $hash{$key}->hash;
            $hash{$key} = $sub_hash;
        }
    }

    return \%hash;
}

sub TIEHASH
{
    my ($class, $self) = @_;
    return bless $self, $class;
}

sub STORE
{

    # Do nothing. If someone tries to access a field that doesn't exist,
    # Perl will try to create it via autovilification. We don't want to
    # create anything, but we also don't want this to trigger any warnings.
}

sub FETCH
{
    my ($self, $key) = @_;
    my @nodes = $self->__fields($key);

    # If nothing was found, do a deep search in the child nodes for a name match
    if (!@nodes)
    {
        foreach my $child (@{ $self->{__child_nodes} })
        {
            push @nodes,
              grep { $_->{name} =~ /^(?:.*\.)?$key$/i }
              (@{ $child->{field} || [] }, @{ $child->{proto} || [] });
        }
    }

    # If all the matching fields are leaves, append all their values and
    # return them as a constructed field
    if (all { !defined $_->{field} && !defined $_->{proto} } @nodes)
    {
        my $show = join(q(),
            map { (defined $_->{show}) ? $_->{show} : $_->{showname} } @nodes);
        return Net::Tshark::Field->new({ show => $show });
    }

    # Otherwise, return the first matching node
    return Net::Tshark::Field->new($nodes[0]);
}

sub EXISTS
{
    my ($self, $key) = @_;
    return any { $_->{name} =~ /^(?:.*\.)?$key$/i } @{ $self->{__child_nodes} };
}

sub DEFINED
{
    return EXISTS(@_);
}

sub CLEAR
{
    warn 'You cannot clear a ' . __PACKAGE__ . ' object';
    return;
}

sub DELETE
{
    warn 'You cannot delete from a ' . __PACKAGE__ . ' object';
    return;
}

sub FIRSTKEY
{
    my ($self) = @_;
    return (@{ $self->{__child_nodes} })[0]->{name};
}

sub NEXTKEY
{
    my ($self, $last_key) = @_;

    # Get a set of all the names of the child nodes, with no repeats
    my @keys = uniq(map { $_->{name} } @{ $self->{__child_nodes} });
    return (after { $_ eq $last_key } (@keys))[0];
}

sub __fields
{
    my ($self, $key) = @_;

    # Message bodies are named differently in different versions of Wireshark
    if ($key eq 'Message body' || $key eq 'msg_body')
    {
        $key = qr/Message body|msg_body/;
    }

    # Find all the fields with a name that matches $key.
    my @matching_nodes =
      grep { $_->{name} =~ /^(?:.*\.)?$key$/i } @{ $self->{__child_nodes} };

    # Choose the shortest matching field name
    my $shortestName = reduce { length($a) < length($b) ? $a : $b }
    map { $_->{name} } @matching_nodes;

    # If there are more than one matching field, choose the
    # field or protocol with the shortest name.
    my @nodes = grep { $_->{name} eq $shortestName } (@matching_nodes);

    return @nodes;
}

1;

__END__

=head1 NAME

Net::Tshark::Field - Represents a field in a packet returned by Net::Tshark.

=head1 SYNOPSIS

  use Net::Tshark;

  # Start the capture process, looking for HTTP packets
  my $tshark = Net::Tshark->new;
  $tshark->start(interface => 2, display_filter => 'http');

  # Do some stuff that would trigger HTTP packets for 30 s
  ...

  # Get any packets captured
  my @packets = $tshark->get_packets;
  
  # Extract packet information by accessing each packet like a nested hash
  foreach my $packet (@packets) {
    if ($packet->{http}->{request})
    {
      my $host = $packet->{http}->{host};
      my $method = $packet->{http}->{'http.request.method'};
      print "\t - HTTP $method request to $host\n";
    }
    else
    {
      my $code = $packet->{http}->{'http.response.code'};
      print "\t - HTTP response: $code\n";
    }
  }

=head1 DESCRIPTION

Represents a field within a packet returned by Net::Tshark->get_packet.

=head2 METHODS

=over 4

=item $packet->fields

Returns an array of the child fields of this field.

=item $packet->show

=item $packet->showname

=item $packet->name

=item $packet->size

=item $packet->value

=item $packet->hash

Returns a hash containing the contents of this field.

=back

=head1 SEE ALSO

Net::Tshark - Interface for the tshark network capture utility

The PDML Specification - http://www.nbee.org/doku.php?id=netpdl:pdml_specification

=head1 AUTHOR

Zachary Blair, E<lt>zblair@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Zachary Blair

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

