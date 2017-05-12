use strict;
use warnings;

package Net::Amazon::Route53;
$Net::Amazon::Route53::VERSION = '0.160530';
use LWP::UserAgent;
use HTTP::Request;
use Digest::HMAC_SHA1;
use MIME::Base64;
use XML::Bare;
use HTML::Entities;
use Any::Moose;

use Net::Amazon::Route53::HostedZone;
use Net::Amazon::Route53::ResourceRecordSet::Change;

# ABSTRACT: Interface to Amazon's Route 53

=head2 SYNOPSIS

    use strict;
    use warnings;
    use Net::Amazon::Route53;
    my $route53 = Net::Amazon::Route53->new( id => '...', key => '...' );
    my @zones = $route53->get_hosted_zones;
    for my $zone ( @zones ) {
        # use the Net::Amazon::Route53::HostedZone object
    }

=cut

=head2 ATTRIBUTES

=cut

=head3 id

The Amazon id, needed to contact Amazon's Route 53.

=head3 key

The Amazon key, needed to contact Amazon's Route 53.

=cut

has 'id'  => (is => 'rw', isa => 'Str', required => 1,);
has 'key' => (is => 'rw', isa => 'Str', required => 1,);

=head3 ua

Internal user agent object used to perform requests to
Amazon's Route 53

=cut

has 'ua' => (
    is       => 'rw',
    isa      => 'LWP::UserAgent',
    required => 1,
    default  => sub {
        my $self = shift;
        LWP::UserAgent->new(
            keep_alive            => 10,
            requests_redirectable => [qw(GET HEAD DELETE PUT)],
        );
    },
);

=head2 METHODS

=cut

=head3 C<request>

    my $hr_xml_response = $self->request( $method, $url );

Requests something from Amazon Route 53, signing the request.  Uses
L<LWP::UserAgent> internally, and returns the hashref obtained from the
request. Dies on error, showing the request's error given by the API.

=cut

sub request {
    my $self   = shift;
    my $method = shift;
    my $uri    = shift;

    return unless $method;
    return
        unless ($method eq 'get' or $method eq 'post' or $method eq 'delete');
    return unless $uri;

    # Get amazon server's date
    my $date = do {
        my $rc = $self->ua->get('https://route53.amazonaws.com/date');
        $rc->header('date');
    };

    # Create signed request
    my $hmac = Digest::HMAC_SHA1->new($self->key);
    $hmac->add($date);
    my $signature = encode_base64($hmac->digest, '');

    my %options = (
        'Date'                 => $date,
        'X-Amzn-Authorization' => sprintf(
            "AWS3-HTTPS AWSAccessKeyId=%s,Algorithm=HmacSHA1,Signature=%s",
            $self->id, $signature
        ),
        @_
    );
    my $content = delete $options{Content};
    my $request = HTTP::Request->new(
        uc $method, $uri,
        [map {$_ => $options{$_}} keys %options],
        $content ? $content : undef,
    );
    my $rc = $self->ua->request($request);
    die "Could not perform request $method on $uri: "
        . $rc->status_line . "\n"
        . $rc->decoded_content . "\n"
        . "Original request: "
        . (defined $content ? $content : '') . "\n"
        unless $rc->is_success;

    #use YAML;warn "\n\nmethod $method to $uri @_: " . Dump($rc);
    my $resp = XML::Bare::xmlin($rc->decoded_content);
    die "Error: $resp->{Error}{Code}\n" if (exists $resp->{Error});
    return $resp;
}

=head3 C<get_hosted_zones>

    my $route53 = Net::Amazon::Route53->new( key => '...', id => '...' );
    my @zones = $route53->get_hosted_zones();
    my $zone = $route53->get_hosted_zones( 'example.com.' );

Gets one or more L<Net::Amazon::Route53::HostedZone> objects,
representing the zones associated with the account.

Takes an optional parameter indicating the name of the wanted hosted zone.

=cut

sub get_hosted_zones {
    my $self         = shift;
    my $which        = shift;
    my $start_marker = '';
    my @zones;
    while (1) {
        my $resp = $self->request('get',
            'https://route53.amazonaws.com/2010-10-01/hostedzone?maxitems=100'
                . $start_marker);
        if ($resp->{HostedZones}) {
            push @zones,
                (
                ref $resp->{HostedZones}{HostedZone} eq 'ARRAY'
                ? @{ $resp->{HostedZones}{HostedZone} }
                : $resp->{HostedZones}{HostedZone});
        }
        last if $resp->{IsTruncated} eq 'false';
        $start_marker = '?marker=' . $resp->{NextMarker};
    }
    my @o_zones;
    for my $zone (@zones) {
        push @o_zones,
            Net::Amazon::Route53::HostedZone->new(
            route53 => $self,
            (map {lc($_) => $zone->{$_}} qw/Id Name CallerReference/),
            comment =>
                (exists $zone->{Config} and ref $zone->{Config} eq 'HASH')
            ? $zone->{Config}{Comment}
            : '',
            );
    }
    @o_zones = grep {$_->name eq $which} @o_zones if $which;
    return @o_zones;
}

