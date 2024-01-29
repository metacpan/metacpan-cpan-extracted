#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use File::Temp;
use File::Path qw(mkpath);
use File::Spec;
use Data::Dumper;

#if ( $^O =~ /MSWin32/ ) {
#  plan skip_all => 'cannot run on Windows';
#}

# -Mblib makes a lot of noise
my $libs = join " ",
 map { '-I' . File::Spec->catfile( 'blib', $_ ) } qw(lib arch);
my $RUN = "$^X $libs examples/perl-reversion";

if ( system( "$RUN -quiet" ) ) {
  plan skip_all => 'cannot run perl-reversion, skipping its tests';
}

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
  my $output = readpipe( $cmd );

  #diag $output;
  return { output => $output };
}

sub with_file {
  my ( $name, $content, $code ) = @_;

  subtest $name => sub {
      my $path = File::Spec->catfile( $dir, $name );
      open my $fh, '>', $path or die "Can't open $path: $!";
      binmode $fh;
      print $fh $content;
      close $fh;
      $code->();
      unlink $path or die "Can't unlink $path: $!";
    };
}

sub count_newlines {
    my @newlines= ("\x{0d}\x{0a}","\x{0d}","\x{0a}");
    my %result;
    for my $name (@_) {
        local $/;
        open my $fh, '<:raw', $name;
        my $content = do { local $/; <$fh> };
        close $fh;

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

  is_deeply( find( $dir ), { found => $version }, "found $version in $name" );
  is_deeply( find( $dir, "-current=1.2" ), {}, "partial does not match " );

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

mkpath( File::Spec->catfile( $dir, "lib" ) );

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
   version: 7.8.9
   meta-spec:
     url: whatever
     version: 1.3
END
  sub { runtests( META => '7.8.9' ) },
);

with_file(
  "lib/Foo_pod.pm", <<'END',
=head1 VERSION

Version 2.4.6

=cut
END
  sub { runtests( pod => "2.4.6" ) },
);

with_file(
  "Foo.pm", <<'END',
package Foo;
our $VERSION = '3.6.9';
1;
END
  sub { runtests( pm => "3.6.9" ) },
);

with_file(
  "Foo.pm", <<'END',
package Foo;
our $VERSION = version->declare('v7.6.5');
1;
END
  sub {
    is_deeply( find( $dir ), { found => 'v7.6.5' }, "found in pm" );
    _run( $dir, '-set', '7.7' );
    _run( $dir, '-bump' );
    is_deeply( find( $dir ), { found => 'v7.8' }, "bump subversion with v prefix" );
  },
);

with_file(
  "Foo.pm", <<'END',
package Foo v1.2.3;
1;
END
  sub {
    is_deeply( find( $dir ), { found => 'v1.2.3' }, "package-v-string found in pm" );
    _run( $dir, '-set', '1.2' );
    is_deeply( find( $dir ), { found => 'v1.2' }, "set version keeps v prefix" );
    _run( $dir, '-bump' );
    is_deeply( find( $dir ), { found => 'v1.3' }, "bump subversion with v prefix" );
  },
);

with_file(
  "Foo.pm", <<'END',
package Foo 1.0;
1;
END
  sub {
    is_deeply( find( $dir ), { found => '1.0' }, "package version found in pm" );
    _run( $dir, '-set', '1.2' );
    _run( $dir, '-bump' );
    is_deeply( find( $dir ), { found => '1.3' }, "bump version without v prefix" );
  },
);

with_file(
  README => <<'END',
This README describes version 5.4.6 of Flurble.
END
  sub { runtests( plain => "5.4.6" ) },
);

with_file(
  README => "This README describes\x{0d}\x{0a}version 1.2.3 of\x{0d}\x{0a}Flurble.\x{0a}",
  sub { runtests( newlines => "1.2.3" ) },
);

with_file(
  "FooBar.pm", <<'END',
package FooBar 1.0;
1;
END
  sub {
    is_deeply( find( $dir ), { found => '1.0' }, "package version found in pm" );

    my $previous = '1.0';
    foreach my $v ( qw(1.000005 1.000005_001 1.000005_01 1.000005 1.000005_02 1.000005_002 1.000005_003) ) {
        _run( $dir, '-set', $v, '-numify' );
        is_deeply( find( $dir ), { found => $v }, "set version from $previous to $v" );
        $previous = $v;
    }
  },
);

with_file(
  "FooBar.pm", <<'END',
package FooBar 1.0;
1;
END
  sub {
    is_deeply( find( $dir ), { found => '1.0' }, "package version found in pm" );
    my @table = (
        [ qw( 1.000005 1.000006 ) ],
        [ qw( 1.000005_001 1.000005_002 ) ],
        [ qw( 1.000005_01 1.000005_02 ) ],
    );

    foreach my $row ( @table ) {
        _run( $dir, '-set', $row->[0], '-numify' );
        is_deeply( find( $dir ), { found => $row->[0] }, "set version to $row->[0]" );
        _run( $dir, '-bump' );
        is_deeply( find( $dir ), { found => $row->[1] }, "bump version from $row->[0] to $row->[1]" );
    }
  },
);
done_testing();
