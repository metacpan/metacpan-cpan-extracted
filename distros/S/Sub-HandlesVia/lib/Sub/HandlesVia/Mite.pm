# NOTE: Since the intention is to ship this file with a project, this file
# cannot have any non-core dependencies.
package Sub::HandlesVia::Mite;
use 5.008001;
use strict;
use warnings;
no strict 'refs';

if ( $] < 5.009005 ) { require MRO::Compat; }
else                 { require mro;         }

defined ${^GLOBAL_PHASE}
or eval { require Devel::GlobalDestruction; 1 }
or do {
    carp( "WARNING: Devel::GlobalDestruction recommended!" );
    *Devel::GlobalDestruction::in_global_destruction = sub { undef; };
};

# Constants
sub true  () { !!1 }
sub false () { !!0 }
sub ro    () { 'ro' }
sub rw    () { 'rw' }
sub rwp   () { 'rwp' }
sub lazy  () { 'lazy' }
sub bare  () { 'bare' }

# More complicated constants
BEGIN {
    my @bool = ( \&false, \&true );
    *_HAS_AUTOCLEAN = $bool[ 0+!! eval { require namespace::autoclean } ];
    *STRICT         = $bool[ 0+!! ( $ENV{PERL_STRICT} || $ENV{EXTENDED_TESTING} || $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING} ) ];
};

# Exportable error handlers
sub _error_handler {
    my ( $func, $message, @args ) = @_;
    if ( @args ) {
        require Data::Dumper;
        local $Data::Dumper::Terse  = 1;
        local $Data::Dumper::Indent = 0;
        $message = sprintf $message, map {
            ref($_) ? Data::Dumper::Dumper($_) : defined($_) ? $_ : '(undef)'
        } @args;
    }
    my $next = do { require Carp; \&{"Carp::$func"} };
    @_ = ( $message );
    goto $next;
}

sub carp    { unshift @_, 'carp'   ; goto \&_error_handler }
sub croak   { unshift @_, 'croak'  ; goto \&_error_handler }
sub confess { unshift @_, 'confess'; goto \&_error_handler }

# Exportable guard function
{
    my $GUARD_PACKAGE = __PACKAGE__ . '::Guard';
    *{"$GUARD_PACKAGE\::DESTROY"} = sub { $_[0][0] or $_[0][1]->() };
    *{"$GUARD_PACKAGE\::restore"} = sub { $_[0]->DESTROY; $_[0][0] = true };
    *{"$GUARD_PACKAGE\::dismiss"} = sub {                 $_[0][0] = true };
    *{"$GUARD_PACKAGE\::peek"}    = sub { $_[0][2] };
    *guard = sub (&) { bless [ 0, @_ ] => $GUARD_PACKAGE };
}

# Exportable lock and unlock
sub _lul {
    my ( $lul, $ref ) = @_;
    if ( ref $ref eq 'ARRAY' ) {
        &Internals::SvREADONLY( $ref, $lul );
        &Internals::SvREADONLY( \$_, $lul ) for @$ref;
        return;
    }
    if ( ref $ref eq 'HASH' ) {
        &Internals::hv_clear_placeholders( $ref );
        &Internals::SvREADONLY( $ref, $lul );
        &Internals::SvREADONLY( \$_, $lul ) for values %$ref;
        return;
    }
    return;
}

sub lock {
    unshift @_, true;
    goto \&_lul;
}

sub unlock {
    my $ref = shift;
    _lul( 0 , $ref );
    &guard( sub { _lul( 1, $ref ) } );
}

sub _is_compiling {
    defined $Mite::COMPILING and $Mite::COMPILING eq __PACKAGE__;
}

sub import {
    my $me = shift;
    my %arg = map +( lc($_) => true ), @_;
    my ( $caller, $file ) = caller;

    if( _is_compiling() ) {
        require Mite::Project;
        'Mite::Project'->default->inject_mite_functions(
            'package' => $caller,
            'file'    => $file,
            'arg'     => \%arg,
            'shim'    => $me,
        );
    }
    else {
        # Changes to this filename must be coordinated with Mite::Compiled
        my $mite_file = $file . '.mite.pm';
        local @INC = ( '.', @INC );
        local $@;
        if ( not eval { require $mite_file; 1 } ) {
            my $e = $@;
            croak "Compiled Mite file ($mite_file) for $file is missing or an error occurred loading it: $e";
        }
    }

    'warnings'->import;
    'strict'->import;
    'namespace::autoclean'->import( -cleanee => $caller )
        if _HAS_AUTOCLEAN && !$arg{'-unclean'};
}

