package Pandoc::Release;
use strict;
use warnings;
use 5.010;

# core modules since 5.014
use HTTP::Tiny;
use JSON::PP;

use Pandoc;
use Pandoc::Version;
use Cwd;
use File::Path qw(make_path remove_tree);
use File::Copy 'move';
use File::Temp 'tempdir';

=head1 NAME

Pandoc::Release - get pandoc releases from GitHub

=cut

our $VERSION = '0.8.0';
our $CLIENT = HTTP::Tiny->new;

sub _api_request {
    my ($url, %opts) = @_;

    say $url if $opts{verbose};
    my $res = $CLIENT->get($url);

    $res->{success} or die "failed to fetch $url";
    $res->{content} = JSON::PP::decode_json($res->{content});

    $res;
}

sub get {
    my ($class, $version, %opts) = @_;
    warn "Pandoc release 1.17 had a bug, please don't use!\n"
        if "$version" eq "1.17";
    my $url = "https://api.github.com/repos/jgm/pandoc/releases/tags/$version";
    bless _api_request($url, %opts)->{content}, $class;
}

sub list {
    my ($class, %opts) = @_;

    my $range = $opts{range};
    my $since = Pandoc::Version->new($opts{since} // 0);
    my $url = "https://api.github.com/repos/jgm/pandoc/releases";
    my @releases;

    LOOP: while ($url) {
        my $res = _api_request($url, %opts);
        foreach (@{ $res->{content} }) {
            my $version = Pandoc::Version->new($_->{tag_name});
            last LOOP unless $since < $version; # abort if possible
            next if $version == '1.17'; # version had a bug
            if (!$range || $version->fulfills($range)) {
                push @releases, bless $_, $class;
            }
        }

        my $link = $res->{headers}{link} // '';
        $link =~ /<([^>]+)>; rel="next"/ or last;
        $url = $1;
    }

    @releases;
}

sub download {
    my ($self, %opts) = @_;

    my $dir = $opts{dir} // tempdir(CLEANUP => 1);
    my $arch = $opts{arch} // `dpkg --print-architecture`;
    chomp $arch;
    my $bin = $opts{bin};

    make_path($dir);
    -d $dir or die "missing directory $dir";
    if ($bin) {
        make_path($bin);
        -d $bin or die "missing directory $bin";
    }

    my ($asset) = grep { $_->{name} =~ /-$arch\.deb$/ } @{$self->{assets}};

    my $url = ($asset // {})->{browser_download_url} or do {
        say "release $self->{tag_name} contains no $arch Debian package"
            if $opts{verbose};
        return;
    };

    my $version = Pandoc::Version->new($self->{tag_name});
    my $deb = "$dir/".$asset->{name};
    say $deb if $CLIENT->mirror($url, $deb)->{success} and $opts{verbose};

    if ($bin) {
        my $pandoc = "$bin/pandoc-$version";
        my $cmd = "dpkg --fsys-tarfile '$deb'"
                . "| tar -x ./usr/bin/pandoc -O > '$pandoc'"
                . "&& chmod +x '$pandoc'";
        system($cmd) and die "failed to extract pandoc from $deb:\n $cmd";
        say "$pandoc" if $opts{verbose};

        return Pandoc->new("$pandoc");
    } else {
        return $version;
    }
}

1;

__END__

=head1 SYNOPSIS

  use Pandoc::Release;

  # get a specific release
  my $release = Pandoc::Release->get('2.1.3');

  # get multiple releases
  my @releases = Pandoc::Release->list(since => '2.0', verbose => 1);
  foreach my $release (@releases) {

      # print version number
      say $release->{tag_name};

      # download Debian package and executable
      $release->download(dir => './deb', bin => './bin');
  }

  # download executable and use as temporary Pandoc object:
  my $pandoc = Pandoc::Release->get('2.1.3)->download(bin => './bin');

=head1 DESCRIPTION

This utility module fetches information about pandoc releases via GitHub API.
It requires at least Perl 5.14 or L<HTTP::Tiny> and L<JSON::PP> installed.

=head1 METHODS

=head2 get( $version [, verbose => 0|1 ] )

Get a specific release by its version or die if the given version does not
exist. Returns data as returned by GitHub releases API:
L<https://developer.github.com/v3/repos/releases/#get-a-release-by-tag-name>.

=head2 list( [ since => $version ] [ range => $range ] [ verbose => 0|1 ] )

Get a list of all pandoc releases at GitHub, optionally since some version and
within a version range such as C<!=1.16, <=1.17> or C<==2.1.2>. See
L<CPAN::Meta::Spec/Version Ranges> for possible values. Option C<verbose> will
print URLs before each request.

=head2 download( [ dir => $dir ] [ arch => $arch ] [ bin => $bin ] [ verbose => 0|1] )

Download the Debian release file for some architecture (e.g. C<amd64>) to
directory C<dir>, unless already there. By default architecture is determined
via calling C<dpkg> and download directory is a newly created temporary
directory.  Optionally extract pandoc executables to directory C<bin>, each
named by pandoc version number (e.g. C<pandoc-2.1.2>).

You can download pandoc executables into subdirectory C<bin> of Pandoc user
data directory and add this directory to your C<$PATH>:

  $release->download( bin => $ENV{HOME}.'/.pandoc/bin' )

Returns a L<Pandoc> instance if C<bin> is given or L<Pandoc::Version>
otherwise.

=head1 SEE ALSO

L<https://developer.github.com/v3/repos/releases/>

=cut
