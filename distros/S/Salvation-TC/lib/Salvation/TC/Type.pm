package Salvation::TC::Type;

=head1 NAME

    Salvation::TC::Type - базовый класс для всех типов.

=head1 SYNOPSIS

    use Salvation::TC::Type;

    eval { Salvation::TC::Type::SomeType -> Check( $value ) };

    if( $@ ) {

        warn( $@ -> getMessage() );
    };

=head1 DESCRIPTION
=cut

use strict;
use Salvation::TC::Exception::WrongType;

=head2 Check
    Проверяет синтакcис значения согласно правилам, описанным в типе данных.

    Принимает следующие параметры:
      $class - имя своего пакета
      $value - значение переменной $name
      $object - некий объект, необязательный параметр для проверки сложных значений (например по типу записи DNS - A, AAA, NS, MX, etc).
                реализация таких проверок должна быть реализована в пакете, отвечающем за проверку данного значения

      В случае ошибки синтаксиса $value будет брошен exception с типом Salvation::TC::Exception::WrongType (возможны исключения, за деталями смотрите пакет,
      отвечающий за проверку нужного типа данных).
=cut

1;
__END__
