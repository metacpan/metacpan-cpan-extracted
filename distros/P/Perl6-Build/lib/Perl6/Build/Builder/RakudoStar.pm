package Perl6::Build::Builder::RakudoStar;
use strict;
use warnings;

use File::Spec;
use File::Which ();
use Perl6::Build::Builder;
use Perl6::Build::Helper;

our $URL = [
    'https://rakudo.perl6.org/downloads/star/',
    'https://rakudostar.com/files/star/',
];

sub available {
    my $class = shift;
    my @err;
    for my $url (@$URL) {
        my $res = Perl6::Build::Helper->HTTP(timeout => 10)->get($url);
        if (!$res->{success}) {
            my $msg = $res->{status} == 599 ? "\n$res->{content}" : "";
            chomp $msg;
            push @err, "$res->{status} $res->{reason}, $url$msg\n";
            next;
        }
        my %available = map { $_ => 1 } $res->{content} =~ m{href="(rakudo-star-\d+\.\d+)\.tar\.gz"}g;
        return reverse sort keys %available;
    }
    die join "", @err;
}

sub new {
    my ($class, %args) = @_;
    bless { %args }, $class;
}

sub fetch {
    my $self = shift;
    my $file = File::Spec->catfile($self->{cache_dir}, "$self->{version}.tar.gz");
    if (-f $file) {
        warn "Using cache $file\n";
    } else {
        $self->_fetch($self->{version} => $file);
    }
    my $dir = $self->_unpack($file, $self->{build_dir});
    $self->{dir} = $dir;

}

sub _fetch {
    my ($self, $version, $file) = @_;

    my @err;
    for my $url (map { "$_$version.tar.gz" } @$URL) {
        warn "Fetching $url...\n";
        my $temp = join ".", $file, int rand 10000, $$;
        my $res = Perl6::Build::Helper->HTTP(timeout => 120)->mirror($url => $temp);
        warn "$res->{status} $res->{reason}\n";
        if (!$res->{success}) {
            unlink $temp;
            if ($res->{status} == 599) {
                my $msg = $res->{content};
                chomp $msg;
                warn "$_\n" for split /\n/, $msg;
            }
            next;
        }
        rename $temp, $file;
        return $file;
    }
    die "Failed to get $version\n";
}

sub _unpack {
    my ($self, $file, $dir) = @_;
    my ($outdir) = $file =~ m{([^/]+)\.tar\.gz$};
    $outdir = File::Spec->catdir($dir, $outdir);
    my $tar = File::Which::which('gtar') || 'tar';
    my $status = system $tar, "xf", $file, "-C", $dir;
    if ($status == 0 and -d $outdir) {
        return $outdir;
    } else {
        die "Failed\n";
    }
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
    my $builder = Perl6::Build::Builder->new(log_file => $self->{log_file});
    $builder->build($self->{dir}, $prefix, @option);
}

1;
