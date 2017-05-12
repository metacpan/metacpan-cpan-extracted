package Salvation::DaemonDecl::Backend;

=head1 NAME

Salvation::DaemonDecl::Backend - Бэкэнд для L<Salvation::DaemonDecl>

=cut

use strict;
use warnings;
use boolean;
use feature 'state';

# BEGIN {
#
#     require Carp;
#
#     $SIG{ __WARN__ } = \&Carp::cluck;
# };

use POSIX ':sys_wait_h', 'SIGTERM';
use Socket 'AF_UNIX', 'SOCK_STREAM', 'PF_UNSPEC';
use AnyEvent ();
use AnyEvent::Handle ();
use Salvation::DaemonDecl::Worker ();

use Salvation::Method::Signatures;

use constant {

    TRANSPORT_R => 1,
    TRANSPORT_W => 2,

    TUN_PREFIX_DISCOVERY_REQUEST => 'D',
    TUN_PREFIX_DISCOVERY_REPLY => 'd',
    TUN_PREFIX_DATA_REQUEST => 'R',

    TUN_NEAR => 1,
    TUN_FAR => 2,
};

use Salvation::TC::Utils;

BEGIN {

    enum 'Salvation::DaemonDecl::Transports', [
        TRANSPORT_R,
        TRANSPORT_W,
        TRANSPORT_R | TRANSPORT_W,
    ];
};

no Salvation::TC::Utils;

=head1 METHODS

=cut

{
    my %daemons;

=head2 get_meta( Str class )

Возвращает HashRef, представляющий описание демона.

Если описания для конкретного демона ещё нет - оно будет создано.

=cut

    sub get_meta {

        my ( $self, $class ) = @_;

        return $daemons{ $class } //= {
            name => $class,
            dead => [],
            pipes => {},
            routes => {},
            tunnels => {},
            workers => {},
            instances => {
                $$ => {
                    name => '.',
                    pid => $$,
                }
            },
            condvar => undef,
            tmp_tunnel_prefixes => {
                $$ => {},
            },
            signals_reinstalled => false,
            signals => [],
            non_zero_exit_statuses_count => 0,
        };
    }
}

=head2 add_worker( HashRef meta, HashRef( Str :name!, CodeRef :main!, Int :max_instances!, CodeRef :log, Salvation::DaemonDecl::Transports :transport, CodeRef :reap, CodeRef :wrapper ) descr )

Добавляет новый воркер к описанию демона.

Воркер характеризуется следующими параметрами:

=over

=item name

Строка, представляющая имя воркера.

Обязательный параметр.

=item main

Функция, представляющая основной код воркера, соверщающий одну итерацию и
передающий управление вызвавшему его коду.

В эту функцию первым параметром будет передан экземпляр класса
L<Salvation::DaemonDecl::Worker>, соответствующий текущему воркеру, а далее -
параметры, переданные воркеру при запуске.

В этой функции ни в коем случае не должно быть вечных циклов или вечного ожидания.

Обязательный параметр.

=item max_instances

Целое число, представляющее максимальное количество экземпляров конкретного
воркера, которое может существовать единовременно.

Обязательный параметр.

=item log

Функция для логирования сообщений от воркера.

=item transport

Битовая маска, представляющая собой способность воркера к общению с внешним миром.

Составляющие биты (далее перечислены константы):

=over

=item TRANSPORT_R

Воркер может принимать сообщения из внешнего мира.

=item TRANSPORT_W

Воркер может отправлять сообщения во внешний мир.

=back

=item reap

Функция, представляющая код, выполняющийся в родительском процессе в момент,
когда воркер завершается.

Первым аргументом функция получает идентификатор процесса завершившегося
воркера.

=item wrapper

Функция, представляющая обёртку вокруг кода, переданного в C<main>.

Если необходимо, чтобы основной код воркера выполнялся в вечном цикле или
содержал вечное ожидание - это должно быть сделано в данной функции.

Первым параметром в функцию будет передан экземпляр класса
L<Salvation::DaemonDecl::Worker>, соответствующий текущему воркеру, вторым -
CodeRef, представляющий основной код воркера, не принимающий никаких параметров.

=back

=cut

