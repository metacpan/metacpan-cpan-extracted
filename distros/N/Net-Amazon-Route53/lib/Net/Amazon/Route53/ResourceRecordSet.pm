use strict;
use warnings;

package Net::Amazon::Route53::ResourceRecordSet;
$Net::Amazon::Route53::ResourceRecordSet::VERSION = '0.173450';
use Moo;
use Types::Standard qw(InstanceOf Str Int ArrayRef);
use XML::Bare;
use HTML::Entities;

=head2 SYNOPSIS

    my $resource = Net::Amazon::Route53::ResourceRecordSet->new(...);
    # use methods on $resource

=cut

=head2 ATTRIBUTES

=cut

=head3 route53

A L<Net::Amazon::Route53> object, needed and used to perform requests
to Amazon's Route 53 service

=head3 hostedzone

The L<Net::Amazon::Route53::HostedZone> object this hosted zone refers to

=cut

has 'route53'    => ( is => 'rw', isa => InstanceOf['Net::Amazon::Route53'],             required => 1, weak_ref => 1 );
has 'hostedzone' => ( is => 'rw', isa => InstanceOf['Net::Amazon::Route53::HostedZone'], required => 1, weak_ref => 1 );

=head3 name

The name for this resource record

=head3 ttl

The TTL associated with this resource record

=head3 type

The type of this resource record (C<A>, C<AAAA>, C<NS>, etc)

=head3 values

The values associated with this resource record.

=cut

has 'name'   => ( is => 'rw', isa => Str,      required => 1 );
has 'ttl'    => ( is => 'rw', isa => Int,      required => 1 );
has 'type'   => ( is => 'rw', isa => Str,      required => 1 );
has 'values' => ( is => 'rw', isa => ArrayRef, required => 1, default => sub { [] } );

=head2 METHODS

=cut

=head3 create

    my $record = Net::Amazon::Route53::ResourceRecordSet->new( ... );
    $record->create;

Creates a new record. Needs all the attributes (name, ttl, type and values).

Takes an optional boolean parameter, C<wait>, to indicate whether the request should
return straightaway (default, or when C<wait> is C<0>) or it should wait until the
request is C<INSYNC> according to the Change's status.

Returns a L<Net::Amazon::Route53::Change> object representing the change requested.

=cut

sub create
{
    my $self = shift;
    my $wait = shift;
    $wait = 0 if !defined $wait;
    $self->name =~ /\.$/ or die "Zone name needs to end in a dot, to be created\n";
    my $request_xml_str = <<'ENDXML';
<?xml version="1.0" encoding="UTF-8"?>
<ChangeResourceRecordSetsRequest xmlns="https://route53.amazonaws.com/doc/2010-10-01/">
   <ChangeBatch>
      <Comment>This change batch creates the %s record for %s</Comment>
      <Changes>
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
        map { $_ }
        $self->type, $self->name, $self->name, $self->type, $self->ttl,
        join( "\n", map { "<ResourceRecord><Value>$_</Value></ResourceRecord>" } @{ $self->values } ) );
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


=head3 delete

    $rrs->delete();

Asks Route 53 to delete the associated record. This should be used only when
you want to delete the resource, not when changing a resource. In that case,
use the C<change> method instead, which takes care of creating a unique change
in which the record is first deleted with the current details and then created
with the new details.

Takes an optional boolean parameter, C<wait>, to indicate whether the request should
return straightaway (default, or when C<wait> is C<0>) or it should wait until the
request is C<INSYNC> according to the Change's status.

Returns a L<Net::Amazon::Route53::Change> object representing the change requested.

=cut

sub delete
{
    my $self = shift;
    my $wait = shift;
    $wait = 0 if !defined $wait;
    my $request_xml_str = <<'ENDXML';
<?xml version="1.0" encoding="UTF-8"?>
<ChangeResourceRecordSetsRequest xmlns="https://route53.amazonaws.com/doc/2010-10-01/">
   <ChangeBatch>
      <Comment>This change batch deletes the %s record for %s</Comment>
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
        </Changes>
   </ChangeBatch>
</ChangeResourceRecordSetsRequest>
ENDXML
    my $request_xml = sprintf( $request_xml_str,
        (map { $_ } ( $self->type, $self->name, $self->name, $self->type, $self->ttl )),
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
