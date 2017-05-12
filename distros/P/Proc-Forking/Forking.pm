package Proc::Forking;

###########################################################
# Fork package
# Gnu GPL2 license
#
# Forking.pm 1.49 2010 09 02 14:52

#
# Fabrice Dulaunoy <fabrice@dulaunoy.com>
###########################################################
# ChangeLog:
#
###########################################################
use strict;

use POSIX qw(:signal_h setsid WNOHANG);
use IO::File;
use Cwd;
use Sys::Load qw/getload/;
use Sys::Prctl;
use Carp;

use vars qw( $VERSION);

$VERSION = '1.50';

my $DAEMON_PID;
$SIG{ CHLD } = \&garbage_child;

my %PID;
my %NAME;

my @CODE;
$CODE[0]  = [ 0,  " success" ];
$CODE[1]  = [ 1,  " Can't fork a new process" ];
$CODE[2]  = [ 2,  " Can't open PID file" ];
$CODE[3]  = [ 3,  " Process already running with same PID" ];
$CODE[4]  = [ 4,  " maximun LOAD reached" ];
$CODE[5]  = [ 5,  " maximun number of processes reached" ];
$CODE[6]  = [ 6,  " error in parameters" ];
$CODE[7]  = [ 7,  " No function provided" ];
$CODE[8]  = [ 8,  " Can't fork" ];
$CODE[9]  = [ 9,  " PID already present in list of PID processes" ];
$CODE[10] = [ 10, " NAME already present in list of NAME processes" ];
$CODE[11] = [ 11, " Can't chdir" ];
$CODE[12] = [ 12, " Can't chroot" ];
$CODE[13] = [ 13, " Can't become DAEMON" ];
$CODE[14] = [ 14, " Can't unlink PID file" ];
$CODE[15] = [ 15, " maximun MEM used reached" ];
$CODE[16] = [ 16, " Expiration TIMEOUT reached" ];
$CODE[17] = [ 17, " NO expiration parameter" ];
$CODE[18] = [ 18, " Don't fork, NAME already present (STRICT mode enabled)" ];
$CODE[19] = [ 19, " Don't fork, PID_FILE already present (STRICT mode enabled)" ];

sub daemonize
{


    my @param = @_;
    my $self  = shift @param;
    
    $SIG{ INT } = $SIG{ KILL } = $SIG{ TERM } = sub {    
    									$self->killall_childs;
  									unlink $DAEMON_PID;
									exit 0 ;
								};
    
    if ( @param % 2 )
    {
        return ( $CODE[6][0], 0, $CODE[6][1] );
    }
    my %param    = @param;
    my $uid      = exists( $param{ uid } ) ? $param{ uid } : '';
    my $gid      = exists( $param{ gid } ) ? $param{ gid } : '';
    my $home     = exists( $param{ home } ) ? $param{ home } : '';
    my $pid_file = $param{ pid_file } if exists( $param{ pid_file } );
    my $name     = $param{ name } if exists( $param{ name } );
    if ( defined( $name ) )
    {
        my $exp_name = $name;
        $exp_name =~ s/##/$$/g;
        $0 = $exp_name;
	my $main_process = new Sys::Prctl();
        $main_process->name( $0 );
    }

    my $child = fork;
    if ( !defined $child )
    {
        return ( $CODE[13][0], 0, $CODE[13][1] );
    }
    exit 0 if $child;    # parent dies;

    if ( exists( $param{ pid_file } ) )
    {
        $pid_file =~ s/##/$$/g;
        $DAEMON_PID = $pid_file;
        my @ret = create_pid_file( $pid_file, $$ );
        if ( $ret[0] )
        {
#             die "Another process is RUNNING\n";
	    carp "Another process is RUNNING\n";
	    return ( $CODE[3][0], 0, $CODE[3][1] ) ;
        }
    }

    my $luid = -1;
    my $lgid = -1;
    if ( $uid ne '' )
    {
        $luid = $uid;
    }
    if ( $gid ne '' )
    {
        $lgid = $gid;
    }
    chown $luid, $lgid, $pid_file;
    if ( $home ne '' )
    {
        local ( $>, $< ) = ( $<, $> );
        my $cwd = $home;
        chdir( $cwd )  || return ( $CODE[11][0], 0, $CODE[11][1] );
        chroot( $cwd ) || return ( $CODE[12][0], 0, $CODE[12][1] );
        $< = $>;
    }

    if ( $gid ne '' )
    {
        $) = "$gid $gid";
    }

    if ( $uid ne '' )
    {
        $> = $uid;
    }
    POSIX::setsid();
    open( STDIN,  "</dev/null" );
    open( STDOUT, ">/dev/null" );
    open( STDERR, ">&STDOUT" );
    chdir '/';
    umask( 0 );
    $ENV{ PATH } = '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin';
    delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };
    $SIG{ CHLD } = \&garbage_child;
}

