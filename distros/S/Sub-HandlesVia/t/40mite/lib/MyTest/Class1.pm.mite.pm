{
package MyTest::Class1;
use strict;
use warnings;
no warnings qw( once void );

our $USES_MITE = "Mite::Class";
our $MITE_SHIM = "MyTest::Mite";
our $MITE_VERSION = "0.010008";
# Mite keywords
BEGIN {
    my ( $SHIM, $CALLER ) = ( "MyTest::Mite", "MyTest::Class1" );
    ( *after, *around, *before, *extends, *has, *signature_for, *with ) = do {
        package MyTest::Mite;
        no warnings 'redefine';
        (
            sub { $SHIM->HANDLE_after( $CALLER, "class", @_ ) },
            sub { $SHIM->HANDLE_around( $CALLER, "class", @_ ) },
            sub { $SHIM->HANDLE_before( $CALLER, "class", @_ ) },
            sub {},
            sub { $SHIM->HANDLE_has( $CALLER, has => @_ ) },
            sub { $SHIM->HANDLE_signature_for( $CALLER, "class", @_ ) },
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


# Standard Moose/Moo-style constructor
sub new {
    my $class = ref($_[0]) ? ref(shift) : shift;
    my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
    my $self  = bless {}, $class;
    my $args  = $meta->{HAS_BUILDARGS} ? $class->BUILDARGS( @_ ) : { ( @_ == 1 ) ? %{$_[0]} : @_ };
    my $no_build = delete $args->{__no_BUILD__};

    # Attribute list (type: ArrayRef)
    # has declaration, file lib/MyTest/Role1.pm, line 42
    do { my $value = exists( $args->{"list"} ) ? $args->{"list"} : $MyTest::Role1::__list_DEFAULT__->( $self ); (ref($value) eq 'ARRAY') or MyTest::Mite::croak "Type check failed in constructor: %s should be %s", "list", "ArrayRef"; $self->{"list"} = $value; }; 


    # Call BUILD methods
    $self->BUILDALL( $args ) if ( ! $no_build and @{ $meta->{BUILD} || [] } );

    # Unrecognized parameters
    my @unknown = grep not( /\Alist\z/ ), keys %{$args}; @unknown and MyTest::Mite::croak( "Unexpected keys in constructor: " . join( q[, ], sort @unknown ) );

    return $self;
}

# Used by constructor to call BUILD methods
sub BUILDALL {
    my $class = ref( $_[0] );
    my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
    $_->( @_ ) for @{ $meta->{BUILD} || [] };
}

# Destructor should call DEMOLISH methods
sub DESTROY {
    my $self  = shift;
    my $class = ref( $self ) || $self;
    my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
    my $in_global_destruction = defined ${^GLOBAL_PHASE}
        ? ${^GLOBAL_PHASE} eq 'DESTRUCT'
        : Devel::GlobalDestruction::in_global_destruction();
    for my $demolisher ( @{ $meta->{DEMOLISH} || [] } ) {
        my $e = do {
            local ( $?, $@ );
            eval { $demolisher->( $self, $in_global_destruction ) };
            $@;
        };
        no warnings 'misc'; # avoid (in cleanup) warnings
        die $e if $e;       # rethrow
    }
    return;
}

my $__XS = !$ENV{PERL_ONLY} && eval { require Class::XSAccessor; Class::XSAccessor->VERSION("1.19") };

# Accessors for list
# has declaration, file lib/MyTest/Role1.pm, line 42
if ( $__XS ) {
    Class::XSAccessor->import(
        chained => 1,
        "getters" => { "list" => "list" },
    );
}
else {
    *list = sub { @_ == 1 or MyTest::Mite::croak( 'Reader "list" usage: $self->list()' ); $_[0]{"list"} };
}


BEGIN {
    require MyTest::Role2;
    
    our %DOES = ( "MyTest::Class1" => 1, "MyTest::Role2" => 1, "MyTest::Role1" => 1 );
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

1;
}