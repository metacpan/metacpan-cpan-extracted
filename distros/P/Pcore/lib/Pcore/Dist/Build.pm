package Pcore::Dist::Build;

use Pcore -class;
use Pcore::Util::File::Tree;

has dist => ( is => 'ro', isa => InstanceOf ['Pcore::Dist'] );

has wiki   => ( is => 'lazy', isa => Maybe [ InstanceOf ['Pcore::Dist::Build::Wiki'] ],   init_arg => undef );
has issues => ( is => 'lazy', isa => Maybe [ InstanceOf ['Pcore::Dist::Build::Issues'] ], init_arg => undef );
has docker => ( is => 'lazy', isa => Maybe [ InstanceOf ['Pcore::Dist::Build::Docker'] ], init_arg => undef );

sub _build_wiki ($self) {
    state $init = !!require Pcore::Dist::Build::Wiki;

    return Pcore::Dist::Build::Wiki->new( { dist => $self->dist } );
}

sub _build_issues ($self) {
    state $init = !!require Pcore::Dist::Build::Issues;

    return Pcore::Dist::Build::Issues->new( { dist => $self->dist } );
}

sub _build_docker ($self) {
    state $init = !!require Pcore::Dist::Build::Docker;

    return Pcore::Dist::Build::Docker->new( { dist => $self->dist } );
}

sub create ( $self, $args ) {
    state $init = !!require Pcore::Dist::Build::Create;

    return Pcore::Dist::Build::Create->new($args)->run;
}

sub setup ($self) {
    $ENV->user_cfg;

    say qq["@{[$ENV->user_cfg_path]}" was created, fill it manually with correct values];

    return;
}

sub clean ($self) {
    state $init = !!require Pcore::Dist::Build::Clean;

    Pcore::Dist::Build::Clean->new( { dist => $self->dist } )->run;

    return;
}

sub update ($self) {
    state $init = !!require Pcore::Dist::Build::Update;

    Pcore::Dist::Build::Update->new( { dist => $self->dist } )->run;

    return;
}

sub deploy ( $self, %args ) {
    state $init = !!require Pcore::Dist::Build::Deploy;

    Pcore::Dist::Build::Deploy->new( { dist => $self->dist, %args } )->run;

    return;
}

sub test ( $self, @ ) {
    my %args = (
        author  => 0,
        release => 0,
        smoke   => 0,
        all     => 0,
        jobs    => 1,
        verbose => 0,
        keep    => 0,
        splice @_, 1,
    );

    local $ENV{AUTHOR_TESTING}    = 1 if $args{author}  || $args{all};
    local $ENV{RELEASE_TESTING}   = 1 if $args{release} || $args{all};
    local $ENV{AUTOMATED_TESTING} = 1 if $args{smoke}   || $args{all};

    local $ENV{HARNESS_OPTIONS} = $ENV{HARNESS_OPTIONS} ? "$ENV{HARNESS_OPTIONS}:j$args{jobs}" : "j$args{jobs}";

    my $build = $self->temp_build( $args{keep} );

    # build & test
    {
        my $chdir_guard = P->file->chdir($build);

        my $psplit = $MSWIN ? q[\\] : q[/];

        return if !P->sys->run_proc( [qw[perl Build.PL]] );

        return if !P->sys->run_proc(".${psplit}Build");

        return if !P->sys->run_proc( [ ".${psplit}Build", 'test', $args{verbose} ? '--verbose' : q[] ] );
    }

    return 1;
}

sub release ( $self, @args ) {
    state $init = !!require Pcore::Dist::Build::Release;

    return Pcore::Dist::Build::Release->new( { dist => $self->dist, @args } )->run;
}

sub par ( $self, @ ) {
    my %args = (
        release => 0,
        crypt   => undef,
        clean   => undef,
        splice @_, 1,
    );

    state $init = !!require Pcore::Dist::Build::PAR;

    Pcore::Dist::Build::PAR->new( { %args, dist => $self->dist } )->run;    ## no critic qw[ValuesAndExpressions::ProhibitCommaSeparatedStatements]

    return;
}

sub temp_build ( $self, $keep = 0 ) {
    state $init = !!require Pcore::Dist::Build::Temp;

    return Pcore::Dist::Build::Temp->new( { dist => $self->dist } )->run($keep);
}

sub tgz ($self) {
    my $temp = $self->temp_build;

    state $init = !!require Archive::Tar;

    my $tgz = Archive::Tar->new;

    my $base_dir = $self->dist->name . q[-] . $self->dist->version;

    for my $path ( P->path1($temp)->read_dir( max_depth => 0, is_dir => 0 )->@* ) {
        my $mode;

        if ( $path =~ m[\A(script|t)/]sm ) {
            $mode = P->file->calc_chmod('rwxr-xr-x');
        }
        else {
            $mode = P->file->calc_chmod('rw-r--r--');
        }

        $tgz->add_data( "$base_dir/$path", P->file->read_bin("$temp/$path")->$*, { mode => $mode } );
    }

    my $path = $ENV->{PCORE_SYS_DIR} . 'build/' . $self->dist->name . q[-] . $self->dist->version . '.tar.gz';

    $tgz->write( $path, Archive::Tar::COMPRESS_GZIP() );

    return $path;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::Build

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
