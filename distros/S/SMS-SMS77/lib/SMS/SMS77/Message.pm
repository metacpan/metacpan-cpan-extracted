package SMS::SMS77::Message;

use strict;
use warnings;

=head1 NAME
  
SMS::SMS77::Message - a message object for SMS::SMS77
    
=head1 VERSION
      
Version 0.01

=cut

sub new {
    my $invocant = shift();
    my $class    = ref($invocant) || $invocant;
    my $self     = {
				'type' => undef,
				'from' => undef,
				'to' => [],
				'text' => undef,
				'delay' => undef,
				'status' => undef,
        @_
    };

    bless( $self, $class );
    return ($self);
}

sub add_to {
	my $self = shift();

	push(@{$self->{'to'}}, @_);
}

=head1 see also

SMS::SMS77

=head1 AUTHOR

Markus Benning, C<< <me at w3r3wolf.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Markus Benning, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of SMS::SMS77::Message

# vim:ts=2:syntax=perl:
# vim600:foldmethod=marker:

