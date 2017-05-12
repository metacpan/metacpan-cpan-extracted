package Salvation::TC;

=head1 NAME

Salvation::TC - Type Constraint, система проверки типов значений.

=head1 SYNOPSIS

    Salvation::TC -> is( 'asd', 'Str' );
    Salvation::TC -> is( 123, 'Int' );
    Salvation::TC -> is( 123.45, 'Num' );
    Salvation::TC -> is( [], 'ArrayRef' );
    Salvation::TC -> is( [ 1, 2, "asd" ], 'ArrayRef[Int|Str]' );

    Salvation::TC -> assert( [ { a => undef, b => 1 } ], 'ArrayRef[HashRef[Maybe[Int]]]' );
    Salvation::TC -> assert( DBScheme::Image -> search_one([]), 'DBScheme' );

    Salvation::TC -> assert( { asd => 1 }, 'HashRef(Int :asd!, ArrayRef[Int] :list)' ); # OK
    Salvation::TC -> assert( { asd => 1, list => [ 2 ] }, 'HashRef(Int :asd!, ArrayRef[Int] :list)' ); # OK
    Salvation::TC -> assert( { qwe => 1 }, 'HashRef(Int :asd!, ArrayRef[Int] :list)' ); # FAIL

    Salvation::TC -> assert( [ { asd => [], qwe => 1 } ], 'ArrayRef[HashRef(Int :qwe!)](HashRef(ArrayRef :asd!) el)' ); # OK

=head1 SEE ALSO

L<Moose::Manual::Types>

http://perlcabal.org/syn/S06.html#Signatures

=cut

use strict;
use warnings;
use boolean;

use Carp 'confess';
use Module::Load ();
use Scalar::Util 'blessed';
use Class::Inspector ();
use Devel::PartialDump ();

use Salvation::TC::Parser ();
use Salvation::TC::Meta::Type ();
use Salvation::TC::Meta::Type::Maybe ();
use Salvation::TC::Meta::Type::Union ();
use Salvation::TC::Exception::WrongType ();

our $VERSION = 0.12;


=head1 METHODS

=cut

=head2 init_regular_cases()

Инициализирует и кэширует самые частые кейсы.

=cut

sub init_regular_cases {

    my ( $self ) = @_;

    my %table = (
        Int => 'Number::Integer',
        Num => 'Number::Float',
    );

    while( my ( $alias, $type ) = each( %table ) ) {

        $type = $self -> get( $type );

        $self -> setup_type( $alias,
            validator => $type -> validator(),
            signed_type_generator => $type -> signed_type_generator(),
            length_type_generator => $type -> length_type_generator(),
        );
    }

    foreach my $type (
        'Any',
        'ArrayRef',
        'Bool',
        'CodeRef',
        'Date::Reverse',
        'Date',
        'Defined',
        'HashRef',
        'Object',
        'Ref',
        'SessionId',
        'Str',
        'Text::English',
        'Text',
        'Time',
        'Undef',
        'ScalarRef',
    ) {

        $self -> get( $type );
    }

    return;
}

{
    my $table = undef;

=head2 get_known_types()

Возвращает таблицу известных базовых валидаторов и генератором для них.

=cut

    sub get_known_types {

        my ( $self ) = @_;

        return $table //= [
            [ 'Salvation::TC::Type' => {
                validator => sub {
                    $self -> gen_salvation_tc_type_validator( @_ );
                },
                signed_type_generator => sub {
                    $self -> gen_salvation_tc_type_signer( @_ );
                },
                length_type_generator => sub {
                    $self -> gen_salvation_tc_type_length_check( @_ );
                }
            } ],
        ];
    }
}

=head2 gen_salvation_tc_type_validator( Str $class )

Генератор валидаторов значений на основе L<Salvation::TC::Type>.

Возвращает CodeRef, являющийся валидатором, соответствующий следующей сигнатуре:

    ( Any $value )

, где:

=over

=item $value

Валидируемое значение.

Обязательный параметр.

=back

