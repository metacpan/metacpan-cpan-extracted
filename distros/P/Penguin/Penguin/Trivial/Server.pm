package Penguin::Trivial::Server;

$VERSION = 3.00;

use Penguin;
use Penguin::Rights;
use Penguin::Frame::Code;
use Penguin::Frame::Data;
use Penguin::Wrapper::PGP;
use Penguin::Wrapper::Transparent;
use Penguin::Compartment;
use Penguin::Channel::TCP::Server;

sub new {
    my ($class, %args) = @_;
    my $self = {};
    bless $self, $class;
    $self->{'Port'} = $args{'Port'};
    $self->{'Password'} = $args{'Password'};
    $self->{'Share'} = $args{'Share'};
    $self->{'_rightsdb'} = new Penguin::Rights;
    $self->{'_rightsdb'}->get();
    $self;
}

sub serve {
    my ($self, %args) = @_;
    my $mychannel = new Penguin::Channel::TCP::Server Bind => $self->{'Port'},
                                                      Listen => 5;
    while(1) {
        $mychannel->open(); # blocks waiting for a client
         # ($remotehost, $remoteport) = $mychannel->getinfo();
        $frame = getframe $mychannel; # blocks waiting for the frame

        if ($frame eq undef) { # silly client sent wrong frame
            $mychannel->close();
            next;
        }

        ($title, $signer, $wrapmethod, $code) = 
                  $frame->disassemble(Password => $self->{'Password'});

        $userrights = $self->{'_rightsdb'}->getrights(User => $signer);

        $compartment = new Penguin::Compartment;
        $compartment->initialize( Operations => $userrights );
        if (ref($self->{'Share'}) eq "ARRAY") {
            $compartment->{'compartment'}->share_from("main",
                                                      $self->{'Share'} );
        }

        $result = $compartment->execute( Code => $code );

        if ($@) { # illegal code tried to execute
            $result = $@;
        }

        $resultframe = new Penguin::Frame::Data;
        assemble $resultframe Text => $result;
        putframe $mychannel Frame => $resultframe;
        $mychannel->close();
    } # while(1) does not ever terminate
}
