package Pcore::Dist::Build;

use Pcore -class;
use Pcore::Util::File::Tree;

has dist => ();    # InstanceOf ['Pcore::Dist']

has wiki   => ( is => 'lazy', init_arg => undef );    # Maybe [ InstanceOf ['Pcore::Dist::Build::Wiki'] ]
has issues => ( is => 'lazy', init_arg => undef );    # Maybe [ InstanceOf ['Pcore::Dist::Build::Issues'] ]
has docker => ( is => 'lazy', init_arg => undef );    # Maybe [ InstanceOf ['Pcore::Dist::Build::Docker'] ]

sub _build_wiki ($self) {
    require Pcore::Dist::Build::Wiki;

    return Pcore::Dist::Build::Wiki->new( { dist => $self->{dist} } );
}

sub _build_issues ($self) {
    require Pcore::Dist::Build::Issues;

    return Pcore::Dist::Build::Issues->new( { dist => $self->{dist} } );
}

sub _build_docker ($self) {
    require Pcore::Dist::Build::Docker;

    return Pcore::Dist::Build::Docker->new( { dist => $self->{dist} } );
}

sub create ( $self, $args ) {
    require Pcore::Dist::Build::Create;

    return Pcore::Dist::Build::Create->new($args)->run;
}

sub setup ($self) {
    $ENV->user_cfg;

    say qq["@{[$ENV->user_cfg_path]}" was created, fill it manually with correct values];

    return;
}

sub clean ($self) {
    require Pcore::Dist::Build::Clean;

    Pcore::Dist::Build::Clean->new( { dist => $self->{dist} } )->run;

    return;
}

sub update ($self) {
    require Pcore::Dist::Build::Update;

    Pcore::Dist::Build::Update->new( { dist => $self->{dist} } )->run;

    return;
}

sub deploy ( $self, %args ) {
    require Pcore::Dist::Build::Deploy;

    Pcore::Dist::Build::Deploy->new( { dist => $self->{dist}, %args } )->run;

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

        my $psplit = $MSWIN ? '\\' : '/';

        return if !P->sys->run_proc( [ $^X, 'Build.PL' ] );

        return if !P->sys->run_proc(".${psplit}Build");

        return if !P->sys->run_proc( [ ".${psplit}Build", 'test', $args{verbose} ? '--verbose' : $EMPTY ] );
    }

    return 1;
}

sub release ( $self, @args ) {
    require Pcore::Dist::Build::Release;

    return Pcore::Dist::Build::Release->new( { dist => $self->{dist}, @args } )->run;
}

sub par ( $self, @ ) {
    my %args = (
        release => 0,
        crypt   => undef,
        clean   => undef,
        splice @_, 1,
    );

    require Pcore::Dist::Build::PAR;

    Pcore::Dist::Build::PAR->new( { %args, dist => $self->{dist} } )->run;    ## no critic qw[ValuesAndExpressions::ProhibitCommaSeparatedStatements]

    return;
}

sub temp_build ( $self, $keep = 0 ) {
    require Pcore::Dist::Build::Temp;

    return Pcore::Dist::Build::Temp->new( { dist => $self->{dist} } )->run($keep);
}

sub tgz ($self) {
    my $temp = $self->temp_build;

    require Archive::Tar;

    my $tgz = Archive::Tar->new;

    my $base_dir = $self->{dist}->name . q[-] . $self->{dist}->version;

    for my $path ( $temp->read_dir( max_depth => 0, is_dir => 0 )->@* ) {
        my $mode;

        if ( $path =~ m[\A(script|t)/]sm ) {
            $mode = P->file->calc_chmod('rwxr-xr-x');
        }
        else {
            $mode = P->file->calc_chmod('rw-r--r--');
        }

        $tgz->add_data( "$base_dir/$path", P->file->read_bin("$temp/$path"), { mode => $mode } );
    }

    my $path = "$self->{dist}->{root}/data/.build/$base_dir.tar.gz";

    if ( -e $path ) {
        unlink $path or die qq[Can't unlink "$path"];
    }
    elsif ( !-d "$self->{dist}->{root}/data/.build" ) {
        P->file->mkpath("$self->{dist}->{root}/data/.build");
    }

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
