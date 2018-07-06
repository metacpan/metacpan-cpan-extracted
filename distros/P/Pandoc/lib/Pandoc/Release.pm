package Pandoc::Release;
use strict;
use warnings;
use 5.010;

our $VERSION = '0.8.6';

# core modules since 5.014
use HTTP::Tiny;
use JSON::PP;

use Cwd;
use File::Path qw(make_path remove_tree);
use File::Copy 'move';
use File::Temp 'tempdir';

use Pandoc;
use Pandoc::Version;

use parent 'Exporter';

our @EXPORT = qw(get list latest);

=head1 NAME

Pandoc::Release - get pandoc releases from GitHub

=cut

our $CLIENT = HTTP::Tiny->new;

sub _api_request {
    my ( $url, %opts ) = @_;

    say $url if $opts{verbose};
    my $res = $CLIENT->get($url);

    $res->{success} or die "failed to fetch $url";
    $res->{content} = JSON::PP::decode_json( $res->{content} );

    $res;
}

sub get {
    shift if __PACKAGE__ eq ( $_[0] // '' );    # can also be used as method

    my ( $version, %opts ) = @_;
    warn "Pandoc release 1.17 had a bug, please don't use!\n"
      if "$version" eq "1.17";
    my $url = "https://api.github.com/repos/jgm/pandoc/releases/tags/$version";
    bless _api_request( $url, %opts )->{content}, __PACKAGE__;
}

sub list {
    shift if __PACKAGE__ eq ( $_[0] // '' );    # can also be used as method

    my %opts = @_;

    my $range = $opts{range};
    my $limit = $opts{limit} // -1;
    my $since = Pandoc::Version->new( $opts{since} // 0 );
    my $url   = "https://api.github.com/repos/jgm/pandoc/releases";
    my @releases;

  LOOP: while ($url) {
        my $res = _api_request( $url, %opts );
        foreach ( @{ $res->{content} } ) {
            my $version = Pandoc::Version->new( $_->{tag_name} );
            last LOOP unless $since < $version;    # abort if possible
            next if $version == '1.17';            # version had a bug
            if ( !$range || $version->fulfills($range) ) {
                push @releases, bless $_, __PACKAGE__;
                last LOOP if --$limit == 0;
            }
        }

        my $link = $res->{headers}{link} // '';
        $link =~ /<([^>]+)>; rel="next"/ or last;
        $url = $1;
    }

    @releases;
}

sub latest {
    shift if __PACKAGE__ eq ( $_[0] // '' );    # can also be used as method

    ( list( @_, limit => 1 ) )[0];
}

sub download {
    my ( $self, %opts ) = @_;

    my $version = Pandoc::Version->new( $self->{tag_name} );
    my $bin = $opts{bin} // pandoc_data_dir('bin');

    if ($bin) {
        make_path($bin);
        -d $bin or die "missing directory $bin";
        $bin = "$bin/pandoc-$version";
        if ( -f $bin ) {
            say "skipping existing $bin" if $opts{verbose};
            my $pandoc = Pandoc->new($bin);
            $pandoc = $pandoc->symlink( $opts{symlink}, %opts )
              if exists $opts{symlink};
            return $pandoc;
        }
    }

    my $arch = $opts{arch} // `dpkg --print-architecture`;
    chomp $arch;
    my $dir = $opts{dir} // tempdir( CLEANUP => 1 );

    my ($asset) = grep { $_->{name} =~ /-$arch\.deb$/ } @{ $self->{assets} };

    my $url = ( $asset // {} )->{browser_download_url} or do {
        say "release $self->{tag_name} contains no $arch Debian package"
          if $opts{verbose};
        return;
    };

    make_path($dir);
    -d $dir or die "missing directory $dir";

    my $deb = "$dir/" . $asset->{name};
    say $deb if $CLIENT->mirror( $url, $deb )->{success} and $opts{verbose};

    if ($bin) {
        my $cmd =
            "dpkg --fsys-tarfile '$deb'"
          . "| tar -x ./usr/bin/pandoc -O > '$bin'"
          . "&& chmod +x '$bin'";
        system($cmd) and die "failed to extract pandoc from $deb:\n $cmd";
        say $bin if $opts{verbose};

        my $pandoc = Pandoc->new($bin);
        $pandoc = $pandoc->symlink( $opts{symlink}, %opts )
          if exists $opts{symlink};
        return $pandoc;
    }
    else {
        return $version;
    }
}

1;

__END__

=head1 SYNOPSIS

From command line:

  # print latest release name
  perl -MPandoc::Release -E 'say latest->{name}'

  # download latest release unless already in ~/.pandoc/bin
  perl -MPandoc::Release -E 'latest->download'

  # same and create symlink ~/.pandoc/bin/pandoc
  perl -MPandoc::Release -E 'latest->download->symlink'

In Perl code:

  use Pandoc::Release;

  my $release = get('2.1.3');   # get a specific release
  my $latest = latest;          # get a latest release

  # get multiple releases
  my @releases = list( since => '2.0', verbose => 1 );
  foreach my $release (@releases) {

      # print version number
      say $release->{tag_name};

      # download Debian package and executable
      $release->download( dir => './deb', bin => './bin' );
  }

  # download executable and use as temporary Pandoc object:
  my $pandoc = get('2.1.3)->download( bin => './bin' );

=head1 DESCRIPTION

This utility module fetches information about pandoc releases via GitHub API.
It requires at least Perl 5.14 or L<HTTP::Tiny> and L<JSON::PP> installed.

On Debian-bases systems, this module can update and switch locally installed
pandoc versions if you add directory C<~/.pandoc/bin> to your C<$PATH>.

=head1 FUNCTIONS

All functions are exported by default.

=head2 get( $version [, verbose => 0|1 ] )

Get a specific release by its version or die if the given version does not
exist. Returns data as returned by GitHub releases API:
L<https://developer.github.com/v3/repos/releases/#get-a-release-by-tag-name>.

=head2 list( ... )

Get a list of all pandoc releases, optionally C<since> some version or
within a version C<range> such as C<!=1.16, <=1.17> or C<==2.1.2>. See
L<CPAN::Meta::Spec/Version Ranges> for possible values. Option C<verbose> will
print URLs before each request. Option C<limit> limits the maximum number
of releases to be returned.

=head2 latest( ... )

Get the latest release, optionally C<since> some version or within a version
C<range>. Equivalent to method C<list> with option C<< limit => 1 >>.

=head1 METHODS

=head2 download( %options )

Download the Debian release file for some architecture (e.g. C<amd64>) Pandoc
executables is then extracted to directory C<bin> named by pandoc version
number (e.g. C<pandoc-2.1.2>). Skips downloading if an executable of this name
is already found there.  Returns a L<Pandoc> instance if C<bin> is not false or
L<Pandoc::Version> otherwise.

=over

=item dir

Where to download release files to. A temporary directory is used by default.

=item arch

System architecture, detected with C<dpkg --print-architecture> by default.

=item bin

Where to extract pandoc binary to. By default set to C<~/.pandoc/bin> on Unix
(see L<Pandoc> function C<pandoc_data_dir>).  Extraction of executables can be
disabled by setting C<bin> to a false value.

=item symlink

Create a symlink to the executable. This is just a shortcut for calling function
C<symlink> of L<Pandoc>:

  $release->download( verbose => $v )->symlink( $l, verbose => $v )
  $release->download( verbose => $v, symlink => $l )   # equivalent

=item verbose

Print what's going on (disabled by default).

=back

=head1 SEE ALSO

L<https://developer.github.com/v3/repos/releases/>

=cut
