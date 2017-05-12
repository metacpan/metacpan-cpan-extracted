package Salvation::DaemonDecl;

=head1 NAME

Salvation::DaemonDecl - Сахар для создания и разработки демонов

=head1 DESCRIPTION

Система призвана сделать разработку демонов более простой, скрывая от
разработчика необходимые действия для порождения воркеров, коммуникации
между воркерами, обработки событий завершения воркеров и иной рутины.

=head1 SYNOPSIS

# TODO

=cut

use strict;
use warnings;

use Sub::Prototype 'set_prototype';
use B::Hooks::EndOfScope 'on_scope_end';
use Salvation::DaemonDecl::Backend ();

our $VERSION = 0.03;

=head1 METHODS

=cut

my @backend_methods = (
    'can_spawn_worker',
    'spawn_worker',
    'daemon_main',
    'write_to',
    'read_from',
    'has_alive_workers',
    'count_alive_workers',
    'wait_all_workers',
    'wait_worker_slot',
);

my @sugar_methods = (
    'worker',
    'wrapper',
    'name',
    'main',
    'max_instances',
    'log',
    'reap',
    'rw',
    'ro',
    'wo',
    'wait_cond',
);

=head2 import

Экспортирует функции сахара.

=cut

sub import {

    my ( $self, @required_methods ) = @_;
    my $caller = caller();

    my @tmp = ();

    while( defined( my $node = shift( @required_methods ) ) ) {

        if( $node eq '-to' ) {

            $caller = shift( @required_methods );

        } else {

            push( @tmp, $node );
        }
    }

    @required_methods = @tmp;
    undef @tmp;

    my %required_methods = map( { $_ => 1 } @required_methods );
    my $import_all = ( scalar( @required_methods ) == 0 );

    foreach my $name ( @backend_methods ) {

        next unless( $import_all || exists $required_methods{ $name } );

        my $method = "${caller}::${name}";

        no strict 'refs';
        no warnings 'once';

        *$method = sub {

            local *__ANON__ = $name;

            return $self -> backend_class() -> $name(
                $self -> backend_class() -> get_meta( $caller ), @_
            );
        };
    }

    my %prototypes = (
        worker => '$',
        wrapper => '&',
        name => '$',
        main => '&',
        max_instances => '$',
        log => '&',
        reap => '&',
        rw => '',
        ro => '',
        wo => '',
    );

    foreach my $name ( @sugar_methods ) {

        next unless( $import_all || exists $required_methods{ $name } );

        my $method = "${caller}::${name}";
        my $target = "ext_${name}";

        no strict 'refs';
        no warnings 'once';

        my $code = sub {

            local *__ANON__ = $name;

            $self -> $target( $caller, @_ );
        };

        set_prototype( $code, $prototypes{ $name } ) if( exists $prototypes{ $name } );

        *$method = $code;
    }

    on_scope_end {

        my $ns = "${caller}::";

        foreach my $name ( @backend_methods, @sugar_methods ) {

            next unless( $import_all || exists $required_methods{ $name } );

            no strict 'refs';

            delete $$ns{ $name };
        }
    };

    return;
}

=head2 worker

Алиас для C<Salvation::DaemonDecl::Backend::add_worker>.

=cut

sub ext_worker {

    my ( $self, $class, $descr ) = @_;

    $self -> backend_class() -> add_worker(
        $self -> backend_class() -> get_meta( $class ) => $descr
    );

    return;
}

=head2 wrapper

Сахар для указания параметра C<wrapper> воркера.

=cut

sub ext_wrapper {

    my ( $self, $class, $code ) = @_;

    return ( wrapper => $code );
}

=head2 name

Сахар для указания параметра C<name> воркера.

=cut

sub ext_name {

    my ( $self, $class, $name ) = @_;

    return ( name => $name );
}

=head2 main

Сахар для указания параметра C<main> воркера.

=cut

sub ext_main {

    my ( $self, $class, $code ) = @_;

    return ( main => $code );
}

=head2 max_instances

Сахар для указания параметра C<max_instances> воркера.

=cut

sub ext_max_instances {

    my ( $self, $class, $num ) = @_;

    return ( max_instances => $num );
}

=head2 log

Сахар для указания параметра C<log> воркера.

=cut

sub ext_log {

    my ( $self, $class, $code ) = @_;

    return ( log => $code );
}

=head2 reap

Сахар для указания параметра C<reap> воркера.

=cut

sub ext_reap {

    my ( $self, $class, $code ) = @_;

    return ( reap => $code );
}

=head2 rw

Сахар для установки параметра C<transport> воркера в значение C<TRANSPORT_R | TRANSPORT_W>.

=cut

sub ext_rw {

    my ( $self, $class ) = @_;

    return ( transport => (
        Salvation::DaemonDecl::Backend::TRANSPORT_R
        | Salvation::DaemonDecl::Backend::TRANSPORT_W
    ) );
}

=head2 ro

Сахар для установки параметра C<transport> воркера в значение C<TRANSPORT_R>.

=cut

sub ext_ro {

    my ( $self, $class ) = @_;

    return ( transport => Salvation::DaemonDecl::Backend::TRANSPORT_R );
}

=head2 wo

Сахар для установки параметра C<transport> воркера в значение C<TRANSPORT_W>.

=cut

sub ext_wo {

    my ( $self, $class ) = @_;

    return ( transport => Salvation::DaemonDecl::Backend::TRANSPORT_W );
}

=head2 wait_cond( AnyEvent::CondVar cv )

Выполняет прерываемый C<$cv -> recv()>.

=cut

sub ext_wait_cond {

    my ( $self, $class, $cv ) = @_;

    return $self -> backend_class() -> wait_cond( $cv );
}

=head2 backend_class()

=cut

sub backend_class { 'Salvation::DaemonDecl::Backend' }

1;

__END__
