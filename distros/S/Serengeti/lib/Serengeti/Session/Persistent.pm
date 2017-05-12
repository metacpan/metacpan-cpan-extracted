package Serengeti::Session::Persistent;

use strict;
use warnings;

use File::Spec;
use File::Path qw(mkpath);

use base qw(Serengeti::Session);

use accessors qw(log);

sub new {
    my ($pkg, $args) = @_;

    my $name = $args->{name};

    my $parent;
    if (exists $args->{parent_dir}) {
        $parent = $args->{parent_dir};
        $parent = File::Spec->catdir(@$parent) if ref $parent eq "ARRAY";
    }
    else {
        $parent = File::Spec->tmpdir;
        warn "No parent_dir supplied, assuming tmpdir which is: $parent";
        
    }

    my $session_dir = File::Spec->catdir($parent, $name);
    mkpath($session_dir) unless -e $session_dir;

    my $log_path = File::Spec->catfile($session_dir, "actions.log");
    open my $log, ">", $log_path or die "Can't open session log: $!";

    my $self = bless {
        name => $name,
        session_dir => $session_dir,
        log => $log,
        stash => {},
    }, $pkg;

    $self->log_action("Created session", "backend: foo");
    
    return $self;
}

sub log_action {
    my ($self, $action, @info) = @_;

    my $log = $self->{log};
    return unless $log;
    my ($sec, $min, $hour, $day, $mon, $year) = gmtime(time);

    my $ts = sprintf("%4d-%02d-%02d %02d:%02d:%02d", 
                     $year + 1900, $mon + 1, $day, $hour, $min, $sec);

    print $log "[$ts] $action - ", join(" | ", @info), "\n";

    1;
}

sub DESTROY {
    my $self = shift;
}

1;