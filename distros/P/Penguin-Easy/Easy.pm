=head1 NAME

  Penguin::Easy -- provides easy access to Penguin module.


=head1 SYNOPSIS

  use Penguin::Easy;
  my $ep = new Penguin::Easy Title => 'Easy Program',
			     Name => 'James Duncan',
			     Sig => $my_pgp_sig,
			     Code => $my_perl_code;
  $results = $ep->run;
  print "$results\n";


=head1 DESCRIPTION

C<Penguin::Easy> is an OO module, that provides quick-and-dirty access to the
penguin module for those not wanting to learn the nittygrittys about it.  The
C<Easy> module provides transparent access to the C<Penguin> module, even to
the extent of deciding whether the Penguin code should be transparently wrapped,
or PGP wrapped (if you include a sig in the call to the C<new> method,  it
will use PGP).  


=head1 NOTES

While writing this little module,  I've decided that C<Wrapper> is perhaps one
of the funniest words I have ever seen.  It has completly lost all meaning.


=cut


package Penguin::Easy;

$VERSION = 1.1;

use Penguin;
use Penguin::Rights;
use Penguin::Frame::Code;
use Penguin::Frame::Data;
use Penguin::Compartment;
use Penguin::Channel::TCP::Client;


sub new {
  my ($class, %args) = @_;
  my $self = {};
  $self->{'Port'} = $args{'Port'} or 8118;
  $self->{'Title'} = $args{'Title'} or 'Untitled Program';
  $self->{'Name'} = $args{'Name'} or 'Just another Penguin';
  $self->{'PGP'} = $args{'Sig'};
  $self->{'Text'} = $args{'Code'};
  bless $self, $class;
}

sub run {
  my ($self, %args) = @_;
  my $channel = new Penguin::Channel::TCP::Client Peer => $args{'Host'},
					          Port => $self->{'Port'};
  $channel->open();
  my $frame = '';
  my $wrapper = '';
  if($self->{'PGP'}) { 
      use Penguin::Wrapper::PGP;
      $wrapper = 'Penguin::Wrapper::PGP'; 
  }
  else { 
      use Penguin::Wrapper::Transparent;
      $wrapper = 'Penguin::Wrapper::Transparent'; 
  }
  $frame = new Penguin::Frame::Code Wrapper => $wrapper;
  assemble $frame Password => $self->{'PGP'},
		  Text => $self->{'Text'},
		  Title => $self->{'Title'},
		  Name => $self->{'Name'};
  putframe $channel Frame => $frame;
  my $outframe = getframe $channel;
  $results = $outframe->disassemble(Password => $pgpsig);
  return $results;
}


1;









