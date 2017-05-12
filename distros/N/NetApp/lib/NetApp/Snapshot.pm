
package NetApp::Snapshot;

our $VERSION = '500.002';
$VERSION = eval $VERSION;  ##  no critic: StringyEval

use strict;
use warnings;
use English;
use Carp;

use Class::Std;
use Params::Validate qw( :all );
use Regexp::Common;

use NetApp::Snapshot::Delta;
use NetApp::Snapshot::Schedule;

{

    my %parent_of	:ATTR( get => 'parent' );

    my %name_of		:ATTR( get => 'name' );
    my %date_of		:ATTR( get => 'date' );
    my %used_of		:ATTR( get => 'used' );
    my %total_of	:ATTR( get => 'total' );

    sub BUILD {

        my ($self,$ident,$args_ref) = @_;

        my @args = %$args_ref;

        my (%args) 	= validate( @args, {
            parent	=> { type	=> OBJECT },
            name	=> { type	=> SCALAR },
            date	=> { type	=> SCALAR },
            used	=> { type	=> SCALAR },
            total	=> { type	=> SCALAR },
        });        

        $parent_of{$ident}	= $args{parent};
        $name_of{$ident}	= $args{name};
        $date_of{$ident}	= $args{date};
        $used_of{$ident}	= $args{used};
        $total_of{$ident}	= $args{total};

    }

    sub get_filer {
        return shift->get_parent->get_filer;
    }

    sub get_snapshot_deltas {

        my $self	= shift;

        return $self->_get_snapshot_deltas(
            parent	=> $self->get_parent,
            from	=> $self,
        );

    }

    sub get_reclaimable {

        my $self	= shift;

        if ( $self->get_parent->isa("NetApp::Aggregate") ) {
            croak("Aggregate snapshots do not support 'snap reclaimable'\n");
        }

        $self->get_filer->_run_command(
            command	=> [ qw( snap reclaimable ),
                             $self->get_parent->get_name,
                             $self->get_name ],
            nonfatal	=> 1,
        );

        my @stdout	= $self->get_filer->_get_command_stdout;
        my @stderr	= $self->get_filer->_get_command_stderr;

        while ( defined (my $line = shift @stdout) ) {
            if ( $line	=~ /Approximately (\d+)/ ) {
                return $1;
            }
        }

        carp(
            "Unable to determine reclaimable space for ",
            $self->get_parent->get_name, ":",
            $self->get_name, "\n",
            @stderr,
        );

        return undef;

    }

    sub restore {

        my $self	= shift;

        my (%args)	= validate( @_, {
            type	=> { type	=> SCALAR,
                             regexp	=> qr{^(vol|file)$},
                             default	=> 'vol',
                             optional	=> 1 },
            from_path	=> { type	=> SCALAR,
                             optional	=> 1 },
            to_path	=> { type	=> SCALAR,
                             optional	=> 1 },
        });

        if ( $args{type} eq 'file' && ! $args{from_path} ) {
            croak(
                "Missing required argment 'from_path'\n",
                "File restores must specify the from_path\n",
            );
        }

        if ( $args{type} eq 'vol' && $args{to_path} ) {
            croak(
                "Invalid argument 'to_path'\n",
                "Volume restores can not specify to_path\n",
            );
        }

        my @command	= qw( snap restore );

        if ( $self->get_parent->isa("NetApp::Aggregate" ) ) {
            push @command, '-A';
        }

        if ( $args{to_path} ) {
            push @command, '-r', $args{to_path};
        }

        push @command, (
            qw( -f -s ), $self->get_name,
            qw( -t ), $args{type},
        );

        if ( $args{type} eq 'vol' ) {
            push @command, $self->get_parent->get_name;
        } else {
            push @command, $args{from_path};
        }

        return $self->get_filer->_run_command(
            command	=> \@command,
        );

    }

    sub rename {

        my $self	= shift;
        my $ident	= ident $self;

        my ($newname)	= validate_pos(
            @_,
            { type	=> SCALAR },
        );

        my @command	= qw( snap rename );

        if ( $self->get_parent->isa("NetApp::Aggregate") ) {
            push @command, '-A';
        }

        push @command, $self->get_name, $newname;

        $self->_run_command(
            command	=> \@command,
        );

        $name_of{$ident} = $newname;

        return 1;

    }

}

# NOTE: These are class methods, since you can request snapshots,
# deltas, etc from an aggregate, volume, or a specific snapshot.

sub _get_snapshots {

    my $class		= shift;

    my (%args)		= validate( @_, {
        parent		=> { type	=> OBJECT },
    });

    my $parent		= $args{parent};

    my @command		= qw( snap list );

    if ( $parent->isa("NetApp::Aggregate") ) {
        push @command, '-A';
    }

    push @command, $parent->get_name;

    $parent->get_filer->_run_command(
        command		=> \@command,
    );

    my @stdout		= $parent->get_filer->_get_command_stdout;

    my @snapshots	= ();

    while ( defined (my $line = shift @stdout) ) {

        next if $line	=~ /^(Volume|Aggregate)/;
        next if $line	=~ /^working/;
        next if $line	=~ /^\s*$/;

        last if $line	=~ /No snapshots exist/;

        next if $line	=~ m:^\s*%/used:;
        next if $line	=~ /^-+/;

        my $snapshot	= $class->_parse_snap_list( $line );

        push @snapshots, NetApp::Snapshot->new({
            parent	=> $parent,
            %$snapshot,
        });

    }

    return @snapshots;

}

