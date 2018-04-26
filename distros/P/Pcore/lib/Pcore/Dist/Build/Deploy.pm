package Pcore::Dist::Build::Deploy;

use Pcore -class;
use Config;

has dist => ( is => 'ro', isa => InstanceOf ['Pcore::Dist'], required => 1 );

has install    => ( is => 'ro', isa => Bool, default => 0 );
has develop    => ( is => 'ro', isa => Bool, default => 0 );
has recommends => ( is => 'ro', isa => Bool, default => 0 );
has suggests   => ( is => 'ro', isa => Bool, default => 0 );
has verbose    => ( is => 'ro', isa => Bool, default => 0 );

# TODO under windows acquire superuser automatically with use Win32::RunAsAdmin qw[force];

sub BUILDARGS ( $self, $args ) {
    $args->{develop} = $args->{recommends} = $args->{suggests} = 1 if $args->{all};

    return $args;
}

sub run ($self) {
    my $chdir_guard = P->file->chdir( $self->dist->root );

    # deps
    exit 3 if !$self->_deps;

    # build
    exit 3 if !$self->_build;

    # chmod
    $self->_chmod;

    # install
    exit 3 if $self->install && !$self->_install;

    return;
}

sub _chmod ($self) {
    print 'chmod ... ';

    if ( !$MSWIN ) {
        P->file->find(
            q[.],
            sub ($path) {

                # directory
                if ( -d $path ) {
                    P->file->chmod( 'rwxr-xr-x', $path ) or say qq[$!: $path];
                }

                # file
                else {
                    my $is_exe;

                    if ( ( $path->dirname eq 'bin/' || $path->dirname eq 'script/' ) && !$path->suffix ) {
                        $is_exe = 1;
                    }
                    elsif ( $path->suffix eq 'sh' || $path->suffix eq 'pl' || $path->suffix eq 't' ) {
                        $is_exe = 1;
                    }

                    # executable script
                    if ($is_exe) {
                        P->file->chmod( 'rwxr-xr-x', $path ) or say qq[$!: $path];
                    }

                    # non-executable file
                    else {
                        P->file->chmod( 'rw-r--r--', $path ) or say qq[$!: $path];
                    }
                }

                chown $>, $), $path or say qq[$!: $path];    # EUID, EGID

                return;
            }
        );
    }

    say 'done';

    return;
}

sub _deps ($self) {
    if ( -f 'cpanfile' ) {
        my @args = (    #
            'cpanm',
            '--with-feature', ( $MSWIN ? 'windows' : 'linux' ),
            ( $self->develop    ? '--with-develop'    : () ),
            ( $self->recommends ? '--with-recommends' : () ),
            ( $self->suggests   ? '--with-suggests'   : () ),
            ( $self->verbose    ? '--verbose'         : () ),
            '--metacpan', '--installdeps', q[.],
        );

        say join q[ ], @args;

        P->pm->run_proc( \@args ) or return;
    }

    return 1;
}

sub _build ($self) {
    eval {
        P->file->find(
            $self->dist->root . 'lib/',
            abs => 1,
            dir => 0,
            sub ($file) {
                if ( $file->suffix eq 'PL' ) {
                    my $res = P->pm->run_proc( [ $^X, $file, $file->dirname . $file->filename_base ] );

                    if ( !$res ) {
                        say qq["$file" return ] . $res;

                        die;
                    }
                }
            }
        );
    };

    return $@ ? 0 : 1;
}

sub _install ($self) {
    if ( !P->pm->is_superuser ) {
        say qq[Root privileges required to deploy pcore at system level.];

        return;
    }

    my $canon_dist_root = P->path( $self->dist->root )->canonpath;

    my $canon_bin_dir = "$canon_dist_root/bin";

    my $pcore_lib_dir_canon = P->path("$canon_dist_root/../")->realpath->canonpath;

    if ($MSWIN) {
        if ( $self->dist->is_pcore ) {

            # set $ENV{PERL5LIB}
            P->pm->run_proc(qq[setx.exe /M PERL5LIB "$canon_dist_root/lib;"]) or return;

            say qq[%PERL5LIB% updated];

            # set $ENV{PCORE_LIB}
            P->pm->run_proc(qq[setx.exe /M PCORE_LIB "$pcore_lib_dir_canon"]) or return;

            say qq[%PCORE_LIB% updated];
        }

        # update $ENV{PATH}
        if ( -d $canon_bin_dir ) {
            state $init = !!require Win32::TieRegistry;

            my @system_path;

            for my $path ( grep { $_ && !/\A\h+\z/sm } split /$Config{path_sep}/sm, Win32::TieRegistry->new('LMachine\SYSTEM\CurrentControlSet\Control\Session Manager\Environment')->GetValue('PATH') ) {
                my $normal_path = P->path( $path, is_dir => 1 );

                push @system_path, $path if $normal_path !~ m[\A\Q$canon_bin_dir\E/\z]sm;
            }

            push @system_path, $canon_bin_dir =~ s[/][\\]smgr;

            $ENV{PATH} = join $Config{path_sep}, @system_path;    ## no critic qw[Variables::RequireLocalizedPunctuationVars]

            P->pm->run_proc(qq[setx.exe /M PATH "$ENV{PATH};"]) or return;

            say qq[%PATH% updated];
        }
    }
    else {
        my $data;

        $data = qq[if ! echo \$PATH | grep -Eq "(^|$Config{path_sep})$canon_bin_dir/?(\$|$Config{path_sep})" ; then export PATH="\$PATH$Config{path_sep}$canon_bin_dir" ; fi\n] if -d $canon_bin_dir;

        if ( $self->dist->is_pcore ) {
            $data .= <<"SH";
if ! echo \$PERL5LIB | grep -Eq "(^|$Config{path_sep})$canon_dist_root/lib/?(\$|$Config{path_sep})" ; then export PERL5LIB="$canon_dist_root/lib$Config{path_sep}\$PERL5LIB" ; fi
export PCORE_LIB="$pcore_lib_dir_canon"
SH
        }

        if ($data) {
            P->file->write_bin( "/etc/profile.d/@{[lc $self->dist->name]}.sh", { mode => q[rw-r--r--] }, \$data );

            say "/etc/profile.d/@{[lc $self->dist->name]}.sh installed";
        }
    }

    return 1;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 108                  | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 132, 149, 154, 175   | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 163                  | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::Build::Deploy - deploy distribution

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
