package Skype::Any::Object::Call;
use strict;
use warnings;
use parent qw/Skype::Any::Object/;

sub property { shift->SUPER::property('CALL', @_) }
sub alter    { shift->SUPER::alter('CALL', @_) }

__PACKAGE__->_mk_boolean_property(qw/vaa_input_status/);

1;
__END__

=head1 NAME

Skype::Any::Object::Call - Call object for Skype::Any

=head1 SYNOPSIS

  use Skype::Any;

  my $skype = Skype::Any->new;
  my $call = $skype->call($id);

=head1 METHODS

=over 4

=item C<< $call->property($property[, $value]) >>

=over 4

=item timestamp

=item partner_handle

=item partner_dispname

=item target_identity

=item conf_id

=item type

=item status

=item video_status

=item video_send_status

=item video_receive_status

=item failurereason

=item subject

=item pstn_number

=item duration

=item pstn_status

=item conf_participants_count

=item conf_participant

=item vm_duration

=item vm_allowed_duration

=item rate

=item rate_currency

=item rate_precision

=item input

=item output

=item capture_mic

=item vaa_input_status

=item forwarded_by

=item transfer_active

=item transfer_status

=item transferred_by

=item transferred_to

=back

=item C<< $call->alter($action[, $value]) >>

=back

=cut
