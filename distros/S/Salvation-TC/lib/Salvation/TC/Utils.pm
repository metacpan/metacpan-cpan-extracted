package Salvation::TC::Utils;

=head1 NAME

Salvation::TC::Utils - Дополнительные публичные функции L<Salvation::TC>

=head1 SYNOPSIS

    use Salvation::TC::Utils;

    subtype 'CustomString',
        as 'Str',
        where { $_ eq 'asd' };

    subtype 'ArrayRefOfCustomStrings',
        as 'ArrayRef[CustomString]',
        where {};

    coerce 'ArrayRefOfCustomStrings',
        from 'CustomString',
        via { [ $_ ] };

    type 'CustomTopLevelType',
        where { ( ref( $_ ) eq 'HASH' ) && exists $_ -> { 'asd' } };

    enum 'RGB', [ 'red', 'green', 'blue' ];

    no Salvation::TC::Utils;

    Salvation::TC -> is( 'asd', 'CustomString' ); # true
    Salvation::TC -> is( 'qwe', 'CustomString' ); # false

    Salvation::TC -> is( 'green', 'RGB' ); # true
    Salvation::TC -> is( 'white', 'RGB' ); # false

    Salvation::TC -> coerce( 'asd', 'ArrayRefOfCustomStrings' ); # [ 'asd' ]
    Salvation::TC -> coerce( 'qwe', 'ArrayRefOfCustomStrings' ); # 'qwe'

    Salvation::TC -> ensure( 'asd', 'ArrayRefOfCustomStrings' ); # [ 'asd' ]
    Salvation::TC -> ensure( 'qwe', 'ArrayRefOfCustomStrings' ); # BOOM

    Salvation::TC -> assert( { asd => 123 }, 'CustomTopLevelType' ); # true
    Salvation::TC -> assert( { qwe => 123 }, 'CustomTopLevelType' ); # BOOM

=head1 SEE ALSO

L<Moose::Manual::Types>

=cut

use strict;
use warnings;
use boolean;

use Salvation::TC ();
use Salvation::TC::Exception::WrongType ();
use List::MoreUtils 'uniq';

require Exporter;

our @ISA = ( 'Exporter' );

our %EXPORT_TAGS = (
    coerce => [
        'coerce',
        'from',
        'via',
    ],
    type => [
        'type',
        'where',
    ],
    subtype => [
        'subtype',
        'as',
        'where',
    ],
    enum => [
        'enum',
    ],
);

our @EXPORT = uniq( map( { @$_ } values( %EXPORT_TAGS ) ) );

our @EXPORT_OK = @EXPORT;

$EXPORT_TAGS{ 'all' } = \@EXPORT_OK;

=head1 METHODS

=cut

=head2 coerce( Str $to, Salvation::TC::Meta::Type :$from!, CodeRef :$how! )

Объявляет новое правило приведения типа. Предполагаемое использование:

    coerce 'DestTypeName',
        from 'SourceTypeName',
        via { do_something_with( $_ ) };

Блок кода, переданный в C<via>, будет содержать в C<$_> значение типа
C<SourceTypeName>, и должен вернуть значение типа C<DestTypeName>.

Каждое правило приведения - глобальное, и доступно по всему коду сразу после
определения правила.

При попытке привести значение к типу будет выбрано первое подходящее правило
приведения. Например, если объявлено два правила:

    coerce 'Something',
        from 'Str',
        via { ... };

    coerce 'Something',
        from 'Int',
        via { ... };

, и происходит попытка привести к типу C<Something> значение типа C<Int>, то
с указанными выше правилами будет выполнено приведение по правилу для типа C<Str>,
так как значение типа C<Int> подходит и к типу C<Str>. Если поменять правила
местами, вот так:

    coerce 'Something',
        from 'Int',
        via { ... };

    coerce 'Something',
        from 'Str',
        via { ... };

, то поведение будет более ожидаемым: при попытке привести к типу C<Something>
значение типа C<Int> будет выполнено приведение именно по правилу для типа C<Int>:
это правило встречается раньше, чем правило приведения для типа C<Str>,
и приводимое значение подходит под требуемый правилом тип.