sub new
{
    my ( $class ) = @_;
    bless {
        _function        => $_[1],
        _args            => $_[2],
        _name            => $_[3],
        _pid             => $_[4],
        _pid_file        => $_[5],
        _home            => $_[6],
        _uid             => $_[7],
        _gid             => $_[8],
        _max_child       => $_[9],
        _max_load        => $_[10],
        _pids            => $_[11],
        _names           => $_[12],
        _max_mem         => $_[13],
        _expiration      => $_[14],
        _expiration_auto => $_[15],
        _start_time      => $_[16],
        _eagain_sleep    => $_[17],
#        _strict           => $_[17],
    }, $class;

}

sub fork_child
{
    my @param      = @_;
    my $self       = shift @param;
    my $start_time = time;
    if ( @param % 2 )
    {
        return ( $CODE[6][0], 0, $CODE[6][1] );
    }
    my %param = @param;
    if ( !exists( $param{ function } ) )
    {
        return ( $CODE[7][0], 0, $CODE[7][1] );
    }
    $self->{ _function } = $param{ function };
    $self->{ _args }     = $param{ args } if exists( $param{ args } );
    $self->{ _name }     = $param{ name } if exists( $param{ name } );
    $self->{ _home }     = exists( $param{ home } ) ? $param{ home } : '';
    $self->{ _uid }      = exists( $param{ uid } ) ? $param{ uid } : '';
    $self->{ _gid }      = exists( $param{ gid } ) ? $param{ gid } : '';
    $self->{ _eagain_sleep } =  exists( $param{ eagain_sleep } ) ?  $param{ eagain_sleep }: 5; ;
    
    
    $self->{ _strict } = 0;
    if ( exists( $param{ strict } ) )
    {
        $self->{ _strict } = $param{ strict };
        if ( exists( $self->{ _names }{ $param{ name } }{ pid } ) )
        {
            return ( $CODE[18][0], $self->{ _pid }, ( $param{ name } . $CODE[18][1] ) );
        }
        if ( exists( $param{ pid_file } ) )
        {
            if ( -e $param{ pid_file } )
            {
# pid file already exists
                my $fh      = IO::File->new( $param{ pid_file } );
                my $pid_num = <$fh>;
                close $fh;
                if ( kill 0 => $pid_num )
                {
                    return ( $CODE[19][0], $pid_num, $CODE[19][1] );
                }
            }
        }
    }

    $self->{ _pid_file } = exists( $param{ pid_file } ) ? $param{ pid_file } : '';

    if ( exists( $param{ max_load } ) )
    {
        $self->{ _max_load } = $param{ max_load };
        if ( $self->{ _max_load } <= ( getload() )[0] )
        {
            return ( $CODE[4][0], 0, $CODE[4][1] );
        }
    }

    if ( exists( $param{ max_child } ) )
    {
        $self->{ _max_child } = $param{ max_child };
        if ( $self->{ _max_child } <= ( keys %{ $self->{ _pids } } ) )
        {
            return ( $CODE[5][0], 0, $CODE[5][1] );
        }
    }

    if ( exists( $param{ max_mem } ) )
    {
        $self->{ _max_mem } = $param{ max_mem };
        if ( $self->{ _max_mem } >= getmemfree() )
        {
            return ( $CODE[15][0], 0, $CODE[15][1] );
        }
    }

    if ( exists( $param{ expiration } ) )
    {
        $self->{ _expiration } = $param{ expiration } + $start_time;
        if ( exists( $param{ expiration_auto } ) )
        {
            $self->{ _expiration_auto } = $param{ expiration_auto };
        }
#	else
#	{
#	 $self->{ _expiration_auto } = 0;
#	}
    }
    else
    {
        $self->{ _expiration } = 0;
    }

    {
        my $pid;
        my $ret;

        if ( $pid = fork() )
        {
## in  parent
            $self->{ _pid } = $pid;
            my $pid_file;
            my $exp_name;
            $self->{ _start_time } = $^T;
            if ( defined( $self->{ _name } ) )
            {
                $exp_name = $self->{ _name };
                $exp_name =~ s/##/$pid/g;
            }
            if ( defined( $self->{ _pid_file } ) )
            {
                $pid_file = $self->{ _pid_file };
                $pid_file =~ s/##/$pid/g;
            }
            if ( !defined( $self->{ _pids }{ $pid } ) )
            {
                $self->{ _pids }{ $pid }{ name }       = $exp_name;
                $self->{ _pids }{ $pid }{ start_time } = $start_time;
                if ( defined( $self->{ _expiration } ) )
                {
                    $self->{ _pids }{ $pid }{ expiration } = $self->{ _expiration };
                }
                if ( defined( $self->{ _expiration_auto } ) )
                {
                    $self->{ _pids }{ $pid }{ expiration_auto } = $self->{ _expiration_auto };
                }
                $PID{ $pid }{ name } = $exp_name;
                if ( defined( $self->{ _pid_file } ) )
                {
                    $self->{ _pids }{ $pid }{ pid_file } = $pid_file;
                    $PID{ $pid }{ pid_file } = $pid_file;
                }
                if ( defined( $self->{ _home } ) )
                {
                    $self->{ _pids }{ $pid }{ home } = $self->{ _home };
                    $PID{ $pid }{ home } = $self->{ _home };
                }
            }
            else
            {
                return ( $CODE[9][0], $self->{ _pid }, $CODE[9][1] );
            }
            if ( !defined( $self->{ _names }{ $exp_name }{ pid } ) )
            {
                $self->{ _names }{ $exp_name }{ pid }        = $pid;
                $self->{ _names }{ $exp_name }{ start_time } = $start_time;
                if ( defined( $self->{ _expiration } ) )
                {
                    $self->{ _names }{ $exp_name }{ expiration } = $self->{ _expiration };
                }
                if ( defined( $self->{ _expiration_auto } ) )
                {
                    $self->{ _names }{ $exp_name }{ expiration_auto } = $self->{ _expiration_auto };
                }
                $NAME{ $exp_name }{ pid } = $pid;
                if ( defined( $self->{ _pid_file } ) )
                {
                    $self->{ _names }{ $exp_name }{ pid_file } = $pid_file;
                    $NAME{ $exp_name }{ pid_file } = $pid_file;
                }
                if ( defined( $self->{ _home } ) )
                {
                    $self->{ _names }{ $exp_name }{ home } = $self->{ _home };
                    $NAME{ $exp_name }{ home } = $self->{ _home };
                }
            }
            else
            {
                return ( $CODE[10][0], $self->{ _pid }, ( $self->{ _name } . $CODE[10][1] ) );
            }

            return ( $CODE[0][0], $self->{ _pid }, $CODE[0][1] );
        }
        elsif ( defined $pid )
        {
## in  child
            $SIG{ INT } = $SIG{ CHLD } = $SIG{ TERM } = 'DEFAULT';
            if ( defined( $self->{ _name } ) )
            {
                my $exp_name = $self->{ _name };
                $exp_name =~ s/##/$$/g;
                $0 = $exp_name;
	        my $main_process = new Sys::Prctl();
                $main_process->name( $0 );
            }
            $self->{ _start_time } = $start_time;

            $self->{ _pid } = $pid;
            if ( $self->{ _home } ne '' )
            {
                local ( $>, $< ) = ( $<, $> );
                my $cwd = $self->{ _home };
                chdir( $cwd )  || return ( $CODE[11][0], 0, $CODE[11][1] );
                chroot( $cwd ) || return ( $CODE[12][0], 0, $CODE[12][1] );
                $< = $>;
            }

            if ( $self->{ _gid } ne '' )
            {
                my $gid = $self->{ _gid };
                $) = "$gid $gid";
            }
            if ( $self->{ _uid } ne '' )
            {
                $> = $self->{ _uid };
            }
            if ( $self->{ _pid_file } ne '' )
            {
                my $pid_file = $self->{ _pid_file };

                $pid_file =~ s/##/$$/g;

                if ( defined $self->{ _pid_folder } )
                {
                    $pid_file = $self->{ _pid_folder } . $pid_file;
                }
                $ret = create_pid_file( $pid_file, $$ );
            }
            if ( ( exists( $self->{ _expiration } ) && ( exists( $self->{ _expiration_auto } ) ) ) )
            {
                my $sta;
                eval {
                    local $SIG{ ALRM } = sub {
                        if ( defined $self->{ _pid_file } )
                        {
                            my $pid_file = $self->{ _pid_file };
                            $pid_file =~ s/##/$$/g;

                            if ( -e $pid_file )
                            {
                                delete_pid_file( $pid_file );
                            }
                        }
			return ( $CODE[16][0], 16, $CODE[16][1] );
                      #  die "TIMEOUT";
                    };
                    alarm( $self->{ _expiration } - $self->{ _start_time } );
                    eval { $self->{ _function }( $self->{ _args } ); };
                    alarm 0;
                    return ( $CODE[16][0], 16, $CODE[16][1] );
                };
                alarm 0;
#		if ($@ && $@ =~ /TIMEOUT/)
                if ( $! =~ /Interrupted system call/ )
                {
                    return ( $CODE[16][0], 16, $CODE[16][1] );
                }
            }
            else
            {
                $self->{ _function }( $self->{ _args } );
            }

            if ( defined $self->{ _pid_file } )
            {
                my $pid_file = $self->{ _pid_file };
                $pid_file =~ s/##/$$/g;

                if ( -e $pid_file )
                {
                    delete_pid_file( $pid_file );
                }
            }
            exit 0;
        }
        elsif ( $! == &POSIX::EAGAIN )
        {
            my $o0 = $0;
            $0 = "$o0: waiting to fork";
#             sleep 5;
	    sleep $self->{ _eagain_sleep };
            $0 = $o0;
            redo;
        }
        else
        {
            return ( $CODE[8][0], 0, $CODE[8][1] );
        }
    }

}

