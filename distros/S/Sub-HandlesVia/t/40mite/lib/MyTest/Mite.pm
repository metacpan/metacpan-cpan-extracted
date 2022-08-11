use 5.008001;
use strict;
use warnings;

# NOTE: Since the intention is to ship this file with a project, this file
# cannot have any non-core dependencies.

package MyTest::Mite;

# Constants
sub true  () { !!1 }
sub false () { !!0 }
sub ro    () { 'ro' }
sub rw    () { 'rw' }
sub rwp   () { 'rwp' }
sub lazy  () { 'lazy' }
sub bare  () { 'bare' }

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
    my $next = do { no strict 'refs'; require Carp; \&{"Carp::$func"} };
    @_ = ( $message );
    goto $next;
}

sub carp    { unshift @_, 'carp'   ; goto \&_error_handler }
sub croak   { unshift @_, 'croak'  ; goto \&_error_handler }
sub confess { unshift @_, 'confess'; goto \&_error_handler }

BEGIN {
    my @bool = ( \&false, \&true );
    *_HAS_AUTOCLEAN = $bool[ 0+!! eval { require namespace::autoclean } ];
    *STRICT         = $bool[ 0+!! ( $ENV{PERL_STRICT} || $ENV{EXTENDED_TESTING} || $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING} ) ];
};

if ( $] < 5.009005 ) {
    require MRO::Compat;
}
else {
    require mro;
}

defined ${^GLOBAL_PHASE}
or eval { require Devel::GlobalDestruction; 1 }
or do {
    carp( "WARNING: Devel::GlobalDestruction recommended!" );
    *Devel::GlobalDestruction::in_global_destruction = sub { undef; };
};

{
    no strict 'refs';
    my $GUARD_PACKAGE = __PACKAGE__ . '::Guard';
    *{"$GUARD_PACKAGE\::DESTROY"} = sub { $_[0][0] or $_[0][1]->() };
    *{"$GUARD_PACKAGE\::restore"} = sub { $_[0]->DESTROY; $_[0][0] = true };
    *{"$GUARD_PACKAGE\::dismiss"} = sub {                 $_[0][0] = true };
    *{"$GUARD_PACKAGE\::peek"}    = sub { $_[0][2] };
    *guard = sub (&) { bless [ 0, @_ ] => $GUARD_PACKAGE };
}

my $parse_mm_args = sub {
    my $coderef = pop;
    my $names   = [ map { ref($_) ? @$_ : $_ } @_ ];
    ( $names, $coderef );
};

sub _is_compiling {
    return !! $ENV{MITE_COMPILE};
}

sub import {
    my $class = shift;
    my %arg = map { lc($_) => true } @_;
    my ( $caller, $file ) = caller;

    # Turn on warnings and strict in the caller
    warnings->import;
    strict->import;

    my $kind = $arg{'-role'} ? 'role' : 'class';

    if( _is_compiling() ) {
        require Mite::Project;
        Mite::Project->default->inject_mite_functions(
            package     => $caller,
            file        => $file,
            arg         => \%arg,
            kind        => $kind,
            shim        => $class,
        );
    }
    else {
        # Changes to this filename must be coordinated with Mite::Compiled
        my $mite_file = $file . ".mite.pm";
        if( !-e $mite_file ) {
            croak "Compiled Mite file ($mite_file) for $file is missing";
        }

        {
            local @INC = ('.', @INC);
            require $mite_file;
        }

        $class->_inject_mite_functions( $caller, $file, $kind, \%arg );
    }

    if ( _HAS_AUTOCLEAN and not $arg{'-unclean'} ) {
        'namespace::autoclean'->import( -cleanee => $caller );
    }
}

sub _inject_mite_functions {
    my ( $class, $caller, $file, $kind, $arg ) = ( shift, @_ );
    my $requested = sub { $arg->{$_[0]} ? true : $arg->{'!'.$_[0]} ? false : $arg->{'-all'} ? true : $_[1]; };

    no strict 'refs';
    my $has = $class->_make_has( $caller, $file, $kind );
    *{"$caller\::has"}   = $has if $requested->( has   => true  );
    *{"$caller\::param"} = $has if $requested->( param => false );
    *{"$caller\::field"} = $has if $requested->( field => false );

    *{"$caller\::with"} = $class->_make_with( $caller, $file, $kind )
        if $requested->( with => true );

    *{"$caller\::signature_for"} = sub {
        my ( $name ) = @_;
        $name =~ s/^\+//;
        $class->around( $caller, $name, ${"$caller\::SIGNATURE_FOR"}{$name} );
    } if $requested->( signature_for => false );

    *{"$caller\::extends"} = sub {}
        if $kind eq 'class' && $requested->( extends => true );
    *{"$caller\::requires"} = sub {}
        if $kind eq 'role' && $requested->( requires => true );

    my $MM = ( $kind eq 'class' ) ? [] : \@{"$caller\::METHOD_MODIFIERS"};

    for my $modifier ( qw/ before after around / ) {
        next unless $requested->( $modifier => true );

        if ( $kind eq 'class' ) {
            *{"$caller\::$modifier"} = sub {
                $class->$modifier( $caller, @_ );
                return;
            };
        }
        else {
            *{"$caller\::$modifier"} = sub {
                my ( $names, $coderef ) = &$parse_mm_args;
                push @$MM, [ $modifier, $names, $coderef ];
                return;
            };
        }
    }
}

sub _make_has {
    my ( $class, $caller, $file, $kind ) = @_;

    no strict 'refs';
    return sub {
        my $names = shift;
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
    };
}

sub _make_with {
    my ( $class, $caller, $file, $kind ) = @_;

    return sub {
        while ( @_ ) {
            my $role = shift;
            my $args = ref($_[0]) ? shift : undef;
            if ( $INC{'Role/Tiny.pm'} and 'Role::Tiny'->is_role( $role ) ) {
                $class->_finalize_application_roletiny( $role, $caller, $args );
            }
            else {
                $role->__FINALIZE_APPLICATION__( $caller, $args );
            }
        }
        return;
    };
}

{
    my ( $cb_before, $cb_after );
    sub _finalize_application_roletiny {
        my ( $class, $role, $caller, $args ) = @_;

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
            my @args = @$_;
            my $kind = shift @args;
            $class->$kind( $caller, @args );
        }

        if ( $cb_after ) {
            $_->( $role, $caller ) for @{ $cb_after->{$role} || [] };
        }

        return;
    }
}

{
    my $get_orig = sub {
        my ( $caller, $name ) = @_;

        my $orig = $caller->can( $name );
        return $orig if $orig;

        croak "Cannot modify method $name in $caller: no such method";
    };

    sub before {
        my ( $me, $caller ) = ( shift, shift );
        my ( $names, $coderef ) = &$parse_mm_args;
        for my $name ( @$names ) {
            my $orig = $get_orig->( $caller, $name );
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

    sub after {
        my ( $me, $caller ) = ( shift, shift );
        my ( $names, $coderef ) = &$parse_mm_args;
        for my $name ( @$names ) {
            my $orig = $get_orig->( $caller, $name );
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

    sub around {
        my ( $me, $caller ) = ( shift, shift );
        my ( $names, $coderef ) = &$parse_mm_args;
        for my $name ( @$names ) {
            my $orig = $get_orig->( $caller, $name );
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

1;
__END__

=pod

=head1 NAME

MyTest::Mite - shim to load .mite.pm files

=head1 DESCRIPTION

This is a copy of L<Mite::Shim>.

=head1 AUTHOR

Michael G Schwern E<lt>mschwern@cpan.orgE<gt>.

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2011-2014 by Michael G Schwern.

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut
