
package NetApp::Aggregate;

our $VERSION = '500.002';
$VERSION = eval $VERSION;  ##  no critic: StringyEval

use strict;
use warnings;
use English;
use Carp;

use Class::Std;
use Params::Validate qw( :all );
use Regexp::Common;

use NetApp::Aggregate::Plex;
use NetApp::Aggregate::RAIDGroup;

{

    my %filer_of	:ATTR( get => 'filer' );

    my %name_of		:ATTR( get => 'name' );
    my %state_of	:ATTR;
    my %status_of	:ATTR;
    my %options_of	:ATTR;
    my %volumes_of	:ATTR;

    my %plex_of		:ATTR( get => 'plex' );

    sub BUILD {

        my ($self,$ident,$args_ref) = @_;

        my @args = %$args_ref;

        my (%args) 	= validate( @args, {
            filer	=> { isa	=> 'NetApp::Filer' },
            name	=> { type	=> SCALAR },
            state	=> { type	=> HASHREF },
            status	=> { type	=> HASHREF },
            options	=> { type	=> HASHREF },
            volumes	=> { type	=> HASHREF },
            plex	=> { type	=> HASHREF },
        });

        $filer_of{$ident}	= $args{filer};
        $name_of{$ident}	= $args{name};
        $state_of{$ident}	= $args{state};
        $status_of{$ident}	= $args{status};
        $options_of{$ident}	= $args{options};
        $volumes_of{$ident}	= $args{volumes};

        $plex_of{$ident}	=
            NetApp::Aggregate::Plex->new( $args{plex} );

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
        my $value	= shift;

        my $ident	= ident $self;

        my $name	= $self->get_name;

        my @command	= ( qw(aggr options), $name, $option, $value );

        $self->get_filer->_run_command( command => @command );

        $options_of{$ident}->{$option} = $value;

        return 1;

    }

    sub get_volume_names {
        return keys %{ $volumes_of{ident shift} };
    }

    sub get_volumes {

        my $self	= shift;

        my @volumes	= ();

        foreach my $volume ( $self->get_volume_names ) {
            push @volumes, $self->get_filer->get_volume( $volume );
        }

        return @volumes;

    }

    sub get_volume {
        
        my $self	= shift;
        my $ident	= ident $self;

        my $name	= shift;

        if ( not exists $volumes_of{$ident}->{$name} ) {
            croak(
                "No such volume $name in aggregate ",
                $self->get_name, "\n",
            );
        }

        return $self->get_filer->get_volume( $name );

    }

    sub create_volume {

        my $self	= shift;

        my (%args)	= validate( @_, {
            name	=> { type	=> SCALAR },
            size	=> { type	=> SCALAR },
            space	=> { type	=> SCALAR,
                             regexp	=> qr{^(none|filer|volume)$},
                             optional	=> 1 },
            language	=> { type	=> SCALAR,
                             optional	=> 1 },
            source_filer => { type	=> SCALAR,
                              depends	=> [qw( source_volume )],
                              optional	=> SCALAR },
            source_folume => { type	=> SCALAR,
                               depends	=> [qw( source_filer )],
                               optional => 1 },
        });

        if ( ref $args{source_filer} &&
                 $args{source_filer}->isa("NetApp::Filer") ) {
            $args{source_filer}	= $args{source_filer}->get_hostname;
        }

        if ( ref $args{source_volume} &&
                 $args{source_volume}->isa("NetApp::Volume") ) {
            $args{source_volume} = $args{source_volume}->get_name;
        }

        if ( $args{source_filer} &&
                 ( $args{space} || $args{language} ) ) {
            croak(
                "Mutually exclusive options: space and/or language may not\n",
                "be specified when source_filer/source_volume are given.\n",
            );
        }

        my @command	= ( qw( vol create ), $args{name} );

        if ( $args{language} ) {
            push @command, '-l', $args{language};
        }

        if ( $args{space} ) {
            push @command, '-s', $args{space};
        }

        push @command, $self->get_name, $args{size};

        if ( $args{source_filer} ) {
            push @command, '-S',
                join( ':', $args{source_filer}, $args{source_volume} );
        }

        $self->get_filer->_run_command( command => \@command );

        return $self->get_filer->get_volume( name => $args{name} );

    }

    sub destroy_volume {

        my $self	= shift;
        my $ident	= ident $self;

        my (%args)	= validate( @_, {
            name	=> { type	=> SCALAR },
        });

        my $aggrname	= $self->get_name;

        if ( not $volumes_of{$ident}->{$args{name}} ) {
            croak("No such volume $args{name} in aggregate $aggrname\n");
        }

        $self->get_filer->_run_command(
            command	=> [qw(vol destroy), $args{name}, '-f'],
        );

        delete $volumes_of{$ident}->{$args{name}};

        return 1;
        
    }

    sub get_qtree_names {
        my $self	= shift;
        return map { $_->get_name } $self->get_qtrees;
    }

    sub get_qtree {
        my $self	= shift;
        my $name	= shift;
        return $self->get_filer->get_qtree( $name );
    }

    sub get_qtrees {

        my $self	= shift;

        my @qtrees	= ();

        foreach my $volume ( $self->get_volumes ) {
            push @qtrees, $volume->get_qtrees;
        }
        
        return @qtrees;

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

    sub rename {

        my $self	= shift;
        my $ident	= ident $self;

        my (%args)	= validate( @_, {
            newname	=> { type	=> SCALAR },
        });

        my $oldname	= $self->get_name;

        $self->get_filer->_run_command(
            command	=> [qw(aggr rename), $oldname, $args{newname}],
        );

        $name_of{$ident} = $args{newname};

        return 1;

    }

    sub offline {

        my $self	= shift;
        my $ident	= ident $self;

        my (%args)	= validate( @_, {
            cifsdelaytime	=> { type	=> SCALAR,
                                     optional	=> 1 },
        });

        my @command	= ( qw(aggr offline), $self->get_name );

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

        my @command	= ( qw( aggr online ), $self->get_name );

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

    sub restrict {
        
        my $self	= shift;
        my $ident	= ident shift;

        my (%args)	= validate( @_, {
            cifsdelaytime	=> { type	=> SCALAR,
                                     optional	=> 1 },
        });

        my @command	= ( qw(aggr restrict), $self->get_name );

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

# Class methods for parsing aggr command output

sub _parse_aggr_status_headers {

    my $class		= shift;
    my $header		= shift;

    my $indices		= {};
    my $index		= 0;

    my ($aggr) 		= ( $header =~ /(^\s+Aggr\s+)/ ) or
        croak(
            "Unable to match 'Aggr' column header\n"
        );

    $indices->{aggr}	= [ 0, length($aggr) ];
    $index		+= length($aggr);

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

    $indices->{options}	= [ $index ];

    return $indices;

}

sub _parse_aggr_status_aggregate {

    my $class		= shift;
    
    my %args		= validate( @_, {
        indices		=> { type	=> HASHREF },
        line		=> { type	=> SCALAR },
        aggregate	=> { type   	=> HASHREF,
                             default	=> {},
                             optional	=> 1 },
    });
                                      
    my $indices		= $args{indices};
    my $aggregate	= $args{aggregate};
    my $line		= $args{line};

    if ( $line		=~ m{Volumes: <N/A>} ) {
        return $aggregate;
    }

    foreach my $column ( qw( aggr state status options ) ) {

        my $value	= "";

        if ( $indices->{$column}->[1] ) {
            $value	= substr( $line,
                                  $indices->{$column}->[0],
                                  $indices->{$column}->[1] );
        } else {
            $value	= substr( $line,
                                  $indices->{$column}->[0] );
        }

        $value		=~ s/$RE{ws}{crop}//g;

        if ( $column eq 'aggr' ) {
            if ( $value ) {

                $aggregate->{name}	= $value;

                my ($name) = split( /\s+/, $line );

                if ( length($name) > length($value) ) {
                    $aggregate->{name}	= $name;
                    $line =~ s/^$name/$value/;
                }

            }
        } else {
            foreach my $entry ( split( /[,\s]+/, $value ) ) {

                my ($key,$value);

                if ( $entry =~ /=/ ) {
                    ($key,$value)	= split( /=/, $entry, 2 );
                } else {
                    ($key,$value)	= ($entry,1);
                }

                $aggregate->{$column}->{$key} = $value;

            }
        }

    }

    return $aggregate;

}

sub _parse_aggr_status_volumes {

    my $class		= shift;

    my %args		= validate( @_, {
        volumes		=> { type	=> HASHREF },
        line		=> { type	=> SCALAR },
    });
                                      
    my $volumes		= $args{volumes};
    my $line		= $args{line};

    $line		=~ s/Volumes://g;
    $line		=~ s/$RE{ws}{crop}//g;
    $line		=~ s/,//g;

    foreach my $volume ( split( /\s+/, $line ) ) {
        $volumes->{$volume}++;
    }

    return 1;

}

sub _parse_aggr_status_plex {

    my $class		= shift;
    my $line		= shift;

    $line		=~ s/$RE{ws}{crop}//g;

    my ($name,$state)  = ( $line =~ m{Plex\s+(\S+): (.*)} ) or
        croak(
            "Unable to parse Plex name and state:\n$line\n"
        );

    return {
        name		=> $name,
        state		=> { map { $_ => 1 } split( /[,\s]+/, $state ) },
    };

}

sub _parse_aggr_status_raidgroup {

    my $class		= shift;
    my $line		= shift;

    $line		=~ s/$RE{ws}{crop}//g;

    my ($name,$state)  = ( $line =~ m{RAID group\s+(\S+): (.*)} ) or
        croak(
            "Unable to parse RAIDGroup name and state:\n$line\n"
        );

    return {
        name		=> $name,
        state		=> { map { $_ => 1 } split( /[,\s]+/, $state ) },
    };

}

1;
