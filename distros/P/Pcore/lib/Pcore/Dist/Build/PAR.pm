package Pcore::Dist::Build::PAR;

use Pcore -class, -ansi;
use Config;
use Pcore::Dist::Build::PAR::Script;

has dist => ( required => 1 );    # InstanceOf ['Pcore::Dist']

has force  => ();
has crypt  => ();
has clean  => ();
has gui    => ();
has script => ();                 # Maybe[ArrayRef]

sub run ($self) {
    if ( !$self->{dist}->par_cfg ) {
        say q[PAR profile wasn't found.];

        exit 1;
    }
    elsif ( !$self->{dist}->git ) {
        say q[Git was not required.];

        exit 1;
    }

    my $dist_id = $self->{dist}->id;

    if ( !$dist_id->{hash} ) {
        say q[Unable to identify current changeset.];

        exit 1;
    }

    if ( $dist_id->{is_dirty} && !$self->{force} ) {
        say q[Working copy has uncommited changes. Use --force to build PAR from the dirty source.];

        exit 1;
    }

    my $par_cfg = $self->{dist}->par_cfg;

    $self->{script} //= [];
    my %scripts = map { $_ => 1 } $self->{script}->@*;
    my @scripts = %scripts ? keys %scripts : keys $par_cfg->%*;

    # build scripts
    for my $script ( sort @scripts ) {

        # check, that par profile for script is exists
        if ( !$par_cfg->{$script} ) {
            say qq[Profile for script "$script" is ] . $BOLD . $WHITE . $ON_RED . ' not found ' . $RESET . '. Skip.';

            next;
        }

        # skip script if it is disabled
        elsif ( !$scripts{$script} && $par_cfg->{$script}->{disabled} ) {
            say qq[Script "$script" is ] . $BOLD . $WHITE . $ON_RED . ' disabled ' . $RESET . '. Skip.';

            next;
        }

        # load pardeps.json
        my $pardeps;

        my $pardeps_path = "$self->{dist}->{root}/share/pardeps-$script-@{[$^V->normal]}-$Config{archname}.json";

        if ( -f $pardeps_path ) {
            $pardeps = P->cfg->read($pardeps_path);
        }
        else {
            say qq[File "$pardeps_path" is not exists.];

            say $BOLD . $RED . qq[Deps for script "$script" wasn't scanned.] . $RESET;

            exit 1;
        }

        my $profile = { $par_cfg->{$script}->%* };

        $profile->{dist}   = $self->{dist};
        $profile->{script} = P->path("$self->{dist}->{root}/bin/$script");
        $profile->{crypt}  = $self->{crypt} if defined $self->{crypt};
        $profile->{clean}  = $self->{clean} if defined $self->{clean};
        $profile->{gui}    = $self->{gui} if defined $self->{gui};

        # check, that script from par profile exists in filesystem
        if ( !-f $profile->{script} ) {
            say $BOLD . $RED . qq[Script "$script" wasn't found.] . $RESET;

            next;
        }

        # add pardeps.json modules, skip eval modules
        $profile->{mod}->@{ grep { !/\A[(]eval\s/sm } $pardeps->@* } = ();

        # remove Inline.pm
        # TODO maybe remove all Inline::* modules???
        delete $profile->{mod}->{'Inline.pm'};

        # add Filter::Crypto::Decrypt deps if crypt mode is used
        $profile->{mod}->{'Filter/Crypto/Decrypt.pm'} = undef if $profile->{crypt};

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