sub kill_child
{
    my $self   = shift;
    my $pid    = shift;
    my $signal = shift || 15;
    kill $signal => $pid;
    my ($dp , $dn) = $self->clean_childs();
    return wantarray ? ( scalar( @{$dp} ), $dp, $dn ) : scalar( @{$dp} );
}

sub killall_childs
{
    my $self   = shift;
    my $signal = shift || 15;
    my $pids   = $self->{ _pids };
    my %pids   = %{ $pids };

    foreach ( keys %pids )
    {
        kill $signal => $_;
    }
    my ($dp , $dn) = $self->clean_childs();
    return wantarray ? ( scalar( @{$dp} ), $dp, $dn ) : scalar( @{$dp} );
}

sub expirate
{
    my $self   = shift;
    my $signal = shift || 15;
    my $pids   = $self->{ _pids };
    my %pids   = %{ $pids };
    my $now = time;

    foreach my $pid ( keys %pids )
    {
        if ( $self->{ _pids }{ $pid }{ expiration } < $now )
        {
	    kill $signal => $pid;
        }
    }
    my ($dp , $dn) = $self->clean_childs();
    return wantarray ? ( scalar( @{$dp} ), $dp, $dn ) : scalar( @{$dp} );
}

sub get_expiration
{
    my $self = shift;
    my $pid  = shift;
    if ( exists( $self->{ _pids }{ $pid }{ expiration } ) )
    {
        return ( $self->{ _pids }{ $pid }{ expiration } );
    }
    else
    {
        return ( $CODE[17][0], 17, $CODE[17][1] );
    }
}

