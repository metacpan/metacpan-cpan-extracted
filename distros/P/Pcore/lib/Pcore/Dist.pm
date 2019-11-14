package Pcore::Dist;

use Pcore -class;
use Config;
use Pcore::Lib::Scalar qw[is_path];

has root         => ( required => 1 );    # Maybe [Str], absolute path to the dist root
has is_installed => ( required => 1 );    # dist is installed to @INC as CPAN module, root is undefined
has share_dir    => ( required => 1 );    # absolute path to the dist share dir

has module => ( is => 'lazy' );           # InstanceOf ['Pcore::Lib::Perl::Module']

has is_main    => ( init_arg => undef );                        # main process dist
has cfg        => ( is       => 'lazy', init_arg => undef );    # dist cfg
has docker_cfg => ( is       => 'lazy', init_arg => undef );    # Maybe [HashRef], docker.yaml
has par_cfg    => ( is       => 'lazy', init_arg => undef );    # Maybe [HashRef], par.yaml
has name       => ( is       => 'lazy', init_arg => undef );    # Dist-Name
has is_pcore   => ( is       => 'lazy', init_arg => undef );
has git        => ( is       => 'lazy', init_arg => undef );    # Maybe [ InstanceOf ['Pcore::API::GIT'] ]
has build      => ( is       => 'lazy', init_arg => undef );    # InstanceOf ['Pcore::Dist::Build']
has id         => ( is       => 'lazy', init_arg => undef );
has releases   => ( is       => 'lazy', init_arg => undef );    # Maybe [ArrayRef]
has docker     => ( is       => 'lazy', init_arg => undef );    # Maybe [HashRef]

around new => sub ( $orig, $self, $dist ) {

    # PAR dist processing
    if ( $ENV{PAR_TEMP} && $dist eq $ENV{PAR_TEMP} ) {

        # dist is the PAR dist
        return $self->$orig( {
            root         => undef,
            is_installed => 1,
            share_dir    => P->path("$ENV{PAR_TEMP}/inc/share"),
        } );
    }

    my $module_name;

    # if $dist contain .pm suffix - this is a full or related module name
    if ( substr( $dist, -3, 3 ) eq '.pm' ) {
        $module_name = $dist;
    }

    # if $dist doesn't contain .pm suffix, but contain ".", "/" or "\" - this is a path
    elsif ( $dist =~ m[[./\\]]sm ) {

        # try find dist by path
        if ( my $root = $self->find_dist_root($dist) ) {

            # path is a part of the dist
            return $self->$orig( {
                root         => $root,
                is_installed => 0,
                share_dir    => "$root/share",
            } );
        }
        else {

            # path is NOT a part of a dist
            return;
        }
    }

    # otherwise $dist is a Package::Name
    else {
        $module_name = $dist =~ s[(?:::|-)][/]smgr . '.pm';
    }

    # find dist by module name
    my $module_lib;

    # find full module path
    if ( $module_lib = $INC{$module_name} ) {

        # if module is already loaded - get full module path from %INC
        # cut module name, throw error in case, where: 'Module/Name.pm' => '/path/to/Other/Module.pm'
        die q[Invalid module name in %INC, please report] if $module_lib !~ s[[/\\]\Q$module_name\E\z][]sm;
    }
    else {

        # or try to find module in @INC
        for my $inc (@INC) {
            next if ref $inc;

            if ( -f "$inc/$module_name" ) {
                $module_lib = $inc;

                last;
            }
        }
    }

    # module was not found in @INC
    return if !$module_lib;

    # normalize module lib
    $module_lib = P->path($module_lib);

    # convert Module/Name.pm to Dist-Name
    my $dist_name = $module_name =~ s[/][-]smgr;

    # remove .pm suffix
    substr $dist_name, -3, 3, $EMPTY;

    if ( -f "$module_lib/auto/share/dist/$dist_name/dist.yaml" ) {

        # module is installed
        return $self->$orig( {
            root         => undef,
            is_installed => 1,
            share_dir    => "$module_lib/auto/share/dist/$dist_name",
            module       => P->perl->module( $module_name, $module_lib ),
        } );
    }
    elsif ( $self->dir_is_dist_root("$module_lib/..") ) {
        my $root = P->path("$module_lib/..");

        # module is a dist
        return $self->$orig( {
            root         => $root,
            is_installed => 0,
            share_dir    => "$root/share",
            module       => P->perl->module( $module_name, $module_lib ),
        } );
    }
};