method add_worker( HashRef meta, HashRef(
    Str :name!, CodeRef :main!, Int :max_instances!, CodeRef :log,
    Salvation::DaemonDecl::Transports :transport, CodeRef :reap, CodeRef :wrapper
) descr ) {

    if( exists $meta -> { 'workers' } -> { $descr -> { 'name' } } ) {

        die( sprintf( 'Daemon %s already has worker %s', $meta -> { 'name' }, $descr -> { 'name' } ) );
    }

    $meta -> { 'workers' } -> { $descr -> { 'name' } } = {
        instances => 0,
        condvar => undef,
        descr => $descr,
    };

    return;
}

=head2 can_spawn_worker( HashRef meta, Str worker )

Возвращает C<true>, если может быть порождён ещё один конкретный воркер, или
C<false>, если воркер не может быть порождён.

=cut

method can_spawn_worker( HashRef meta, Str worker ) {

    unless( exists $meta -> { 'workers' } -> { $worker } ) {

        die( sprintf( 'Daemon %s has no worker %s', $meta -> { 'name' }, $worker ) );
    }

    my $worker_meta = $meta -> { 'workers' } -> { $worker };

    return ( $worker_meta -> { 'instances' } < $worker_meta -> { 'descr' } -> { 'max_instances' } );
}

=head2 has_alive_workers( HashRef meta, Str worker? )

Возвращает C<true>, если может быть порождён ещё один конкретный воркер, или
C<false>, если воркер не может быть порождён.

Если имя воркера не передано - ворзвращает C<true>, если есть хотя бы один
живой воркер, иначе - возвращает C<false>.

=cut

method has_alive_workers( HashRef meta, Str worker? ) {

    unless( defined $worker ) {

        my $cnt = 0;

        while( my ( undef, $data ) = each( %{ $meta -> { 'workers' } } ) ) {

            $cnt += $data -> { 'instances' };
        }

        return ( $cnt > 0 );
    }

    unless( exists $meta -> { 'workers' } -> { $worker } ) {

        die( sprintf( 'Daemon %s has no worker %s', $meta -> { 'name' }, $worker ) );
    }

    return ( $meta -> { 'workers' } -> { $worker } -> { 'instances' } > 0 );
}

=head2 count_alive_workers( HashRef meta, Str worker )

Возвращает целое число, представляющее количество активных экземпляров
конкретного воркера.

=cut

method count_alive_workers( HashRef meta, Str worker ) {

    unless( exists $meta -> { 'workers' } -> { $worker } ) {

        die( sprintf( 'Daemon %s has no worker %s', $meta -> { 'name' }, $worker ) );
    }

    return $meta -> { 'workers' } -> { $worker } -> { 'instances' };
}

=head2 wait_all_workers( HashRef meta, Str worker? )

Блокирует до тех пор, пока все воркеры не завершатся.

=cut

method wait_all_workers( HashRef meta, Str worker? ) {

    # warn "($0) wait all workers", ( defined $worker ? " (${worker})" : '' );
    if( defined $worker ) {

        unless( exists $meta -> { 'workers' } -> { $worker } ) {

            die( sprintf( 'Daemon %s has no worker %s', $meta -> { 'name' }, $worker ) );
        }

        if( defined( my $cv = $meta -> { 'workers' } -> { $worker } -> { 'condvar' } ) ) {

            $self -> wait_cond( $cv );
        }

    } else {

        if( defined( my $cv = $meta -> { 'condvar' } ) ) {

            $self -> wait_cond( $cv );
        }
    }

    return;
}

=head2 wait_worker_slot( HashRef meta, Str worker )

Блокирует до тех пор, пока хотя бы один конкретный воркер не завершится.

=cut

method wait_worker_slot( HashRef meta, Str worker ) {

    # warn "($0) wait worker slot (${worker})";
    unless( exists $meta -> { 'workers' } -> { $worker } ) {

        die( sprintf( 'Daemon %s has no worker %s', $meta -> { 'name' }, $worker ) );
    }

    if( defined( my $cv = $meta -> { 'workers' } -> { $worker } -> { 'slot_condvar' } ) ) {

        $self -> wait_cond( $cv );
    }

    return;
}

=head2 spawn_worker( HashRef meta, Str worker, ArrayRef args? )

