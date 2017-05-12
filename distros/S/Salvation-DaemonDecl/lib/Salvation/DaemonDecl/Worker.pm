package Salvation::DaemonDecl::Worker;

=head1 NAME

Salvation::DaemonDecl::Worker - Класс воркера для демона на базе L<Salvation::DaemonDecl>

=cut

use strict;
use warnings;


=head1 METHODS

=cut

=head2 new( Str :name!, CodeRef :main!, Int :max_instances!, CodeRef :log, Salvation::DaemonDecl::Transports :transport, CodeRef :reap, CodeRef :wrapper )

Конструктор.

Внутренний метод.

=cut

sub new {

    my ( $proto, %args ) = @_;

    return bless( \%args, ( ref( $proto ) || $proto ) );
}

=head2 parent()

Возвращает идентификатор процесса родителя.

=cut

sub parent {

    my ( $self ) = @_;

    return $self -> { 'parent' };
}

=head2 name()

Возвращает имя текущего воркера.

=cut

sub name {

    my ( $self ) = @_;

    return $self -> { 'name' };
}

=head2 get_meta()

Возвращает описание текущего демона.

Внутренний метод.

=cut

sub get_meta {

    my ( $self ) = @_;

    return $self -> { 'meta' };
}

=head2 write_to_parent( Str data )

Отправляет данные в процессу родителя.

=cut

sub write_to_parent {

    my ( $self, $data ) = @_;

    return $self -> backend_class() -> write_to( $self -> get_meta(), $self -> parent(), $data );
}

=head2 read_from_parent( Int len, CodeRef cb )

Читает данные из процесса родителя и выполняет коллбэк.

=cut

sub read_from_parent {

    my ( $self, $len, $cb ) = @_;

    return $self -> backend_class() -> read_from( $self -> get_meta(), $self -> parent(), $len, $cb );
}

=head2 main( ArrayRef args? )

Точка входа в воркер.

Внутренний метод.

=cut

sub main {

    my ( $self, $args ) = @_;

    my $main = sub {

        $self -> { 'main' } -> ( $self, ( defined $args ? @$args : () ) );
    };

    if( exists $self -> { 'wrapper' } ) {

        $self -> { 'wrapper' } -> ( $self, $main );

    } else {

        $main -> ();
    }

    return;
}

=head2 log( ... )

Логирующая функция.

=cut

sub log {

    my ( $self, @rest ) = @_;

    if( exists $self -> { 'log' } ) {

        $self -> { 'log' } -> ( @rest );
    }

    return;
}

=head2 attr( Str key, Any value? )

Функция, позволяющая запоминать информацию в рамках воркера.

Если передан аргумент C<value> - устанавливает его значением для ключа C<key>,
иначе - возвращает текущее значение ключа.

=cut

sub attr {

    my ( $self, $key, $value ) = @_;

    if( scalar( @_ ) > 2 ) {

        return $self -> { 'ctx' } -> { $key } = $value;
    }

    return $self -> { 'ctx' } -> { $key };
}

=head2 backend_class()

=cut

sub backend_class { 'Salvation::DaemonDecl::Backend' }

1;

__END__
