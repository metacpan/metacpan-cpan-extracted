use strict;
use warnings;

package Net::Amazon::Route53::ResourceRecordSet::Change;
$Net::Amazon::Route53::ResourceRecordSet::Change::VERSION = '0.173450';
use Moo;
use Types::Standard 'ArrayRef';
extends "Net::Amazon::Route53::ResourceRecordSet";
use HTML::Entities;

=head2 SYNOPSIS

    my $record_change = Net::Amazon::Route53::ResourceRecordSet::Change->new(
        name            => "example.com",
        ttl             => 600,
        type            => "A",
        values          => [ "new_value1","new_value2", ],
        original_values => [ "old_value1", "old_value2", ],
    );

=cut

=head2 ATTRIBUTES

=cut

=head3 original_values

The values associated with this resource record.

=cut

has 'original_values' => ( is => 'rw', isa => ArrayRef, required => 1, default => sub { [] } );

=head2 METHODS

=cut

=head3 change

This method changes the value of a record from original_value X to value Y.

    my $record = Net::Amazon::Route53::ResourceRecordSet::Change->new(
        name            => "example.com",
        ttl             => 600,
        type            => "A",
        values          => [ "new_value1","new_value2", ],
        original_values => [ "old_value1", "old_value2", ],
    );
    my $change = $record->change(1); # Set the 1 if you want to wait.

=cut

sub change {
    my $self = shift;
    my $wait = shift;
    $wait = 0 if !defined $wait;

    my $request_xml_str = <<'ENDXML';
<?xml version="1.0" encoding="UTF-8"?>
<ChangeResourceRecordSetsRequest xmlns="https://route53.amazonaws.com/doc/2010-10-01/">
   <ChangeBatch>
     <Comment>This change batch updates the %s record from original_values to values</Comment>
     <Changes>
       <Change>
           <Action>DELETE</Action>
           <ResourceRecordSet>
               <Name>%s</Name>
               <Type>%s</Type>
               <TTL>%s</TTL>
               <ResourceRecords>
                  %s
               </ResourceRecords>
           </ResourceRecordSet>
       </Change>
       <Change>
           <Action>CREATE</Action>
           <ResourceRecordSet>
               <Name>%s</Name>
               <Type>%s</Type>
               <TTL>%s</TTL>
               <ResourceRecords>
                  %s
               </ResourceRecords>
           </ResourceRecordSet>
       </Change>
     </Changes>
   </ChangeBatch>
</ChangeResourceRecordSetsRequest>
ENDXML
    my $request_xml = sprintf( $request_xml_str,
        (map { $_ } ( $self->type, $self->name, $self->type, $self->ttl, ) ),
        join( "\n", map { "<ResourceRecord><Value>" . $_ . "</Value></ResourceRecord>" } @{ $self->original_values } ),
        (map { $_ } ( $self->name, $self->type, $self->ttl, ) ),
        join( "\n", map { "<ResourceRecord><Value>" . $_ . "</Value></ResourceRecord>" } @{ $self->values } ) );

    my $resp = $self->route53->request(
        'post',
        'https://route53.amazonaws.com/2010-10-01/' . $self->hostedzone->id . '/rrset',
        Content => $request_xml
    );
    my $change = Net::Amazon::Route53::Change->new(
        route53 => $self->route53,
        ( map { lc($_) => decode_entities($resp->{ChangeInfo}{$_}) } qw/Id Status SubmittedAt/ ),
    );
    $change->refresh();
    return $change if !$wait;
    while ( lc( $change->status ) ne 'insync' ) {
        sleep 2;
        $change->refresh();
    }
    return $change;
}

no Moo;

=head1 AUTHOR

Marco FONTANI <mfontani@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Marco FONTANI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