Если значение не подходит - валидатор бросает исключение
L<Salvation::TC::Exception::WrongType>.

Описание аргументов:

=over

=item $class

Имя класса типа.

Обязательный параметр.

=back

=cut

sub gen_salvation_tc_type_validator {

    my ( $self, $class ) = @_;

    return sub {

        $class -> Check( $_[ 0 ] );
    };
}

=head2 gen_salvation_tc_type_signer( Str $class )

Генератор валидаторов значений на основе подписанных L<Salvation::TC::Type>.

Возвращает CodeRef, являющийся валидатором, соответствующий следующей сигнатуре:

    ( Any $value )

, где:

=over

=item $value

Валидируемое значение.

Обязательный параметр.

=back

Если значение не подходит - валидатор бросает исключение
L<Salvation::TC::Exception::WrongType>.

Описание аргументов:

=over

=item $class

Имя класса типа.

Обязательный параметр.

=back

=cut

sub gen_salvation_tc_type_signer {

    my ( $self, $class ) = @_;

    return undef unless( $class -> can( 'create_validator_from_sig' ) );

    return sub {

        $class -> create_validator_from_sig( @_[ 0, 1 ] );
    };
}

=head2 gen_salvation_tc_type_length_check( Str $class )

Генератор валидаторов значений на основе L<Salvation::TC::Type>, ограниченных
под длине.

Возвращает CodeRef, являющийся валидатором, соответствующий следующей сигнатуре:

    ( Any $value )

, где:

=over

=item $value

Валидируемое значение.

Обязательный параметр.

=back

Если значение не подходит - валидатор бросает исключение
L<Salvation::TC::Exception::WrongType>.

Описание аргументов:

=over

=item $class

Имя класса типа.

Обязательный параметр.

=back

=cut

sub gen_salvation_tc_type_length_check {

    my ( $self, $class ) = @_;

    return undef unless( $class -> can( 'create_length_validator' ) );

    return sub {

        $class -> create_length_validator( @_[ 0, 1 ] );
    };
}

=head2 gen_class_type_validator( Str $class )

Генератор валидаторов значений, являющихся экземпярами классов.

Возвращает CodeRef, являющийся валидатором, соответствующий следующей сигнатуре:

    ( Any $value )

, где:

=over

=item $value

Валидируемое значение.

Обязательный параметр.

=back

Если значение не подходит - валидатор бросает исключение
L<Salvation::TC::Exception::WrongType>.

Описание аргументов:

=over

=item $class

Имя класса типа.

Обязательный параметр.

=back

=cut

sub gen_class_type_validator {

    my ( $self, $class ) = @_;

    return sub {

        ( defined $_[ 0 ] && blessed $_[ 0 ] && $_[ 0 ] -> isa( $class ) )
        || Salvation::TC::Exception::WrongType -> throw(
            type => $class, value => $_[ 0 ]
        )
    };
}

{
    my %TYPE;

=head2 setup_type( Str $name, @rest )

Инициализирует класс для класса типа.

Описание аргументов:

=over

=item $name

Имя типа.

Обязательный параметр.

=item @rest

Иные, сопутствующие типу параметры (пары ключ-значение). Основные параметры типа:

=over

=item validator

CodeRef, функция-валидатор.

=back

=back

=cut

    sub setup_type {

        my ( $self, $name, @rest ) = @_;

        return $TYPE{ ref( $self ) || $self } -> { $name } //= $self -> simple_type_class_name() -> new( @rest, name => $name );
    }

=head2 simple_type_class_name()

=cut

sub simple_type_class_name {

    return 'Salvation::TC::Meta::Type';
}

=head2 setup_maybe_type( Str $name, @rest )

=cut

    sub setup_maybe_type {

        my ( $self, $name, @rest ) = @_;

        return $TYPE{ ref( $self ) || $self } -> { $name } //= $self -> maybe_type_class_name() -> new( @rest, name => $name );
    }

=head2 maybe_type_class_name()

=cut

sub maybe_type_class_name {

    return 'Salvation::TC::Meta::Type::Maybe';
}

=head2 setup_union_type( Str $name, @rest )

=cut

    sub setup_union_type {

        my ( $self, $name, @rest ) = @_;

        return $TYPE{ ref( $self ) || $self } -> { $name } //= $self -> union_type_class_name() -> new( @rest, name => $name );
    }

=head2 union_type_class_name()

=cut

sub union_type_class_name {

    return 'Salvation::TC::Meta::Type::Union';
}

=head2 setup_parameterized_type( Str $name, Str $class, @rest )

=cut

    sub setup_parameterized_type {

        my ( $self, $name, $class, @rest ) = @_;

        return $TYPE{ ref( $self ) || $self } -> { $name } //= $class -> new( @rest, name => $name );
    }

=head2 get_type( Str $name )

Возвращает уже созданный класс для класса типа.

Описание аргументов:

=over

=item $name

Имя типа.

Обязательный параметр.

=back

=cut

    sub get_type {

        my ( $self, $name ) = @_;

        return $TYPE{ ref( $self ) || $self } -> { $name };
    }
}