Порождает новый экземпляр конкретного воркера.

Возвращает идентификатор порождённого процесса.

=cut

method spawn_worker( HashRef meta, Str worker, ArrayRef args? ) {

    unless( exists $meta -> { 'workers' } -> { $worker } ) {

        die( sprintf( 'Daemon %s has no worker %s', $meta -> { 'name' }, $worker ) );
    }

    my $worker_meta = $meta -> { 'workers' } -> { $worker };

    if( ++$worker_meta -> { 'instances' } > $worker_meta -> { 'descr' } -> { 'max_instances' } ) {

        die( sprintf( 'Can\'t create more instances of worker %s', $worker ) );
    }

    $meta -> { 'condvar' } //= AnyEvent -> condvar( cb => sub {
        $meta -> { 'condvar' } = undef;
    } );

    $worker_meta -> { 'condvar' } //= AnyEvent -> condvar( cb => sub {
        $worker_meta -> { 'condvar' } = undef;
    } );

    $worker_meta -> { 'slot_condvar' } //= AnyEvent -> condvar( cb => sub {
        $worker_meta -> { 'slot_condvar' } = undef;
    } );

    my $parent_pid = $$;
    my @alien_pipes = grep( { defined $_ } map( { @$_ }
        values( %{ $meta -> { 'pipes' } -> { $parent_pid } } ) ) );
    my %pipes = ();
    my %out = ( name => $worker );

    if( exists $worker_meta -> { 'descr' } -> { 'transport' } ) {

        my $mask = $worker_meta -> { 'descr' } -> { 'transport' };
        my ( $parent, $child ) = $self -> create_pipe();

        push( @alien_pipes, $parent );

        if( $mask & TRANSPORT_R ) {

            $out{ 'write' } = $parent;
            $pipes{ 'read' } = $child;

        } else {

            shutdown( $parent -> fh(), 1 );
            shutdown( $child -> fh(), 0 );
        }

        if( $mask & TRANSPORT_W ) {

            $out{ 'read' } = $parent;
            $pipes{ 'write' } = $child;

        } else {

            shutdown( $parent -> fh(), 0 );
            shutdown( $child -> fh(), 1 );
        }
    }

    {
        my ( $parent_tun, $child_tun ) = $self -> create_pipe();

        push( @alien_pipes, $parent_tun );
        @out{ 'tun_read', 'tun_write' } = ( $parent_tun )x2;
        @pipes{ 'tun_read', 'tun_write' } = ( $child_tun )x2;
    }

    $out{ 'tun_mgr' } = $self -> create_tunnel_manager( $meta, [ @out{ 'tun_read', 'tun_write' } ] );

    my $pid = fork();

    unless( defined $pid ) {

        die( 'fork(): ' . $! );
    }

    if( $pid == 0 ) {

        undef %out;

        foreach my $obj ( @alien_pipes ) {

            if( defined( my $fh = $obj -> fh() ) ) {

                # Если не разрушить эти хэндлы - они могут продолжить делать
                # своё дело, но будут сыпать ошибками, ибо дескрипторы всё
                # равно уже закрыты
                $obj -> destroy();
                close( $fh );
            }
        }

        undef @alien_pipes;

        $meta -> { 'condvar' } = undef;

        while( my ( undef, $worker_meta ) = each( %{ $meta -> { 'workers' } } ) ) {

            $worker_meta -> { 'condvar' } = undef;
            $worker_meta -> { 'slot_condvar' } = undef;
        }

        $pid = $$;
        $0 = $worker_meta -> { 'descr' } -> { 'name' } . ' (' . $0 . ')';

        $meta -> { 'parent_watcher' } = AnyEvent -> timer( after => 3, interval => 3, cb => sub {

            if( kill( 0, $parent_pid ) == 0 ) {

                kill( SIGTERM, $pid );
            }
        } );

        $meta -> { 'pipes' } = {
            $pid => {
                $parent_pid => [ @pipes{ 'read', 'write' } ],
            }
        };

        $meta -> { 'tunnels' } = {
            $pid => {
                $parent_pid => [ @pipes{ 'tun_read', 'tun_write' } ],
            }
        };

        $meta -> { 'instances' } = {
            $pid => {
                name => $worker_meta -> { 'descr' } -> { 'name' },
                pid => $pid,
            },
            $parent_pid => {
                name => $meta -> { 'instances' } -> { $parent_pid } -> { 'name' },
                pid => $parent_pid,
                %pipes,
            },
        };

        while( my ( undef, $worker_meta ) = each( %{ $meta -> { 'workers' } } ) ) {

            $worker_meta -> { 'instances' } = 0;
        }

        $meta -> { 'dead' } = [];
        $meta -> { 'routes' } = {};
        $meta -> { 'tmp_tunnel_prefixes' } = { $pid => {} };
        $meta -> { 'non_zero_exit_statuses_count' } = 0;

        # Если в качестве бэкэнда AnyEvent используется EV (на что итак идёт
        # рассчёт), то рекомендуется явно сказать EV'у о вызове fork()
        EV::FLAG_FORKCHECK() if defined *EV::FLAG_FORKCHECK{ 'CODE' };

        # Грязный хак для AnyEvent, который так и не понял, что глобальные
        # переменные - это плохо, а рекурсия - хорошо
        undef $AnyEvent::CondVar::Base::WAITING;

        my $tun_mgr = $self -> create_tunnel_manager( $meta, [ @pipes{ 'tun_read', 'tun_write' } ] );
        my $o = $self -> worker_class() -> new(
            %{ $worker_meta -> { 'descr' } },
            parent => $parent_pid,
            meta => $meta,
            %pipes,
        );

        eval{ $o -> main( defined $args ? $args : () ) };
        my $err = $@;

        $o -> log( $0 . ': ' . $err ) if $err;

        undef $o;
        undef $tun_mgr;

        foreach ( 'read', 'write', 'tun_read', 'tun_write' ) {

            if( exists $pipes{ $_ } && defined( my $fh = $pipes{ $_ } -> fh() ) ) {

                $pipes{ $_ } -> destroy();
                close( $fh );
            }
        }

        if( $err || ( $meta -> { 'non_zero_exit_statuses_count' } > 0 ) ) {

            exit( 1 );

        } else {

            exit( 0 );
        }
    }

    $out{ 'reap_mgr' } = AnyEvent -> child(
        pid => $pid,
        cb => sub {
            my ( $pid, $status ) = @_;

            $self -> reap_worker( $meta, $meta -> { 'instances' } -> { $pid }, $status );
        },
    );

    $meta -> { 'instances' } -> { $pid } = \%out;
    $out{ 'pid' } = $pid;

    $meta -> { 'pipes' } -> { $parent_pid } -> { $pid } = [ @out{ 'read', 'write' } ];
    $meta -> { 'tunnels' } -> { $parent_pid } -> { $pid } = [ @out{ 'tun_read', 'tun_write' } ];

    foreach ( 'read', 'write', 'tun_read', 'tun_write' ) {

        if( exists $pipes{ $_ } && defined( my $fh = $pipes{ $_ } -> fh() ) ) {

            $pipes{ $_ } -> destroy();
            close( $fh );
        }
    }

    return $pid;
}

