{

    package Sub::HandlesVia::Toolkit::Moo;
    use strict;
    use warnings;

    our $USES_MITE    = "Mite::Class";
    our $MITE_SHIM    = "Sub::HandlesVia::Mite";
    our $MITE_VERSION = "0.008003";

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
