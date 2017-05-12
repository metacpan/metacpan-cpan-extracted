
package NetApp::Volume;

our $VERSION = '500.002';
$VERSION = eval $VERSION;  ##  no critic: StringyEval

use strict;
use warnings;
use English;
use Carp;

use Class::Std;
use Params::Validate qw( :all );
use Regexp::Common;

use NetApp::Volume::Source;

{

    my %filer_of		:ATTR( get => 'filer' );

    my %name_of			:ATTR( get => 'name' );
    my %state_of		:ATTR;
    my %status_of		:ATTR;
    my %options_of		:ATTR;
    my %source_of		:ATTR( get => 'source' );

    my %plex_of			:ATTR( get => 'plex' );

    my %aggregate_name_of	:ATTR( get => 'aggregate_name' );

    my %clone_names_of		:ATTR;
    my %parent_name_of		:ATTR( get => 'parent_name' );
    my %snapshot_name_of 	:ATTR( get => 'snapshot_name' );

    my %path_of			:ATTR( get => 'path' );

    sub BUILD {

        my ($self,$ident,$args_ref) = @_;

        my @args = %$args_ref;

        my (%args) 	= validate( @args, {
            filer	=> { isa	=> 'NetApp::Filer' },
            name	=> { type	=> SCALAR },
            state	=> { type	=> HASHREF },
            status	=> { type	=> HASHREF },
            options	=> { type	=> HASHREF },
            plex	=> { type	=> HASHREF },
            aggregate_name => { type	=> SCALAR,
                                optional => 1 },
            source	=> { type	=> HASHREF,
                             optional	=> 1 },
            clone_names	=> { type	=> ARRAYREF,
                             default	=> [],
                             optional	=> 1 },
            parent_name	=> { type	=> SCALAR,
                             optional	=> 1 },
            snapshot_name => { type	=> SCALAR,
                               optional => 1 },
        });        

        $filer_of{$ident}	= $args{filer};
        $name_of{$ident}	= $args{name};
        $state_of{$ident}	= $args{state};
        $status_of{$ident}	= $args{status};
        $options_of{$ident}	= $args{options};

        $plex_of{$ident}	=
            NetApp::Aggregate::Plex->new( $args{plex} );

        if ( $args{aggregate_name} ) {
            $aggregate_name_of{$ident}	= $args{aggregate_name};
        }

        if ( $args{source} ) {
            $source_of{$ident} =
                NetApp::Volume::Source->new( $args{source} );
        }

        $clone_names_of{$ident}	= $args{clone_names};

        if ( $args{parent_name} ) {
            $parent_name_of{$ident}	= $args{parent_name};
        }

        if ( $args{snapshot_of} ) {
            $snapshot_name_of{$ident}	= $args{snapshot_name};
        }

        $path_of{$ident}	= "/vol/$args{name}";

    }

    sub get_states {
        return keys %{ $state_of{ident shift} };
    }

    sub get_state {
        
        my $self     	= shift;
        my $ident	= ident $self;
        my $state	= shift;

        return $state_of{$ident}->{$state};

    }

    sub get_statuses { # Stati?  Oh, hell no...
        return keys %{ $status_of{ident shift} };
    }

    sub get_status { 

        my $self     	= shift;
        my $ident	= ident $self;
        my $status	= shift;

        return $status_of{$ident}->{$status};

    }
    
    sub get_options {
        return keys %{ $options_of{ident shift} };
    }

    sub get_option { 

        my $self     	= shift;
        my $ident	= ident $self;
        my $option	= shift;

        if ( exists $options_of{$ident}->{$option} ) {
            return $options_of{$ident}->{$option};
        } else {
            return undef;
        }

    }

    sub set_option {

        my $self	= shift;
        my $option	= shift;
        my $value	= $option eq 'root' ? '-f' : shift;

        my $ident	= ident $self;

        my $name	= $self->get_name;

        my @command	= ( qw(vol options), $name, $option, $value );

        $self->get_filer->_run_command( command => @command );

        if ( $option eq 'root' ) {
            $options_of{$ident}->{$option} = 1;
        } else {
            $options_of{$ident}->{$option} = $value;
        }

        return 1;

    }

    sub get_aggregate {
        my $self	= shift;
        return $self->get_filer->get_aggregate( $self->get_aggregate_name );
    }

    sub get_qtree_names {
        my $self	= shift;
        return map { $_->get_name } $self->get_qtrees;
    }

    sub get_qtree {
        my $self	= shift;
        my $name	= shift || "/vol/" . $self->get_name;
        return $self->get_filer->get_qtree( $name );
    }

    sub get_qtrees {
        my $self	= shift;
        return $self->get_filer->_get_qtree_status( volume => $self );
    }

    sub get_language {

        my $self	= shift;

        my $name	= $self->get_name;
            
        $self->get_filer->_run_command(
            command	=> [qw(vol language), $name],
        );

        my @stdout	= $self->get_filer->_get_command_stdout;

        my $language	= "";

        while ( my $line = shift @stdout ) {
            if ( $line =~ /Volume language is (\S+)/ ) {
                $language	= $1;
            }
        }

        if ( not $language ) {
            croak(
                "Unable to determine language for volume $name\n",
            );
        }

        return $language;

    }

    sub set_language {

        my $self	= shift;
        my $language	= shift;

        my $name	= $self->get_name;

        return $self->get_filer->_run_command(
            command	=> [qw(vol language), $name, $language],
        );

    }

    sub get_size {

        my $self	= shift;

        my $name	= $self->get_name;

        $self->get_filer->_run_command(
            command	=> [qw(vol size), $name],
        );

        my @stdout	= $self->get_filer->_get_command_stdout;

        my $size	= "";

        while ( defined(my $line = shift @stdout) ) {
            if ( $line 	=~ /has size (\S+)\./ ) {
                $size	= $1;
            }
        }

        if ( not $size ) {
            croak("Unable to determine size of volume $name\n");
        }

        return $size;

    }

    sub set_size {

        my $self	= shift;
        my $size	= shift;

        return $self->get_filer->_run_command(
            command	=> [qw(vol size), $self->get_name, $size],
        );

    }

    sub get_maxfiles {

        my $self	= shift;

        my $name	= $self->get_name;

        $self->get_filer->_run_command(
            command	=> ['maxfiles', $name],
        );

        my @stdout	= $self->get_filer->_get_command_stdout;

        my $maxfiles	= "";

        while ( my $line = shift @stdout ) {
            if ( $line =~ /is currently (\d+)/ ) {
                $maxfiles	= $1;
            }
        }

        if ( not $maxfiles ) {
            croak("Unable to determine maxfiles of volume $name\n");
        }

        return $maxfiles;

    }

    sub set_maxfiles {

        my $self	= shift;
        my $maxfiles	= shift;

        return $self->get_filer->_run_command(
            command	=> ['maxfiles', $self->get_name, $maxfiles],
        );

    }

    sub get_clone_names {

        my $self	= shift;
        my $ident	= ident $self;

        return @{ $clone_names_of{$ident} };

    }

    sub get_clones {

        my $self	= shift;

        my @clones	= ();

        foreach my $clone_name ( $self->get_clone_names ) {
            push @clones, $self->get_filer->get_volume( $clone_name );
        }

        return @clones;

    }

    sub is_clone {
        my $self	= shift;
        return ( $self->get_parent_name ? 1 : 0 );
    }

    sub get_parent {
        my $self	= shift;
        if ( $self->is_clone ) {
            return $self->get_filer->get_volume( $self->get_parent_name );
        } else {
            return;
        }
    }

    sub get_snapmirrors {
        my $self	= shift;
        return $self->get_filer->_get_snapmirrors( volume => $self );
    }

    sub get_snapshots {
        return NetApp::Snapshot->_get_snapshots( parent => shift );
    }

    sub get_snapshot {
        my $self	= shift;
        my ($name)	= validate_pos( @_, { type => SCALAR } );
        return grep { $_->get_name eq $name } $self->get_snapshots;
    }

    sub create_snapshot {
        my $self	= shift;
        my ($name)	= validate_pos( @_, { type => SCALAR } );
        return NetApp::Snapshot->_create_snapshot(
            parent	=> $self,
            name	=> $name,
        );
    }

    sub delete_snapshot {
        my $self	= shift;
        my ($name)	= validate_pos( @_, { type => SCALAR } );
        return NetApp::Snapshot->_delete_snapshot(
            parent	=> $self,
            name	=> $name,
        );
    }

    sub delete_all_snapshots {

        croak(__PACKAGE__ . "->delete_all_snapshots not yet implemented\n");

        # XXX: This one's tricky to implement.  Should we parse the
        # output, and attempt to return a list of what was delete, and
        # what was busy?  Probably too ugly.

        my $self	= shift;

        return $self->get_filer->_run_command(
            command	=> [ qw( snap delete -a -f -q ), $self->get_name ],
        );

    }

    sub get_snapshot_deltas {
        return NetApp::Snapshot->_get_snapshot_deltas( parent => shift );
    }

    sub get_snapshot_reserved {
        return NetApp::Snapshot->_get_snapshot_reserved( parent => shift );
    }

    sub set_snapshot_reserved {
        my $self	= shift;
        my ($reserved)	= validate_pos( @_, { type => SCALAR } );
        return NetApp::Snapshot->_set_snapshot_reserved(
            parent 	=> $self,
            reserved	=> $reserved,
        );
    }

    sub get_snapshot_schedule {
        return NetApp::Snapshot->_get_snapshot_schedule(
            parent	=> shift,
            @_
        );
    }

    sub set_snapshot_schedule {
        return NetApp::Snapshot->_set_snapshot_schedule(
            parent	=> shift,
            @_
        );
    }

    sub enable_snapshot_autodelete {
        my $self	= shift;
        return $self->get_filer->_run_command(
            command	=> [ qw(snap autodelete), $self->get_name, qw(on) ],
        );
    }

    sub disable_snapshot_autodelete {
        my $self	= shift;
        return $self->get_filer->_run_command(
            command	=> [ qw(snap autodelete), $self->get_name, qw(off) ],
        );
    }

    sub reset_snapshot_autodelete {
        my $self	= shift;
        return $self->get_filer->_run_command(
            command	=> [ qw(snap autodelete), $self->get_name, qw(reset) ],
        );
    }

    sub set_snapshot_autodelete_option {

        my $self	= shift;

        my ($name,$value) = validate_pos(
            @_,
            { type	=> SCALAR },
            { type	=> SCALAR },
        );

        my @command	= (
            qw( snap autodelete ),
            $self->get_name, $name, $value,
        );

        return $self->get_filer->_run_command(
            command	=> \@command,
        );

    }

    sub get_snapshot_autodelete_option {

        my $self	= shift;

        my ($name) 	= validate_pos(
            @_,
            { type	=> SCALAR },
        );

        my @command	= ( qw( snap autodelete ), $self->get_name );

        $self->get_filer->_run_command(
            command	=> \@command,
        );

        my @stdout	= $self->get_filer->_get_command_stdout;

        my $found	= 0;
        my $value	= "";

        while ( defined (my $line = shift @stdout) ) {
            if ( $line 	=~ /^$name\s*:\s*(.*)/ ) {
                $found	= 1;
                $value	= $1;
                $value	= "" if $value eq '(not specified)';
            }
        }

        if ( not $found ) {
            croak("Invalid autodelete option name '$name'\n");
        }

        return $value;

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

    sub get_export {
        my $self	= shift;
        my ($path)	= validate_pos( @_, { type => SCALAR } );
        return grep { $_->get_path eq $path } $self->get_exports;
    }

    sub get_exports {
        my $self	= shift;
        return
            grep { $_->get_path eq $self->get_path ||
                       $_->get_actual eq $self->get_path }
                $self->get_filer->get_exports;
    }

    sub create_export {

        my $self	= shift;

        my (%args)	= validate( @_, {
            exportas	=> { type	=> SCALAR,
                             optional	=> 1 },
            type	=> { type	=> SCALAR,
                             optional	=> 1 },
            nosuid	=> { type	=> SCALAR,
                             optional	=> 1 },
            anon	=> { type	=> SCALAR,
                             optional	=> 1 },
            sec		=> { type	=> ARRAYREF,
                             optional	=> 1 },
            root	=> { type	=> ARRAYREF,
                             optional	=> 1 },
            rw		=> { type	=> ARRAYREF,
                             optional	=> 1 },
            ro		=> { type	=> ARRAYREF,
                             optional	=> 1 },
            rw_all	=> { type	=> SCALAR,
                             optional	=> 1 },
            ro_all	=> { type	=> SCALAR,
                             optional	=> 1 },
        });

        if ( $args{exportas} ) {
            $args{actual}	= $self->get_path,
            $args{path}		= delete $args{exportas},
        } else {
            $args{path}		= $self->get_path;
        }

        my $export	= NetApp::Filer::Export->new( \%args );

        return $export->update;

    }

    sub destroy_export {

        my $self     	= shift;

        # XXX: Hmm....

    }

    sub offline {

        my $self	= shift;
        my $ident	= ident $self;

        my (%args)	= validate( @_, {
            cifsdelaytime	=> { type	=> SCALAR,
                                     optional	=> 1 },
        });

        my @command	= ( qw(vol offline), $self->get_name );

        if ( $args{cifsdelaytime} ) {
            push @command, '-t', $args{cifsdelaytime};
        }

        $self->get_filer->_run_command(
            command	=> \@command,
        );

        delete $state_of{$ident}->{online};
        delete $state_of{$ident}->{restricted};
        $state_of{$ident}->{offline} = 1;
        
        return 1;

    }

    sub online {

        my $self	= shift;
        my $ident	= ident $self;

        my (%args)	= validate( @_, {
            force	=> { type	=> SCALAR,
                             optional	=> 1 },
        });

        my @command	= ( qw( vol online ), $self->get_name );

        if ( $args{force} ) {
            push @command, '-f';
        }
        
        $self->get_filer->_run_command(
            command	=> \@command,
        );

        delete $state_of{$ident}->{offline};
        delete $state_of{$ident}->{restricted};
        $state_of{$ident}->{online} = 1;
        
        return 1;

    }

    sub rename {

        my $self	= shift;
        my $ident	= ident shift;

        my (%args)	= validate( @_, {
            newname	=> { type	=> SCALAR },
        });

        my $oldname	= $self->get_name;

        $self->get_filer->_run_command(
            command	=>[qw(vol rename), $oldname, $args{newname}],
        );

        $name_of{$ident} = $args{newname};

        return 1;

    }

    sub restrict {
        
        my $self	= shift;
        my $ident	= ident shift;

        my (%args)	= validate( @_, {
            cifsdelaytime	=> { type	=> SCALAR,
                                     optional	=> 1 },
        });

        my @command	= ( qw(vol restrict), $self->get_name );

        if ( $args{cifsdelaytime} ) {
            push @command, '-t', $args{cifsdelaytime};
        }

        $self->get_filer->_run_command(
            command	=> \@command,
        );

        delete $state_of{$ident}->{offline};
        delete $state_of{$ident}->{online};
        $state_of{$ident}->{restricted} = 1;

        return 1;

    }

}

sub _parse_vol_status_headers {

    my $class		= shift;
    my $header		= shift;

    my $indices		= {};
    my $index		= 0;

    my ($volume)	= ( $header =~ /(^\s+Volume\s+)/ ) or
        croak(
            "Unable to match 'Volume' column header\n"
        );

    $indices->{volume}	= [ 0, length($volume) ];
    $index		+= length($volume);

    my ($state)		= ( $header =~ /(State\s+)/ ) or
        croak(
            "Unable to match 'State' column header\n"
        );

    $indices->{state}	= [ $index, length($state) ];
    $index		+= length($state);

    my ($status)	= ( $header =~ /(Status\s+)/ ) or
        croak(
            "Unable to match 'Status' column header\n"
        );
        
    $indices->{status}	= [ $index, length($status) ];
    $index		+= length($status);

    my ($options)	= ( $header =~ /(Options\s*)/ ) or
        croak(
            "Unable to match 'Options' column header\n"
        );
        
    $indices->{options}	= [ $index ];

    if ( $header	=~ /Source/ ) {
        $indices->{options}->[1]	= length($options);
        $index			+= length($options);
        $indices->{source}	= [ $index ];
    }

    $indices->{length}	= $index + 1;

    return $indices;

}

sub _parse_vol_status_volume {

    my $class		= shift;
    
    my %args		= validate( @_, {
        indices		=> { type	=> HASHREF },
        line		=> { type	=> SCALAR },
        volume		=> { type   	=> HASHREF,
                             default	=> {},
                             optional	=> 1 },
    });
                                      
    my $indices		= $args{indices};
    my $volume		= $args{volume};
    my $line		= $args{line};

    if ( $line =~ /Clone, backed by volume '(.*)', snapshot '(.*)'/ ) {

        $volume->{parent_name}		= $1;
        $volume->{snapshot_name}	= $2;
        return $volume;

    } elsif ( $line =~ /Volume has clones: (.*)/ ) {

        my $clones	= $1;
        $volume->{clone_names} = [ split( /[,\s]+/, $clones ) ];
        return $volume;

    } elsif ( $line =~ /Containing aggregate: (\S+)/ ) {

        my $aggrname	= $1;
        $aggrname	=~ s/'//g;
        if ( $aggrname ne '<N/A>' ) {
            $volume->{aggregate_name} = $aggrname;
        }
        return $volume;

    } 

    if ( length($line) < $indices->{length} ) {
        $line		.= " " x ( $indices->{length} - length($line) );
    }

    foreach my $column ( qw( volume state status options source ) ) {

        my $value	= "";

        next unless $indices->{$column};

        if ( defined $indices->{$column}->[1] ) {
            $value	= substr( $line,
                                  $indices->{$column}->[0],
                                  $indices->{$column}->[1] );
        } else {
            $value	= substr( $line,
                                  $indices->{$column}->[0] );
        }

        $value		=~ s/$RE{ws}{crop}//g;

        if ( $column eq 'volume' ) {

            if ( $value ) {

                $volume->{name}	= $value;

                my ($name) = split( /\s+/, $line );

                if ( length($name) > length($value) ) {
                    $volume->{name}	= $name;
                    $line =~ s/^$name/$value/;
                }

            }

        } elsif ( $column eq 'source' ) {

            my ($hostname,$source) = split( /:/, $value );

            $volume->{source} 	= {
                hostname	=> $hostname,
                volume		=> $source,
            };

            $indices->{options}->[1] = undef;

            delete $indices->{source};

        } else {

            foreach my $entry ( split( /[,\s]+/, $value ) ) {

                my ($key,$value);

                if ( $entry =~ /=/ ) {
                    ($key,$value)	= split( /=/, $entry, 2 );
                } else {
                    ($key,$value)	= ($entry,1);
                }

                $volume->{$column}->{$key} = $value;

            }

        }

    }

    return $volume;

}

1;
