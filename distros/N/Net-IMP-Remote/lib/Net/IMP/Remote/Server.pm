use strict;
use warnings;

package Net::IMP::Remote::Server;
use Net::IMP;
use Net::IMP::Remote::Protocol;
use Scalar::Util 'weaken';
use Net::IMP::Debug;
use Carp;

sub new {
    my ($class,$conn,$factory,%args) = @_;
    my $self = bless { 
	conn => $conn,
	factory => $factory,
    }, $class;

    weaken( my $wself = $self );
    $conn->nextop({
	IMPRPC_EXCEPTION+0     => [ \&exception, $wself ],
	IMPRPC_GET_INTERFACE+0 => [ \&get_interface, $wself ],
	IMPRPC_SET_INTERFACE+0 => [ \&set_interface, $wself ],
	IMPRPC_NEW_ANALYZER+0  => [ \&new_analyzer, $wself ],
	IMPRPC_DEL_ANALYZER+0  => [ \&del_analyzer, $wself ],
	IMPRPC_DATA+0          => [ \&data, $wself ],
    }, -1);
    return $self;
}

sub get_interface {
    my ($self,@if) = @_;
    @if = $self->{factory}->get_interface(@if);
    $self->{conn}->rpc([ IMPRPC_INTERFACE, @if ]);
    return;
}

sub set_interface {
    my ($self,$if) = @_;
    my $newf = $self->{factory}->set_interface($if);
    if ( ! $newf ) {
	$self->{conn}->rpc([ 
	    IMPRPC_EXCEPTION,0,
	    "set_interface: unsupported interface" 
	]);
	return;
    } else {
	$self->{factory} = $newf;
    }
}

sub new_analyzer {
    my ($self,$id,$ctx) = @_;
    my $conn = $self->{conn};
    if ( $conn->get_analyzer($id) ) {
	$conn->rpc([IMPRPC_EXCEPTION,$id,"analyzer exists already"]);
	return;
    }

    my $obj = $self->{factory}->new_analyzer(%$ctx);
    if ( ! $obj ) {
	debug("analyzer $id not wanted - using dummy");
	$conn->add_analyzer('dummy',$id);
	$conn->rpc([IMPRPC_RESULT,$id,IMP_PASS,0,IMP_MAXOFFSET]);
	$conn->rpc([IMPRPC_RESULT,$id,IMP_PASS,1,IMP_MAXOFFSET]);
	return;
    } else {
	debug("created analyzer $id - $obj");
	$conn->add_analyzer($obj,$id);
	weaken( my $wconn = $conn );
	$obj->set_callback(sub {
	    $wconn->rpc([IMPRPC_RESULT,$id,@$_]) for (@_);
	});
    }
}

sub del_analyzer {
    my ($self,$id) = @_;
    $self->{conn}->del_analyzer($id);
}

sub data {
    my ($self,$id,$dir,$offset,$type,$data) = @_;
    my $obj = $self->{conn}->get_analyzer($id) or do {
	debug("no analyzer $id");
	$self->{conn}->rpc([IMPRPC_EXCEPTION,$id,"no analyzer $id"]);
	return;
    };
    debug("got data($dir,%s,$type,datalen=%d)",$offset//"<undef>",length($data));
    ref($obj) or return; # dummy
    $obj->data($dir,$data,$offset,$type);
}

sub exception {
    my ($self,$id,$msg) = @_;
    if ( $id ) {
	warn "[$id] $msg\n";
    } else {
	warn "[*] $msg\n";
    }
}

sub close {
    my $self = shift;
    my $id = $self->{id} or return;
    my $conn = $self->{conn} or return;
    $conn->del_analyzer($id);
}

sub DESTROY { goto &close }

1;
__END__

