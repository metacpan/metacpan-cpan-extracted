package Net::OpenMicroBlogging::Message;
use warnings;
use strict;
use NEXT;

sub init_omb_message {
  my $class = shift;
  $class->add_extension_param_pattern(qr/^omb_/);
}

sub set_defaults {
  my $self = shift;
  $self->{omb_version} = 'http://openmicroblogging.org/protocol/0.1';
  $self->NEXT::set_defaults;
}

=head1 NAME

Net::OpenMicroBlogging::Message - An OpenMicroBlogging message

=head1 SEE ALSO

L<Net::OpenMicroBlogging>, L<http://openmicroblogging.org>

=head1 AUTHOR

Keith Grennan, C<< <kgrennan at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Keith Grennan, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;