=head2 daemon_main( HashRef meta, Str worker, ArrayRef args? )

Точка входа в демон.

Аргументы C<worker> и C<args> используются для вызова C<spawn_worker>.
Предполагается, что так этот вызов породит главный воркер.

=cut

method daemon_main( HashRef meta, Str worker, ArrayRef args? ) {

    $self -> reinstall_signals( $meta );
    $self -> spawn_worker( $meta => $worker, ( defined $args ? $args : () ) );
    $self -> wait_all_workers( $meta );

    return ( $meta -> { 'non_zero_exit_statuses_count' } == 0 );
}

=head2 reinstall_signals( HashRef meta )

Переинициализирует обработчики сигналов.

Внутренний метод.

=cut

sub reinstall_signals {

    my ( $self, $meta ) = @_;

    unless( $meta -> { 'signals_reinstalled' } ) {

        $meta -> { 'signals_reinstalled' } = true;
        my %handlers = ();

        while( my ( $sig, $handler ) = each( %SIG ) ) {

            if(
                defined $handler && ( substr( $sig, 0, 1 ) ne '_' )
                && ( ref( $handler ) eq 'CODE' )
            ) {

                $handlers{ $sig } = $handler;
            }
        }

        while( my ( $sig, $handler ) = each( %handlers ) ) {

            $SIG{ $sig } = undef;
            push( @{ $meta -> { 'signals' } }, AnyEvent -> signal(
                signal => $sig,
                cb => $handler,
            ) );
        }
    }

    return;
}

