package Perl6::Build::Builder::RakudoStar;
use strict;
use warnings;

use File::Spec;
use File::Which ();
use HTTP::Tinyish;
use Perl6::Build::Builder;

our $URL = 'https://rakudo.perl6.org/downloads/star/';

sub _http {
    my $class = shift;
    for my $try (map "HTTP::Tinyish::$_", qw(Curl Wget HTTPTiny LWP)) {
        HTTP::Tinyish->configure_backend($try) or next;
        $try->supports("https") or next;
        return $try->new(agent => 'perl6-build', verify_SSL => 1);
    }
    die "No http clients are available";
}

sub available {
    my $class = shift;
    my $res = $class->_http->get($URL);
    if (!$res->{success}) {
        my $msg = $res->{status} == 599 ? "\n$res->{content}" : "";
        die "$res->{status} $res->{reason}, $URL$msg\n"
    }
    my %available = map { $_ => 1 } $res->{content} =~ m{href="(rakudo-star-\d+\.\d+)\.tar\.gz"}g;
    reverse sort keys %available;
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
    my $url = "$URL$version.tar.gz";
    warn "Fetching $url\n";
    my $temp = join ".", $file, time, $$;
    my $res = $self->_http->mirror($url => $temp);
    if (!$res->{success}) {
        unlink $temp;
        my $msg = $res->{status} == 599 ? "\n$res->{content}" : "";
        die "$res->{status} $res->{reason}, $url$msg\n";
    }
    rename $temp, $file;
    $file;
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