sub _create_snapshot {

    my $class		= shift;

    my (%args)		= validate( @_, {
        parent		=> { type	=> OBJECT },
        name		=> { type	=> SCALAR },
    });

    my $parent		= $args{parent};

    my @command		= qw( snap create );

    if ( $parent->isa("NetApp::Aggregate") ) {
        push @command, '-A';
    }

    push @command, $args{name};

    return $parent->get_filer->_run_command(
        command		=> \@command,
    );

}

sub _delete_snapshot {

    my $class		= shift;

    my (%args)		= validate( @_, {
        parent		=> { type	=> OBJECT },
        name		=> { type	=> SCALAR },
    });

    my $parent		= $args{parent};

    my @command		= qw( snap delete );

    if ( $parent->isa("NetApp::Aggregate") ) {
        push @command, '-A';
    }

    push @command, $args{name};

    return $parent->get_filer->_run_command(
        command		=> \@command,
    );

}

sub _set_snapshot_schedule {

    my $class		= shift;

    my (%args)		= validate( @_, {
        parent		=> { type	=> OBJECT },
        weekly		=> { type	=> SCALAR },
        daily		=> { type	=> SCALAR },
        hourly		=> { type	=> SCALAR },
        hourlist	=> { type	=> ARRAYREF,
                             optional	=> 1 },
    });

    my $parent		= $args{parent};

    my @command		= qw( snap sched );

    if ( $parent->isa("NetApp::Aggregate") ) {
        push @command, '-A';
    }

    push @command, $parent->get_name, $args{weekly}, $args{daily};

    my $hourly		= $args{hourly};

    if ( $args{hourlist} ) {
        $hourly		.= '@' . join( ',', @{ $args{hourlist} } );
    }

    push @command, $args{hourly};

    return $parent->get_filer->_run_command(
        command		=> \@command,
    );

}

sub _get_snapshot_schedule {

    my $class		= shift;

    my (%args)		= validate( @_, {
        parent		=> { type	=> OBJECT },
    });

    my $parent		= $args{parent};

    my @command		= qw( snap sched );

    if ( $parent->isa("NetApp::Aggregate") ) {
        push @command, '-A';
    }

    push @command, $parent->get_name;

    $parent->get_filer->_run_command(
        command		=> \@command,
    );

    my @stdout		= $parent->get_filer->_get_command_stdout;

    my $schedule 	=
        NetApp::Snapshot::Schedule->_parse_snap_sched( shift @stdout );

    return NetApp::Snapshot::Schedule->new({
        parent		=> $parent,
        %$schedule,
    });

}

sub _set_snapshot_reserved {

    my $class		= shift;

    my (%args)		= validate( @_, {
        parent		=> { type	=> OBJECT },
        reserved	=> { type	=> SCALAR },
    });

    my $parent		= $args{parent};
    my $reserved	= $args{reserved};

    my @command		= qw( snap reserve );

    if ( $parent->isa("NetApp::Aggregate") ) {
        push @command, '-A';
    }

    push @command, $parent->get_name, $reserved;

    return $parent->get_filer->_run_command(
        command		=> \@command,
    );

}

sub _get_snapshot_reserved {

    my $class		= shift;

    my (%args)		= validate( @_, {
        parent		=> { type	=> OBJECT },
    });

    my $parent		= $args{parent};
    my $parent_class	= ref $parent;

    my @command		= qw( snap reserve );

    if ( $parent->isa("NetApp::Aggregate") ) {
        push @command, '-A';
    }

    push @command, $parent->get_name;

    $parent->get_filer->_run_command(
        command		=> \@command,
    );

    my @stdout		= $parent->get_filer->_get_command_stdout;

    my $line		= shift @stdout;

    if ( $line		=~ /reserve is (\d+)%/ ) {
        return $1;
    } else {
        croak(
            "Unable to determine snapshot reserve for $parent_class",
            $parent->get_name, "\n",
        );
    }

}

sub _get_snapshot_deltas {

    my $class		= shift;

    my (%args)		= validate( @_, {
        parent		=> { type	=> OBJECT },
        from		=> { isa	=> 'NetApp::Snapshot',
                             optional	=> 1 },
        to		=> { isa	=> 'NetApp::Snapshot',
                             depends	=> [qw( from )],
                             optional	=> 1 },
    });

    my $parent		= $args{parent};

    my @command		= qw( snap delta );

    if ( $parent->isa("NetApp::Aggregate") ) {
        push @command, '-A';
    }

    push @command, $parent->get_name;

    if ( $args{from} ) {
        push @command, $args{from}->get_name;
    }

    if ( $args{to} ) {
        push @command, $args{to}->get_name;
    }

    $parent->get_filer->_run_command(
        command	=> \@command,
    );

    my @stdout		= $parent->get_filer->_get_command_stdout;

    my @deltas		= ();

    my $summary		= 0;

    while ( defined( my $line = shift @stdout) ) {

        next if $line	=~ /^\s*$/;
        next if $line	=~ /^(Volume|Aggregate|working|From)/;
        next if $line	=~ /^[-\s]+$/;

        last if $line	=~ /No snapshots exist/;

        if ( $line	=~ /^Summary/ ) {
            $summary	= 1;
            next;
        }

        my $delta	= NetApp::Snapshot::Delta->_parse_snap_delta( $line );

        push @deltas, NetApp::Snapshot::Delta->new({
            summary	=> $summary,
            %$delta,
        });

    }

    return @deltas;

}

sub _parse_snap_list {

    my $class		= shift;
    my $line		= shift;

    $line =~ m{ ^ \s* \d+% \s+ \( \s*
                (\d+)
                % \) \s+ \d+% \s+ \( \s*
                (\d+)
                % \) \s+
                ( \w+ \s+ \d+ \s+ \d+ : \d+ )
                \s+
                (\S+) }x;

    return {
        used		=> $1,
        total		=> $2,
        date		=> $3,
        name		=> $4,
    };

}

1;