sub set_expiration
{
    my $self           = shift;
    my $pid            = shift;
    my $new_expiration = shift;
    $new_expiration += time;

    if ( exists( $self->{ _pids }{ $pid }{ expiration } ) )
    {
        $self->{ _pids }{ $pid }{ expiration } = $new_expiration;
        my $name = $self->{ _pids }{ $pid }{ name };
        $self->{ _names }{ $name }{ expiration } = $new_expiration;
        return ( $self->{ _pids }{ $pid }{ expiration } );
    }
    else
    {
        return ( $CODE[17][0], 17, $CODE[17][1] );
    }
}

sub list_pids
{
    my $self = shift;
#     $self->clean_childs();
    return $self->{ _pids };
}

sub list_names
{
    my $self = shift;
#     $self->clean_childs();
    return $self->{ _names };
}

sub pid_nbr
{
    my $self = shift;
#     $self->clean_childs();
    return ( scalar( keys %{ $self->{ _pids } } ) );
}

sub clean_childs
{
    my $self = shift;
    my @pid_remove_list;
    my @name_remove_list;
    foreach my $child ( keys %{ $self->{ _pids } } )
    {
        my $state = kill 0 => $child;
        if ( !$state )
        {
            my $name = $self->{ _pids }{ $child }{ name };
            if ( defined $self->{ _pids }{ $child }{ pid_file } )
            {
                my $pid_file = $self->{ _pids }{ $child }{ pid_file };
                if ( defined $self->{ _pids }{ $child }{ home } )
                {
                    $pid_file = $self->{ _pids }{ $child }{ home } . $pid_file;
                }

                if ( -e $pid_file )
                {
                    delete_pid_file( $pid_file );
                }
                delete $self->{ _pids }{ $child }{ pid_file };
                delete $self->{ _names }{ $name }{ pid_file };
            }
            delete $self->{ _pids }{ $child }{ start_time };
            delete $self->{ _pids }{ $child }{ name };
            delete $self->{ _pids }{ $child };
            delete $self->{ _names }{ $name }{ start_time };
            delete $self->{ _names }{ $name }{ pid };
            delete $self->{ _names }{ $name };

            delete $NAME{ $name }{ pid };
            delete $NAME{ $name };

            push @pid_remove_list,  $child;
            push @name_remove_list, $name;
        }
    }

    return \@pid_remove_list, \@name_remove_list;
}

sub test_pid
{
    my $self = shift;
#     $self->clean_childs();
    my $child = shift;
    my $state;
    if ( exists $self->{ _pids }{ $child } )
    {
        $state = kill 0 => $child;
        return wantarray ? ( $state, ( $self->{ _pids }{ $child }{ name } ) ) : $state;
    }
    return wantarray ? ( 0, ( $self->{ _pids }{ $child }{ name } ) ) : $state;
}

sub test_name
{
    my $self = shift;
#     $self->clean_childs();
    my $name = shift;
    my $state;
    if ( defined( $self->{ _names }{ $name } ) )
    {
        $state = kill 0 => ( $self->{ _names }{ $name }{ pid } );
        return wantarray ? ( $state, ( $self->{ _names }{ $name }{ pid } ) ) : $state;
    }
    return wantarray ? ( 0, ( $self->{ _names }{ $name }{ pid } ) ) : $state;
}

