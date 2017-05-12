package Penguin::Trivial::Client;

use Penguin;
use Penguin::Rights;
use Penguin::Frame::Code;
use Penguin::Frame::Data;
use Penguin::Wrapper::PGP;
use Penguin::Compartment;
use Penguin::Channel::TCP::Client;

sub new {
    my ($class, %args) = @_;
    my $self = {};
    bless $self, $class;
    $self->{'Code'} = $args{'Code'};
    $self->{'Host'} = $args{'Host'};
    $self->{'Port'} = $args{'Port'};
    $self->{'Password'} = $args{'Password'};
    $self->{'Title'} = $args{'Title'};
    $self->{'Name'} = $args{'Name'};
    $self;
}

sub run {
    my ($self, %args) = @_;

    my $mychannel = new Penguin::Channel::TCP::Client Peer => $self->{'Host'},
                                                      Port => $self->{'Port'};
                                             
    $mychannel->open();

    my $frame = new Penguin::Frame::Code Wrapper => 'Penguin::Wrapper::PGP';

    assemble $frame Password => $self->{'Password'},
                    Text     => $self->{'Code'},
                    Title    => $self->{'Title'},
                    Name     => $self->{'Name'};

    putframe $mychannel Frame => $frame;

    my $returnframe = getframe $mychannel; # expecting a data frame return

    $mychannel->close();

    $results = $returnframe->disassemble(Password => $PGP_Password);
}
1;
