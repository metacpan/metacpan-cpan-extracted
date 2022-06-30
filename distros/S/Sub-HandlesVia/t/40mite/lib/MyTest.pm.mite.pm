{
package MyTest;
our $USES_MITE = 1;
use strict;
use warnings;
## skip Test::Tabs

sub new {
    my $class = ref($_[0]) ? ref(shift) : shift;
    my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
    my $self  = bless {}, $class;
    my $args  = $meta->{HAS_BUILDARGS} ? $class->BUILDARGS( @_ ) : { ( @_ == 1 ) ? %{$_[0]} : @_ };
    my $no_build = delete $args->{__no_BUILD__};

    # Initialize attributes
    if ( exists($args->{q[list]}) ) { do { package MyTest::Mite; ref($args->{q[list]}) eq 'ARRAY' } or require Carp && Carp::croak(q[Type check failed in constructor: list should be ArrayRef]); $self->{q[list]} = $args->{q[list]};  } else { my $value = do { my $default_value = do { our $__list_DEFAULT__; $__list_DEFAULT__->($self) }; (ref($default_value) eq 'ARRAY') or do { require Carp; Carp::croak(q[Type check failed in default: list should be ArrayRef]) }; $default_value }; $self->{q[list]} = $value;  }

    # Enforce strict constructor
    my @unknown = grep not( do { package MyTest::Mite; (defined and !ref and m{\A(?:list)\z}) } ), keys %{$args}; @unknown and require Carp and Carp::croak("Unexpected keys in constructor: " . join(q[, ], sort @unknown));

    # Call BUILD methods
    unless ( $no_build ) { $_->($self, $args) for @{ $meta->{BUILD} || [] } };

    return $self;
}

defined ${^GLOBAL_PHASE}
    or eval { require Devel::GlobalDestruction; 1 }
    or do   { *Devel::GlobalDestruction::in_global_destruction = sub { undef; } };

sub DESTROY {
    my $self = shift;
    my $class = ref( $self ) || $self;
    my $meta = ( $Mite::META{$class} ||= $class->__META__ );
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
    require mro;
    my $class = shift; $class = ref($class) || $class;
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
    };
}

my $__XS = !$ENV{MITE_PURE_PERL} && eval { require Class::XSAccessor; Class::XSAccessor->VERSION("1.19") };

# Accessors for list
if ( $__XS ) {
    Class::XSAccessor->import(
        chained => 1,
        getters => { q[list] => q[list] },
    );
}
else {
    *list = sub { @_ > 1 ? require Carp && Carp::croak("list is a read-only attribute of @{[ref $_[0]]}") : $_[0]{q[list]} };
}


1;
}