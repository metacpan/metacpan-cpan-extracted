package Net::SSH::Any::SCP::Getter::Finder;

use strict;
use warnings;

use Net::SSH::Any::Util qw(_warn);

require Net::SSH::Any::SCP::Getter;
our @ISA = qw(Net::SSH::Any::SCP::Getter);

sub _new {
    my $class = shift;
    my $any = shift;
    my $opts = shift;
    $opts->{recursive} = 1;
    my $g = $class->SUPER::_new($any, $opts, @_);
    $g->{found} = [];
    $g->{stack} = [];
    $g;
}

sub on_open_dir {
    my ($g, $action) = @_;
    push @{$g->{stack}}, $action->{name};
    1;
}

sub on_close_dir {
    my $g = shift;
    pop @{$g->{stack}};
    1;
}

sub on_open_file {
    my ($g, $action) = @_;
    my $path = join '/', @{$g->{stack}}, $action->{name};
    push @{$g->{found}}, $path;
    0;
}

sub on_close_file {
    my ($g, $action, $failed) = @_;
    not $failed;
}

sub run {
    my $g = shift;
    # remote SCP command return failure when asked to skip some
    # file or directory, so we ignore the exit code from SUPER::run
    # if ($g->SUPER::run(@_)) ...
    $g->SUPER::run(@_);
    @{$g->{found}}
}

1;
