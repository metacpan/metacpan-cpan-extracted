package Seis::BuiltinFunctions;
use strict;
use warnings;
use utf8;
use 5.010_001;
use Time::HiRes ();
use Socket;

sub end { @{$_[0]}-1 }
sub end_list { @_-1 }

sub slurp {
    if (@_==1) {
        my $fname = shift;
        open my $fh, '<', $fname
            or Carp::croak("Can't open '$fname' for reading: '$!'");
        scalar(do { local $/; <$fh> })
    } else {
        ...
    }
}

sub open :method {
    my $mode = @_==2 && $_[1]->key eq 'w' ? '>' : '<';
    CORE::open my $fh, $mode, $_[0];
    return Seis::IO->_new_with_fh($_[0], $fh);
}

sub get :method {
    my $stuff = shift;
    return $stuff->get() if Scalar::Util::blessed($stuff);
    my $line = <$stuff>;
    if (defined $line) {
        $line =~ s/\n//;
    }
    $line;
}

sub close:method {
    my $stuff = shift;
    if (UNIVERSAL::isa($stuff, 'Seis::IO')) {
        $stuff->close;
    } else {
        CORE::close($stuff);
    }
}

sub getc:method {
    my $stuff = shift;
    if (UNIVERSAL::isa($stuff, 'Seis::IO')) {
        $stuff->getc;
    } else {
        CORE::getc($stuff);
    }
}

sub now:method {
    Seis::Instant->_new(Time::HiRes::time())
}

sub gcd:method {
    int(Math::BigInt::bgcd(@_) - 0)
}

sub any:method {
    Seis::Any->_new(@_);
}

sub is_prime {
    require Math::Prime::Util;
    Math::Prime::Util::is_prime($_[0])
}

sub ords {
    my @ret = map { ord($_) } split //, $_[0];
    wantarray ? @ret : \@ret;
}

sub connect:method {
    my ($host, $port) = @_;

    my $sock;
    socket($sock, PF_INET, SOCK_STREAM, getprotobyname('tcp'))
      or die "Cannot create socket: $!";
    my $address = sockaddr_in($port, inet_aton($host));
    CORE::connect($sock, $address)
        or die "Cannot connect $host:$port: $!";
    return bless $sock, 'Seis::Socket';
}

sub reduce:method {
    my $code = shift;
    return shift unless @_ > 1;

    my $a = shift;
    for (@_) {
        $a = &{$code}($a, $_);
    }
    $a;
}

sub copy:method {
    require File::Copy;
    File::Copy::copy($_[0], $_[1])
        or die Seis::Exception::IO->throw("$!");
}

1;

