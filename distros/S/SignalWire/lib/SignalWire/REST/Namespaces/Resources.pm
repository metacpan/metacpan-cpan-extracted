package SignalWire::REST::Namespaces::Resources;
use strict;
use warnings;
use Moo;

# --- Addresses (no update) ---
package SignalWire::REST::Namespaces::Addresses;
use Moo;
extends 'SignalWire::REST::Namespaces::Base';

sub list {
    my ($self, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_base_path, params => $p);
}

sub create {
    my ($self, %kwargs) = @_;
    return $self->_http->post($self->_base_path, body => \%kwargs);
}

sub get {
    my ($self, $address_id) = @_;
    return $self->_http->get($self->_path($address_id));
}

sub delete {
    my ($self, $address_id) = @_;
    return $self->_http->delete_request($self->_path($address_id));
}

# --- Queues ---
package SignalWire::REST::Namespaces::Queues;
use Moo;
extends 'SignalWire::REST::Namespaces::CrudResource';
has '+_update_method' => ( default => sub { 'PUT' } );

sub list_members {
    my ($self, $queue_id, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_path($queue_id, 'members'), params => $p);
}

sub get_next_member {
    my ($self, $queue_id) = @_;
    return $self->_http->get($self->_path($queue_id, 'members', 'next'));
}

sub get_member {
    my ($self, $queue_id, $member_id) = @_;
    return $self->_http->get($self->_path($queue_id, 'members', $member_id));
}

# --- Recordings (read-only + delete) ---
package SignalWire::REST::Namespaces::Recordings;
use Moo;
extends 'SignalWire::REST::Namespaces::Base';

sub list {
    my ($self, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_base_path, params => $p);
}

sub get {
    my ($self, $recording_id) = @_;
    return $self->_http->get($self->_path($recording_id));
}

sub delete_recording {
    my ($self, $recording_id) = @_;
    return $self->_http->delete_request($self->_path($recording_id));
}

# Python parity alias.
sub delete {
    my ($self, $recording_id) = @_;
    return $self->_http->delete_request($self->_path($recording_id));
}

# --- NumberGroups ---
package SignalWire::REST::Namespaces::NumberGroups;
use Moo;
extends 'SignalWire::REST::Namespaces::CrudResource';
has '+_update_method' => ( default => sub { 'PUT' } );

sub list_memberships {
    my ($self, $group_id, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_path($group_id, 'number_group_memberships'), params => $p);
}

sub add_membership {
    my ($self, $group_id, %kwargs) = @_;
    return $self->_http->post($self->_path($group_id, 'number_group_memberships'), body => \%kwargs);
}

sub get_membership {
    my ($self, $membership_id) = @_;
    return $self->_http->get("/api/relay/rest/number_group_memberships/$membership_id");
}

sub delete_membership {
    my ($self, $membership_id) = @_;
    return $self->_http->delete_request("/api/relay/rest/number_group_memberships/$membership_id");
}

# --- VerifiedCallers ---
package SignalWire::REST::Namespaces::VerifiedCallers;
use Moo;
extends 'SignalWire::REST::Namespaces::CrudResource';
has '+_update_method' => ( default => sub { 'PUT' } );

sub redial_verification {
    my ($self, $caller_id) = @_;
    return $self->_http->post($self->_path($caller_id, 'verification'));
}

sub submit_verification {
    my ($self, $caller_id, %kwargs) = @_;
    return $self->_http->put($self->_path($caller_id, 'verification'), body => \%kwargs);
}

# --- SipProfile (singleton) ---
package SignalWire::REST::Namespaces::SipProfile;
use Moo;
extends 'SignalWire::REST::Namespaces::Base';

sub get {
    my ($self) = @_;
    return $self->_http->get($self->_base_path);
}

sub update {
    my ($self, %kwargs) = @_;
    return $self->_http->put($self->_base_path, body => \%kwargs);
}

# --- Lookup ---
package SignalWire::REST::Namespaces::Lookup;
use Moo;
extends 'SignalWire::REST::Namespaces::Base';

sub phone_number {
    my ($self, $e164, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_path('phone_number', $e164), params => $p);
}

# --- ShortCodes (read + update) ---
package SignalWire::REST::Namespaces::ShortCodes;
use Moo;
extends 'SignalWire::REST::Namespaces::Base';

sub list {
    my ($self, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_base_path, params => $p);
}

sub get {
    my ($self, $short_code_id) = @_;
    return $self->_http->get($self->_path($short_code_id));
}

sub update {
    my ($self, $short_code_id, %kwargs) = @_;
    return $self->_http->put($self->_path($short_code_id), body => \%kwargs);
}

# --- ImportedNumbers (create only) ---
package SignalWire::REST::Namespaces::ImportedNumbers;
use Moo;
extends 'SignalWire::REST::Namespaces::Base';

sub create {
    my ($self, %kwargs) = @_;
    return $self->_http->post($self->_base_path, body => \%kwargs);
}

# --- MFA ---
package SignalWire::REST::Namespaces::MFA;
use Moo;
extends 'SignalWire::REST::Namespaces::Base';

sub sms {
    my ($self, %kwargs) = @_;
    return $self->_http->post($self->_path('sms'), body => \%kwargs);
}

sub call {
    my ($self, %kwargs) = @_;
    return $self->_http->post($self->_path('call'), body => \%kwargs);
}

sub verify {
    my ($self, $request_id, %kwargs) = @_;
    return $self->_http->post($self->_path($request_id, 'verify'), body => \%kwargs);
}

1;