sub version
{
    my $self = shift;
    return $VERSION;
}

sub create_pid_file
{
    my $file    = shift;
    my $pid_num = shift;
    if ( -z $file )
    {
        if ( !( -w $file && unlink $file ) )
        {
            return ( $CODE[14][0], $pid_num, $CODE[14][1] );
        }
    }
    if ( -e $file )
    {

# pid file already exists
        my $fh      = IO::File->new( $file );
        my $pid_num = <$fh>;
        close $fh;
        if ( kill 0 => $pid_num )
        {
            return ( $CODE[3][0], $pid_num, $CODE[3][1] );
        }
        if ( !( -w $file && unlink $file ) )
        {
            return ( $CODE[14][0], $pid_num, $CODE[14][1] );
        }
    }
    my $fh = IO::File->new( $file, O_WRONLY | O_CREAT | O_EXCL, 0644 );
    if ( !$fh ) { return ( $CODE[2][0], $pid_num, $CODE[2][1] ); }
    print $fh $pid_num."\n";
    close $fh;
    return ( $CODE[0][0], $pid_num, $CODE[0][1] );
}

sub delete_pid_file
{
    my $file = shift;
    if ( -e $file )
    {
        if ( !( -w $file && unlink $file ) )
        {
            Carp::carp "Can't unlink PID file $file";
        }
    }
}

sub garbage_child
{
    while ( ( my $child = waitpid( -1, WNOHANG ) ) > 0 )
    {
        my $name = $PID{ $child }{ name };
        if ( defined $PID{ $child }{ pid_file } )
        {
            my $pid_file = $PID{ $child }{ pid_file };
            $pid_file =~ s/##/$child/g;

            if ( defined $PID{ $child }{ home } )
            {
                $pid_file = $PID{ $child }{ home } . $pid_file;
            }

            if ( -e $pid_file )
            {
                delete_pid_file( $pid_file );
            }
            delete $PID{ $child }{ pid_file };
            delete $NAME{ $name }{ pid_file };
        }

        delete $PID{ $child }{ name };
        delete $PID{ $child };
        if ( exists $NAME{ $name } )
        {
            delete $NAME{ $name }{ pid };
            delete $NAME{ $name };
        }
    }
    $SIG{ CHLD } = \&garbage_child;
}

sub DESTROY
{
    my $self = shift;
    unlink $self->{ _pid_file };
}

sub getmemfree
{
    undef $/;
    open MEM, "/proc/meminfo";
    my $temp = <MEM>;
    close MEM;
    $temp =~ /MemFree:\s+(\d+) (\w+)\s/;
    my $mem  = $1;
    my $unit = $2;
    if ( $unit =~ /kb/i )
    {
        $mem *= 1024;
    }
    elsif ( $unit =~ /mb/i )
    {
        $mem *= 1048576;
    }
    $temp =~ /SwapFree:\s+(\d+) (\w+)\s/;
    my $swap = $1;
    $unit = $2;
    if ( $unit =~ /kb/i )
    {
        $swap *= 1024;
    }
    elsif ( $unit =~ /mb/i )
    {
        $swap *= 1048576;
    }
    my $tot = $mem + $swap;
    return wantarray ? ( $tot, $mem, $swap ) : $tot;
}

1;

=head1 ABSTRACT

The B<Proc::Forking.pm> module provides a set of tool to fork and daemonize.
The module fork a function code

=head1 SYNOPSIS

=over 3

	#!/usr/bin/perl

	use strict;
	use Proc::Forking;
	use Data::Dumper;
	use Time::HiRes qw(usleep);    # to allow micro sleep

	my $f = Proc::Forking->new();
	$SIG{ KILL } = $SIG{ TERM } = $SIG{ INT } = sub { $f->killall_childs;sleep 1; exit },
	          $f->daemonize(
	##              uid      => 1000,
	##              gid      => 1000,
	##              home     => "/tmp",
	              pid_file => "/tmp/master.pid"
	          );

	open( STDOUT, ">>/tmp/master.log" );
	my $nbr = 0;
	my $timemout;

	while ( 1 )
	{
	    if ( $nbr < 20 )
    	{
	        my $extra = "other parameter";
	        my ( $status, $pid, $error ) = $f->fork_child(
	            function => \&func,
	            name     => "new_name.##",
	            args     => [ "hello SOMEONE", 3, $extra ],
	            pid_file => "/tmp/fork.##.pid",
	            uid      => 1000,
	            gid      => 1000,
	            home       => "/tmp",
	            max_load   => 5,
	            max_mem    => 185000000,
	            expiration => 10,
	#	    expiration_auto => 1,
	        );
	        if ( $status == 4 )    # if the load become to high
	        {
	            print "Max load reached, do a little nap\n";
	            usleep( 100000 );
	            next;
	        }
	        elsif ( $status )      # if another kind of error
	
	        {
	            print "PID=$pid\t error=$error\n";
	            print Dumper( $f->list_names() );
	            print Dumper( $f->list_pids() );
	        }
	    }
	    $nbr = $f->pid_nbr;
	    my ( $n, @dp, @dn ) = $f->expirate;
	    if ( $n )
	    {
	        print Dumper( @dp );
	    }
	    print "free=<" . scalar( $f->getmemfree ) . ">\n";
	    usleep( 100000 );    # always a good idea to put a small sleep to allow task swapper to gain some free resources
	}
	
	sub func
	{
	    my $ref  = shift;
	    my @args = @$ref;
	    my ( $data, $time_out, $sockC ) = @args;
	    $SIG{ USR1 } = sub { open my $log, ">>/tmp/log.s"; print $log "signal USR1 received\n"; close $log; };
	    if ( !$time_out )
	    {
	        $time_out = 3;
	    }
	    open my $FF, ">>/tmp/loglist";
	    print $FF $$, " start time =", $^T;
	    close $FF;
	
	    for ( 1 .. 4 )
	    {
	        open my $fh, ">>/tmp/log";
	        if ( defined $fh )
	        {
	            print $fh "TMOUT = $time_out  " . time . " PID=$$  cwd=" . Cwd::cwd() . " name =$0\n";
	            $fh->close;
	        }
	        sleep $time_out + rand( 5 );
	    }
	}


