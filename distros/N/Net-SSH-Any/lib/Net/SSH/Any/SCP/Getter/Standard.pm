package Net::SSH::Any::SCP::Getter::Standard;

use strict;
use warnings;

use File::Spec;
use Carp;
use Fcntl ();
use Net::SSH::Any::Util qw($debug _debug _debugf _debug_hexdump _first_defined);
use Net::SSH::Any::Constants ();

require Net::SSH::Any::SCP::Getter;
our @ISA = qw(Net::SSH::Any::SCP::Getter);

sub _new {
    my ($class, $any, $opts, @srcs) = @_;
    my $target = (@srcs > 1 ? pop @srcs : File::Spec->curdir);
    my $copy_attr = _first_defined delete($opts->{copy_attr}), 1;
    my $copy_perm = _first_defined delete($opts->{copy_perm}), $copy_attr;
    my $copy_time = _first_defined delete($opts->{copy_time}), $copy_attr;
    my $update = delete $opts->{update};
    my $numbered = delete $opts->{numbered};
    my $overwrite = _first_defined delete($opts->{overwrite}), !$numbered;
    $opts->{request_time} = 1 if ($copy_time or $update);
    my $g = $class->SUPER::_new($any, $opts, @srcs);
    $g->{lcwd} = [];
    $g->{copy_perm} = $copy_perm;
    $g->{copy_time} = $copy_time;
    $g->{target} = $target;
    $g->{keep_after_error} = delete $opts->{keep_after_error};
    $g->{target_is_dir} = delete $opts->{target_is_dir};
    $g->{update} = $update;
    $g->{numbered} = $numbered;
    $g->{overwrite} = $overwrite;
    croak "bad combination of options, numbered can not be used together with overwrite or update"
        if $numbered and ($update or $overwrite);
    croak "bad combination of options, update requires overwrite"
        if $update and not $overwrite;

    $g;
}

sub run {
    my $g = shift;
    my $target = $g->{target};
    if ($g->{target_is_dir}) {
        unless (-d $target or mkdir $target) {
            $g->_or_set_error(Net::SSH::Any::Constants::SSHA_SCP_ERROR(),
                              "unable to create directory", $!);
            return
        }
    }

    push @{$g->{lcwd}}, $target if -d $target;

    $g->SUPER::run(@_);
}

sub _resolve_local_path {
    my ($g, $name) = @_;
    return ( @{$g->{lcwd}}
             ? File::Spec->join($g->{lcwd}[-1], $name)
             : $g->{target} )
}

sub on_open_before_wanted {
    my ($g, $action) = @_;
    $action->{local_path} = $g->_resolve_local_path($action->{name});
    1;
}

sub _perm {
    my ($g, $action) = @_;
    $g->{copy_perm} ? $action->{perm} & 0777 : 0777
}

sub on_open_dir {
    my ($g, $action) = @_;
    my $dn = $action->{local_path};

    my $perm = $g->_perm($action);
    unless (-d $dn or mkdir($dn, 0700 | $perm)) {
        $g->set_local_error($action);
        return;
    }

    push @{$g->{lcwd}}, $dn;

    1;
}

sub on_close_dir {
    my ($g, $action) = @_;
    pop @{$g->{lcwd}};

    my $perm = $g->_perm($action);
    if (($perm | 0700) != $perm) {
        chmod $perm, $action->{local_path}
    }
    1;
}

sub on_open_file {
    my ($g, $action) = @_;
    my $fn = $action->{local_path};
    my $perm = $g->_perm($action);

    if ($g->{update}) {
        if (my @s = stat $fn) {
            if ($s[7] == $g->{size} and $s[9] == $g->{mtime}) {
                $action->{already_up_to_date} = 1;
                return;
            }
        }
    }

    unlink $fn if $g->{overwrite};
    my $flags = Fcntl::O_CREAT|Fcntl::O_WRONLY;
    $flags |= Fcntl::O_EXCL if $g->{numbered} or not $g->{overwrite};

    my $cfh;
    while (1) {
        sysopen $cfh, $fn, $flags, $perm and last;
        my $error = $!;
        unless ($g->{numbered} and -e $fn) {
            $g->set_local_error($action, $error);
            return;
        }
        _inc_numbered($fn);
        $action->{local_path} = $fn;
    }

    binmode $cfh;
    $g->{cfh} = $cfh;

    1;
}

sub on_write {
    my ($g, $action) = @_;
    # $debug and $debug & 4096 and _debug_hexdump('data received', $_[2]);
    print {$g->{cfh}} $_[2];
    1;
}

sub on_close_file {
    my ($g, $action, $failed) = @_;
    $debug and $debug & 4096 and _debugf("%s->on_close_file(%s, %s)", $g, $action, $failed);

    my $cfh = delete $g->{cfh}
        or croak "internal error: on_close_file called but there isn't file handle";

    unless (close $cfh) {
        $g->set_local_error($action);
        $failed = 1;
    }

    unlink $action->{local_path} if ($failed and not $g->{keep_after_error});
    not $failed;
}

1;