=head3 batch_create

    my $route53 = Net::Amazon::Route53->new( key => '...', id => '...' );
    my @records = record_generating_subroutine(); # returning an array of Net::Amazon::Route53::ResourceRecordSets
    my $change = $route53->batch_create(\@records); # Or ->batch_create(\@records,1) if you want to wait

Turns an arrayref of L<Net::Amazon::Route53::ResourceRecordSet> objects into
one big create request. All records must belong to the same hosted zone.

Takes an optional boolean parameter, C<wait>, to indicate whether the request
should return straightaway (default, or when C<wait> is C<0>) or it should wait
until the request is C<INSYNC> according to the Change's status.

Returns a L<Net::Amazon::Route53::Change> object representing the change
requested.

=cut

sub batch_create {
    my $self  = shift;
    my $batch = shift;
    my $wait  = shift;
    $wait = 0 if !defined $wait;

    die "Your batch is not an arrayref" unless ref($batch) eq 'ARRAY';
    my @invalid =
        grep {!($_->isa("Net::Amazon::Route53::ResourceRecordSet"))} @$batch;
    die
        "Your batch is not an arrayref of Net::Amazon::Route53::ResourceRecordSets"
        if scalar(@invalid);

    my $hostedzone_id = $batch->[0]->hostedzone->id;
    my @wrong_zone = grep {$_->hostedzone->id ne $hostedzone_id} @$batch;
    die "Your batch contains records from different hosted zones"
        if scalar(@wrong_zone);

    $hostedzone_id =~ s/^\///g;

    my $batch_xml = $self->_batch_request_header;

    for my $rr (@$batch) {
        $rr->name =~ /\.$/
            or die "Zone name needs to end in a dot, to be created\n";
        my $change_xml = $self->_get_create_xml($rr);
        $batch_xml .= $change_xml;
    }

    $batch_xml .= $self->_batch_request_footer;

    my $resp = $self->request(
        'post',
        'https://route53.amazonaws.com/2010-10-01/' . $hostedzone_id . '/rrset',
        Content => $batch_xml
    );
    my $change = Net::Amazon::Route53::Change->new(
        route53 => $self,
        (
            map {lc($_) => decode_entities($resp->{ChangeInfo}{$_})}
                qw/Id Status SubmittedAt/
        ),
    );
    $change->refresh();
    return $change if !$wait;
    while (lc($change->status) ne 'insync') {
        sleep 2;
        $change->refresh();
    }
    return $change;
}

=head3 atomic_update

    my $route53 = Net::Amazon::Route53->new( key => '...', id => '...' );
    my $hosted_zone = $route_53->get_hosted_zones("example.com.");
    my $old_records = $hosted_zone->resource_record_sets;
    my $new_records = record_generating_subroutine();
    my $change = $route53->atomic_update($old_records,$new_records);
    # Or ->atomic_update($ref1,$ref2,1) if you want to wait

Be warned: B<this method can be destructive>. Give it the arrayref of records
currently in your zone and an arrayref of records representing the desired
state of your zone, and it will create, change, and delete the current records
in the zone to match the set you submitted.

B<Don't send the Amazon Route53 NS or SOA record in the set of original records>.

This method discovers which records needs to be deleted/created, e.g., changed,
which ones need simply to be created for the first time, and
B<deletes records not defined in the new set>.
It's an "all-in-one, all-at-once" update for all the records in your zone.
This, and the fact that it is destructive, is why it is called
C<atomic_update>.

Takes an optional boolean parameter, C<wait>, to indicate whether the request
should return straightaway (default, or when C<wait> is C<0>) or it should wait
until the request is C<INSYNC> according to the Change's status.

Returns a L<Net::Amazon::Route53::Change> object representing the change
requested.

=cut