=back

=head1 REQUIREMENT

The B<Proc::Forking> module need the following modules

	POSIX
	IO::File
	Cwd
	Sys::Load

=head1 METHODS

=over 1

The Fork module is object oriented and provide the following method


=back

=head2 new

To create of a new pool of child: 

	my $f = Proc::Forking->new();


=head2 fork_child

To fork a process

	my ( $status, $pid, $error ) = $f->fork_child(
              function        => \&func,
              name            => "new_name.$_",
              args            => [ "\thello SOMEONE",3, $other param],
              pid_file        => "/tmp/fork.$_.pid",
              uid             => 1000,
              gid             => 1000,
              home            => "/tmp",q
              max_load        => 5,
              max_child       => 5,
	      max_mem         => 1850000000,
	      expiration      => 20,
	      expiration_auto => 1,
	      strict          => 1,
	      eagain_sleep    => 2,
              );
	
The only mandatory parameter is the reference to the function to fork (function => \&func)
The normal return value is an array with: 3 elements (see B<RETURN VALUE>)

=over 2

=back

=head3 function

=over 3

I<function> is the reference to the function to use as code for the child. It is the only mandatory parameter.

=back

=head3 name

=over 3

I<name> is the name for the newly created process (affect new_name  to $0 in the child).
A ## (double sharp) into the name is replaced with the PID of the process created.

=back

=head3 home

=over 3

the I<path> provided will become the working directory of the child with a chroot.
Be carefull for the files created into the process forked, authorizasions and paths are relative to this chroot

=back

=head3 uid

=over 3

the child get this new I<uid> (numerical value)
Be carefull for the files created into the process forked, authorizations and paths are relative to this chroot

=back

=head3 gid

=over 3

the child get this new I<gid> (numerical value)
Be carefull for the files created into the process forked, authorizations and paths are relative to this chroot

=back

=head3 pid_file

=over 3

I<pid_file> give the file containing the pid of the child (be care of uid, gid and chroot because the pid_file is created by the child)
A ## (double sharp ) into the name is expanded with the PID of the process created

=back

=head3 max_load

=over 3

if the "1 minute" load is greater than I<max_load>, the process is not forked
and the function will return [ 4, 0, "maximun LOAD reached" ]

=back

=head3 max_child

=over 3

if the number of running child is greater than max_child, the process is not forked
and the function return [ 5, 0,  "maximun number of processes reached" ]

=back

=head3 max_mem

=over 3

if the total free memory is lower than this value, the process is not forked
and the function will return [ 15, 0, "maximun MEM used reached" ]

=back

=head3 expiration

=over 3

it is a value linked with each forked process to allow the function expirate() 
to kill the process if it is still running after that expiration time
The expiration value write in list_pids and list_names are this value (in sec ) + the start_time 
(to allow set_expiration to modify the value)

=back


=head3 expiration_auto

=over 3

if defined, the child kill themselve after the defined expiration time (!!! the set_expiration function is not able to modify this expiration time)

=back


=head3 strict

=over 3

if defined, the process is not forked if the NAME is already in process table, or if the PID_FILE id present and a corresponding process is still running

BECARE, because the test is done before the fork, the NAME and the PID_FILE is not expanded with the child PID


=back


=head3 eagain_sleep

=over 3

timeout between a new try of forking if POSIX::EAGAIN error occor ( default 5 second);


=back

=head2 kill_child

	$f->kill_child(PID[,SIGNAL]);
 
 This function kill with a signal 15 (by default) the process with the provided PID.
 An optional signal could be provided.
 This function return the number of childs killed, a ref to a list of PID killed, a ref to a list of names killed.


