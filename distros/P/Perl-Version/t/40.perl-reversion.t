#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use File::Temp;
use File::Path qw(mkpath);
use File::Spec;
use FileHandle;
use File::Slurp::Tiny qw(read_file);
use Data::Dumper;

if ( $^O =~ /MSWin32/ ) {
  plan skip_all => 'cannot run on Windows';
}

# -Mblib makes a lot of noise
my $libs = join " ",
 map { '-I' . File::Spec->catfile( 'blib', $_ ) } qw(lib arch);
my $RUN = "$^X $libs examples/perl-reversion";

if ( system( "$RUN -quiet" ) ) {
  plan skip_all => 'cannot run perl-reversion, skipping its tests';
}
plan tests => 44;

my $dir = File::Temp::tempdir( CLEANUP => 1 );

sub find {
  my $rv = _run( @_ );
  if ( $rv->{output} =~ /version is (\S+)$/ ) {
    return { found => $1 };
  }
  else {
    return {};
  }
}

sub _run {
  my $cmd = "$RUN @_";
  #diag $cmd;
  my $output;
  my $pid = open my $fh, '-|';
  die "Could not open pipe: $!" unless defined $pid;
  if ( $pid ) {
    $output = join '', <$fh>;
  }
  else {
    close *STDERR;
    exec $cmd;
  }

  #diag $output;
  return { output => $output };
}

sub with_file {
  my ( $name, $content, $code ) = @_;
  my $fh = FileHandle->new( "> $dir/$name" )
   or die "Can't open $dir/$name: $!";
  binmode $fh;
  print $fh $content;
  close $fh;
  $code->();
  unlink "$dir/$name" or die "Can't unlink $dir/$name: $!";
}

sub count_newlines {
    my @newlines= ("\x{0d}\x{0a}","\x{0d}","\x{0a}");
    my %result;
    for my $name (@_) {
        my $content= read_file($name, binmode => ':raw' );
        
        $result{ $name }= +{
            map {
                my $key= unpack 'H*', $_;
                my $count =()= $content=~ /$_/g;
                $key=>$count
            } @newlines
        };
    };
    %result
};

sub ok_newlines {
    my( $name, %expected ) = @_;
    my %got= count_newlines( keys %expected );
    
    is_deeply \%got, \%expected,
        "$name - All newlines remain intact"
      or diag Dumper [ \%expected, \%got ];
};


sub runtests {
  my ( $name, $version ) = @_;
  
  # Check that we keep line endings consistent:
  my @files= (grep { -f } glob( "$dir/*" ), glob( "$dir/*/*" ) );
  my %newlines= count_newlines( @files );
  
  is_deeply( find( $dir ), { found => '1.2.3' }, "found in $name" );
  is_deeply( find( $dir, "-current=1.2" ),
    {}, "partial does not match" );
  _run( $dir, '-set', '1.2' );
  ok_newlines( "$name -set", %newlines );
  _run( $dir, '-bump' );
  ok_newlines( "$name -bump", %newlines );
  is_deeply(
    find( $dir ),
    { found => '1.3', },
    "-bump did not extend version"
  );
  my $rv = _run( $dir, '-bump-subversion', '2>&1' );
  ok_newlines( "$name -bump-subversion", %newlines );
  like(
    $rv->{output},
    qr/version 1\.3 does not have 'subversion' component/,
    "-bump- with missing component has useful error",
  );
}

FileHandle->new( "> $dir/Makefile.PL" );
mkpath( "$dir/lib" );

with_file(
  "META.yml", <<'END',
---
bar: 2
version: 1.2.3
meta-spec:
  url: whatever
  version: 1.3
END
  sub { runtests( META => '1.2.3' ) },
);

# weirdly indented but still valid
with_file(
  "META.yml", <<'END',
---
   bar: 2
   version: 1.2.3
   meta-spec:
     url: whatever
     version: 1.3
END
  sub { runtests( META => '1.2.3' ) },
);

with_file(
  "lib/Foo_pod.pm", <<'END',
=head1 VERSION

Version 1.2.3

=cut
END
  sub { runtests( pod => "1.2.3" ) },
);

with_file(
  "Foo.pm", <<'END',
package Foo;
our $VERSION = '1.2.3';
1;
END
  sub { runtests( pm => "1.2.3" ) },
);

with_file(
  "Foo.pm", <<'END',
package Foo;
our $VERSION = version->declare('v1.2.3');
1;
END
  sub {
    is_deeply( find( $dir ), { found => 'v1.2.3' }, "found in pm" );
    _run( $dir, '-set', '1.2' );
    _run( $dir, '-bump' );
    is_deeply( find( $dir ), { found => 'v1.3' }, "bump subversion with v prefix" );
  },
);

with_file(
  README => <<'END',
This README describes version 1.2.3 of Flurble.
END
  sub { runtests( plain => "1.2.3" ) },
);

with_file(
  README => "This README describes\x{0d}\x{0a}version 1.2.3 of\x{0d}\x{0a}Flurble.\x{0a}",
  sub { runtests( newlines => "1.2.3" ) },
);
