package Pcore::Dist::Build::PAR;

use Pcore -class, -ansi;
use Config;
use Pcore::Dist::Build::PAR::Script;

has dist => ( is => 'ro', isa => InstanceOf ['Pcore::Dist'], required => 1 );

has crypt => ( is => 'ro', isa => Maybe [Bool] );
has clean => ( is => 'ro', isa => Maybe [Bool] );

has release => ( is => 'lazy', isa => Bool, init_arg => undef );

sub _build_release ($self) {
    return $self->dist->id->{release_distance} ? 0 : 1;
}

sub run ($self) {
    if ( !$self->dist->par_cfg ) {
        say q[par profile wasn't found.];

        exit 1;
    }
    elsif ( !$self->dist->scm ) {
        say q[SCM is required];

        exit 1;
    }
    elsif ( !$self->dist->is_commited ) {
        say q[Working copy has uncommited changes];

        exit 1;
    }

    # load global pcore.perl config
    my $pcore_cfg = P->cfg->load( $ENV->share->get( '/data/pcore.perl', lib => 'Pcore' ) );

    # build scripts
    for my $script ( sort keys $self->dist->par_cfg->%* ) {

        # load pardeps.json
        my $pardeps;

        my $pardeps_path = $self->dist->root . "share/pardeps-$script-@{[$^V->normal]}-$Config{archname}.json";

        if ( -f $pardeps_path ) {
            $pardeps = P->cfg->load($pardeps_path);
        }
        else {
            say qq["$pardeps_path" is not exists.];

            say BOLD . RED . qq[Deps for script "$script" wasn't scanned.] . RESET;

            say q[Run source scripts with --scan-deps option.];

            exit 1;
        }

        my $profile = $self->dist->par_cfg->{$script};

        $profile->{dist}    = $self->dist;
        $profile->{script}  = P->path( $self->dist->root . 'bin/' . $script );
        $profile->{release} = $self->release;
        $profile->{crypt}   = $self->crypt if defined $self->crypt;
        $profile->{clean}   = $self->clean if defined $self->clean;

        # check, that script from par profile exists in filesystem
        if ( !-f $profile->{script} ) {
            say BOLD . RED . qq[Script "$script" wasn't found.] . RESET;

            next;
        }

        # add pardeps.json modules, skip eval records
        $profile->{mod}->@{ grep { !/\A[(]eval\s/sm } $pardeps->@* } = ();

        # add common modules
        $profile->{mod}->@{ $pcore_cfg->{par}->{mod}->@* } = ();

        # add global arch modules
        $profile->{mod}->@{ $pcore_cfg->{par}->{arch}->{ $Config{archname} }->{mod}->@* } = () if exists $pcore_cfg->{par}->{arch}->{ $Config{archname} }->{mod};

        # remove common ignored modules
        delete $profile->{mod}->@{ $pcore_cfg->{par}->{mod_ignore}->@* };

        # replace Inline.pm with Pcore/Core/Inline.pm
        $profile->{mod}->{'Pcore/Core/Inline.pm'} = undef if delete $profile->{mod}->{'Inline.pm'};

        # add Filter::Crypto::Decrypt deps if crypt mode is used
        $profile->{mod}->{'Filter/Crypto/Decrypt.pm'} = undef if $profile->{crypt};

        # index and add shlib
        my $shlib = {};

        if ( exists $pcore_cfg->{par}->{arch}->{ $Config{archname} }->{mod_shlib} ) {
            for my $mod ( grep { exists $profile->{mod}->{$_} } keys $pcore_cfg->{par}->{arch}->{ $Config{archname} }->{mod_shlib}->%* ) {
                $shlib->@{ $pcore_cfg->{par}->{arch}->{ $Config{archname} }->{mod_shlib}->{$mod}->@* } = ();
            }
        }

        $profile->{shlib} = [ keys $shlib->%* ];

        Pcore::Dist::Build::PAR::Script->new($profile)->run;
    }

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::Build::PAR - build PAR executable

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
