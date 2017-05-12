package Skype::Any::Object::Message;
use strict;
use warnings;
use parent qw/Skype::Any::Object/;

sub property { shift->SUPER::property('MESSAGE', @_) }

1;
__END__

=head1 NAME

Skype::Any::Object::Message - Message object for Skype::Any

=head1 SYNOPSIS

  use Skype::Any;

  my $skype = Skype::Any->new;
  my $message = $skype->message($id);

=head1 DESCRIPTION

Deprecated in Skype protocol 3. Use C<Skype::Any::Object::ChatMessage>.

=cut