=head2 killall_childs

	$f->killall_childs([SIGNAL]);

This function kills all processes with a signal 15 (by default).
An optional signal could be provided.
This function return the number of childs killed, a ref to a list of PID killed, a ref to a list of names killed.
 
=head2 list_pids

	my $pid = $f->list_pids;

This function return a reference to a HASH like 

       {
          '1458' => {
                      'pid_file' => '/tmp/fork.3.pid',
                      'name' => 'new_name.3',
                      'home' => '/tmp',
		      'expiration' => '1105369235',
		      'start_time' => 1104998945
                    },
          '1454' => {
                      'pid_file' => '/tmp/fork.1.pid',
                      'name' => 'new_name.1',
                      'home' => '/tmp'
                    },
          '1456' => {
                      'pid_file' => '/tmp/fork.2.pid',
                      'name' => 'new_name.2',
                      'home' => '/tmp'
                    }
        };


The I<pid_file> element in the HASH is only present if we provide the corresponding tag in the constructor B<fork_child>
Same for I<home> element

=head2 list_names

	my $name = $f->list_names;

This function return a reference to a HASH like  
          
	  {
          'new_name.2' => {
                            'pid_file' => '/tmp/fork.2.pid',
                            'pid' => 1456,
                            'home' => '/tmp'
			    'expiration' => '1104999045',
		            'start_time' => 1104998945
                          },
          'new_name.3' => {
                            'pid_file' => '/tmp/fork.3.pid',
                            'pid' => 1458,
                            'home' => '/tmp'
                          },
          'new_name.1' => {
                            'pid_file' => '/tmp/fork.1.pid',
                            'pid' => 1454,
                            'home' => '/tmp'
                          }
        };

The I<pid_file> element in the HASH is only present if we provide the corresponding tag in the constructor B<fork_child>
Same for I<home> element
	
=head2 expirate

	my ($n, $dp, n ) =$f->expirate([signal])

This function test if child reach the expiration time and kill if necessary with the optional signal (default 15).
In scalar context, this function return the number of childs killed.
In array context, this function return the number of childs killed, a ref to a list of PID killed, a ref to a list of names killed.

=head2 get_expirate

	$f->get_expirate(PID)

This function return the expiration time for the PID process provided
Be care!!! If called from a child,  you could only receive the value of child forked before the child from where you call that function

=head2 set_expirate

	$f->set_expirate(PID, EXP)

This function set the expiration time for the PID process provided.
The new expiration time is the value + the present time.
This function is only useable fron main program (not childs)


=head2 getmemfree

	$f->getmemfree

In scalar context, this function return the total free memory (real + swap).
In array context, this function return ( total_memory, real_memory, swap_memory).

	
=head2 pid_nbr

	$f->pid_nbr

This function return the number of process

=head2 clean_childs

	my (@pid_removed , @name_removed) =$f->clean_childs
	
This function return a ref to a list list of pid(s)  and a ref to a list of name(s) removed because no more responding

=head2 test_pid

	my @state = $f->test_pid(PID);
	
In ARRAY context, this function return a ARRAY with 
the first element is the status (1 = running and 0 = not running) 
the second element is the NAME of process if the process with the PID is present in pid list and running
In SCALAR contect, this function return the status (1 = running and 0 = not running)

=head2 test_name

	my @state = $f->test_pid(NAME);
	
In ARRAY context, this function return a ARRAY with
the first element is the status (1 = running and 0 = not running)
the second element is the PID of the process if the process with the NAME is present in name list and running.
In SCALAR contect, this function return the status (1 = running and 0 = not running)
	
=head2 version

	$f->version;

Return the version number

=head2 daemonize

	$f->daemonize(
		uid=>1000,
		gid => 1000,
		home => "/tmp",
		pid_file => "/tmp/master.pid"
		name => "DAEMON"
		);
		
This function put the main process in daemon mode and detaches it from console
All parameter are optional
The I<pid_file> is always created in absolute path, before any chroot either if I<home> is provided.
After it's creation, the file is chmod according to the provided uid and gig
When process is kill, the  pid_file is deleted

=head3 uid

=over 3

the process get this new uid  (numerical value)

=back

=head3 gid

=over 3

the process get this new gid (numerical value)

=back

=head3 home

=over 3

the path provided become the working directory of the child with a chroot

=back

=head3 pid_file

I<pid_file> specified the path to the pid_file for the child
Be carefull of uid, gid and chroot because the pid_file is created by the child)

=head3 name

=over 3

I<name> is the name for the newly created process (affect new_name  to $0 in the child).
A ## (double sharp ) into the name is replaced with the PID of the process created.

=back

=head1 RETURN VALUE

I<fork_child()> constructor returns an array of 3 elements:
        
	1) the numerical value of the status
        2) th epid if the fork succeed
        3) the text of the status
	
