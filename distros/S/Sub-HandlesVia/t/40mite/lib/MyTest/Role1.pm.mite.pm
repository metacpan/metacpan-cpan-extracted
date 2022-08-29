{
package MyTest::Role1;
use strict;
use warnings;
no warnings qw( once void );

our $USES_MITE = "Mite::Role";
our $MITE_SHIM = "MyTest::Mite";
our $MITE_VERSION = "0.010008";
# Mite keywords
BEGIN {
    my ( $SHIM, $CALLER ) = ( "MyTest::Mite", "MyTest::Role1" );
    ( *after, *around, *before, *has, *requires, *signature_for, *with ) = do {
        package MyTest::Mite;
        no warnings 'redefine';
        (
            sub { $SHIM->HANDLE_after( $CALLER, "role", @_ ) },
            sub { $SHIM->HANDLE_around( $CALLER, "role", @_ ) },
            sub { $SHIM->HANDLE_before( $CALLER, "role", @_ ) },
            sub { $SHIM->HANDLE_has( $CALLER, has => @_ ) },
            sub {},
            sub { $SHIM->HANDLE_signature_for( $CALLER, "role", @_ ) },
            sub { $SHIM->HANDLE_with( $CALLER, @_ ) },
        );
    };
};

# Gather metadata for constructor and destructor
sub __META__ {
    no strict 'refs';
    my $class      = shift; $class = ref($class) || $class;
    my $linear_isa = mro::get_linear_isa( $class );
    return {
        BUILD => [
            map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
            map { "$_\::BUILD" } reverse @$linear_isa
        ],
        DEMOLISH => [
            map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
            map { "$_\::DEMOLISH" } @$linear_isa
        ],
        HAS_BUILDARGS => $class->can('BUILDARGS'),
        HAS_FOREIGNBUILDARGS => $class->can('FOREIGNBUILDARGS'),
    };
}

# See UNIVERSAL
sub DOES {
    my ( $self, $role ) = @_;
    our %DOES;
    return $DOES{$role} if exists $DOES{$role};
    return 1 if $role eq __PACKAGE__;
    if ( $INC{'Moose/Util.pm'} and my $meta = Moose::Util::find_meta( ref $self or $self ) ) {
        $meta->can( 'does_role' ) and $meta->does_role( $role ) and return 1;
    }
    return $self->SUPER::DOES( $role );
}

# Alias for Moose/Moo-compatibility
sub does {
    shift->DOES( @_ );
}

# Callback which classes consuming this role will call
sub __FINALIZE_APPLICATION__ {
    my ( $me, $target, $args ) = @_;
    our ( %CONSUMERS, @METHOD_MODIFIERS );

    # Ensure a given target only consumes this role once.
    if ( exists $CONSUMERS{$target} ) {
        return;
    }
    $CONSUMERS{$target} = 1;

    my $type = do { no strict 'refs'; ${"$target\::USES_MITE"} };
    return if $type ne 'Mite::Class';

    my @missing_methods;
    @missing_methods = ()
        and MyTest::Mite::croak( "$me requires $target to implement methods: " . join q[, ], @missing_methods );

    my @roles = (  );
    my %nextargs = %{ $args || {} };
    ( $nextargs{-indirect} ||= 0 )++;
    MyTest::Mite::croak( "PANIC!" ) if $nextargs{-indirect} > 100;
    for my $role ( @roles ) {
        $role->__FINALIZE_APPLICATION__( $target, { %nextargs } );
    }

    my $shim = "MyTest::Mite";
    for my $modifier_rule ( @METHOD_MODIFIERS ) {
        my ( $modification, $names, $coderef ) = @$modifier_rule;
        my $handler = "HANDLE_$modification";
        $shim->$handler( $target, "class", $names, $coderef );
    }

    return;
}

1;
}