package Scaffold::Lockmgr::UnixMutex;

our $VERSION = '0.03';

use Try::Tiny;
use IPC::Semaphore;
use Scaffold::Lockmgr::SharedMem;
use Errno qw( EAGAIN EINTR );
use IPC::SysV qw( IPC_CREAT IPC_RMID IPC_SET SEM_UNDO IPC_NOWAIT );

use Scaffold::Class
  version   => $VERSION,
  base      => 'Scaffold::Lockmgr',
  constants => 'TRUE FALSE LOCK',
  utils     => 'numlike textlike',
  accessors => 'shmem',
  constant => {
      BUFSIZ => 256,
  },
  messages => {
      'baselock'     => "unable to aquire the base lock",
      'allocate'     => "unable to allocate a lock, reason: %s",
      'deallocate'   => "unable to deallocate a lock, reason: %s",
      'nosharedmem'  => "unable to aquire shared memory, reason: %s",
      'nosemaphores' => "unable to aquire a semaphore set, reason: %s",
      'shmwrite'     => "unable to write to shared memory, reason: %s",
      'shmread'      => "unable to read from shared memory, reason: %s",
  }
;

my $BLANK = pack('A256', '');
my $LOCK  = pack('A256', LOCK);

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub allocate {
    my ($self, $key) = @_;

    my $buffer;
    my $skey = pack('A256', $key);
    my $size = $self->config('nsems');

    try {

        if ($self->_lock_semaphore(0)) {

            for (my $x = 1; $x < $size; $x++) {

                $buffer = $self->shmem->read($x, BUFSIZ) or die $!;
                if ($buffer eq $BLANK) {

                    $self->shmem->write($skey, $x, BUFSIZ) or die $!;
                    last;

                }

            }

            $self->_unlock_semaphore(0);

        } else {

            $self->throw_msg(
                'scaffold.lockmgr.unixmutex.allocate',
                'baselock',
            );

        }

    } catch {

        my $ex = $_;

        $self->engine->op(0, 1, 0);
        $self->throw_msg(
            'scaffold.lockmgr.unixmutex.allocate',
            'allocate',
            $ex
        );

    };

}

sub deallocate {
    my ($self, $key) = @_;

    my $buffer;
    my $skey = pack('A256', $key);
    my $size = $self->config('nsems');

    try {

        if ($self->_lock_semaphore(0)) {

            for (my $x = 1; $x < $size; $x++) {

                $buffer = $self->shmem->read($x, BUFSIZ) or die $!;
                if ($buffer eq $skey) {

                    $self->shmem->write($BLANK, $x, BUFSIZ) or die $!;
                    last;

                }

            }

            $self->_unlock_semaphore(0);

        } else {

            $self->throw_msg(
                'scaffold.lockmgr.unixmutex.deallocate',
                'baselock',
            );

        }

    } catch {

        my $ex = $_;

        $self->engine->op(0, 1, 0);
        $self->throw_msg(
            'scaffold.lockmgr.unixmutex.deallocate',
            'deallocate',
            $ex
        );

    };

}

sub lock {
    my ($self, $key) = @_;

    my $stat;
    my $semno;

    if (($semno = $self->_get_semaphore($key)) > 0) {

        $stat = $self->_lock_semaphore($semno);

    } else {

        $stat = FALSE;

    }

    return $stat;

}

sub unlock {
    my ($self, $key) = @_;

    my $semno;

    if (($semno = $self->_get_semaphore($key)) > 0) {

        $self->_unlock_semaphore($semno);

    }

}

sub try_lock {
    my ($self, $key) = @_;

    my $semno;
    my $stat = FALSE;

    if (($semno = $self->_get_semaphore($key)) > 0) {

        $stat = $self->engine->getncnt($semno) ? FALSE : TRUE;

    }

    return $stat;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;

    my $gid;
    my $uid;
    my $mode;
    my $size;
    my $buffer;

    unless (defined($config->{mode})) {

        # We are being really liberal here... but apache pukes on the
        # defaults.

        $mode = ( 0666 | IPC_CREAT ); 
        
    }

    if (defined($config->{uid})) {

        $uid = $config->{gid};

        unless (numlike($config->{gid})) {

            $uid = getpwnam($config->{uid});

        }

    } else {

        $uid = $>;

    }

    if (defined($config->{gid})) {

        $gid = $config->{gid};

        unless (numlike($config->{gid})) {

            $gid = getgrnam($config->{gid});

        }

    } else {

        $gid = $);

    };

    if (! defined($config->{nsems})) {

        if ($^O eq "aix") {

            $config->{nsems} = 250;

        } elsif ($^O eq 'linux') {

            $config->{nsems} = 250;

        } elsif ($^O eq 'bsd') {

            $config->{nsems} = 8;

        } else {

            $config->{nsems} = 16;

        }

    }

    $config->{key} = 'scaffold' unless defined $config->{key};

    if (textlike($config->{key})) {

        my $hash;
        my $name = $config->{key};
        my $len = length($name);

        for (my $x = 0; $x < $len; $x++) {

            $hash += ord(substr($name, $x, 1));

        }

        $config->{key} = $hash;

    }

    $self->{config}  = $config;
    $self->{limit}   = $config->{limit} || 10;
    $self->{timeout} = $config->{timeout} || 10;

    try {

        $self->{engine} = IPC::Semaphore->new(
            $config->{key},
            $config->{nsems},
            $mode
        ) or die $!;

        if ((my $rc = $self->engine->set(uid => $uid, gid => $gid)) != 0) {

            die "unable to set ownership on shared memory - $rc";

        };

        $self->engine->setall((1) x $config->{nsems}) or die $!;

    } catch {

        my $ex = $_;

        $self->throw_msg(
            'scaffold.lockmgr.unixmutex',
            'nosemaphores',
            $ex
        );

    };

    try {

        $size = $config->{nsems} * BUFSIZ;

        $self->{shmem} = Scaffold::Lockmgr::SharedMem->new(
            $config->{key}, 
            $size, 
            $mode
        ) or die $!;

        if ((my $rc = $self->shmem->set(uid => $uid, gid => $gid)) != 0) {

            die "unable to set ownership on shared memory - $rc";

        };

        $buffer = $self->shmem->read(0, BUFSIZ) or die $!;
        if ($buffer ne $LOCK) {

            $self->shmem->write($LOCK, 0, BUFSIZ) or die $!;

            for (my $x = 1; $x < $config->{nsems}; $x++) {

                $self->shmem->write($BLANK, $x, BUFSIZ) or die $!;

            }

        }

    } catch {

        my $ex = $_;

        $self->throw_msg(
            'scaffold.lockmgr.unixmutex',
            'nosharedmem',
            $ex
        );

    };

    return $self;

}

