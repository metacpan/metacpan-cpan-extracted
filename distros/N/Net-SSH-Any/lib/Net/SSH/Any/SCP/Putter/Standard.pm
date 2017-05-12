package Net::SSH::Any::SCP::Putter::Standard;

use strict;
use warnings;

use Net::SSH::Any::Util qw($debug _debug _debug_dump _first_defined);

require Net::SSH::Any::SCP::Putter;
our @ISA = qw(Net::SSH::Any::SCP::Putter);

use Carp;

sub _new {
    my ($class, $any, $opts, @srcs) = @_;
    my $target = (@srcs > 1 ? pop @srcs : '.');
    my $glob = delete $opts->{glob};
    $opts->{send_time} = _first_defined delete($opts->{copy_attr}), 1;
    my $p = $class->SUPER::_new($any, $opts, $target);
    if ($glob) {
        $p->{glob} = 1;
        require File::Glob;
        @srcs = map File::Glob::bsd_glob($_), @srcs;
    }
    $p->{follow_links} = _first_defined delete($opts->{follow_links}), 1;
    $p->{srcs} = \@srcs;
    $p;
}

my @ignore_dirs = grep { defined } map { File::Spec->$_ } qw(curdir updir);

sub read_dir {
    my ($p, $parent_action, $dh) = @_;
    if ($parent_action) {
        # _debug_dump("parent", $parent_action);
        while (1) {
            my $name = readdir $dh;
            return unless defined $name;
            redo if grep $name eq $_, @ignore_dirs;
            my $local_path = File::Spec->join($parent_action->{local_path}, $name);
            return { name => $name,
                     local_path => $local_path };
        }
    }
    my $local_path = shift @{$p->{srcs}};
    if (defined $local_path) {
        return { local_path => $local_path,
                 name       => (File::Spec->splitpath($local_path))[2] };
    }
    return;
}

sub do_stat {
    my ($p, $action) = @_;
    if (not $p->{follow_links} and -l $action->{local_path}) {
        $debug and $debug & 4096 and _debug "skipping link $action->{path}";
        $p->set_local_error($action, "not a regular file");
    }
    elsif (my @s = stat $action->{local_path}) {
        @{$action}{qw(perm size atime mtime)} = @s[2, 7, 8, 9];
        return 1
    }
    else {
        $p->set_local_error($action);
    }
    return;
}

sub open_dir {
    my ($p, $action) = @_;
    if (opendir my $dh, $action->{local_path}) {
        return $dh
    }
    $p->set_local_error($action);
    return
}

sub close_dir {
    my ($p, $action, $dh) = @_;
    closedir $dh and return 1;
    $p->set_local_error($action);
    return;
}

sub open_file {
    my ($p, $action) = @_;
    if (open my $fh, '<', $action->{local_path}) {
        if (binmode $fh) {
            return $fh
        }
    }
    $p->set_local_error($action);
    return
}

sub read_file {
    my ($p, $action, $fh, $len) = @_;
    my $bytes = read $fh, my($data), $len;
    unless ($bytes) {
        $p->set_local_error($action, (defined($bytes) ? "premature EOF reached" : $!));
        return;
    }
    return $data
}


sub close_file {
    my ($p, $action, $fh) = @_;
    close $fh and return 1;
    $p->set_local_error($action);
    return;
}


1;