{
    my ( $cb_before, $cb_after );
    sub _finalize_application_roletiny {
        my ( $me, $role, $caller, $args ) = @_;
        if ( $INC{'Role/Hooks.pm'} ) {
            $cb_before ||= \%Role::Hooks::CALLBACKS_BEFORE_APPLY;
            $cb_after  ||= \%Role::Hooks::CALLBACKS_AFTER_APPLY;
        }
        if ( $cb_before ) {
            $_->( $role, $caller ) for @{ $cb_before->{$role} || [] };
        }
        'Role::Tiny'->_check_requires( $caller, $role );
        my $info = $Role::Tiny::INFO{$role};
        for ( @{ $info->{modifiers} || [] } ) {
            my @args         = @$_;
            my $modification = shift @args;
            my $handler      = "HANDLE_$modification";
            $me->$handler( $caller, undef, @args );
        }
        if ( $cb_after ) {
            $_->( $role, $caller ) for @{ $cb_after->{$role} || [] };
        }
        return;
    }

    # Usage: $me, $caller, @with_args
    sub HANDLE_with {
        my ( $me, $caller ) = ( shift, shift );
        while ( @_ ) {
            my $role = shift;
            my $args = ref($_[0]) ? shift : undef;
            if ( $INC{'Role/Tiny.pm'} and 'Role::Tiny'->is_role( $role ) ) {
                $me->_finalize_application_roletiny( $role, $caller, $args );
            }
            else {
                $role->__FINALIZE_APPLICATION__( $caller, $args );
            }
        }
        return;
    }
}

# Usage: $me, $caller, $keyword, @has_args
sub HANDLE_has {
    my ( $me, $caller, $keyword, $names ) = ( shift, shift, shift, shift );
    if ( @_ % 2 ) {
        my $default = shift;
        unshift @_, ( 'CODE' eq ref( $default ) )
            ? ( is => lazy, builder => $default )
            : ( is => ro, default => $default );
    }
    my %spec = @_;
    my $code;
    for my $name ( ref($names) ? @$names : $names ) {
        $name =~ s/^\+//;
        'CODE' eq ref( $code = $spec{default} )
            and ${"$caller\::__$name\_DEFAULT__"} = $code;
        'CODE' eq ref( $code = $spec{builder} )
            and *{"$caller\::_build_$name"} = $code;
        'CODE' eq ref( $code = $spec{trigger} )
            and *{"$caller\::_trigger_$name"} = $code;
        'CODE' eq ref( $code = $spec{clone} )
            and *{"$caller\::_clone_$name"} = $code;
    }
    return;
}

{
    my $_kind = sub { ${ shift() . '::USES_MITE' } =~ /Role/ ? 'role' : 'class' };

    sub _get_orig_method {
        my ( $caller, $name ) = @_;
        my $orig = $caller->can( $name );
        return $orig if $orig;
        croak "Cannot modify method $name in $caller: no such method";
    }

    sub _parse_mm_args {
        my $coderef = pop;
        my $names   = [ map { ref($_) ? @$_ : $_ } @_ ];
        ( $names, $coderef );
    }

    # Usage: $me, $caller, $caller_kind, @before_args
    sub HANDLE_before {
        my ( $me, $caller, $kind ) = ( shift, shift, shift );
        my ( $names, $coderef ) = &_parse_mm_args;
        $kind ||= $caller->$_kind;
        if ( $kind eq 'role' ) {
            push @{"$caller\::METHOD_MODIFIERS"},
                [ before => $names, $coderef ];
            return;
        }
        for my $name ( @$names ) {
            my $orig = _get_orig_method( $caller, $name );
            local $@;
            eval <<"BEFORE" or die $@;
                package $caller;
                no warnings 'redefine';
                sub $name {
                    \$coderef->( \@_ );
                    \$orig->( \@_ );
                }
                1;
BEFORE
        }
        return;
    }

    # Usage: $me, $caller, $caller_kind, @after_args
    sub HANDLE_after {
        my ( $me, $caller, $kind ) = ( shift, shift, shift );
        my ( $names, $coderef ) = &_parse_mm_args;
        $kind ||= $caller->$_kind;
        if ( $kind eq 'role' ) {
            push @{"$caller\::METHOD_MODIFIERS"},
                [ after => $names, $coderef ];
            return;
        }
        for my $name ( @$names ) {
            my $orig = _get_orig_method( $caller, $name );
            local $@;
            eval <<"AFTER" or die $@;
                package $caller;
                no warnings 'redefine';
                sub $name {
                    my \@r;
                    if ( wantarray ) {
                        \@r = \$orig->( \@_ );
                    }
                    elsif ( defined wantarray ) {
                        \@r = scalar \$orig->( \@_ );
                    }
                    else {
                        \$orig->( \@_ );
                        1;
                    }
                    \$coderef->( \@_ );
                    wantarray ? \@r : \$r[0];
                }
                1;
AFTER
        }
        return;
    }

    # Usage: $me, $caller, $caller_kind, @around_args
    sub HANDLE_around {
        my ( $me, $caller, $kind ) = ( shift, shift, shift );
        my ( $names, $coderef ) = &_parse_mm_args;
        $kind ||= $caller->$_kind;
        if ( $kind eq 'role' ) {
            push @{"$caller\::METHOD_MODIFIERS"},
                [ around => $names, $coderef ];
            return;
        }
        for my $name ( @$names ) {
            my $orig = _get_orig_method( $caller, $name );
            local $@;
            eval <<"AROUND" or die $@;
                package $caller;
                no warnings 'redefine';
                sub $name {
                    \$coderef->( \$orig, \@_ );
                }
                1;
AROUND
        }
        return;
    }
}

# Usage: $me, $caller, $caller_kind, @signature_for_args
sub HANDLE_signature_for {
    my ( $me, $caller, $kind, $name ) = @_;
    $name =~ s/^\+//;
    $me->HANDLE_around( $caller, $kind, $name, ${"$caller\::SIGNATURE_FOR"}{$name} );
    return;
}

1;
