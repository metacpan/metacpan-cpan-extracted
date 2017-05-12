use strict;
use warnings;

# ----------------------------------------------------------------------------
# simple file cache to handle more "open" files than the system allows
# the cache gets created with an explicit limit, which gets automatically
# decreased if a file open fails
# handles only files for writing, which gets opened the first time with '>'
# and later with '>>'
# ----------------------------------------------------------------------------

package privFileCache;
use fields qw(open closed max n);
use Symbol 'gensym';

sub new {
    my ($class,$max) = @_;
    my $self = fields::new($class);
    $self->{n} = 0;
    $self->{max} = $max||128;
    $self->{open} = {};
    $self->{closed} = {};
    return $self;
}

sub create {
    my ($self,$fname) = @_;
    $self->_get($fname,1) or return;
    my $fh = gensym();
    tie *$fh,'privFileCache::HANDLE',$self,$fname;
    return $fh;
}

sub _get {
    my ($self,$fname,$create) = @_;
    my $fh = $self->{open}{$fname};
    $fh = $fh && $fh->[0];
    if ($create) {
	_expire($self) if ! $fh;
	$fh = _open($self,'>',$fname) or do {
	    delete $self->{open}{$fname};
	    return;
	};
    }
    if ( ! $fh ) {
	$self->{closed}{$fname} or die "$fname not in pool";
	$fh = _open($self,'>>',$fname) or return;
	delete $self->{closed}{$fname};
    }

    $self->{open}{$fname} = [ $fh,$self->{n}++ ];
    return $fh;
}

sub _del {
    my ($self,$fname) = @_;
    delete $self->{open}{$fname};
    delete $self->{closed}{$fname};
}


sub _open {
    my ($self,$what,$fname) = @_;
    my $fh;
    while ( ! open( $fh,$what,$fname )) {
	if ( $!{ENFILE} || $!{EMFILE} || $!{ENOMEM} ) {
	    $self->{max}-- >1 or die "pool to small";
	    _expire($self);
	} else {
	    return;
	}
    }
    return $fh;
}

sub _expire {
    my ($self) = @_;
    my @fn = keys %{$self->{open}};
    @fn > $self->{max} or return;
    @fn = sort { $self->{open}{$a}[1] <=> $self->{open}{$b}[1] } @fn;
    while (@fn > $self->{max}) {
	my $fn = shift(@fn);
	delete $self->{open}{$fn};
	$self->{closed}{$fn} = 1;
    }
}

package privFileCache::HANDLE;
use strict;
use Errno 'EBADF';
use Scalar::Util 'weaken';

sub TIEHANDLE {
    my ($class, $fcache, $fname) = @_;
    weaken($fcache);
    bless { fcache => $fcache, fname => $fname }, $class;
}

sub PRINT {
    my $self = shift;
    my $fh = $self->{fcache}->_get($self->{fname}) or return;
    print $fh @_;
};

sub PRINTF {
    my $self = shift;
    my $fh = $self->{fcache}->_get($self->{fname}) or return;
    printf $fh @_;
};
    
*WRITE = \&PRINT;
*READ = *READLINE = *GETC = *FILENO = *TELL = sub { die "not implemented" };
sub BINMODE  { return 0 }

sub CLOSE {
    my $self = shift;
    $self->{fcache}->_del($self->{fname}) or return;
}


1;
