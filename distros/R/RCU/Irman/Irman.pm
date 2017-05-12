=head1 NAME

RCU::Irman - RCU interface to libirman.

=head1 SYNOPSIS

   use RCU::Irman;

=head1 DESCRIPTION

See L<RCU>.

=over 4

=cut

package RCU::Irman;

use Carp;
use Errno ();
use Fcntl;

use RCU;

use base qw(RCU::Interface);

$VERSION = 0.11;

=item new <path>

Create an interface to the RCU receiver at serial port <path> (default
from in irman.conf used if omitted).

=cut

sub new {
   my $class = shift;
   my $path = shift;
   my $self = $class->SUPER::new();
   local (*CW, *CR);

   $self->{fh} = local *IRMAN_FH;
   $self->{ifh} = local *IRMAN_IFH;

   pipe $self->{fh}, CW or die "unable to create communications pipe";
   pipe CR, $self->{ifh} or die "unable to create communications pipe";

   $self->{pid} = fork;

   if ($self->{pid} == 0) {
      use Config;
      close $self->{ifh}; close $self->{fh};
      open STDIN, "<&CR"; open STDOUT, ">&CW"; close STDERR;
      fcntl STDIN, F_SETFD, 0; fcntl STDOUT, F_SETFD, 0;
      exec "$Config{installbin}/rcu-irman-helper", "", $path || "";
   } elsif (!defined $self->{pid}) {
      die;
   }
   close CR; close CW;
   
   $self->get; # wait for I packet

   $self;
}

sub fd {
   fileno $_[0]->{fh};
}

sub _get {
   my $self = shift;
   my $fh = $self->{fh};
   local $/ = "\x00";
   $! = 0;
   my $code = <$fh>;
   if ("=" eq substr $code, 0, 1) {
      split /\x01/, substr $code, 1, -1;
   } elsif ($code =~ s/^E//) {
      die substr $code, 0, -1;
   } elsif ($code =~ /^I/) {
      # NOP
      ();
   } elsif ($! != Errno::EAGAIN) {
      delete $self->{fh}; # to make event stop
      croak "irman communication error ($!)";
   } else {
      ();
   }
}

sub get {
   fcntl $_[0]->{fh}, F_SETFL, 0;
   goto &_get;
}

sub poll {
   fcntl $_[0]->{fh}, F_SETFL, O_NONBLOCK;
   goto &_get;
}

1;

=back

=head1 AUTHOR

This perl extension was written by Marc Lehmann <schmorp@schmorp.de>.