=head2 get_type_parser()

Возвращает имя класса парсера типов.

=cut

sub get_type_parser {

    return 'Salvation::TC::Parser';
}

=head2 parse_type( Str $str )

Анализирует строку и возвращает класс описанного в ней класса типа.

Если класс для этого класса типа ещё не был инициализирован - инициализирует
его.

Описание аргументов:

=over

=item $str

Строка, описывающая тип.

Обязательный параметр.

=back

=cut

sub parse_type {

    my ( $self, $str ) = @_;

    return $self -> materialize_type(
        $self -> get_type_parser() -> tokenize_type_str( $str, {} )
    );
}

=head2 materialize_type( HashRef( HashRef :opts!, ArrayRef[HashRef] :data! ) input )

Превращает токены �� классы типов.

=cut

sub materialize_type {

    my ( $self, $input ) = @_;
    my ( $opts, $tokens ) = @$input{ 'opts', 'data' };

    if( scalar( @$tokens ) == 1 ) {

        if( exists $tokens -> [ 0 ] -> { 'type' } ) {

            return $self -> get_or_create_simple_type( $tokens -> [ 0 ] -> { 'type' } );

        } elsif( exists $tokens -> [ 0 ] -> { 'maybe' } ) {

            my $type = $self -> materialize_type( $tokens -> [ 0 ] -> { 'maybe' } );
            my $name = sprintf( 'Maybe[%s]', $type -> name() );

            return ( $self -> get_type( $name ) // $self -> setup_maybe_type(
                $name, validator => $type -> validator(), base => $type,
            ) );

        } elsif( exists $tokens -> [ 0 ] -> { 'class' } ) {

            my $base  = $self -> materialize_type( $tokens -> [ 0 ] -> { 'base' } );
            my $inner = $self -> materialize_type( $tokens -> [ 0 ] -> { 'param' } );
            my $name  = sprintf( '%s[%s]', $base -> name(), $inner -> name() );

            return ( $self -> get_type( $name ) // $self -> setup_parameterized_type(
                $name, $tokens -> [ 0 ] -> { 'class' }, base => $base,
                validator => $base -> validator(), inner => $inner,
                length_type_generator => $base -> length_type_generator(),
            ) );

        } elsif( exists $tokens -> [ 0 ] -> { 'signed' } ) {

            my $data = $tokens -> [ 0 ] -> { 'signed' };

            my $type = $self -> materialize_type( {
                opts => {},
                data => [ $data -> { 'type' } ],
            } );
            my $name = sprintf( '%s%s', $type -> name(), $data -> { 'source' } );

            my $present_type = $self -> get_type( $name );

            return $present_type if( defined $present_type );

            my ( $sig_tokens, $sig_opts ) = @{ $data -> { 'signature' } }{ 'data', 'opts' };

            foreach my $el ( @$sig_tokens ) {

                $el -> { 'type' } = $self -> materialize_type( $el -> { 'type' } );
            }

            my $method = ( $type -> isa( 'Salvation::TC::Meta::Type::Parameterized' )
                ? 'setup_parameterized_type'
                : 'setup_type' );

            return $self -> $method( $name,
                ( ( $method eq 'setup_parameterized_type' ) ? (
                    ref( $type ),
                    inner => $type -> inner(),
                ) : () ),
                validator => $type -> sign( $sig_tokens, $sig_opts ),
                length_type_generator => $type -> length_type_generator(),
                signature => $sig_tokens,
                base => $type, options => $sig_opts,
            );

        } elsif( exists $tokens -> [ 0 ] -> { 'length' } ) {

            my $data = $tokens -> [ 0 ] -> { 'length' };

            my $type = $self -> materialize_type( {
                opts => {},
                data => [ $data -> { 'type' } ],
            } );
            my $name = sprintf( '%s{%s,%s}', $type -> name(), $data -> { 'min' }, ( $data -> { 'max' } // '' ) );

            my $method = ( $type -> isa( 'Salvation::TC::Meta::Type::Parameterized' )
                ? 'setup_parameterized_type'
                : 'setup_type' );

            return ( $self -> get_type( $name ) // $self -> $method( $name,
                ( ( $method eq 'setup_parameterized_type' ) ? (
                    ref( $type ),
                    inner => $type -> inner(),
                ) : () ),
                validator => $type -> length_checker( @$data{ 'min', 'max' } ),
                signed_type_generator => $type -> signed_type_generator(),
                ( $type -> has_signature() ? (
                    signature => $type -> signature(),
                    options => $type -> options(),
                ) : () ),
                base => $type,
            ) );

        } else {

            require Data::Dumper;

            die( 'Unknown token: ' . Data::Dumper::Dumper( $tokens ) );
        }

    } else {

        my @types = ();

        foreach my $token ( @$tokens ) {

            push( @types, $self -> materialize_type( {
                opts => {},
                data => [ $token ],
            } ) );
        }

        my $name = join( '|', map( { $_ -> name() } @types ) );

        return ( $self -> get_type( $name ) // $self -> setup_union_type(
            $name, types => \@types
        ) );
    }
}

