use v5.10;
use strict;
use warnings;
use Test2::V0;

use Perl::Version::Bumper qw(
    version_fmt
    stable_version
);

my $max_version = Perl::Version::Bumper->feature_version;
my $this_version = stable_version;  # round current version to the latest stable

# constructor errors
my @errors = (
    [ '6.0.1'  => qr{\AUnsupported Perl version: 6\.0\.1 \(greater than \Q$max_version\E\) } ],
    [ 'v4.2'   => qr{\AUnsupported Perl version: v4\.2 } ],
    [ 'v5.15'  => qr{\Av5\.15 is not a stable Perl version } ],
    [ 'v5.25'  => qr{\Av5\.25 is not a stable Perl version } ],
    [ '5.28'   => qr{\AUnsupported Perl version: 5\.28 \(greater than \Q$max_version\E\) } ],
    [ 'v5.100' => qr{\AUnsupported Perl version: v5\.100 \(greater than \Q$max_version\E\) } ],
    [ 'v5.8'   => qr{\AUnsupported Perl version: v5\.8 } ],
    [    # returns 0 in v5.10, dies otherwise
        'not' => eval { version->new('not') || 1 }
        ? qr{\AUnsupported Perl version: not }
        : qr{\AInvalid version format \(non-numeric data\)}
    ],
);

# check the default
if ( $this_version > $max_version ) {
    push @errors,
      [ '' => qr{\AUnsupported Perl version: \Q$this_version\E \(greater than \Q$max_version\E\) } ];
}
else {
    is( Perl::Version::Bumper->new->version_num,
        $this_version, "default version is $this_version" );
}

for my $e (@errors) {
    my ( $version, $error ) = @$e;
    ok(
        !eval {
            Perl::Version::Bumper->new(
                $version ? ( version => $version ) : () );
        },
        "failed to create object with version => $version"
    );
    like( $@, $error, ".. expected error message" );
}

# version normalisation
my %version = qw(
  v5.10.1     v5.10
  5.012002    v5.12
  5.014       v5.14
  v5.16       v5.16
  v5.26       v5.26
  5.028       v5.28
  5.030002    v5.30
  v5.32.1     v5.32
);

version_fmt( $version{$_} ) <= $this_version
  ? is( Perl::Version::Bumper->new( version => $_ )->version,
    $version{$_}, "$_ => $version{$_}" )
  : do {
  SKIP: {
        skip( skip "This is Perl $^V, not $_", 1 );
    }
  }
  for sort keys %version;

done_testing;
