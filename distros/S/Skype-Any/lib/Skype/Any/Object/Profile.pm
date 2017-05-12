package Skype::Any::Object::Profile;
use strict;
use warnings;
use parent qw/Skype::Any::Object/;

sub property { shift->SUPER::property('PROFILE', @_) }

1;
__END__

=head1 NAME

Skype::Any::Object::Profile - Profile object for Skype::Any

=head1 SYNOPSIS

  use Skype::Any;

  my $skype = Skype::Any->new;
  my $profile = $skype->profile();

=head1 METHODS

=over 4

=item C<< $profile->property($property[, $value]) >>

=over 4

=item pstn_balance

=item pstn_balance_currency

=item fullname

=item birthday

=item sex

=item languages

=item country

=item ipcountry

=item province

=item city

=item phone_home

=item phone_office

=item phone_mobile

=item homepage

=item about

=item mood_text

=item rich_mood_text

=item timezone

=item call_apply_cf

=item call_noanswer_timeout

=item call_forward_rules

=item call_send_to_vm

=item sms_validated_numbers

=back

=back

=cut
