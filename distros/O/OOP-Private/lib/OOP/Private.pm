package OOP::Private;
our $VERSION = "1.01";

use strict;
use warnings;

no warnings "redefine";

use Carp "croak";
use Attribute::Handlers;

sub UNIVERSAL::Private :ATTR(CODE) {
    my ($pkg, $sym, $fun) = @_;

    *{$sym} = sub {
        croak "Attempt to call private subroutine $pkg".'::'. *{$sym}{NAME} ." from outer code"
            unless caller eq $pkg;

        $fun -> (@_);
    };
}

sub UNIVERSAL::Protected :ATTR(CODE) {
    my ($pkg, $sym, $fun) = @_;

    *{$sym} = sub {
        croak "Attempt to call protected subroutine $pkg".'::'. *{$sym}{NAME} ." from outer code"
            unless caller eq $pkg or caller -> UNIVERSAL::isa($pkg);

        $fun -> (@_);
    };
}

1
