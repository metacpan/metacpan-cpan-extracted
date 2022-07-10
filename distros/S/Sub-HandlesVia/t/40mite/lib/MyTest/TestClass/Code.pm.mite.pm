{
package MyTest::TestClass::Code;
our $USES_MITE = "Mite::Class";
our $MITE_SHIM = "MyTest::Mite";
use strict;
use warnings;


sub new {
    my $class = ref($_[0]) ? ref(shift) : shift;
    my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
    my $self  = bless {}, $class;
    my $args  = $meta->{HAS_BUILDARGS} ? $class->BUILDARGS( @_ ) : { ( @_ == 1 ) ? %{$_[0]} : @_ };
    my $no_build = delete $args->{__no_BUILD__};

        # Attribute: attr
    do { my $value = exists( $args->{"attr"} ) ? $args->{"attr"} : do { my $method = $MyTest::TestClass::Code::__attr_DEFAULT__; $self->$method }; (ref($value) eq 'CODE') or MyTest::Mite::croak "Type check failed in constructor: %s should be %s", "attr", "CodeRef"; $self->{"attr"} = $value; }; 


    # Enforce strict constructor
    my @unknown = grep not( /\Aattr\z/ ), keys %{$args}; @unknown and MyTest::Mite::croak( "Unexpected keys in constructor: " . join( q[, ], sort @unknown ) );

    # Call BUILD methods
    $self->BUILDALL( $args ) if ( ! $no_build and @{ $meta->{BUILD} || [] } );

    return $self;
}

sub BUILDALL {
    my $class = ref( $_[0] );
    my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
    $_->( @_ ) for @{ $meta->{BUILD} || [] };
}

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

sub DOES {
    my ( $self, $role ) = @_;
    our %DOES;
    return $DOES{$role} if exists $DOES{$role};
    return 1 if $role eq __PACKAGE__;
    return $self->SUPER::DOES( $role );
}

sub does {
    shift->DOES( @_ );
}

my $__XS = !$ENV{MITE_PURE_PERL} && eval { require Class::XSAccessor; Class::XSAccessor->VERSION("1.19") };

# Accessors for attr
if ( $__XS ) {
    Class::XSAccessor->import(
        chained => 1,
        "getters" => { "attr" => "attr" },
    );
}
else {
    *attr = sub { @_ > 1 ? MyTest::Mite::croak( "attr is a read-only attribute of @{[ref $_[0]]}" ) : $_[0]{"attr"} };
}
sub _set_attr { (ref($_[1]) eq 'CODE') or MyTest::Mite::croak( "Type check failed in %s: value should be %s", "writer", "CodeRef" ); $_[0]{"attr"} = $_[1]; $_[0]; }


1;
}