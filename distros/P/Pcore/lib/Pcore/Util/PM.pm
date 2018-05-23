package Pcore::Util::PM;

use Pcore -export;
use POSIX qw[];

our $EXPORT = [qw[is_superuser run_proc run_rpc connect_rpc]];

sub change_priv {
    my %args = (
        gid => undef,
        uid => undef,
        @_,
    );

    if ( !$MSWIN ) {
        if ( defined $args{gid} ) {
            my $gid = $args{gid} =~ /\A\d+\z/sm ? $args{gid} : getgrnam $args{gid};

            croak qq[Can't find gid: "$args{gid}"] if !defined $gid;

            POSIX::setgid($gid) or die qq[Can't set GID to "$args{gid}". $!];
        }

        if ( defined $args{uid} ) {
            my $uid = $args{uid} =~ /\A\d+\z/sm ? $args{uid} : getpwnam $args{uid};

            croak qq[Can't find uid "$args{uid}"] if !defined $uid;

            POSIX::setuid($uid) or die qq[Can't set UID to "$args{uid}". $!];
        }
    }

    return;
}

sub daemonize {
    state $daemonized = 0;

    return 0 if $daemonized;

    $daemonized++;

    if ( !$MSWIN ) {
        fork && exit 0;    ## no critic qw[InputOutput::RequireCheckedSyscalls]

        open STDIN, '+<', '/dev/null' or die;
        open STDOUT, '>&STDIN' or die;
        open STDERR, '>&STDIN' or die;

        POSIX::setsid() or die qq[Can't set sid: $!];

        return 1;
    }

    return 0;
}

sub is_superuser {
    if ($MSWIN) {
        return Win32::IsAdminUser();
    }
    else {
        return $> == 0 ? 1 : 0;
    }
}

sub run_proc (@) {
    state $init = !!require Pcore::Util::PM::Proc;

    return Pcore::Util::PM::Proc->new(@_);
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::PM - pcore processs management util functions

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