sub DESTROY {
    my $self = shift;

    if (defined($self->{engine})) {

        $self->engine->remove();

    }

    if (defined($self->{shmem})) {

        $self->shmem->remove();

    }

}

sub _get_semaphore {
    my ($self, $key) = @_;

    my $buffer;
    my $stat = -1;
    my $skey = pack('A256', $key);
    my $size = $self->config('nsems');

    try {

        if ($self->_lock_semaphore(0)) {

            for (my $x = 1; $x < $size; $x++) {

                $buffer = $self->shmem->read($x, BUFSIZ) or die $!;
                if ($buffer eq $skey) {

                    $stat = $x;
                    last;

                }

            }

            $self->_unlock_semaphore(0);

        } else {

            $self->throw_msg(
                'scaffold.lockmgr.unixmutex._get_semaphore',
                'baselock',
            );

        }

    } catch {

        my $ex = $_;

        $self->engine->op(0, 1, 0);
        $self->throw_msg(
            'scaffold.lockmgr.unixmutex._get_semaphore',
            'shmread',
            $ex
        );

    };

    return $stat;

}

sub _lock_semaphore {
    my ($self, $semno) = @_;

    my $count = 0;
    my $stat = TRUE;
    my $flags = ( SEM_UNDO | IPC_NOWAIT );

    LOOP: {

        my $result = $self->engine->op($semno, -1, $flags);
        my $ex = $!;

        if (($result == 0) && ($ex == EAGAIN)) {

            $count++;

            if ($count < $self->limit) {

                sleep $self->timeout;
                next LOOP;

            } else {

                $stat = FALSE;

            }

        }

    }

    return $stat;

}

sub _unlock_semaphore {
    my ($self, $semno) = @_;

    $self->engine->op($semno, 1, SEM_UNDO) or die $!;

}

1;

__END__

=head1 NAME

Scaffold::Lockmgr::UnixMutex - Use SysV semaphores for resource locking.

=head1 SYNOPSIS

 use Scaffold::Server;
 use Scaffold::Lockmgr::UnixMutex;

 my $psgi_handler;

 main: {

    my $server = Scaffold::Server->new(
        lockmgr => Scaffold::Lockmgr::UnixMutex->new(
            key     => 1234,
            nsems   => 32,
            timeout => 10,
            limit   => 10
        },
    );

    $psgi_hander = $server->engine->psgi_handler();

 }

=head1 DESCRIPTION

This implenments general purpose resource locking with SysV semaphores. 

=head1 CONFIGURATION

=over 4

=item key

This is a numeric key to identify the semaphore set. The default is a hash
of "scaffold".

=item nsems

The number of semaphores in the semaphore set. The default is dependent 
on platform. 

    linux - 250
    aix   - 250
    bsd   - 8
    other - 16

=item timeout

The number of seconds to sleep if the lock is not available. Default is 10
seconds.

=item limit

The number of attempts to try the lock. If the limit is passed an exception
is thrown. The default is 10.

=item uid

The uid used to create the semaphores and shared memory segments. Defaults to
effetive uid.

=item gid

The gid used to create the semaphores and shared memory segments. Defaults to
effetive gid.

=item mode

The access permissions which are used by the semaphores and 
shared memory segments. Defaults to ( 0666 | IPC_CREAT ).

=back

=head1 SEE ALSO

 Scaffold
 Scaffold::Base
 Scaffold::Cache
 Scaffold::Cache::FastMmap
 Scaffold::Cache::Manager
 Scaffold::Cache::Memcached
 Scaffold::Class
 Scaffold::Constants
 Scaffold::Engine
 Scaffold::Handler
 Scaffold::Handler::Default
 Scaffold::Handler::Favicon
 Scaffold::Handler::Robots
 Scaffold::Handler::Static
 Scaffold::Lockmgr
 Scaffold::Lockmgr::KeyedMutex
 Scaffold::Lockmgr::UnixMutex
 Scaffold::Plugins
 Scaffold::Render
 Scaffold::Render::Default
 Scaffold::Render::TT
 Scaffold::Routes
 Scaffold::Server
 Scaffold::Session::Manager
 Scaffold::Stash
 Scaffold::Stash::Controller
 Scaffold::Stash::Cookie
 Scaffold::Stash::View
 Scaffold::Uaf::Authenticate
 Scaffold::Uaf::AuthorizeFactory
 Scaffold::Uaf::Authorize
 Scaffold::Uaf::GrantAllRule
 Scaffold::Uaf::Login
 Scaffold::Uaf::Logout
 Scaffold::Uaf::Manager
 Scaffold::Uaf::Rule
 Scaffold::Uaf::User
 Scaffold::Utils

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
