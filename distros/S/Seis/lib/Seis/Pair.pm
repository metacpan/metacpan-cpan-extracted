package Seis::Pair;
use strict;
use warnings;
use utf8;
use 5.010_001;

package # hide from pause
    Pair;

use Seis::Autobox;

use overload (
    '~~' => '_match',
    'eq' => sub {
        my ($x, $y, $r) = @_;
        # optimizable
        $x->perl eq $y->perl
    },
    fallback => 1,
);

# Do not call this directly.
sub _new {
    my ($class, $key, $value) = @_;
    bless [$key, $value], $class;
}

sub key   { $_[0]->[0] }
sub value { $_[0]->[1] }

sub _match {
    my ($self, $stuff) = @_;
    if (UNIVERSAL::isa($stuff, 'Seis::IO::Handle')) {
        my ($key, $val) = @$self;
        my $ret = $stuff->$key();
        if ($val) {
            return !!$ret ? Bool::true() : Bool::false();
        } else {
            return !$ret ? Bool::True() : Bool::False();
        }
    } else {
        ...
    }
}

sub fmt {
    my ($self, $pattern) = @_;
    $pattern //= "%s\t%s";
    sprintf($pattern, $self->key, $self->value);
}

# "foo" => 3
our $_PERL_KEY;
sub perl {
    my $self = shift;
    my $key = do {
        local $_PERL_KEY = 1;
        $self->key->perl;
    };
    my $value = $self->value->perl;
    if ($_PERL_KEY) {
        "($key => $value)";
    } else {
        "$key => $value";
    }
}

sub kv {
    my $self = shift;
    [$self->key, $self->value];
}

sub isa {
    my ($self, $stuff) = @_;
    return UNIVERSAL::isa($self, $stuff->{name}) if UNIVERSAL::isa($stuff, 'Seis::Class');
    return UNIVERSAL::isa($self, $stuff);
}

sub WHAT {
    Seis::Class->_new(nam => 'Pair');
}

1;

