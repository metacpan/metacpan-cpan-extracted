
package NetApp::Filer;

our $VERSION = '500.002';
$VERSION = eval $VERSION;  ##  no critic: StringyEval

use strict;
use warnings;
use English;
use Carp;

use Class::Std;
use Params::Validate qw( :all );
use IPC::Cmd qw( run );
use Regexp::Common;
use Net::Telnet;
use Clone qw(clone);

use Data::Dumper;

use Memoize;
use NetApp::Filer::TimeoutCache;

use NetApp::Filer::Version;
use NetApp::Filer::License;
use NetApp::Filer::Option;
use NetApp::Filer::Export;

{

    my %hostname_of		:ATTR( get => 'hostname' );
    my %username_of		:ATTR( get => 'username' );

    my %protocol_of		:ATTR;

    my %ssh_identity_of		:ATTR;
    my %ssh_command_of		:ATTR;

    my %telnet_password_of	:ATTR;
    my %telnet_timeout_of	:ATTR;
    my %telnet_session_of	:ATTR;
    my %telnet_session_by;	# NOT an ATTR.  Keyed on hostname/username

    my %command_status_of	:ATTR;
    my %command_error_of	:ATTR;
    my %command_stdout_of	:ATTR;
    my %command_stderr_of	:ATTR;

    my %version_of		:ATTR( get => 'version' );

    my %cache_enabled_of	:ATTR;
    my %cache_of		:ATTR;

    my %snapmirror_state_of	:ATTR;

    sub BUILD {

        my ($self,$ident,$args_ref) = @_;

        my @args = %$args_ref;

        my (%args) 		= validate( @args, {
            hostname		=> {
                type		=> SCALAR,
            },
            username		=> {
                type		=> SCALAR,
                default		=> 'root',
                optional	=> 1,
            },
            protocol		=> {
                type		=> SCALAR,
                regex		=> qr{^(ssh|telnet)$},
                default		=> 'ssh',
                optional	=> 1,
            },
            telnet_password	=> {
                type		=> SCALAR,
                optional	=> 1,
            },
            telnet_timeout	=> {
                type		=> SCALAR,
                default		=> 60,
                optional	=> 1,
            },
            ssh_identity 	=> {
                type		=> SCALAR,
                optional	=> 1,
            },
            ssh_command		=> {
                type		=> ARRAYREF,
                default		=> [qw( ssh )],
                optional	=> 1,
            },
            cache_enabled 	=> {
                type		=> SCALAR,
                default		=> 0,
                optional	=> 1,
            },
            cache_expiration 	=> {
                type		=> SCALAR,
                default		=> 10,
                optional	=> 1,
            },
        });

        $hostname_of{$ident}	= $args{hostname};
        $username_of{$ident}	= $args{username};
        $protocol_of{$ident}	= $args{protocol};
        
        $command_stdout_of{$ident}	= [];
        $command_stderr_of{$ident}	= [];

        if ( $protocol_of{$ident} eq 'ssh' ) {

            if ( $args{telnet_password} ) {
                $telnet_password_of{$ident} = $args{telnet_password};
            }

            $ssh_command_of{$ident}	= clone $args{ssh_command};

            if ( $args{ssh_identity} ) {

                if ( not -f $args{ssh_identity} ) {
                    croak("No such ssh_identity file: $args{ssh_identity}\n");
                } 

                $ssh_identity_of{$ident}	= $args{ssh_identity};

                push( @{ $ssh_command_of{$ident} },
                      '-i', $ssh_identity_of{$ident} );

            }

            push( @{ $ssh_command_of{$ident} },
                  '-l', $username_of{$ident}, $hostname_of{$ident} );
        } else {

            $telnet_timeout_of{$ident}	= $args{telnet_timeout};

            $telnet_password_of{$ident} = $args{telnet_password};

            $telnet_session_by{ $args{hostname}, $args{username} } ||=
                $self->_telnet_connect();

            $telnet_session_of{$ident}	=
                $telnet_session_by{ $args{hostname}, $args{username} };

        }

        $self->_run_command(
            command	=> [qw( version )],
        );

        my @stdout	= $self->_get_command_stdout;

        $version_of{$ident} = NetApp::Filer::Version->new({
            string	=> $stdout[0],
        });

        $cache_enabled_of{$ident} = $args{cache_enabled};

        return 1 if not $args{cache_enabled};

        $cache_of{$ident} = {
            get_aggregate	=> {},
            get_volume		=> {},
            get_qtree		=> {},
        };

        foreach my $method ( keys %{ $cache_of{$ident} } ) {

            if ( $args{cache_expiration} ) {
                
                tie %{ $cache_of{$ident}->{$method} },
                    'NetApp::Filer::TimeoutCache',
                        lifetime => $args{cache_expiration};

                memoize(
                    $method,
                    SCALAR_CACHE => [ HASH => $cache_of{$ident}->{$method} ],
                    LIST_CACHE	 => 'MERGE',
                );

            } else {

                memoize $method;

            }
            
        }

    }

    sub _telnet_connect {

        my $self	= shift;
        my $ident	= ident $self;

        my $timeout	= $telnet_timeout_of{$ident};
        my $hostname	= $hostname_of{$ident};
        my $username	= $username_of{$ident};
        my $password	= $telnet_password_of{$ident};

        my $session 	= Net::Telnet->new(
            Timeout	=> $timeout,
            Prompt	=> '/> |\*> /',
        );

        if ( $ENV{NETAPP_TELNET_DEBUG} ) {
            $session->input_log('/var/tmp/netapp-telnet-debug.log');
        }

        $session->open( $hostname );

        $session->waitfor('/login:/');
        $session->print( $username );
        $session->waitfor('/Password:/');
        $session->print( $password );

        eval { $session->waitfor( $session->prompt )  };
        if ( $@ ) {
            croak(
                "Unable to authenticate to $hostname: $@\n"
            );
        }

        return $session;

    }

    sub _run_command {

        my $self	= shift;
        my $ident	= ident $self;

        my $protocol	= $protocol_of{$ident};

        if ( $protocol eq 'ssh' ) {
            return $self->_run_ssh_command(@_);
        } else {
            return $self->_run_telnet_command(@_);
        }
        
    }

    sub _run_telnet_command {

        my $self	= shift;
        my $ident	= ident $self;

        my %args	= validate( @_, {
            command	=> { type	=> ARRAYREF },
            nonfatal	=> { type	=> SCALAR,
                             optional	=> 1 },
        });

        my @command	= ();

        foreach my $argument ( @{ $args{command} } ) {
            if ( $argument =~ /[()]/ ) {
                push @command, qq{'$argument'};
            } else {
                push @command, $argument;
            }
        }

        my $command	= join(" ",@command);

        my @results;

        eval {
            @results	= $telnet_session_of{$ident}->cmd($command);
        };
        
        my $error	= $@;

        if ( $error ) {
            croak(
                "Remote telnet command execution failed!!\n",
                "Command: $command\n",
                "Error: $error\n",
            );
        }

        chomp @results;

        my @stdout	= ();
        my @stderr	= ();

        # XXX: Get rid of the command we sent, which will be the first
        # line in the results, and the part of the prompt that we
        # don't pattern match, which will be the last line.  This
        # keeps getting uglier.... Sometimes the command is NOT the
        # first line of output...
        if ( $results[0] =~ /$command/ ) {
            shift @results;
        }

        pop @results;

        my $command_first	= $command[0];
        my $command_second	= $command[1] || '';

        foreach my $result ( @results ) {

            # XXX: OK, this may get out of hand, but this assumption
            # is not always correct.  We have found at least one case
            # where a non-error is prefixed with the command name.  If
            # we have to add a lot of exceptions here, we'll need a
            # more scalable solution.
            #
            # OK, we have two now....   Using telnet sucks....
            #
            # Yep... This is starting to get ugly....
            if ( $result =~ /^snap reclaimable: Approximately/ ) {
                push @stdout, $result;
            } elsif ( $result =~ /^vol size: .* has size/ ) {
                push @stdout, $result;
            } elsif ( $result =~ /^snap delta: No snapshots exist/ ) {
                push @stdout, $result;
            } elsif ( $result =~ /^$command_first:/ ||
                     $result =~ /^$command_first $command_second:/ ) {
                push @stderr, $result;
            } else {
                push @stdout, $result;
            }

        }

        $command_stdout_of{$ident} 	= [ @stdout ];
        $command_stderr_of{$ident}	= [ @stderr ];

        if ( @stderr ) {
            $command_status_of{$ident}	= 0;
            if ( ! $args{nonfatal} ) {
                my $hostname	= $self->get_hostname;
                croak(
                    "Error running '$command' via telnet on $hostname:\n",
                    @stderr,
                );
            }
        } else {
            $command_status_of{$ident}	= 1;
        }

        return $command_status_of{$ident};

    }

    sub _run_ssh_command {

        my $self	= shift;
        my $ident	= ident $self;

        my %args	= validate( @_, {
            command	=> { type	=> ARRAYREF },
            nonfatal	=> { type	=> SCALAR,
                             optional	=> 1 },
        });

        my $command	= join(" ",@{ $args{command} });

        my @command	= @{ $self->_get_ssh_command };

        foreach my $argument ( @{ $args{command} } ) {
            if ( $argument =~ /[()]/ ) {
                push @command, qq{'$argument'};
            } else {
                push @command, $argument;
            }
        }

        my @results	= run( command => \@command );

        my $full_command	= join(" ",@command);

        $command_status_of{$ident}	= $results[0];
        $command_error_of{$ident}	= $results[1];

        my $stdout	= join( '', @{ $results[3] } );

        $command_stdout_of{$ident} 	= [ split( /\n/, $stdout ) ];

        my $stderr	= join( '', @{ $results[4] } );

        $command_stderr_of{$ident} 	= [ split( /\n/, $stderr ) ];

        if ( not $command_status_of{$ident} ) {
            croak(
                "Remote ssh command execution failed!!\n",
                "Command: $full_command\n",
                "Command_Error code: $command_error_of{$ident}\n",
                "STDERR: $stderr\n",
            );
        }

        if ( $stderr && ! $args{nonfatal} ) {
            my $hostname	= $self->get_hostname;
            croak(
                "Error running '$command' via ssh on $hostname:\n",
                $stderr,
            );
        }

        return $command_status_of{$ident};

    }

    sub _get_command_stdout {
        return @{ $command_stdout_of{ident shift} };
    }

    sub _get_command_stderr {
        return @{ $command_stderr_of{ident shift} };
    }

    sub _get_command_status {
        return $command_status_of{ident shift};
    }

    sub _get_command_error {
        return $command_error_of{ident shift};
    }

    sub _get_ssh_command {
        return $ssh_command_of{ident shift};
    }

    sub _clear_cache {

        my $self	= shift;
        my $ident	= ident $self;

        my (%args)	= validate( @_, {
            method	=> { type	=> SCALAR },
            key		=> { type	=> SCALAR,
                             optional	=> 1 },
        });

        if ( not $cache_enabled_of{$ident} ) {
            return 1;
        }

        if ( not exists $cache_of{$ident}->{ $args{method} } ) {
            croak("Invalid argument: $args{method} is not cached\n");
        }

        if ( $args{key} ) {
            # XXX: The keys might be more complex than this...
            delete $cache_of{$ident}->{ $args{method} }->{ $args{key} };
        } else {
            %{ $cache_of{$ident}->{ $args{method} } } = ();
        }

        return 1;

    }

    sub get_licenses {

        my $self	= shift;

        $self->_run_command(
            command	=> [qw( license )],
        );

        my @stdout	= $self->_get_command_stdout;

        my @licenses	= ();

        while ( my $line = shift @stdout ) {

            next if $line =~ /not licensed/;

            my $license	= $self->_parse_license( $line );

            push @licenses, NetApp::Filer::License->new( $license );

        }

        return @licenses;

    }

    sub get_license {

        my $self	= shift;
        my $service	= shift;

        return grep { $_->get_service eq $service } $self->get_licenses;

    }

    sub add_license {

        my $self	= shift;
        my $code	= shift;

        return $self->_run_command(
            command	=> [qw(license add), $code ],
        );

    }

    sub delete_license {

        my $self	= shift;
        my $service	= shift;

        return $self->_run_command(
            command	=> [qw(license delete), $service ],
        );
    }

    sub get_options {

        my $self	= shift;

        $self->_run_command(
            command	=> ['options'],
        );

        my @stdout	= $self->_get_command_stdout;

        my @options	= ();

        while ( my $line = shift @stdout ) {

            my $option	= $self->_parse_option( $line );

            push @options, NetApp::Filer::Option->new ( $option );

        }

        return @options;

    }

    sub get_aggregate_names {

        my $self	= shift;

        $self->_run_command(
            command	=> [qw( aggr status )],
        );

        my @stdout	= $self->_get_command_stdout;

        my $indices =
            NetApp::Aggregate->_parse_aggr_status_headers( shift @stdout );

        my @names	= ();

        while ( my $line = shift @stdout ) {

            my $data	= NetApp::Aggregate->_parse_aggr_status_aggregate(
                indices	=> $indices,
                line	=> $line,
            );

            if ( $data->{name} ) {
                push( @names, $data->{name} );
            }

        }

        return @names;
        
    }

    sub get_aggregates {
        
        my $self	= shift;

        my @aggregates	= ();

        foreach my $name ( $self->get_aggregate_names ) {
            push @aggregates, $self->get_aggregate( $name );
        }

        return @aggregates;

    }

    sub get_aggregate {
        
        my $self	= shift;
        my $name	= shift;

        $self->_run_command(
            command	=> [qw( aggr status ), $name, '-v' ],
        );

        my @stdout	= $self->_get_command_stdout;

        my $indices =
            NetApp::Aggregate->_parse_aggr_status_headers( shift @stdout );

        my $aggregate	= {};

        while ( my $line = shift @stdout ) {
            last if $line	=~ /^\s+$/;
            NetApp::Aggregate->_parse_aggr_status_aggregate(
                indices		=> $indices,
                aggregate	=> $aggregate,
                line		=> $line,
            );
        }

        my $volumes	= {};

        if ( $aggregate->{status}->{aggr} ) {
            while ( my $line = shift @stdout ) {
                last if $line	=~ /^\s+$/;
                NetApp::Aggregate->_parse_aggr_status_volumes(
                    volumes		=> $volumes,
                    line		=> $line,
                );
            }
        }

        my $plex =
            NetApp::Aggregate->_parse_aggr_status_plex( shift @stdout );

        while ( my $line = shift @stdout ) {
            last if $line =~ /^\s+$/;
            push @{ $plex->{raidgroups} },
                NetApp::Aggregate->_parse_aggr_status_raidgroup( $line );
        }


        return NetApp::Aggregate->new({
            filer	=> $self,
            %$aggregate,
            volumes	=> $volumes,
            plex	=> $plex,
        });

    }

    sub create_aggregate {

        my $self	= shift;

        my (%args)	= validate( @_, {
            name	=> { type	=> SCALAR },
            raidtype	=> { type	=> SCALAR,
                             optional	=> 1 },
            raidsize	=> { type	=> SCALAR,
                             optional	=> 1 },
            disktype	=> { type	=> SCALAR,
                             optional	=> 1 },
            diskcount	=> { type	=> SCALAR,
                             optional	=> 1 },
            disksize	=> { type	=> SCALAR,
                             depends	=> [qw( diskcount )],
                             optional	=> 1 },
            rpm		=> { type	=> SCALAR,
                             optional	=> 1 },
            language	=> { type	=> SCALAR,
                             optional	=> 1 },
            snaplock	=> { type	=> SCALAR,
                             optional	=> 1 },
            mirrored	=> { type	=> SCALAR,
                             optional	=> 1 },
            traditional	=> { type	=> SCALAR,
                             optional	=> 1 },
            force	=> { type	=> SCALAR,
                             optional	=> 1 },
            disks	=> { type	=> ARRAYREF,
                             optional	=> 1 },

        });

        my @command	= ( qw( aggr create ), $args{name} );

        if ( $args{force} ) {
            push @command, '-f';
        }

        if ( $args{mirrored} ) {
            push @command, '-m';
        }

        if ( $args{raidtype} ) {
            push @command, '-t', $args{raidtype};
        }

        if ( $args{raidsize} ) {
            push @command, '-r', $args{raidsize};
        }

        if ( $args{disktype} ) {
            push @command, '-T', $args{disktype};
        }

        if ( $args{rpm} ) {
            push @command, '-R', $args{rpm};
        }

        if ( $args{snaplock} ) {
            push @command, '-L', $args{snaplock};
        }

        if ( $args{traditional} ) {
            push @command, '-v';
        }

        if ( $args{language} ) {
            push @command, '-l', $args{language};
        }

        if ( $args{diskcount} ) {
            if ( $args{disksize} ) {
                push @command, join( '@', $args{diskcount}, $args{disksize} );
            } else {
                push @command, $args{diskcount};
            }
        }

        if ( $args{disks} ) {
            if ( ref $args{disks}->[0] eq 'ARRAY' ) {
                push @command, '-d', @{ $args{disks}->[0] };
                push @command, '-d', @{ $args{disks}->[1] };
            } else {
                push @command, '-d', @{ $args{disks} };
            }
        }

        $self->_run_command( command => \@command );

        return $self->get_aggregate( $args{name} );

    }

    sub destroy_aggregate {

        my $self	= shift;

        my (%args)	= validate( @_, {
            name	=> { type	=> SCALAR },
        });

        return $self->_run_command(
            command	=> [qw( aggr destroy ), $args{name}, '-f'],
        );

    }

    sub get_volume_names {

        my $self	= shift;

        $self->_run_command(
            command	=> [qw( vol status )],
        );

        my @stdout	= $self->_get_command_stdout;

        my $indices =
            NetApp::Volume->_parse_vol_status_headers( shift @stdout );

        my @names	= ();

        while ( my $line = shift @stdout ) {

            my $data	= NetApp::Volume->_parse_vol_status_volume(
                indices	=> $indices,
                line	=> $line,
            );

            if ( $data->{name} ) {
                push( @names, $data->{name} );
            }

        }

        return @names;

    }

    sub get_volumes {
        
        my $self	= shift;

        my @volumes	= ();

        foreach my $name ( $self->get_volume_names ) {
            push @volumes, $self->get_volume( $name );
        }

        return @volumes;

    }

    sub get_volume {
        
        my $self	= shift;
        my $name	= shift;

        $self->_run_command(
            command	=> [qw( vol status ), $name, '-v' ],
        );

        my @stdout	= $self->_get_command_stdout;

        my $indices =
            NetApp::Volume->_parse_vol_status_headers( shift @stdout );

        my $volume	= {};

        while ( my $line = shift @stdout ) {
            last if $line =~ /^\s+$/;
            NetApp::Volume->_parse_vol_status_volume(
                indices		=> $indices,
                volume		=> $volume,
                line		=> $line,
            );
        }

        my $plex =
            NetApp::Aggregate->_parse_aggr_status_plex( shift @stdout );

        while ( my $line = shift @stdout ) {
            last if $line =~ /^\s+$/;
            push @{ $plex->{raidgroups} },
                NetApp::Aggregate->_parse_aggr_status_raidgroup( $line );
        }

        $volume->{ filer }	= $self;
        $volume->{ plex }	= $plex;

        return NetApp::Volume->new( $volume );

    }

    sub get_qtree_names {
        return map { $_->get_name } shift->get_qtrees;
    }

    sub get_qtrees {
        return shift->_get_qtree_status;
    }

    sub get_qtree {
        return shift->_get_qtree_status( name => shift );
    }

    sub _get_qtree_status {

        my $self 	= shift;
        my (%args)	= validate( @_, {
            name	=> { type	=> SCALAR,
                             optional	=> 1 },
            volume	=> { isa	=> 'NetApp::Volume',
                             optional	=> 1 },
        });

        if ( $args{volume} && $args{volume}->get_state('restricted') ) {
            return;
        }

        my @command	= qw(qtree status -v -i);

        if ( $args{name} ) {
            my ($volume_name) = ( split( /\//, $args{name} ) )[2];
            push @command, $volume_name;
        } elsif ( $args{volume} ) {
            push @command, $args{volume}->get_name;
        }

        $self->_run_command(
            command	=> \@command,
        );

        my @stdout	= $self->_get_command_stdout;

        splice( @stdout, 0, 2 ); # trash the two headers

        my @qtrees	= ();

        while ( my $line = shift @stdout ) {
            my $qtree	= NetApp::Qtree->_parse_qtree_status_qtree( $line );
            $qtree->{ filer } = $self;
            push @qtrees, NetApp::Qtree->new( $qtree );
        }

        if ( $args{name} ) {
            my ($qtree) = grep { $_->get_name eq $args{name} } @qtrees;
            return $qtree;
        } else {
            return @qtrees;
        }

    }

    sub create_qtree {

        my $self	= shift;

        my (%args)	= validate( @_, {
            name	=> { type	=> SCALAR },
            mode	=> { type	=> SCALAR,
                             optional	=> 1 },
            security	=> { type	=> SCALAR,
                             optional	=> 1 },
            oplocks	=> { type	=> SCALAR,
                             optional	=> 1 },
        });

        my @command	= ( 'qtree', 'create', $args{name} );

        if ( $args{mode} ) {
            push @command, '-m', sprintf( "%o", $args{mode} );
        }

        $self->_run_command( command => \@command );

        $self->_clear_cache( method => 'get_qtree' );

        my $qtree	= $self->get_qtree( $args{name} );

        if ( not $qtree ) {
            croak(
                "Unable to retrieve the qtree object for $args{name},\n",
                "which we just created successfully!!\n",
            );
        }

        if ( exists $args{security} ) {
            $qtree->set_security( $args{security} );
        }

        if ( exists $args{oplocks} ) {
            $qtree->set_oplocks( $args{oplocks} );
        }

        return $qtree;

    }

    sub set_snapmirror_state {

        my $self	= shift;
        my $ident	= ident $self;

        my $state	= shift;

        if ( $state !~ /^(off|on)$/ ) {
            croak(
                "Invalid snapmirror state '$state'\n",
                "Must be either 'off' or 'on'\n",
            );
        }

        $self->_run_command( command => [qw( snapmirror $state )] );

        $snapmirror_state_of{$ident} = $state;

        return 1;

    }

    sub get_snapmirror_state {

        my $self	= shift;
        my $ident	= ident $self;

        if ( $snapmirror_state_of{$ident} !~ /^(off|on)$/ ) {
            $self->get_snapmirrors;
        }

        return $snapmirror_state_of{$ident};

    }

    sub get_snapmirrors {
        return shift->_get_snapmirrors;
    }

    sub _get_snapmirrors {

        my $self	= shift;
        my $ident	= ident $self;

        my (%args)	= validate( @_, {
            volume	=> { isa	=> 'NetApp::Volume',
                             optional	=> 1 },
        });

        my @command	= qw( snapmirror status -l );

        if ( $args{volume} ) {
            push @command, $args{volume}->get_name;
        }

        $self->_run_command(
            command	=> \@command,
        );

        my @stdout	= $self->_get_command_stdout;

        my @snapmirrors	= ();

        my $snapmirror	= {};

        while ( defined (my $line = shift @stdout) ) {

            if ( $line	=~ /Snapmirror is (on|off)/ ) {
                $snapmirror_state_of{$ident} = $1;
                next;
            }

            if ( $line	=~ /^\s*$/ ) {
                if ( keys %$snapmirror ) {
                    $snapmirror->{ filer } = $self;
                    push @snapmirrors, NetApp::Snapmirror->new( $snapmirror );
                    $snapmirror	= {};
                }
                next;
            }

            $snapmirror	= NetApp::Snapmirror->_parse_snapmirror_status(
                snapmirror	=> $snapmirror,
                line		=> $line,
            );

        }

        if ( keys %$snapmirror ) {
            $snapmirror->{ filer } = $self;
            push @snapmirrors, NetApp::Snapmirror->new( $snapmirror );
        }

        return @snapmirrors;

    }

    sub get_temporary_exports {
        return grep { $_->get_type eq 'temporary' } shift->get_exports;
    }

    sub get_permanent_exports {
        return grep { $_->get_type eq 'permanent' } shift->get_exports;
    }

    sub get_active_exports {
        return grep { $_->get_active } shift->get_exports;
    }

    sub get_inactive_exports {
        return grep { not $_->get_active } shift->get_exports;
    }

    sub get_exports {

        my $self	= shift;

        $self->_run_command(
            command	=> [qw( exportfs )],
        );

        my @stdout	= $self->_get_command_stdout;

        my %temporary	= ();

        while ( defined (my $line = shift @stdout) ) {

            my $export	= NetApp::Filer::Export->_parse_export( $line );

            $export->{ filer }	= $self;
            $export->{ type }	= 'temporary';

            $temporary{ $export->{path} } =
                NetApp::Filer::Export->new( $export );

        }

        $self->_run_command(
            command	=> [qw( rdfile /etc/exports )],
        );

        @stdout		= $self->_get_command_stdout;

        my %permanent	= ();

        while ( defined (my $line = shift @stdout) ) {

            next if $line =~ /^#/;
            next if $line =~ /^\s*$/;

            my $export	= NetApp::Filer::Export->_parse_export( $line );

            $export->{ filer }	= $self;
            $export->{ type }	= 'permanent';

            my $permanent	= NetApp::Filer::Export->new( $export );
            my $temporary	= $temporary{ $export->{path} };

            if ( $temporary ) {
                if ( $temporary->compare( $permanent ) ) {
                    delete $temporary{ $export->{path} };
                } else {
                    $permanent->set_active( 0 );
                }
            }

            $permanent{ $export->{path} } = $permanent;

        }

        my @exports	= (
            values %temporary,
            values %permanent,
        );

        return @exports;

    }

}

sub _parse_license {

    my $class		= shift;
    my $line		= shift;

    $line		=~ s/$RE{ws}{crop}//g;

    my @fields		= split( /\s+/, $line );

    my $license		= {
        service		=> $fields[0],
        expired		=> "",
    };

    if ( $fields[1] eq 'site' ) {
        $license->{type}	= 'site';
        $license->{code}	= $fields[2];
    } else {
        $license->{type}	= 'node';
        $license->{code}	= $fields[1];
    }

    if ( $line	=~ /expired \((\d+ \w+ \d+)\)/ ) {
        $license->{expired}	= $1;
    }

    return $license;

}

sub _parse_option {

    my $class		= shift;
    my $line		= shift;

    $line		=~ s/$RE{ws}{crop}//g;
    $line		=~ s/\(.*\)$//g;
    $line		=~ s/$RE{ws}{crop}//g;

    my @fields		= split( /\s+/, $line );

    if ( not defined $fields[1] ) {
        $fields[1]	= '';
    }

    my $option		= {
        name		=> $fields[0],
        value		=> $fields[1],
    };

    return $option;

}

1;
