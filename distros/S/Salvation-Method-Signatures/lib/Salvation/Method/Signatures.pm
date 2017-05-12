package Salvation::Method::Signatures;

=head1 NAME

Salvation::Method::Signatures - Реализация сигнатур для методов

=head1 SYNOPSIS

    package Some::Package;

    use Salvation::Method::Signatures;
    # use Test::More tests => 3;

    method process( ArrayRef[ArrayRef[Str]] :flags!, ArrayRef[HashRef(Int :id!)] :data! ) {

        # isa_ok( $self, 'Some::Package' );
        # is_deeply( $flags, [ [ 'something' ] ] );
        # is_deeply( $data, [ { id => 1 } ] );

        ...
    }

    package main;

    Some::Package -> process(
        flags => [ [ 'something' ] ],
        data => [ { id => 1 } ],
    );

=head1 DESCRIPTION

Делает то же, что делают другие реализации сигнатур: проверяет тип аргументов
метода, само разбирает C<@_> и инжектит переменные в блок.

=head1 SEE ALSO

http://perlcabal.org/syn/S06.html#Signatures
L<MooseX::Method::Signatures>
L<Method::Signatures>

=cut

use strict;
use warnings;
use boolean;

use B ();
use Module::Load 'load';
use Salvation::UpdateGvFLAGS ();

use base 'Devel::Declare::MethodInstaller::Simple';

our $VERSION = 0.04;

=head1 METHODS

=cut

=head2 type_system_class()

=cut

sub type_system_class {

    return 'Salvation::TC';
}

=head2 token_str()

=cut

sub token_str {

    return 'method';
}

=head2 self_var_name()

=cut

sub self_var_name {

    return '$self';
}

=head2 import()

Экспортирует магическое ключевое слово.

Подробнее: L<Devel::Declare>.

=cut

sub import {

    my ( $self ) = @_;
    my $caller = caller();

    $self -> install_methodhandler(
        name => $self -> token_str(),
        into => $caller,
    );

    return;
}