=head2 reap_worker( HashRef meta, HashRef worker, Int status )

Функция, обрабатывающая событие завершения работы конкретного воркера.

Внутренний метод.

=cut

sub reap_worker {

    my ( $self, $meta, $worker, $status ) = @_;

    my $worker_meta = $meta -> { 'workers' } -> { $worker -> { 'name' } };
    my $reap = sub {

        delete( $meta -> { 'pipes' } -> { $$ } -> { $worker -> { 'pid' } } );
        delete( $meta -> { 'routes' } -> { $$ } -> { $worker -> { 'pid' } } );
        delete( $meta -> { 'tunnels' } -> { $$ } -> { $worker -> { 'pid' } } );
        delete( $meta -> { 'instances' } -> { $worker -> { 'pid' } } );

        $worker -> { 'tun_mgr' } = undef;

        foreach ( 'read', 'write', 'tun_read', 'tun_write' ) {

            if( exists $worker -> { $_ } && defined( my $fh = $worker -> { $_ } -> fh() ) ) {

                $worker -> { $_ } -> destroy();
                close( $fh );
            }
        }

        if( $status != 0 ) {

            ++ $meta -> { 'non_zero_exit_statuses_count' };
        }

        $worker_meta -> { 'slot_condvar' } -> send() if defined $worker_meta -> { 'slot_condvar' };
        $worker_meta -> { 'condvar' } -> send() if( --$worker_meta -> { 'instances' } <= 0 );
        $meta -> { 'condvar' } -> send() unless $self -> has_alive_workers( $meta );
    };

    if( exists $worker_meta -> { 'descr' } -> { 'reap' } ) {

        $worker_meta -> { 'descr' } -> { 'reap' } -> ( $reap, $worker -> { 'pid' }, $status );

    } else {

        $reap -> ();
    }

    return;
}

=head2 serve_tunnel( HashRef meta, ArrayRef( Maybe[Ref] read, Maybe[Ref] write ) tun )

Функция, обрабатывающая запрос из одного конкретного тоннеля.

Внутренний метод.

=cut

sub serve_tunnel {

    my ( $self, $meta, $tun ) = @_;

    $self -> read_len( 1, $tun -> [ 0 ], sub {

        my ( $prefix ) = @_;

        $self -> serve_tunnel_by_prefix( $meta, $tun, $prefix );
    } );

    return;
}

=head2 serve_tunnel_by_prefix( HashRef meta, ArrayRef( Maybe[Ref] read, Maybe[Ref] write ) tun, Str{1} prefix )

Функция, обрабатывающая запрос известного типа из одного конкретного тоннеля.

Внутренний метод.

=cut

sub serve_tunnel_by_prefix {

    my ( $self, $meta, $tun, $prefix ) = @_;

    state $static_prefixes = {
        TUN_PREFIX_DISCOVERY_REQUEST() => 'serve_discovery_request',
        TUN_PREFIX_DATA_REQUEST() => 'serve_data_request',
    };

    if( exists $static_prefixes -> { $prefix } ) {

        my $method = $static_prefixes -> { $prefix };

        $self -> $method( $meta, $tun );

    } else {

        if( exists $meta -> { 'tmp_tunnel_prefixes' } -> { $$ } -> { $prefix } ) {

            my $method = shift( @{ $meta -> { 'tmp_tunnel_prefixes' } -> { $$ } -> { $prefix } } );

            die( "Unexpected prefix in reply: ${prefix}" ) unless( defined $method );

            $self -> $method( $meta, $tun );

        } else {

            die( "Unexpected prefix in reply: ${prefix}" );
        }
    }

    return;
}

=head2 register_tmp_tunnel_handler( HashRef meta, Str prefix, Str|CodeRef method )

Регистрирует временный обработчик неизвестного ранее префикса сообщения,
пришедшего в тоннель.

Такой обработчик выполняется, и тут же убирается из списка обработчиков.

Внутренни�� метод.

