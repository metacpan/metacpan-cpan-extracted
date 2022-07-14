{

    package Sub::HandlesVia::Toolkit::Mouse;
    use strict;
    use warnings;

    our $USES_MITE    = "Mite::Class";
    our $MITE_SHIM    = "Sub::HandlesVia::Mite";
    our $MITE_VERSION = "0.006011";

    BEGIN {
        require Sub::HandlesVia::Toolkit;

        use mro 'c3';
        our @ISA;
        push @ISA, "Sub::HandlesVia::Toolkit";
    }

    sub DOES {
        my ( $self, $role ) = @_;
        our %DOES;
        return $DOES{$role} if exists $DOES{$role};
        return 1            if $role eq __PACKAGE__;
        return $self->SUPER::DOES($role);
    }

    sub does {
        shift->DOES(@_);
    }

    1;
}
