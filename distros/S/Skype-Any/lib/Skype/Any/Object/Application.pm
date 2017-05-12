package Skype::Any::Object::Application;
use strict;
use warnings;
use parent qw/Skype::Any::Object/;

sub property { shift->SUPER::property('APPLICATION', @_) }
sub alter    { shift->SUPER::alter('APPLICATION', @_) }

1;
__END__

=head1 NAME

Skype::Any::Object::Application - Application object for Skype::Any

=head1 SYNOPSIS

  use Skype::Any;

  my $skype = Skype::Any->new;
  my $application = $skype->application($id);

=cut