=cut

sub register_tmp_tunnel_handler {

    my ( $self, $meta, $prefix, $method ) = @_;

    push( @{ $meta -> { 'tmp_tunnel_prefixes' } -> { $$ } -> { $prefix } }, $method );

    return;
}

=head2 serve_discovery_request( HashRef meta, ArrayRef( Maybe[Ref] read, Maybe[Ref] write ) tun )

Функция, обрабатывающая запрос поиска тоннеля до конкретного воркера.

Внутренний метод.

=cut

sub serve_discovery_request {

    my ( $self, $meta, $tun ) = @_;
    my $my_pid = $$;

    $self -> read_len( 4, $tun -> [ 0 ], sub {

        my ( $pid ) = @_;

        $pid = unpack( 'N', $pid );

        $self -> read_len( 4, $tun -> [ 0 ], sub {

            my ( $len ) = @_;

            $len = unpack( 'N', $len );

            $self -> read_len( 4 * $len, $tun -> [ 0 ], sub {

                my ( $data ) = @_;
                my @skip = ();

                foreach ( 1 .. $len ) {

                    push( @skip, unpack( 'N', substr( $data, 0, 4, '' ) ) );
                };

                unless( defined $tun -> [ 1 ] ) {

                    die( 'Endpoint is not accessible' );
                }

                $self -> find_tunnel( $meta, $my_pid, $pid, sub {

                    my ( $result ) = @_;

                    my $flag = ( defined $result ? 1 : 0 );

                    $tun -> [ 1 ] -> push_write( pack( 'A1A1', TUN_PREFIX_DISCOVERY_REPLY, $flag ) );

                }, \@skip );
            } );
        } );
    } );

    return;
}

=head2 serve_data_request( HashRef meta, ArrayRef( Maybe[Ref] read, Maybe[Ref] write ) tun )

Функция, обрабатывающая запрос отправки данных по тунелю до конкретного воркера.

Внутренний метод.

=cut

sub serve_data_request {

    my ( $self, $meta, $tun ) = @_;

    $self -> read_len( 4, $tun -> [ 0 ], sub {

        my ( $pid ) = @_;

        $pid = unpack( 'N', $pid );

        $self -> read_len( 4, $tun -> [ 0 ], sub {

            my( $len ) = @_;

            $len = unpack( 'N', $len );

            $self -> read_len( $len, $tun -> [ 0 ], sub {

                my ( $data ) = @_;

                $self -> write_to( $meta, $pid, $data );
            } );
        } );
    } );

    return;
}

=head2 find_tunnel( HashRef meta, Int from, Int to, CodeRef cb, ArrayRef[Int] skip? )

Функция поиска тоннеля от одного воркера до другого.

Находит (или нет) и выполняет коллбэк.

Внутренний метод.

=cut

sub find_tunnel {

    my ( $self, $meta, $from, $to, $cb, $skip ) = @_;

    $skip //= [];

    push( @$skip, $$ );

    my %skip = map( { $_ => 1 } @$skip );
    my $simple_tun = sub {

        my ( $from, $to ) = @_;

        if(
            exists $meta -> { 'tunnels' } -> { $from }
            && exists $meta -> { 'tunnels' } -> { $from } -> { $to }
        ) {

            return $meta -> { 'tunnels' } -> { $from } -> { $to };
        }

        return undef;
    };

    if( defined( my $straight_tun = $simple_tun -> ( $from, $to ) ) ) {

        return $cb -> ( [ TUN_NEAR, $straight_tun ] );

    } elsif( defined( my $reverse_tun = $simple_tun -> ( $to, $from ) ) ) {

        return $cb -> ( [ TUN_NEAR, $reverse_tun ] );
    }

    $self -> find_tunnel_deep( $meta, $from, $to, \%skip, sub {

        my ( $tun ) = @_;

        if( defined $tun ) {

            $cb -> ( [ TUN_FAR, $meta -> { 'routes' } -> { $from } -> { $to } = $tun ] );

        } else {

            $self -> find_tunnel_deep( $meta, $to, $from, \%skip, sub {

                my ( $tun ) = @_;

                $cb -> ( [ TUN_FAR, $meta -> { 'routes' } -> { $from } -> { $to } = $tun ] );
            } );
        }
    } );

    return;
}

