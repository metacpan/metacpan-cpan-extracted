package Perl6::Build::Builder::Source;
use strict;
use warnings;

use File::pushd 'pushd';
use File::Spec;
use Perl6::Build::Builder;
use IPC::Run3 'run3';

our $URL = {
    rakudo => 'https://github.com/rakudo/rakudo',
    MoarVM => 'https://github.com/MoarVM/MoarVM',
    nqp => 'https://github.com/perl6/nqp',
};

sub available {
    my $class = shift;
    my @cmd = ('git', 'ls-remote', $URL->{rakudo});
    run3 \@cmd, undef, \my $out, undef;
    $? == 0 or die;
    my %version;
    for my $line (split /\n/, $out) {
        $line =~ m{refs/tags/(20[\d.]+)} and $version{$1}++;
    }
    reverse sort keys %version;
}

sub new {
    my ($class, %args) = @_;
    bless { %args }, $class;
}

sub fetch {
    my $self = shift;
    $self->_update;
    $self->{dir} = $self->_clone;
}

sub _update {
    my $self = shift;
    for my $repo (qw(rakudo MoarVM nqp)) {
        my $target = File::Spec->catdir($self->{git_reference_dir}, $repo);
        if (-d $target) {
            my $guard = pushd $target;
            warn "Updating $URL->{$repo}\n";
            !system "git", "pull", "--recurse-submodules", "-t", "-p", "-q" or die "Failed\n";
        } else {
            !system "git", "clone", "--recurse-submodules", $URL->{$repo}, $target or die "Failed\n";
        }
    }
}

sub _clone {
    my $self = shift;
    my $target = File::Spec->catdir($self->{build_dir}, "rakudo");
    my @cmd = (
        "git", "clone", "-q",
        "--reference", File::Spec->catdir($self->{git_reference_dir}, "rakudo"),
        $URL->{rakudo}, $target,
    );
    !system @cmd or die;
    {
        my $guard = File::pushd::pushd $target;
        !system "git", "checkout", "-q", $self->{commitish} or die;
    }
    $target;
}

sub describe {
    my $self = shift;
    my $describe; {
        my $guard = File::pushd::pushd $self->{dir};
        $describe = `git describe`;
        chomp $describe;
    }
    $describe;
}

sub build {
    my ($self, $prefix, @option) = @_;
    if (!@option) {
        if ($self->{backend} eq 'jvm') {
            @option = qw(--backends jvm --gen-nqp);
        } else {
            @option = qw(--backends moar --gen-moar);
        }
    }
    if (!grep { $_ eq "--git-reference" } @option) {
        unshift @option, "--git-reference", $self->{git_reference_dir};
    }
    my $builder = Perl6::Build::Builder->new(log_file => $self->{log_file});
    $builder->build($self->{dir}, $prefix, @option);
}

1;