the different possible values are:

	[ 0, PID, "success" ];
	[ 1, 0, "Can't fork a new process" ];
	[ 2, PID, "Can't open PID file" ];
	[ 3, PID, "Process already running with same PID" ];
	[ 4, 0, "maximun LOAD reached" ];
	[ 5, 0,  "maximun number of processes reached" ];
	[ 6, 0, "error in parameters" ];
	[ 7, 0, "No function provided" ];
	[ 8, 0  "Can't fork" ];
	[ 9, PID, "PID already present in list of PID processes" ];
	[ 10, PID, "NAME already present in list of NAME processes" ];
	[ 11, 0, "Can't chdir" ];
	[ 12, 0  "Can't chroot" ];
	[ 13, 0, "Can't become DAEMON" ];
	[ 14, PID, "Can't unlink PID file" ];
	[ 15, 0, "maximun MEM used reached" ];
	[ 16, 16, "Expiration TIMEOUT reached" ];
        [ 17, 16, "NO expiration parameter" ];
	[ 18, " Don't fork, NAME already present (STRICT mode enbled)" ];
	[ 19, " Don't fork, PID_FILE already present (STRICT mode enbled)" ];

=head1 EXAMPLES

	#!/usr/bin/perl
	
	use strict;
	use Proc::Forking;
	use Data::Dumper;
	use Cache::FastMmap;
	
	my $Cache = Cache::FastMmap->new( raw_values => 1 );
	my $f     = Proc::Forking->new();
	
	my $nbr = 0;
	my $timemout;
	my $flag = 1;
	$SIG{ INT } = $SIG{ TERM } = sub { $flag = 0; };
	
	while ( $flag )
	{
	    if ( $nbr < 5 )
	    {
	        my $extra = "other parameter";
	        my ( $status, $pid, $error ) = $f->fork_child(
	            function => \&func,
	            name     => "new_name.##",
	            args     => [ "hello SOMEONE", ( 300 + rand( 100 ) ), $extra ],
	            pid_file => "/tmp/fork.##.pid",
	#            uid      => 1000,
	#            gid      => 1000,
	#            home     => "/tmp",
	#            max_load => 5,
	#	    max_mem => 1850000000,
	#            expiration_auto => 0,
	            expiration => 10 + rand( 10 ),
	        );
	        if ( $status == 4 )    # if the load become to high
	        {
	            print "Max load reached, do a little nap\n";
	            usleep( 100000 );
	            next;
	        }
	        elsif ( $status )      # if another kind of error
	        {
	            print "PID=$pid\t error=$error\n";
	        }
	    }
	    $nbr = $f->pid_nbr;
	    print "nbr=$nbr\n";   
	    
	    foreach ( keys %list )
	    {
	        my $val = $Cache->get( $_ );
	        if ( $val )
	        {
	            $Cache->remove( $_ );
	            $f->set_expiration( $_, $val );
	            print "*********PID=$_  val=$val\n";
	        }
	    }
	    sleep 1;
	
	   my ($n,@dp,@dn)=$f->expirate;
	   if($n)
	   {
	      print Dumper(@dp);
	   }
	}    
	
	
	    
	sub func
	{
	    my $ref  = shift;
	    my @args = @$ref;
	    my ( $data, $time_out, $sockC ) = @args;
	    $SIG{ USR1 } = sub { open my $log, ">>/tmp/log.s"; print $log "signal USR1 received\n"; close $log; };
	    $SIG{ USR2 } = sub { open my $log, ">>/tmp/log.s"; print $log "signal USR2 received for process $$ \n"; close $log; $Cache->set( $$, 123 ); };
	    if ( !$time_out )
	    {
	        $time_out = 3;
	    }
	    
	    open my $FF, ">>/tmp/loglist";
	    print $FF "$$ free=<" . scalar( $f->getmemfree ) . ">\n";
	    close $FF;
	    
	    while ( 1 )
	    {
	        open my $fh, ">>/tmp/log";
	        if ( defined $fh )
	        {
	            print $fh "$$ expiration=<" . $f->get_expiration . ">\n";
	            print $fh "TMOUT = $time_out  " . time . " PID=$$  cwd=" . Cwd::cwd() . " name =$0\n";
	            $fh->close;
	        }
	        sleep $time_out + rand( 5 );
	    }
	}
	


    
=head1 TODO

=over

=item *

May be a kind of IPC

=item *

A log, debug and/or syslog part 

=item *

A good test.pl for the install

=back

=head1 AUTHOR

Fabrice Dulaunoy <fabrice@dulaunoy.com>

15 July 2009

=head1 LICENSE

Under the GNU GPL2

    
    This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public 
    License as published by the Free Software Foundation; either version 2 of the License, 
    or (at your option) any later version.

    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
    See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along with this program; 
    if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

    Proc::Forking    Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009 DULAUNOY Fabrice  Proc::Forking comes with ABSOLUTELY NO WARRANTY; 
    for details See: L<http://www.gnu.org/licenses/gpl.html> 
    This is free software, and you are welcome to redistribute it under certain conditions;
   
