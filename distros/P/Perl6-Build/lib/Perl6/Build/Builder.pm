package Perl6::Build::Builder;
use strict;
use warnings;

use IPC::Run3 ();
use File::Temp ();
use File::pushd ();
use File::Spec;

sub new {
    my ($class, %args) = @_;
    bless { log_file => $args{log_file} }, $class;
}

sub _system {
    my ($self, @cmd) = @_;
    my $log_file = $self->{log_file};
    IPC::Run3::run3 \@cmd, undef, $log_file, $log_file, { append_stdout => 1 };
    $? == 0;
}

sub build {
    my ($self, $dir, $prefix, @option) = @_;

    die "There already exists $prefix\n" if -e $prefix;

    if (!grep { $_ eq "--make-install" } @option) {
        unshift @option, "--make-install";
    }
    unshift @option, "--prefix", $prefix;

    my @cmd = ($^X, "Configure.pl", @option);
    warn "Running @cmd\n";
    warn "\n  See " . $self->{log_file} . " for progress\n\n";
    my $guard = File::pushd::pushd $dir;
    $self->_system(@cmd) or die "Failed\n";
    warn "Done\n";
    return 1;
}

1;
