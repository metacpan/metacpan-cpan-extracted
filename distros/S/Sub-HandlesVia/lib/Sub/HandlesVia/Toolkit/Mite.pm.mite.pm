{

    package Sub::HandlesVia::Toolkit::Mite;
    use strict;
    use warnings;

    our $USES_MITE    = "Mite::Class";
    our $MITE_SHIM    = "Sub::HandlesVia::Mite";
    our $MITE_VERSION = "0.008003";

    BEGIN {
        require Scalar::Util;
        *STRICT  = \&Sub::HandlesVia::Mite::STRICT;
        *bare    = \&Sub::HandlesVia::Mite::bare;
        *blessed = \&Scalar::Util::blessed;
        *carp    = \&Sub::HandlesVia::Mite::carp;
        *confess = \&Sub::HandlesVia::Mite::confess;
        *croak   = \&Sub::HandlesVia::Mite::croak;
        *false   = \&Sub::HandlesVia::Mite::false;
        *guard   = \&Sub::HandlesVia::Mite::guard;
        *lazy    = \&Sub::HandlesVia::Mite::lazy;
        *ro      = \&Sub::HandlesVia::Mite::ro;
        *rw      = \&Sub::HandlesVia::Mite::rw;
        *rwp     = \&Sub::HandlesVia::Mite::rwp;
        *true    = \&Sub::HandlesVia::Mite::true;
    }

    BEGIN {
        require Sub::HandlesVia::Toolkit;

        use mro 'c3';
        our @ISA;
        push @ISA, "Sub::HandlesVia::Toolkit";
    }

    # See UNIVERSAL
    sub DOES {
        my ( $self, $role ) = @_;
        our %DOES;
        return $DOES{$role} if exists $DOES{$role};
        return 1            if $role eq __PACKAGE__;
        return $self->SUPER::DOES($role);
    }

    # Alias for Moose/Moo-compatibility
    sub does {
        shift->DOES(@_);
    }

    1;
}