# CLASS METHODS
sub find_dist_root ( $self, $path ) {
    $path = P->path($path) if !is_path $path;

    if ( !$self->dir_is_dist_root($path) ) {
        $path = $path->parent;

        while ($path) {
            last if $self->dir_is_dist_root($path);

            $path = $path->parent;
        }
    }

    if ( defined $path ) {
        return $path->clone->to_realpath;
    }
    else {
        return;
    }
}

sub dir_is_dist_root ( $self, $path ) { return -f "$path/share/dist.yaml" ? 1 : 0 }

# BUILDERS
sub _build_module ($self) {
    my $module_name = $self->name =~ s[-][/]smgr . '.pm';

    my $module;

    if ( $self->{is_installed} ) {

        # find main module in @INC
        $module = P->perl->module($module_name);
    }
    elsif ( -f "$self->{root}/lib/$module_name" ) {

        # we check -f manually, because perl->module will search for Module/Name.pm in whole @INC, but we need only to search module in dist root
        # get main module from dist root lib
        $module = P->perl->module( $module_name, "$self->{root}/lib" );
    }

    die qq[Distr main module "$module_name" wasn't found, distribution is corrupted] if !$module;

    return $module;
}

sub _build_cfg ($self) { return P->cfg->read("$self->{share_dir}/dist.yaml") }

sub _build_docker_cfg ($self) {
    if ( -f "$self->{share_dir}/docker.yaml" ) {
        return P->cfg->read("$self->{share_dir}/docker.yaml");
    }

    return;
}

sub _build_par_cfg ($self) {
    if ( -f "$self->{share_dir}/par.yaml" ) {
        return P->cfg->read("$self->{share_dir}/par.yaml");
    }

    return;
}

sub _build_name ($self) { return $self->cfg->{name} }

sub _build_is_pcore ($self) { return $self->name eq 'Pcore' }

sub _build_git ($self) {
    return if $self->{is_installed};

    return P->class->load('Pcore::API::Git')->new( $self->{root} );
}

sub _build_build ($self) { return P->class->load('Pcore::Dist::Build')->new( { dist => $self } ) }

sub _build_id ($self) {
    my $id = {
        branch           => undef,
        date             => undef,
        hash             => undef,
        hash_short       => undef,
        is_dirty         => undef,
        release          => undef,
        release_distance => undef,
        tags             => undef,
    };

    # get data from git
    if ( $self->git ) {
        my ( $is_error, $res1 );

        my $cv = P->cv->begin;

        $cv->begin;
        Coro::async_pool sub {
            my $res = $self->git->git_run('log -1 --pretty=format:%H%n%cI%n%D');

            $cv->end;

            $is_error = 1 if !$res;

            return if $is_error;

            ( $res1->@{qw[hash date]}, my $ref ) = split /\n/sm, $res->{data};

            $res1->{hash_short} = substr $res1->{hash}, 0, 7;

            my @ref = split /,/sm, $ref;

            # parse current branch
            if ( ( shift @ref ) =~ /->\s(.+)/sm ) {
                $res1->{branch} = $1;
            }

            # parse tags
            for my $token (@ref) {
                if ( $token =~ /tag:\s(.+)/sm ) {
                    push $res1->{tags}->@*, $1;
                }
            }

            return;
        };

        $cv->begin;
        Coro::async_pool sub {
            my $res = $self->git->git_run('describe --tags --always --match "v[0-9]*.[0-9]*.[0-9]*"');

            $cv->end;

            $is_error = 1 if !$res;

            return if $is_error;

            # remove trailing "\n"
            chomp $res->{data};

            my @data = split /-/sm, $res->{data};

            if ( $data[0] =~ /\Av\d+[.]\d+[.]\d+\z/sm ) {
                $res1->{release} = $data[0];

                $res1->{release_distance} = 0+ $data[1] if defined $data[1];
            }

            return;
        };

        $cv->begin;
        Coro::async_pool sub {
            my $res = $self->git->git_run('status --porcelain');

            $cv->end;

            $is_error = 1 if !$res;

            return if $is_error;

            $res1->{is_dirty} = 0+ !!$res->{data};

            return;
        };

        $cv->end->recv;

        $id->@{ keys $res1->%* } = values $res1->%* if !$is_error;
    }

    # get data from dist-id.yaml
    elsif ( -f "$self->{share_dir}/dist-id.yaml" ) {
        $id = P->cfg->read("$self->{share_dir}/dist-id.yaml");
    }

    # convert date to UTC
    $id->{date} = P->date->from_string( $id->{date} )->at_utc->to_string if defined $id->{date};

    return $id;
}

sub _build_releases ($self) {
    return if !$self->git;

    my $res = $self->git->git_run('tag --merged master');

    return if !$res;

    return if !$res->{data};

    my @releases = sort { version->parse($a) <=> version->parse($b) } grep {/\Av\d+[.]\d+[.]\d+\z/sm} split /\n/sm, $res->{data};

    return \@releases if @releases;

    return;
}

sub clear ($self) {

    # clear version
    $self->module->clear if exists $self->{module};

    delete $self->{id};

    delete $self->{releases};

    delete $self->{cfg};

    delete $self->{docker_cfg};

    delete $self->{docker};

    return;
}

sub version_string ($self) {
    my @res = ( $self->name );

    my $id = $self->id;

    if ( $id->{hash} ) {
        if ( $id->{release} ) {
            push @res, $id->{release} . ( $id->{release_distance} ? "+$id->{release_distance}" : $EMPTY );
        }

        push @res, $id->{hash_short} . ( $id->{is_dirty} ? '.dirty' : $EMPTY );

        push @res, $id->{date} if $id->{date};
    }

    return join $SPACE, @res;
}

sub _build_docker ($self) {
    if ( $self->docker_cfg && -f "$self->{root}/Dockerfile" ) {
        my $docker = {
            repo_namespace => $self->docker_cfg->{repo_namespace},
            repo_name      => $self->docker_cfg->{repo_name},
            repo_id        => undef,
            from           => undef,
            from_repo_id   => undef,
            from_tag       => undef,
        };

        return if !$docker->{repo_namespace} || !$docker->{repo_name};

        $docker->{repo_id} = "$docker->{repo_namespace}/$docker->{repo_name}";

        my $dockerfile = P->file->read_bin("$self->{root}/Dockerfile");

        if ( $dockerfile =~ /^FROM\s+([[:alnum:]\/_-]+)(?::([[:alnum:]._-]+))?\s*$/sm ) {
            $docker->{from_repo_id} = $1;

            $docker->{from_tag} = $2 // 'latest';

            $docker->{from} = "$docker->{from_repo_id}:$docker->{from_tag}";

            return $docker;
        }
        else {
            die q[Error parsing "FROM" command in Dockerfile];
        }
    }
    else {
        return;
    }
}

sub is_pushed ($self) {
    return if !$self->git;

    my $res = $self->git->git_run('branch -v --no-color');

    return if !$res;

    return if !$res->{data};

    my $data;

    for my $br ( split /\n/sm, $res->{data} ) {
        if ( $br =~ /\A[*]?\s+(.+?)\s+(?:.+?)\s+(?:\[ahead\s(\d+)\])?/sm ) {
            $data->{$1} = $2 || 0;
        }
        else {
            die qq[Can't parse branch: $br];
        }
    }

    return $data;
}

sub get_changesets_log ( $self, $tag = undef ) {
    return if !$self->git;

    my $cmd = 'log --pretty=format:%s';

    $cmd .= " $tag..HEAD" if $tag;

    my $res = $self->git->git_run($cmd);

    return if !$res;

    return if !$res->{data};

    my ( $data, $idx );

    for my $log ( split /\n/sm, $res->{data} ) {
        if ( !exists $idx->{$log} ) {
            $idx->{$log} = 1;

            push $data->@*, $log;
        }
    }

    return $data;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