=head2 simple_type_class_ns()

=cut

sub simple_type_class_ns {

    return 'Salvation::TC::Type';
}

=head2 get_or_create_simple_type( Str $str )

Возвращает базовый тип с именем C<$str>.

=cut

sub get_or_create_simple_type {

    my ( $self, $str ) = @_;

    my $salvation_tc_type_str = sprintf( '%s::%s', $self -> simple_type_class_ns(), $str );

    my $type = ( $self -> get_type( $str ) // $self -> get_type( $salvation_tc_type_str ) );

    return $type if( defined $type );

    {
        local $SIG{ '__DIE__' } = 'DEFAULT';

        if(
            ! Class::Inspector -> loaded( $str )
            && ! eval{ Module::Load::load( $str ); 1 }
            && (
                Class::Inspector -> loaded( $salvation_tc_type_str )
                || eval{ Module::Load::load( $salvation_tc_type_str ); 1 }
            )
        ) {

            $str = $salvation_tc_type_str;
        }
    }

    my $validator = undef;
    my $signed_type_generator = undef;
    my $length_type_generator = undef;

    foreach my $spec ( @{ $self -> get_known_types() } ) {

        if( $str -> isa( $spec -> [ 0 ] ) ) {

            $validator = $spec -> [ 1 ] -> { 'validator' } -> ( $str );
            $signed_type_generator = $spec -> [ 1 ] -> { 'signed_type_generator' } -> ( $str );
            $length_type_generator = $spec -> [ 1 ] -> { 'length_type_generator' } -> ( $str );

            last;
        }
    }

    return $self -> setup_type( $str,
        validator => ( $validator // $self -> gen_class_type_validator( $str ) ),
        signed_type_generator => $signed_type_generator,
        length_type_generator => $length_type_generator,
    );
}

{
    my %cache = ();

=head2 get( Str $constraint )

Возвращает объект для типа C<$constraint>.

=cut

    sub get {

        my ( $self, $constraint ) = @_;

        return $cache{ ref( $self ) || $self } -> { $constraint } //= $self -> parse_type( $constraint );
    }
}

=head2 is( Any $value, Str $constraint )

Проверяет, является ли C<$value> значением типа C<$constraint>.

Возвращает C<true> в случае, если является, иначе - возвращает C<false>.

=cut

sub is {

    my ( $self, $value, $constraint ) = @_;

    {
        local $SIG{ '__DIE__' } = 'DEFAULT';

        eval { $self -> get( $constraint ) -> check( $value ) };
    }

    if( $@ ) {

        if( blessed( $@ ) && $@ -> isa( 'Salvation::TC::Exception::WrongType' ) ) {

            return false;

        } else {

            die( $@ );
        }
    };

    return true;
}

=head2 assert( Any $value, Str $constraint )

Проверяет, является ли C<$value> значением типа C<$constraint>.

Возвращает C<true> в случае, если является, иначе - вызывает C<die>.

=cut

sub assert {

    my ( $self, $value, $constraint ) = @_;

    {
        local $SIG{ '__DIE__' } = 'DEFAULT';

        eval { $self -> get( $constraint ) -> check( $value ) };
    }

    if( $@ ) {

        if( blessed( $@ ) && $@ -> isa( 'Salvation::TC::Exception::WrongType' ) ) {

            confess( join( "\n", ( $self -> create_error_message( $@ ), '' ) ) );

        } else {

            die( $@ );
        }
    };

    return true;
}

=head2 create_error_message( Salvation::TC::Exception::WrongType $e )

=cut

sub create_error_message {

    my ( $self, $e ) = @_;

    my @stack = ( $e );
    my @lines = ();

    while( defined( my $node = shift( @stack ) ) ) {

        if( $node -> isa( 'Salvation::TC::Exception::WrongType::TC' ) ) {

            my $str = '';

            if( defined( my $param_name = $node -> getParamName() ) ) {

                $str = sprintf(
                    'Value %s for parameter "%s" does not match type constraint %s',
                    Devel::PartialDump -> new() -> dump( $node -> getValue() ),
                    $param_name, $node -> getType(),
                );

            } else {

                $str = sprintf(
                    'Value %s does not match type constraint %s',
                    Devel::PartialDump -> new() -> dump( $node -> getValue() ),
                    $node -> getType(),
                );
            }


            if( defined( my $prev = $node -> getPrev() ) ) {

                push( @lines, "${str} because:" );

                if( ref( $prev ) eq 'ARRAY' ) {

                    my $i = 0;

                    foreach my $e ( @$prev ) {

                        push( @lines,
                            ++$i . ': ',
                            map( { "\t$_" } $self -> create_error_message( $e ) )
                        );
                    }

                } else {

                    push( @stack, $prev );
                }

            } else {

                push( @lines, $str );
            }

        } else {

            push( @lines, sprintf(
                'Value %s does not match type constraint %s',
                Devel::PartialDump -> new() -> dump( $node -> getValue() ),
                $node -> getType(),
            ) );
        }
    }

    return @lines;
}

=head2 coerce( Any $value, Str $constraint )

Пытается привести значение C<$value> к значению типа C<$constraint>.

Если приведение прошло успешно - возвращает изменённое значение, иначе -
возвращает C<$value> без изменения*.

* Для совместимости с API Moose.

=cut

sub coerce {

    my ( $self, $value, $constraint ) = @_;

    return $self -> get( $constraint ) -> coerce( $value );
}

=head2 ensure( Any $value, Str $constraint )

Пытается привести значение C<$value> к значению типа C<$constraint>.

Если приведение прошло успешно - возвращает изменённое значение, иначе -
вызывает C<die>.

=cut

sub ensure {

    my ( $self, $value, $constraint ) = @_;

    $value = $self -> coerce( $value, $constraint );

    $self -> assert( $value, $constraint );

    return $value;
}

__PACKAGE__ -> init_regular_cases();

1;

__END__
