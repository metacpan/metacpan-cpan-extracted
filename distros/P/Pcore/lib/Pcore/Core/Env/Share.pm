package Pcore::Core::Env::Share;

use Pcore -class, -const;
use Pcore::Util::Scalar qw[is_plain_arrayref is_plain_hashref];

has _temp => ( is => 'lazy', isa => InstanceOf ['Pcore::Util::File::TempDir'], init_arg => undef );
has _lib         => ( is => 'ro',   isa => HashRef, default => sub { {} }, init_arg => undef );                   # name => [$level, $path]
has _storage     => ( is => 'lazy', isa => HashRef, default => sub { {} }, clearer  => 1, init_arg => undef );    # storage cache, name => [$path, ...]
has _lib_storage => ( is => 'lazy', isa => HashRef, default => sub { {} }, init_arg => undef );                   # lib storage cache, {lib}->{storage} = $path

const our $RESERVED_LIB_NAME => {
    dist => 1,                                                                                                    # alias for main dist
    temp => 1,                                                                                                    # temporary resources lib
};

sub _build__temp ($self) {
    return P->file->tempdir;
}

sub add_lib ( $self, $name, $path, $level ) {
    die qq[resource lib name "$name" is reserved] if exists $RESERVED_LIB_NAME->{$name};

    die qq[resource lib "$name" already exists] if exists $self->_lib->{$name};

    # register lib
    $self->_lib->{$name} = [ $level, $path ];

    # clear cache
    $self->_clear_storage;

    return;
}

# return lib path by name
sub get_lib ( $self, $lib_name ) {
    \my $libs = \$self->_lib;

    if ( $ENV->is_par ) {

        # under the PAR all resources libs are merged under the "dist" alias
        return $libs->{dist}->[1];
    }
    elsif ( $lib_name eq 'temp' ) {
        return $self->_temp->path;
    }
    else {
        if ( $lib_name eq 'dist' ) {
            if ( my $dist = $ENV->dist ) {
                $lib_name = lc $dist->name;
            }
            else {
                return;
            }
        }

        return if !exists $libs->{$lib_name};

        return $libs->{$lib_name}->[1];
    }
}

# return undef if storage is not exists
# return $storage_path if lib is specified
# return ArrayRef[$storage_path] if lib is not specified
sub get_storage ( $self, $storage_name, $lib_name = undef ) {
    \my $libs = \$self->_lib;

    if ($lib_name) {
        my $lib_path = $self->get_lib($lib_name);

        die qq[resource lib is not exists "$lib_name"] if !$lib_path;

        \my $lib_storage = \$self->_lib_storage;

        # cache lib/storage path, if not cached yet
        if ( !exists $lib_storage->{$lib_name}->{$storage_name} ) {
            if ( -d "${lib_path}${storage_name}" ) {
                $lib_storage->{$lib_name}->{$storage_name} = $lib_path . $storage_name;
            }
            else {
                $lib_storage->{$lib_name}->{$storage_name} = undef;
            }
        }

        # return cached path
        return $lib_storage->{$lib_name}->{$storage_name};
    }
    else {
        \my $storage = \$self->_storage;

        # build and cache storage paths array
        if ( !exists $storage->{$storage_name} ) {
            for my $lib_name ( sort { $libs->{$b}->[0] <=> $libs->{$a}->[0] } keys $libs->%* ) {
                my $storage_path = $libs->{$lib_name}->[1] . $storage_name;

                push $storage->{$storage_name}->@*, $storage_path if -d $storage_path;
            }

            $storage->{$storage_name} = undef if !exists $storage->{$storage_name};
        }

        # return cached value
        return $storage->{$storage_name};
    }
}

sub get ( $self, $path, @ ) {
    my %args = (
        storage => undef,
        lib     => undef,
        splice @_, 2,
    );

    # get storage name from path
    if ( !$args{storage} ) {
        if ( $path =~ m[\A/?([^/]+)/(.+)]sm ) {
            $args{storage} = $1;

            $path = P->path( q[/] . $2 );
        }
        else {
            die qq[invalid resource path "$path"];
        }
    }
    else {
        $path = P->path( q[/] . $path );
    }

    if ( $args{lib} ) {
        if ( my $storage_path = $self->get_storage( $args{storage}, $args{lib} ) ) {
            my $res = $storage_path . $path;

            return $res if -f $res;
        }
    }
    elsif ( my $storage = $self->get_storage( $args{storage} ) ) {
        for my $storage_path ( $storage->@* ) {
            my $res = $storage_path . $path;

            return $res if -f $res;
        }
    }

    return;
}

sub store ( $self, $path, $file, $lib_name, @ ) {
    my %args = (
        storage => undef,
        splice @_, 4,
    );

    my $lib_path = $self->get_lib($lib_name);

    die qq[resource lib is not exists "$lib_name"] if !$lib_path;

    # get storage name from path
    if ( !$args{storage} ) {
        if ( $path =~ m[\A/?([^/]+)/(.+)]sm ) {
            $args{storage} = $1;

            $path = P->path( q[/] . $2 );
        }
        else {
            die qq[invalid resource path "$path"];
        }
    }
    else {
        $path = P->path( q[/] . $path );
    }

    # clear storage cache if new storage was created
    if ( !-d "${lib_path}$args{storage}" ) {
        delete $self->_storage->{ $args{storage} };

        delete $self->_lib_storage->{$lib_name}->{ $args{storage} } if exists $self->_lib_storage->{$lib_name};
    }

    # create path
    P->file->mkpath( $lib_path . $args{storage} . $path->dirname ) if !-d "${lib_path}$args{storage}@{[$path->dirname]}";

    # create file
    if ( ref $file eq 'SCALAR' ) {
        P->file->write_bin( $lib_path . $args{storage} . $path, $file );
    }
    elsif ( is_plain_arrayref $file || is_plain_hashref $file ) {
        P->cfg->store( $lib_path . $args{storage} . $path, $file, readable => 1 );
    }
    else {
        P->file->copy( $file, $lib_path . $args{storage} . $path );
    }

    return $lib_path . $args{storage} . $path;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 147                  | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 93                   | BuiltinFunctions::ProhibitReverseSortBlock - Forbid $b before $a in sort blocks                                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Env::Share

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
