package POE::Declare::Meta::Timeout;

=pod

=head1 NAME

POE::Declare::Meta::Timeout - A named timeout with generated support methods

=head1 SYNOPSIS

  # Send a request
  sub request : Event {
      $_[SELF]->request_timeout_start;
      $_[SELF]->{handle}->put('something');
  }
  
  # Received a response
  sub response : Event {
      if ( $_[ARG0] eq 'keepalive' ) {
          $_[SELF]->request_timeout_restart;
          return;
      }
  
      $_[SELF]->request_timeout_stop;
      $_[SELF]->{parent}->post('child_response', $_[ARG0]);
  }
  
  # Did not get a response
  sub request_timeout : Timeout(30) {
      # Take some action
      $_[SELF]->cleanup;
      $_[SELF]->{parent}->post('child_response', 'timeout');
  }

=head1 DESCRIPTION

B<POE::Declare::Meta::Timeout> is a sub-class of C<Event> with access to
a number of additional methods relating to timers and alarms.

=cut

use 5.008007;
use strict;
use warnings;
use POE::Declare::Meta::Event ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.59';
	@ISA     = 'POE::Declare::Meta::Event';
}

use Class::XSAccessor {
	getters => {
		delay    => 'delay',
		variance => 'variance',
	},
};





#####################################################################
# Main Methods

sub as_perl {
	my $name     = $_[0]->{name};
	my $delay    = $_[0]->{delay};
	my $variance = $_[0]->{variance} || 0;
	return <<"END_PERL";
sub ${name}_start {
	my \$delay    = \@_ > 1 ? defined \$_[1] ? \$_[1] : $delay : $delay;
	my \$variance = \@_ > 1 ? \$_[2] || $variance : $variance;
	\$poe_kernel->delay(
		'$name' => \$delay + rand(\$variance * 2) - \$variance
	) or return;
	die("Failed to create timeout for event '$name'");
}

*${name}_restart = *${name}_start;

sub ${name}_stop {
	my \$self  = (\@_ == 1) ? \$_[0] : \$_[HEAP];
	\$poe_kernel->delay( '$name' ) or return;
	die("Failed to create timeout for event '$name'");
}
END_PERL
}

1;

=pod

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Declare>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<POE>, L<POE::Declare>

=head1 COPYRIGHT

Copyright 2006 - 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
