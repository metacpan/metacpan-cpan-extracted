
package NetApp::Filer::Export;

our $VERSION = '500.002';
$VERSION = eval $VERSION;  ##  no critic: StringyEval

use strict;
use warnings;
use Carp;

use Class::Std;
use Params::Validate qw( :all );

{

    my %filer_of		:ATTR( get => 'filer' );

    my %type_of			:ATTR( get => 'type' );
    my %active_of		:ATTR( get => 'active', set => 'active' );

    my %path_of			:ATTR( get => 'path' );
    my %actual_of		:ATTR( get => 'actual' );

    my %nosuid_of		:ATTR( get => 'nosuid', set => 'nosuid' );
    my %anon_of			:ATTR( get => 'anon', set => 'anon' );

    my %sec_of			:ATTR;
    my %root_of			:ATTR;

    my %rw_all_of		:ATTR( get => 'rw_all' );
    my %ro_all_of		:ATTR( get => 'ro_all' );
    my %rw_of			:ATTR;
    my %ro_of			:ATTR;

    sub BUILD {

        my ($self,$ident,$args_ref) = @_;

        my @args = %$args_ref;

        my (%args) 	= validate( @args, {
            filer	=> { isa	=> 'NetApp::Filer' },
            type	=> { type	=> SCALAR,
                             default	=> 'permanent',
                             regex	=> qr{^(permanent|temporary)$},
                             optional	=> 1 },
            active	=> { type	=> SCALAR,
                             default	=> 1,
                             optional	=> 1 },
            path	=> { type	=> SCALAR },
            actual	=> { type	=> SCALAR,
                             default	=> "",
                             optional	=> 1 },
            nosuid	=> { type	=> SCALAR,
                             default	=> 0,
                             optional	=> 1 },
            anon	=> { type	=> SCALAR | UNDEF,
                             default	=> undef,
                             optional	=> 1 },
            sec		=> { type	=> ARRAYREF,
                             default	=> [qw(sys)],
                             optional	=> 1 },
            root	=> { type	=> ARRAYREF,
                             default	=> [],
                             optional	=> 1 },
            rw_all	=> { type	=> SCALAR,
                             optional	=> 1 },
            rw		=> { type	=> ARRAYREF,
                             default	=> [],
                             optional	=> 1 },
            ro_all	=> { type	=> SCALAR,
                             optional	=> 1 },
            ro		=> { type	=> ARRAYREF,
                             default	=> [],
                             optional	=> 1 },
        });

        if ( exists $args{rw_all} && @{ $args{rw} } ) {
            croak("Mutually exclusive arguments: rw_all and rw\n");
        }

        if ( exists $args{ro_all} && @{ $args{ro} } ) {
            croak("Mutually exclusive arguments: ro_all and ro\n");
        }

        if ( ! @{ $args{rw} } && ! exists $args{rw_all} &&
                 ! @{ $args{ro} } && ! exists $args{ro_all} ) {
            $args{rw_all}	= 1;
        }

        $filer_of{$ident}	= $args{filer};
        $path_of{$ident}	= $args{path};
        $type_of{$ident}	= $args{type};
        $active_of{$ident}	= $args{active};
        $actual_of{$ident}	= $args{actual};
        $nosuid_of{$ident}	= $args{nosuid};
        $anon_of{$ident}	= $args{anon};
        $sec_of{$ident}		= $args{sec};
        $root_of{$ident}	= $args{root};

        if ( $args{rw_all} ) {
            $rw_all_of{$ident}	= $args{rw_all};
            $rw_of{$ident}	= [];
        } else {
            $rw_of{$ident}	= $args{rw};
        }

        if ( $args{ro_all} ) {
            $ro_all_of{$ident}	= $args{ro_all};
            $ro_of{$ident}	= [];
        } else {
            $ro_of{$ident}	= $args{ro};
        }

    }

    sub get_rw {
        my $self	= shift;
        my $ident	= ident $self;
        return @{ $rw_of{$ident} };
    }

    sub set_rw_all {
        my $self	= shift;
        my $ident	= ident $self;
        my ($rw_all)	= validate_pos( @_, { type => BOOLEAN } );
        $rw_of{$ident}	= [];
        $rw_all_of{$ident} = $rw_all;
    }

    sub set_rw {
        my $self	= shift;
        my $ident	= ident $self;
        my ($rw)	= validate_pos( @_, { type => ARRAYREF } );
        $self->set_rw_all(0);
        $rw_of{$ident}	= $rw;
    }

    sub has_rw {
        my $self	= shift;
        my $ident	= ident $self;
        my ($rw)	= validate_pos( @_, { type => SCALAR } );
        return grep { $_ eq $rw } @{ $rw_of{$ident} };
    }

    sub add_rw {
        my $self	= shift;
        my $ident	= ident $self;
        my ($rw)	= validate_pos( @_, { type => SCALAR } );
        if ( $self->get_rw_all ) {
            return;
        } else {
            if ( not $self->has_rw( $rw ) ) {
                push @{ $rw_of{$ident} }, $rw;
            }
        }
        return 1;
    }

    sub remove_rw {
        my $self	= shift;
        my $ident	= ident $self;
        my ($rw)	= validate_pos( @_, { type => SCALAR } );
        if ( $self->get_rw_all ) {
            return;
        } else {
            if ( $self->has_rw( $rw ) ) {
                $rw_of{$ident} = [ grep { $_ ne $rw } @{ $rw_of{$ident} } ];
            }
        }
        return 1;
    }

    sub get_ro {
        my $self	= shift;
        my $ident	= ident $self;
        return @{ $ro_of{$ident} };
    }

    sub set_ro_all {
        my $self	= shift;
        my $ident	= ident $self;
        my ($ro_all)	= validate_pos( @_, { type => BOOLEAN } );
        $ro_of{$ident}	= [];
        $ro_all_of{$ident} = $ro_all;
    }

    sub set_ro {
        my $self	= shift;
        my $ident	= ident $self;
        my ($ro)	= validate_pos( @_, { type => ARRAYREF } );
        $self->set_ro_all(0);
        $ro_of{$ident}	= $ro;
    }

    sub has_ro {
        my $self	= shift;
        my $ident	= ident $self;
        my ($ro)	= validate_pos( @_, { type => SCALAR } );
        return grep { $_ eq $ro } @{ $ro_of{$ident} };
    }

    sub add_ro {
        my $self	= shift;
        my $ident	= ident $self;
        my ($ro)	= validate_pos( @_, { type => SCALAR } );
        if ( $self->get_ro_all ) {
            return;
        } else {
            if ( not $self->has_ro( $ro ) ) {
                push @{ $ro_of{$ident} }, $ro;
            }
        }
        return 1;
    }

    sub remove_ro {
        my $self	= shift;
        my $ident	= ident $self;
        my ($ro)	= validate_pos( @_, { type => SCALAR } );
        if ( $self->get_ro_all ) {
            return;
        } else {
            if ( $self->has_ro( $ro ) ) {
                $ro_of{$ident} = [ grep { $_ ne $ro } @{ $ro_of{$ident} } ];
            }
        }
        return 1;
    }

    sub get_sec {
        my $self	= shift;
        my $ident	= ident $self;
        return @{ $sec_of{$ident} };
    }

    sub set_sec {
        my $self	= shift;
        my $ident	= ident $self;
        my ($sec)	= validate_pos( @_, { type => ARRAYREF } );
        $sec_of{$ident}	= $sec;
    }
    
    sub has_sec {
        my $self	= shift;
        my $ident	= ident $self;
        my ($sec)	= validate_pos( @_, { type => SCALAR } );
        return grep { $_ eq $sec } @{ $sec_of{$ident} };
    }

    sub add_sec {
        my $self	= shift;
        my $ident	= ident $self;
        my ($sec)	= validate_pos( @_, { type => SCALAR } );
        if ( not $self->has_sec( $sec ) ) {
            push @{ $sec_of{$ident} }, $sec;
        }
    }

    sub remove_sec {
        my $self	= shift;
        my $ident	= ident $self;
        my ($sec)	= validate_pos( @_, { type => SCALAR } );
        if ( $self->has_sec( $sec ) ) {
            $sec_of{$ident} = [ grep { $_ ne $sec } @{ $sec_of{$ident} } ];
        }
    }

    sub get_root {
        my $self	= shift;
        my $ident	= ident $self;
        return @{ $root_of{$ident} };
    }

    sub set_root {
        my $self	= shift;
        my $ident	= ident $self;
        my ($root)	= validate_pos( @_, { type => ARRAYREF } );
        $root_of{$ident}	= $root;
    }

    sub has_root {
        my $self	= shift;
        my $ident	= ident $self;
        my ($root)	= validate_pos( @_, { type => SCALAR } );
        return grep { $_ eq $root } @{ $root_of{$ident} };
    }

    sub add_root {
        my $self	= shift;
        my $ident	= ident $self;
        my ($root)	= validate_pos( @_, { type => SCALAR } );
        if ( not $self->has_root( $root ) ) {
            push @{ $root_of{$ident} }, $root;
        }
    }

    sub remove_root {
        my $self	= shift;
        my $ident	= ident $self;
        my ($root)	= validate_pos( @_, { type => SCALAR } );
        if ( $self->has_root( $root ) ) {
            $root_of{$ident} = [ grep { $_ ne $root } @{ $root_of{$ident} } ];
        }
    }

    sub update {

        my $self	= shift;
        my $ident	= ident $self;

        my @options	= ();

        if ( $self->get_actual ) {
            push @options, "actual=" . $self->get_actual;
        }

        if ( defined $self->get_anon ) {
            push @options, "anon=" . $self->get_anon;
        }

        if ( $self->get_nosuid ) {
            push @options, "nosuid";
        }

        if ( $self->get_ro_all ) {
            push @options, "ro";
        } elsif ( my @ro = $self->get_ro ) {
            push @options, "ro=" . join( ':', @ro );
        }

        if ( $self->get_rw_all ) {
            push @options, "rw";
        } elsif ( my @rw = $self->get_rw ) {
            push @options, "rw=" . join( ':', @rw );
        }

        if ( my @root = $self->get_root ) {
            push @options, "root=" . join( ':', @root );
        }

        if ( my @sec = $self->get_sec ) {
            push @options, "sec=" . join( ':', @sec );
        }

        my $options	= join ',', @options;

        my $argument	=
            $self->get_type eq 'permanent' ? '-p' : '-io';
            
        $self->get_filer->_run_command(
            command	=> [
                'exportfs', $argument, $options, $self->get_path,
            ],
        );

        if ( $self->get_type eq 'permanent' ) {
            $active_of{$ident}	= 1;
        }

        return 1;

    }

    sub compare {

        my $self	= shift;
        my ($other)	= validate_pos(
            @_,
            { isa	=> 'NetApp::Filer::Export' },
        );

        if ( $self->get_actual ne $other->get_actual ) {
            return;
        }

        if ( $self->get_nosuid ne $other->get_nosuid ) {
            return;
        }

        if ( defined $self->get_anon && defined $other->get_anon ) {
            if ( $self->get_anon ne $other->get_anon ) {
                return;
            }
        } elsif ( defined $self->get_anon || defined $other->get_anon ) {
            return;
        }

        if ( $self->get_rw_all && ! $other->get_rw_all ) {
            return;
        }

        if ( ! $self->get_rw_all && $other->get_rw_all ) {
            return;
        }

        if ( $self->get_ro_all && ! $other->get_ro_all ) {
            return;
        }

         if ( ! $self->get_ro_all && $other->get_ro_all ) {
            return;
        }

        if ( join( ',', sort $self->get_rw) ne
                 join( ',', sort $other->get_rw ) ) {
            return;
        }

        if ( join( ',', sort $self->get_ro) ne
                 join( ',', sort $other->get_ro ) ) {
            return;
        }

        if ( join( ',', sort $self->get_sec) ne
                 join( ',', sort $other->get_sec ) ) {
            return;
        }

        if ( join( ',', sort $self->get_root) ne
                 join( ',', sort $other->get_root ) ) {
            return;
        }

        return 1;

    }

}

sub _parse_export {

    my $class		= shift;
    my $line		= shift;

    chomp($line);
    $line		=~ s/\s*$//;

    my ($path,$options)	= split /\s+/, $line, 2;

    chomp($options);
    $options		=~ s/^-//;

    my $export		= {
        path		=> $path,
    };

    foreach my $option ( split /,/, $options ) {

        my ($key,$value)	= split /=/, $option;    

        if ( $key eq 'nosuid' ) {
            $export->{$key}	= 1
        } elsif ( $key eq 'ro' || $key eq 'rw' ) {
            if ( $value ) {
                $export->{$key}	= [ split /:/, $value ];
            } else {
                $export->{ $key . '_all' } = 1;
            }
        } elsif ( $key eq 'sec' || $key eq 'root' ) {
            $export->{$key}	= [ split /:/, $value ];
        } elsif ( $key eq 'actual' || $key eq 'anon' ) {
            $export->{$key}	= $value;
        } else {
            croak(
                "Unrecognized export option '$key'\n",
                "Exports entry: $line\n",
            );
        }

    }

    return $export;

}

1;