sub atomic_update {
    my $self     = shift;
    my $original = shift;
    my $new      = shift;
    my $wait     = shift;
    $wait = 0 if !defined $wait;

    for my $rrset (($original, $new)) {
        die "A record set is not an arrayref" unless ref($rrset) eq 'ARRAY';
        my @invalid =
            grep {!($_->isa("Net::Amazon::Route53::ResourceRecordSet"))}
            @$rrset;
        die
            "A record set is not an arrayref of Net::Amazon::Route53::ResourceRecordSets"
            if scalar(@invalid);
    }

    my $hostedzone_id = $original->[0]->hostedzone->id;
    my @wrong_zone =
        grep {$_->hostedzone->id ne $hostedzone_id} (@$original, @$new);
    die "A record set contains records from different hosted zones"
        if scalar(@wrong_zone);

    $hostedzone_id =~ s/^\///g;

    my %original    = map {$_->name . '-' . $_->type => 1} @$original;
    my %new         = map {$_->name . '-' . $_->type => 1} @$new;
    my %new_records = map {$_->name . '-' . $_->type => $_} @$new;
    my @creates =
        grep {!(defined $original{ $_->name . '-' . $_->type })} @$new;
    my @deletions =
        grep {!(defined $new{ $_->name . '-' . $_->type })} @$original;
    my %deleted = map {$_->name . '-' . $_->type => 1} @deletions;
    my @changes =
        grep {defined $new{ $_->name . '-' . $_->type }}
        grep {!(defined $deleted{ $_->name . '-' . $_->type })} @$original;
    my @change_objects = map {
        Net::Amazon::Route53::ResourceRecordSet::Change->new(
            route53         => $_->route53,
            hostedzone      => $_->hostedzone,
            name            => $_->name,
            ttl             => $_->ttl,
            type            => $_->type,
            original_values => $_->values,
            values          => $new_records{ $_->name . '-' . $_->type }->values
            )
        } grep {
        join(',', @{ $_->values }) ne
            join(',', @{ $new_records{ $_->name . '-' . $_->type }->values })
        } @changes;

    my $batch_xml = $self->_batch_request_header;

    # Do not attempt to push an empty changeset
    return Net::Amazon::Route53::Change->new(route53 => $self, status => 'NOOP')
        if @change_objects + @deletions + @creates < 1;

    for my $rr (@change_objects) {
        $rr->name =~ /\.$/
            or die "Zone name needs to end in a dot, to be changed\n";
        my $change_xml = $self->_get_change_xml($rr);
        $batch_xml .= $change_xml;
    }

    for my $rr (@deletions) {
        $rr->name =~ /\.$/
            or die "Zone name needs to end in a dot, to be deleted\n";
        my $change_xml = $self->_get_delete_xml($rr);
        $batch_xml .= $change_xml;
    }

    for my $rr (@creates) {
        $rr->name =~ /\.$/
            or die "Zone name needs to end in a dot, to be created\n";
        my $change_xml = $self->_get_create_xml($rr);
        $batch_xml .= $change_xml;
    }

    $batch_xml .= $self->_batch_request_footer;

    my $resp = $self->request(
        'post',
        'https://route53.amazonaws.com/2010-10-01/' . $hostedzone_id . '/rrset',
        Content => $batch_xml
    );
    my $change = Net::Amazon::Route53::Change->new(
        route53 => $self,
        (
            map {lc($_) => decode_entities($resp->{ChangeInfo}{$_})}
                qw/Id Status SubmittedAt/
        ),
    );
    $change->refresh();
    return $change if !$wait;
    while (lc($change->status) ne 'insync') {
        sleep 2;
        $change->refresh();
    }
    return $change;
}

=head3 batch_change

    my $route53 = Net::Amazon::Route53->new( key => '...', id => '...' );
    my $hosted_zone = $route_53->get_hosted_zones("example.com.");
    my $recordset_changes = recordset_changes_generating_subroutine();
    my $change = $route53->batch_change($recordset_changes);
    # Or ->batch_change($recordset_changes,1) if you want to wait

This method takes an arrayref of
L<Net::Amazon::Route53::ResourceRecordSet::Change> objects and the optional
C<wait> argument, and makes one big request to change all the records at once.

=cut