=head2 find_tunnel_deep( HashRef meta, Int from, Int to, HashRef skip, CodeRef cb )

Опрашивает соседних воркеров с целью поиска тоннеля, и выполняет коллбэк.

Внутренний метод.

=cut

sub find_tunnel_deep {

    my ( $self, $meta, $from, $to, $skip, $cb ) = @_;

    if( exists $meta -> { 'routes' } -> { $from } -> { $to } ) {

        return $meta -> { 'routes' } -> { $from } -> { $to };
    }

    return undef unless exists $meta -> { 'tunnels' } -> { $from };

    my @queue = ();

    foreach my $pid ( keys( %{ $meta -> { 'tunnels' } -> { $from } } ) ) {

        next if exists $skip -> { $pid };

        push( @queue, sub {

            my ( $cb ) = @_;

            $self -> ask_pid_about_tunnel( $meta, $from, $to, $pid, [ values( %$skip ) ], sub {

                my ( $tun ) = @_;

                if( defined $tun ) {

                    $cb -> ( $tun );

                } else {

                    if( defined( my $code = shift( @queue ) ) ) {

                        $code -> ( $cb );

                    } else {

                        $cb -> ( undef );
                    }
                }
            } );
        } );
    }

    if( scalar( @queue ) > 0 ) {

        shift( @queue ) -> ( $cb );

    } else {

        $cb -> ( undef );
    }

    return;
}

=head2 ask_pid_about_tunnel( HashRef meta, Int from, Int to, Int pid, ArrayRef[Int] skip, CodeRef cb )

Спрашивает конкретный воркер, есть ли у него тоннель до конкретного воркера,
и выполняет коллбэк.

Внутренний метод.

=cut

sub ask_pid_about_tunnel {

    my ( $self, $meta, $from, $to, $pid, $skip, $cb ) = @_;

    my $pipes = $meta -> { 'tunnels' } -> { $from } -> { $pid };
    my $packet = pack( 'A1NN', TUN_PREFIX_DISCOVERY_REQUEST, $to, scalar( @$skip ) );

    $packet .= pack( 'N', $_ ) for @$skip;

    unless( defined $pipes -> [ 1 ] ) {

        die( "Endpoint ${pid} is not accessible" );
    }

    my $handler; $handler = sub {

        my ( $self, $meta, $tun ) = @_;

        if( $tun -> [ 0 ] -> fh() -> fileno() == $pipes -> [ 0 ] -> fh() -> fileno() ) {

            $self -> read_len( 1, $pipes -> [ 0 ], sub {

                my ( $flag ) = @_;

                $cb -> ( $flag ? $pipes : undef );
            } );

        } else {

            $self -> serve_tunnel_by_prefix( $meta, $tun, TUN_PREFIX_DISCOVERY_REPLY );
            $self -> register_tmp_tunnel_handler( $meta, TUN_PREFIX_DISCOVERY_REPLY, $handler );
        }
    };

    $self -> register_tmp_tunnel_handler( $meta, TUN_PREFIX_DISCOVERY_REPLY, $handler );

    $pipes -> [ 1 ] -> push_write( $packet );

    return;
}

=head2 write_to( HashRef meta, Int pid, Str data )

Отправляет данные в конкретный воркер.

=cut

method write_to( HashRef meta, Int pid, Str data ) {

    if(
        exists $meta -> { 'instances' } -> { $pid }
        && exists $meta -> { 'instances' } -> { $pid } -> { 'write' }
    ) {

        unless( defined $meta -> { 'instances' } -> { $pid } -> { 'write' } ) {

            die( "Endpoint ${pid} is not accessible" );
        }

        $meta -> { 'instances' } -> { $pid } -> { 'write' } -> push_write( $data );

    } else {

        $self -> find_tunnel( $meta, $$, $pid, sub {

            my ( $tun ) = @_;

            die( sprintf( 'Could not write into instance %d', $pid ) ) unless defined $tun;

            $tun = $tun -> [ 1 ];
            my $len = length( $data );

            die( "Endpoint ${pid} is not accessible" ) unless( defined $tun -> [ 1 ] );

            $tun -> [ 1 ] -> push_write( pack( "A1NNA${len}", TUN_PREFIX_DATA_REQUEST, $pid, $len, $data ) );
        } );
    }

    return;
}

