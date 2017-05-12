package Skype::Any::Object::VoiceMail;
use strict;
use warnings;
use parent qw/Skype::Any::Object/;

sub property { shift->SUPER::property('VOICEMAIL', @_) }
sub alter    { shift->SUPER::alter('VOICEMAIL', @_) }

1;
__END__

=head1 NAME

Skype::Any::Object::VoiceMail - VoiceMail object for Skype::Any

=head1 SYNOPSIS

  use Skype::Any;

  my $skype = Skype::Any->new;
  my $voicemail = $skype->voicemail($id);

=head1 METHODS

=over 4

=item C<< $voicemail->property($property[, $value]) >>

=over 4

=item type

=item partner_handle

=item partner_dispname

=item status

=item failurereason

=item subject

=item timestamp

=item duration

=item allowed_duration

=item input

=item output

=item capture_mic

=back

=item C<< $voicemail->alter($action[, $value]) >>

=back

=cut