sub batch_change {
    my $self  = shift;
    my $batch = shift;
    my $wait  = shift;
    $wait = 0 if !defined $wait;

    die "Your batch is not an arrayref" unless ref($batch) eq 'ARRAY';
    my @invalid =
        grep {!($_->isa("Net::Amazon::Route53::ResourceRecordSet::Change"))}
        @$batch;
    die
        "Your batch is not an arrayref of Net::Amazon::Route53::ResourceRecordSet::Changes"
        if scalar(@invalid);

    my $hostedzone_id = $batch->[0]->hostedzone->id;
    my @wrong_zone = grep {$_->hostedzone->id ne $hostedzone_id} @$batch;
    die "Your batch contains records from different hosted zones"
        if scalar(@wrong_zone);

    $hostedzone_id =~ s/^\///g;

    my $batch_xml = $self->_batch_request_header;

    for my $rr (@$batch) {
        $rr->name =~ /\.$/
            or die "Zone name needs to end in a dot, to be created\n";
        my $change_xml = $self->_get_change_xml($rr);
        $batch_xml .= $change_xml;
    }

    $batch_xml .= $self->_batch_request_footer;

    my $resp = $self->request(
        'post',
        'https://route53.amazonaws.com/2010-10-01/' . $hostedzone_id . '/rrset',
        Content => $batch_xml
    );
    my $change = Net::Amazon::Route53::Change->new(
        route53 => $self,
        (
            map {lc($_) => decode_entities($resp->{ChangeInfo}{$_})}
                qw/Id Status SubmittedAt/
        ),
    );
    $change->refresh();
    return $change if !$wait;
    while (lc($change->status) ne 'insync') {
        sleep 2;
        $change->refresh();
    }
    return $change;
}

=head3 _get_create_xml

Private method for xml templating. Takes an
L<Net::Amazon::Route53::ResourceRecordSet::Change> object and returns the xml
to create that single record.

=cut

sub _get_create_xml {
    my ($self, $record) = @_;
    my $create_xml_str = <<'ENDXML';
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
ENDXML

    my $create_xml = sprintf(
        $create_xml_str,
        map {$_} $record->name,
        $record->type,
        $record->ttl,
        join("\n",
            map {"<ResourceRecord><Value>" . $_ . "</Value></ResourceRecord>"}
                @{ $record->values }));

    return $create_xml;
}

=head3 _get_delete_xml

Private method for xml templating. Takes an
L<Net::Amazon::Route53::ResourceRecordSet> object and returns the xml to delete
that single record.

=cut

sub _get_delete_xml {
    my ($self, $record) = @_;
    my $delete_xml_str = <<'ENDXML';
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
ENDXML

    my $delete_xml = sprintf(
        $delete_xml_str,
        map {$_} $record->name,
        $record->type,
        $record->ttl,
        join("\n",
            map {"<ResourceRecord><Value>" . $_ . "</Value></ResourceRecord>"}
                @{ $record->values }));

    return $delete_xml;
}

=head3 _get_change_xml

Private method for xml templating. Takes an
L<Net::Amazon::Route53::ResourceRecordSet::Change> object and returns the xml
to change, i.e., delete and create, that single record.

=cut

sub _get_change_xml {
    my ($self, $record) = @_;
    my $change_xml_str = <<'ENDXML';
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
ENDXML

    my $change_xml = sprintf(
        $change_xml_str,
        (map {$_} ($record->name, $record->type, $record->ttl,)),
        join("\n",
            map {"<ResourceRecord><Value>" . $_ . "</Value></ResourceRecord>"}
                @{ $record->original_values }),
        (map {$_} ($record->name, $record->type, $record->ttl,)),
        join("\n",
            map {"<ResourceRecord><Value>" . $_ . "</Value></ResourceRecord>"}
                @{ $record->values }));
    return $change_xml;
}

=head3 _batch_request_header

Private method for xml templating. Returns a header string.

=cut

sub _batch_request_header {
    my $self   = shift;
    my $header = <<'ENDXML';
<?xml version="1.0" encoding="UTF-8"?>
<ChangeResourceRecordSetsRequest xmlns="https://route53.amazonaws.com/doc/2010-10-01/">
   <ChangeBatch>
      <Comment>Batch changeset</Comment>
      <Changes>
ENDXML
    return $header;
}

=head3 _batch_request_footer

Private method for xml templating. Returns a footer string.

=cut

sub _batch_request_footer {
    my $self   = shift;
    my $footer = <<'ENDXML';
        </Changes>
   </ChangeBatch>
</ChangeResourceRecordSetsRequest>
ENDXML
    return $footer;
}

=head1 SEE ALSO

L<Net::Amazon::Route53::HostedZone>
L<http://docs.amazonwebservices.com/Route53/latest/APIReference/>

=cut

=head1 AUTHOR

Marco FONTANI <mfontani@cpan.org>

=head1 CONTRIBUTORS

Daiji Hirata <hirata@uva.ne.jp>
Amiri Barksdale <amiri@arisdottle.net>
Chris Weyl <cweyl@alumni.drew.edu>
Jason <jasonjayr+oss@gmail.com>
Ulrich Kautz <ulrich.kautz@googlemail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Marco FONTANI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