=head2 read_from( HashRef meta, Int pid, Int len, CodeRef cb )

Читает данные из конкретного воркера и выполняет коллбэк.

=cut

method read_from( HashRef meta, Int pid, Int len, CodeRef cb ) {

    if(
        exists $meta -> { 'instances' } -> { $pid }
        && exists $meta -> { 'instances' } -> { $pid } -> { 'read' }
    ) {

        return $self -> read_len( $len, $meta -> { 'instances' } -> { $pid } -> { 'read' }, $cb );

    } else {

        die( sprintf( 'Could not read from instance %d', $pid ) );
    }
}

=head2 read_len( Int len, Ref pipe, CodeRef cb )

Читает сообщение определённой длины из пайпа и вызывает коллбэк.

Внутренний метод.

=cut

sub read_len {

    my ( $self, $len, $pipe, $cb ) = @_;

    unless( defined $pipe ) {

        die( 'Endpoint is not accessible' );
    }

    my $cv = AnyEvent -> condvar();

    $pipe -> push_read( chunk => $len, sub {

        my ( undef, $data ) = @_;

        $pipe -> on_error( sub {
            $self -> ae_handle_error_cb( @_ );
        } );

        $cb -> ( $data );
        $cv -> send();
    } );

    $pipe -> on_error( sub {
        $self -> ae_handle_error_cb( @_, $cv );
    } );

    return $cv;
}

=head2 create_pipe()

Создаёт пайп.

Внутренний метод.

=cut

sub create_pipe {

    my ( $self ) = @_;
    my ( $from, $to ) = ( undef, undef );

    unless( socketpair( $from, $to, AF_UNIX, SOCK_STREAM, PF_UNSPEC ) ) {

        die( 'socketpair(): ' . $! );
    }

    $from -> autoflush( 1 );
    $to -> autoflush( 1 );

    return map( { my $fh = $_; AnyEvent::Handle -> new(
        fh => $fh,
        on_error => sub {
            $self -> ae_handle_error_cb( @_ );
        },

    ) } ( $from, $to ) );
}

=head2 ae_handle_error_cb( AnyEvent::Handle h, Bool fatal, Str msg, AnyEvent::CondVar cv? )

Обработчик события ошибки для экземпляров класса L<AnyEvent::Handle>.

Внутренний метод.

=cut

sub ae_handle_error_cb {

    my ( $self, $h, $fatal, $msg, $cv ) = @_;
    my $fh = $h -> fh();

    $h -> destroy();
    close( $fh );

    $cv -> send( 1 ) if defined $cv;

    # warn "($0) handle error";

    return;
}

=head2 create_tunnel_manager( HashRef meta, ArrayRef( Ref read, Ref write ) tun )

Создаёт менеджер тоннеля.

Внутренний метод.

=cut

sub create_tunnel_manager {

    my ( $self, $meta, $tun ) = @_;

    return AnyEvent -> io(
        fh => $tun -> [ 0 ] -> fh(),
        poll => 'r',
        cb => sub {

            $self -> serve_tunnel( $meta, $tun );
        },
    );
}

=head2 wait_cond( AnyEvent::CondVar cv )

Выполняет прерываемый C<$cv -> recv()>.

Внутренний метод.

=cut

sub wait_cond {

    my ( $self, $cv ) = @_;

    state $watchers = {};
    state $global_cv;

    unless( exists $watchers -> { $$ } ) {

        $global_cv = AnyEvent -> condvar();
        my @watchers = ();

        foreach my $sig ( 'TERM', 'INT', 'HUP' ) {

            push( @watchers, AnyEvent -> signal( signal => $sig, cb => sub {

                $global_cv -> send( 1 );
            } ) );
        }

        %$watchers = ( $$ => \@watchers );
    }

    # warn "($0) wait cond";

    $global_cv -> cb( sub { $cv -> send( $global_cv -> recv() ) } );

    my $rv = $cv -> recv();

    $global_cv -> cb( sub {} );

    return $rv;
}

=head2 worker_class()

=cut

sub worker_class { 'Salvation::DaemonDecl::Worker' }

1;

__END__
