package MockDBusServer;

use strict;
use warnings;

my $CRLF;
BEGIN {
    $CRLF = "\x0d\x0a";
}

#----------------------------------------------------------------------

sub new {
    my ($class, $socket) = @_;

    return bless { _s => $socket, _in => q<> }, $class;
}

sub socket {
    return $_[0]->{'_s'};
}

sub send_line {
    my ($self, $payload) = @_;

    syswrite $self->{'_s'}, ( $payload . $CRLF );
}

sub getc {
    my ($self) = @_;

    my $c;

    if (length $self->{'_in'}) {
        $c = substr( $self->{'_in'}, 0, 1, q<> );
    }
    else {
        sysread( $self->{'_s'}, $c, 1 ) or die "read(): $!";

        #$self->_consume_control( $rmsg );
    }

    return $c;
}

sub get_line {
    my ($self) = @_;

    my $line = q<>;

    while ( -1 == index($line, $CRLF) ) {
#print "$$ getting line part ($line)\n";
        $line .= $self->getc();
    }

    return substr( $line, 0, -2 );
}

#sub get_line {
#    my ($self) = @_;
#
#    my $crlf_at;
#
#    while (1) {
#        $crlf_at = index( $self->{'_in'}, $CRLF );
#
#        last if -1 != $crlf_at;
#
#        sysread( $self->{'_s'}, $self->{'_in'}, 512, length $self->{'_in'} ) or die "read(): $!";
#
#        #$self->_consume_control( $msg );
#    }
#
#    return substr(
#        substr( $self->{'_in'}, 0, 2 + $crlf_at, q<>),
#        0,
#        -2,
#    );
#}

sub harvest_control {
    my ($self) = @_;

    return splice @{ $self->{'_ctl'} };
}

sub _consume_control {
    my ($self, $msg) = @_;

    if ($msg->control()) {
        push @{ $self->{'_ctl'} }, [ $msg->cmsghdr() ];
    }

    return;
}

1;
