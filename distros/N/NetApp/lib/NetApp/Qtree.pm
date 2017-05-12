
package NetApp::Qtree;

our $VERSION = '500.002';
$VERSION = eval $VERSION;  ##  no critic: StringyEval

use strict;
use warnings;
use English;
use Carp;

use Class::Std;
use Params::Validate qw( :all );
use Regexp::Common;

{

    my %filer_of	:ATTR( get => 'filer' );

    my %volume_name_of	:ATTR( get => 'volume_name' );

    my %name_of		:ATTR( get => 'name' );
    my %security_of	:ATTR( get => 'security' );
    my %oplocks_of	:ATTR( get => 'oplocks' );
    my %status_of	:ATTR( get => 'status' );
    my %id_of		:ATTR( get => 'id' );
    my %vfiler_of	:ATTR( get => 'vfiler' );

    sub BUILD {

        my ($self,$ident,$args_ref) = @_;

        my @args = %$args_ref;

        my (%args) 	= validate( @args, {
            filer	=> { isa	=> 'NetApp::Filer' },
            volume_name => { type	=> SCALAR },
            name	=> { type	=> SCALAR },
            security	=> { type	=> SCALAR },
            oplocks	=> { type	=> SCALAR },
            status	=> { type	=> SCALAR },
            id		=> { type	=> SCALAR },
            vfiler	=> { type	=> SCALAR,
                             optional	=> 1 },
        });        

        $filer_of{$ident}	= $args{filer};
        $volume_name_of{$ident}	= $args{volume_name};

        $name_of{$ident}	= $args{name};
        $security_of{$ident}	= $args{security};
        $oplocks_of{$ident}	= $args{oplocks};
        $status_of{$ident}	= $args{status};
        $id_of{$ident}		= $args{id};

        if ( $args{vfiler} ) {
            $vfiler_of{$ident}	= $args{vfiler};
        }

    }

    sub get_volume {
        my $self	= shift;
        return $self->get_filer->get_volume( $self->get_volume_name );
    }

    sub get_aggregate {
        return shift->get_volume->get_aggregate;
    }

    sub set_security {

        my $self	= shift;
        my $ident	= ident $self;
        my $security	= shift;

        if ( $security !~ /^(unix|ntfs|mixed)$/ ) {
            croak("Invalid qtree security value: $security\n");
        }

        my $name	= $self->get_name;

        $self->get_filer->_run_command(
            command    	=> [qw( qtree security ), $name, $security ],
        );

        $security_of{$ident}	= $security;

    }

    sub set_oplocks {

        my $self	= shift;
        my $ident	= ident $self;

        my $state	= shift;

        my $enable	= $state ? 'enable' : 'disable';

        my $name	= $self->get_name;

        $self->get_filer->_run_command(
            command    	=> [qw( qtree oplocks ), $name, $enable ],
        );

        $oplocks_of{$ident}	= $enable eq 'enable' ? 1 : 0;

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

        my @exports	= ();

        foreach my $export ( $self->get_filer->get_exports ) {

            if ( $export->get_path eq $self->get_name ) {
                push @exports, $export;
            } elsif ( $export->get_actual eq $self->get_name ) {
                push @exports, $export;
            }

        }

        return @exports;

    }

}

sub _parse_qtree_status_qtree {

    my $class		= shift;
    my $line		= shift;

    my $qtree		= {};

    my @data		= split( /\s+/, $line );

    $qtree->{volume_name} = shift @data;

    $qtree->{name}	= "/vol/$qtree->{volume_name}";

    if ( $data[0] !~ /^(unix|ntfs|mixed)$/ ) {
        $qtree->{name}	.= "/" . shift @data;
    }

    $qtree->{security}	= $data[0];
    $qtree->{oplocks}	= $data[1] eq 'enabled' ? 1 : 0;
    $qtree->{status}	= $data[2];
    $qtree->{id}       	= $data[3];

    if ( $data[4] ) {
        $qtree->{vfiler}	= $data[4];
    }

    return $qtree;

}

1;
