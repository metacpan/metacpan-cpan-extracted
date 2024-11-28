use Perlmazing;

sub main {
    if (wantarray) {
        return CORE::stat $_[0];
    } else {
        return Perlmazing::Object::Stat->new($_[0]);
    }
}

package Perlmazing::Object::Stat;
use Perlmazing;
use overload fallback => 1, '""' => \&_stringify;
our $AUTOLOAD;

# These are just respecting the name given in the Perldoc for convienience:
my @keys = qw(
    dev
    ino
    mode
    nlink
    uid
    gid
    rdev
    size
    atime
    mtime
    ctime
    blksize
    blocks
);

sub new {
    my $self = shift;
    my $file = shift;
    my @stat = CORE::stat $file;
    return unless @stat;
    my $this = {};
    for (my $i = 0; $i < @stat; $i++) {
        $this->{$keys[$i]} = $stat[$i];
    }
    bless $this, $self;
}

sub _stringify {
    my $self = shift;
    my $string = '';
    for my $i (@keys) {
        return 1 if defined $self->{$i};
    }
}

sub _keys {
    my @copy = @keys;
    return @copy;
}

sub AUTOLOAD {
    (my $name = $AUTOLOAD) =~ s/^.+:://;
    my $self = shift;
    if (exists $self->{$name}) {
        return $self->{$name};
    } else {
        my @call = caller;
        die qq[Can't locate object method "$name" via package "].__PACKAGE__.qq[" at $call[1] line $call[2].\nTip: valid methods are ].join(', ', @keys)."\n";
    }
}

sub DESTROY {}

1;