Объявление правил приведения одних стандартных типов к другим стандартным типам
напрямую крайне не рекомендуется. Best practice для подобных случаев:

    subtype 'MyCustomArrayOfStrings',
        as 'ArrayRef[Str]',
        where {}; # не проводить дополнительных проверок

    coerce 'MyCustomArrayOfStrings',
        from 'Str',
        via { [ $_ ] };

=cut

sub coerce {

    my ( $to, %params ) = @_;

    Salvation::TC -> get( $to ) -> add_coercion( @params{ 'from', 'how' } );

    return;
}

=head2 from( Str $type )

=cut

sub from( $ ) { ## no critic (ProhibitSubroutinePrototypes)

    my ( $type ) = @_;

    return ( from => Salvation::TC -> get( $type ) );
}

=head2 via( CodeRef $code )

=cut

sub via( & ) { ## no critic (ProhibitSubroutinePrototypes)

    my ( $code ) = @_;

    return ( how => $code );
}

=head2 type( Str $name, CodeRef :$validator! )

Объявляет новый тип верхнего уровня (без родительского типа). Предполагаемое
использование:

    type 'NewTypeName',
        where { check_value_and_return_true_or_false( $_ ) };

Блок кода, переданный во C<where>, будет содержать в C<$_> значение, которое
необходимо проверить на соответствие объявляемому типу, и должен вернуть
C<true> если значение подходит по тип, или C<false>, если значение не подходит.

Имея в распоряжении стандартные типы системы типов L<Moose>
(L<Moose::Manual::Types>), вместо C<type> всегда достаточно использовать
C<subtype>, что сохранит отношения между типами и не потребует дублирования
кода самой проверки.

=cut

sub type {

    my ( $name, %params ) = @_;

    die( "Type ${name} is already present" ) if( Salvation::TC -> get_type( $name ) );

    Salvation::TC -> setup_type( $name, validator => $params{ 'validator' } -> ( $name ) );
}

=head2 where( CodeRef $code )

=cut

sub where( & ) { ## no critic (ProhibitSubroutinePrototypes)

    my ( $code ) = @_;

    return ( validator => sub {

        my ( $type_name ) = @_;

        return sub {

            local $_ = $_[ 0 ];

            $code -> () || Salvation::TC::Exception::WrongType -> throw(
                type => $type_name, value => $_
            );
        };
    } );
}

=head2 subtype( Str $name, Salvation::TC::Meta::Type :$parent!, CodeRef :$validator! )

Объявляет новый тип, наследуемый от другого, уже существующего, типа.
Предполагаемое использование:

    subtype 'ChildTypeName',
        as 'ParentTypeName',
        where { check_value_and_return_true_or_false( $_ ) };

Блок кода, переданный во C<where>, будет содержать в C<$_> значение, которое
необходимо проверить на соответствие объявляемому типу, и должен вернуть
C<true> если значение подходит по тип, или C<false>, если значение не подходит.

Технически сначала будет выполнена проверка значения на соответствие
родительскому типу, и только если эта проверка прошла успешно - будет
выполнена проверка соответствия дочернему типу. Это гарантирует, что в C<$_>
у C<where> типа C<ChildTypeName> всегда будет находиться значение типа
C<ParentTypeName>.

=cut

sub subtype {

    my ( $name, %params ) = @_;

    die( "Type ${name} is already present" ) if( Salvation::TC -> get_type( $name ) );

    Salvation::TC -> setup_type( $name => (
        validator => $params{ 'validator' } -> ( $name ),
        parent => $params{ 'parent' },
    ) );
}

=head2 as( Str $type )

=cut

sub as( $ ) { ## no critic (ProhibitSubroutinePrototypes)

    my ( $type ) = @_;

    return ( parent => Salvation::TC -> get( $type ) );
}

=head2 enum( Str $name, ArrayRef[Str] $values )

Хэлпер для создания enum'ов значений типа C<Str>. Пример использования:

    enum 'RGB', [ 'red', 'green', 'blue' ];

=cut

sub enum {

    my ( $name, $values ) = @_;

    subtype $name,
        as 'Str',
        where {
            my $input = $_;

            foreach ( @$values ) {

                return true if( $_ eq $input );
            }

            return false;
        };
}

1;

__END__
