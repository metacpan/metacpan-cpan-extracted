package Pcore::Util::Path::Dir;

use Pcore -role;
use Fcntl qw[];

has _dir_is_root => ();
has _dir_parent  => ();

around _clear_cache => sub ( $orig, $self ) {
    delete $self->@{qw[_dir_is_root _dir_parent]};

    return $self->$orig;
};

sub is_root ($self) {
    if ( !exists $self->{_dir_is_root} ) {
        if ( $self->{is_abs} ) {
            if ( $self->{volume} ) {
                if ( length $self->{path} == 3 ) {
                    $self->{_dir_is_root} = 1;
                }
                else {
                    $self->{_dir_is_root} = 0;
                }
            }
            else {
                if ( $self->{path} eq '/' ) {
                    $self->{_dir_is_root} = 1;
                }
                else {
                    $self->{_dir_is_root} = 0;
                }
            }
        }
        else {
            $self->{_dir_is_root} = 0;
        }
    }

    return $self->{_dir_is_root};
}

sub parent ($self) {
    if ( !exists $self->{_dir_parent} ) {
        my $path = $self->{is_abs} ? $self : $self->clone->to_abs;

        my $parent = $self->new("$self->{path}/..");

        $self->{_dir_parent} = $parent->is_root ? undef : $parent;
    }

    return $self->{_dir_parent};
}

sub read_dir ( $self, @ ) {
    return if !-d $self;

    my %args = (
        abs         => 0,
        max_depth   => 1,        # 0 - unlimited
        follow_link => 1,
        is_dir      => 1,
        is_file     => 1,
        is_sock     => 1,
        is_link     => undef,    # undef - do not check, 1 - add links only, 0 - skip links
        @_[ 1 .. $#_ ]
    );

    my $abs_base = $self->to_abs->encoded;

    my $prefix = $args{abs} ? $abs_base : '.';

    my $res;

    my $read = sub ( $dir, $depth ) {
        opendir my $dh, "$abs_base/$dir" or die qq[Can't open dir "$abs_base/$dir"];

        my @paths = readdir $dh or die $!;

        closedir $dh or die $!;

        for my $file (@paths) {
            next if $file eq '.' || $file eq '..';

            my $abs_path = "$abs_base/$dir/$file";

            my ( $stat, $lstat );

            my $push = 1;

            if ( defined $args{is_link} ) {
                $lstat //= ( lstat $abs_path )[2] & Fcntl::S_IFMT;

                if ( $lstat == Fcntl::S_IFLNK ) {
                    $push = 0 if !$args{is_link};
                }
                else {
                    $push = 0 if $args{is_link};
                }
            }

            if ( $push && !$args{is_file} ) {
                $stat //= ( stat $abs_path )[2] & Fcntl::S_IFMT;

                $push = 0 if $stat == Fcntl::S_IFREG;
            }

            if ( $push && !$args{is_dir} ) {
                $stat //= ( stat $abs_path )[2] & Fcntl::S_IFMT;

                $push = 0 if $stat == Fcntl::S_IFDIR;
            }

            if ( $push && !$args{is_sock} ) {
                $stat //= ( stat $abs_path )[2] & Fcntl::S_IFMT;

                $push = 0 if $stat == Fcntl::S_IFSOCK;
            }

            if ($push) {
                my $path = "$prefix/$dir/$file";

                $path = $self->decode($path) if $MSWIN;

                push $res->@*, $self->new($path);
            }

            if ( !$args{max_depth} || $depth < $args{max_depth} ) {
                $stat //= ( stat $abs_path )[2] & Fcntl::S_IFMT;

                if ( $stat == Fcntl::S_IFDIR ) {
                    if ( !$args{follow_link} ) {
                        $lstat //= ( lstat $abs_path )[2] & Fcntl::S_IFMT;

                        next if $lstat == Fcntl::S_IFLNK;
                    }

                    __SUB__->( "$dir/$file", $depth + 1 );
                }
            }
        }

        return;
    };

    $read->( $EMPTY, 1 );

    return $res;
}

# mkdir with chmod support
sub mkdir ( $self, $mode = undef ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    if ( defined wantarray ) {
        if ( defined $mode ) {
            return mkdir $self->encoded, P->file->calc_chmod($mode);
        }
        else {
            return mkdir $self->encoded;
        }
    }
    else {
        if ( defined $mode ) {
            mkdir $self->encoded, P->file->calc_chmod($mode) or die qq[Can't mkdir "$self". $!];
        }
        else {
            mkdir $self->encoded or die qq[Can't mkdir "$self". $!];
        }

        return;
    }
}

# TODO
sub mkpath ( $self, %args ) {
    require File::Path;    ## no critic qw[Modules::ProhibitEvilModules]

    # my %args = (
    #     mode  => q[rwx------],
    #     umask => undef,
    #     splice @_, 1,
    # );

    # require File::Path;

    # $args{mode} = calc_chmod( $args{mode} );

    # my $umask_guard = defined $args{umask} ? &umask( delete $args{umask} ) : delete $args{umask};    ## no critic qw[Subroutines::ProhibitAmpersandSigils]

    return File::Path::make_path( $self->encoded, \%args );
}

# TODO
sub rmtree ( $path, @ ) {
    my %args = (
        safe      => 0,    # 0 - will attempts to alter file permission
        keep_root => 0,
        splice @_, 1,
    );

    require File::Path;    ## no critic qw[Modules::ProhibitEvilModules]

    my $error;

    $args{error} = \$error;

    my $removed = File::Path::remove_tree( "$path", \%args );

    return $error->@* ? () : 1;
}

# TODO
sub empty_dir ( $path, @ ) {
    my %args = (
        safe => 0,    # 0 - will attempts to alter file permission
        splice @_, 1,
        keep_root => 1,
    );

    require File::Path;    ## no critic qw[Modules::ProhibitEvilModules]

    return File::Path::remove_tree( "$path", \%args );
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 55                   | Subroutines::ProhibitExcessComplexity - Subroutine "read_dir" with high complexity score (30)                  |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 58                   | CodeLayout::RequireTrailingCommas - List declaration without trailing comma                                    |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Path::Dir

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