{
    my %installed_methods = ();

=head2 strip_name()

Обёртка вокруг L<Devel::Declare#strip_name>.

Делает всё то же самое, но дополнительно запоминает, в каком модуле какие
методы были объявлены с использованием L<DirectMod::Method::Signatures>.

Внутренний метод.

=cut

    sub strip_name {

        my ( $self, @rest ) = @_;
        my $name = $self -> SUPER::strip_name( @rest );

        push( @{ $installed_methods{ $self -> { 'into' } } }, $name );

        return $name;
    }

=head2 mark_methods_as_not_imported( Str class )

Маркирует все методы класса C<class>, объявленные с использованием
L<DirectMod::Method::Signatures>, как "не импортированные".

Внутренний метод.

=cut

    sub mark_methods_as_not_imported {

        my ( $self, $class ) = @_;
        my $imported_cv = ( eval { B::GVf_IMPORTED_CV() } || 0x80 );

        no strict 'refs';

        foreach my $method ( @{ $installed_methods{ $class } // [] } ) {

            my $name = "${class}::${method}";
            my $obj = B::svref_2object( \*$name );

            if( $obj -> GvFLAGS() & $imported_cv ) {

                Salvation::UpdateGvFLAGS::toggle_glob_flag_by_name( $name, $imported_cv );
            }
        }

        return;
    }
}

=head2 parse_proto( Str $str )

Разбирает прототип метода, генерирует код и инжектит этот код в метод.

Подробнее: L<Devel::Declare>.

=cut

sub parse_proto {

    my ( $self, $str ) = @_;
    load my $type_system_class = $self -> type_system_class();
    my $type_parser = $type_system_class -> get_type_parser();
    my $sig = ( ( $str =~ m/^\s*$/ )
        ? { data => [], opts => {} }
        : $type_parser -> tokenize_signature_str( "(${str})", {} )
    );
    ( $sig, my $opts ) = @$sig{ 'data', 'opts' };

    my @positional_vars = ( $self -> self_var_name() );
    my $code = '';
    my $pos  = 0;
    my $prev_was_optional = false;

    my $wrap_check = sub {

        my ( $code, $param_name ) = @_;

        return sprintf(
            '( eval{ local $Carp::CarpLevel = 2; %s } || die( "Validation for parameter \"%s\" failed because:\n$@" ) )',
            $code,
            $param_name,
        );
    };

    while( defined( my $item = shift( @$sig ) ) ) {

        if( $item -> { 'param' } -> { 'named' } ) {

            if( $prev_was_optional ) {

                die( "Error at signature (${str}): named parameter can't follow optional positional parameter" );
            }

            unshift( @$sig, $item );
            last;
        }

        my $type = $type_system_class -> materialize_type( $item -> { 'type' } );
        my $arg  = $item -> { 'param' };

        my $var = sprintf( '$%s', $arg -> { 'name' } );

        push( @positional_vars, $var );

        my $check = sprintf( '%s -> assert( %s, \'%s\' )', $type_system_class, $var, $type -> name() );

        $check = $wrap_check -> ( $check, $arg -> { 'name' } );

        if( $arg -> { 'optional' } ) {

            $prev_was_optional = true;

            $check = sprintf( '( ( scalar( @_ ) > %d ) ? %s : 1 )', 1 + $pos, $check );

        } elsif( $prev_was_optional ) {

            die( "Error at signature (${str}): required positional parameter can't follow optional one" );
        }

        $code .= $check;
        $code .= ';';

        $type_system_class -> get( $type -> name() ); # прогрев кэша

        ++$pos;
    }

    my @named_vars   = ();
    my @named_params = ();
    my $named_checks = '';

    while( defined( my $item = shift( @$sig ) ) ) {

        if( $item -> { 'param' } -> { 'positional' } ) {

            die( "Error at signature (${str}): positional parameter can't follow named parameter" );
        }

        my $type = $type_system_class -> materialize_type( $item -> { 'type' } );
        my $arg  = $item -> { 'param' };

        push( @named_vars, sprintf( '$%s', $arg -> { 'name' } ) );
        push( @named_params, sprintf( '\'%s\'', $arg -> { 'name' } ) );

        my $check = sprintf( '%s -> assert( $args{ \'%s\' }, \'%s\' )', $type_system_class, $arg -> { 'name' }, $type -> name() );

        $check = $wrap_check -> ( $check, $arg -> { 'name' } );

        if( $arg -> { 'optional' } ) {

            $prev_was_optional = true;

            $check = sprintf( '( exists( $args{ \'%s\' } ) ? %s : 1 )', $arg -> { 'name' }, $check );
        }

        $named_checks .= $check;
        $named_checks .= ';';
    }

    my $named_vars_code = '';

    if( $named_checks ) {

        if( $opts -> { 'strict' } ) {

            $named_vars_code = sprintf( '( my ( %s ) = do {

                no warnings \'syntax\';

                if( scalar( () = @_[ %d .. $#_ ] ) %% 2 ) {
                    die( "Too many positional parameters" );
                }
                my %%args = @_[ %d .. $#_ ]; %s my @l = delete( @args{ %s } );
                if( scalar( keys( %%args ) ) > 0 ) {
                    die( "Unexpected named parameters found: " . join( ", ", keys( %%args ) ) );
                }
                @l;

            } );', join( ', ', @named_vars ), ( scalar( @positional_vars ) )x2, $named_checks, join( ', ', @named_params ) );

        } else {

            $named_vars_code = sprintf( '( my ( %s ) = do {

                no warnings \'syntax\';

                if( scalar( () = @_[ %d .. $#_ ] ) %% 2 ) {
                    die( "Too many positional parameters" );
                }
                my %%args = @_[ %d .. $#_ ]; %s @args{ %s };

            } );', join( ', ', @named_vars ), ( scalar( @positional_vars ) )x2, $named_checks, join( ', ', @named_params ) );
        }

    } elsif( $opts -> { 'strict' } ) {

        $named_vars_code = sprintf( 'if( scalar( @_ ) > %d ) {
            die( "Too many positional parameters" );
        }', scalar( @positional_vars ) );
    }

    $code = sprintf( 'my ( %s ) = @_; %s %s local @_ = ();', join( ', ', @positional_vars ), $code, $named_vars_code );

    $code =~ s/\n/ /g;
    $code =~ s/\s{2,}/ /g;

    return $code;
}

1;

__END__
