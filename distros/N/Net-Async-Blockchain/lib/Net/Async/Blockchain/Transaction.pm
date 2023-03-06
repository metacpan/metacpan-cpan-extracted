package Net::Async::Blockchain::Transaction;

use strict;
use warnings;

our $VERSION = '0.002';

=head1 NAME

Net::Async::Blockchain::Transaction - Transaction abstraction.

=head1 SYNOPSIS

Objects of this type would not normally be constructed directly.

=head1 DESCRIPTION

Transaction abstraction

=over 4

=back

=cut

no indirect;

sub message_type : method { shift->{message_type} }
sub currency : method     { shift->{currency} }
sub hash : method         { shift->{hash} }
sub block : method        { shift->{block} }
sub from : method         { shift->{from} }
sub to : method           { shift->{to} }
sub contract : method     { shift->{contract} }
sub amount : method       { shift->{amount} }
sub fee : method          { shift->{fee} }
sub fee_currency : method { shift->{fee_currency} }
sub type : method         { shift->{type} }
sub data : method         { shift->{data} }
sub property_id : method  { shift->{property_id} }
sub timestamp : method    { shift->{timestamp} }

=head2 new

Create a new L<Net::Async::Blockchain::Transaction> instance

=over 4

=item * C<message_type> Message Type (Default: transaction)
=item * C<currency> Currency symbol
=item * C<hash> Transaction hash
=item * C<block> Block where the transaction is included
=item * C<from> Transaction sender
=item * C<to> Transaction receiver
=item * C<contract> Contract address (when it's a contract transaction)
=item * C<amount> The transaction value
=item * C<fee> The transaction value
=item * C<fee_currency> The currency of the fee paid for this transaction
=item * C<type> String transaction type it can be (receive, sent, internal)
=item * C<data> contract instructions
=item * C<property_id> omnicore property id
=item * C<timestamp> block timestamp

=back

L<Net::Async::Blockchain::Transaction>

=cut

sub new {
    my ($class, %params) = @_;
    my $self = bless {}, $class;

    $self->{message_type} = 'transaction';

    foreach (qw(message_type currency hash block from to contract amount fee fee_currency type data property_id timestamp)) {
        $self->{$_} = delete $params{$_} if exists $params{$_};
    }

    die "Invalid transaction parameters" if keys %params;
    return $self;
}

=head2 clone

Clone the self object and the attribute values

=over 4

=back

new L<Net::Async::Blockchain::Transaction> based on self

=cut

sub clone {
    my ($self) = @_;
    return Net::Async::Blockchain::Transaction->new(%$self);
}

1;
