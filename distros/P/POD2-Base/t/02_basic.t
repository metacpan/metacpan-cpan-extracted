

use strict;
use Test::More tests => 15;

BEGIN { use_ok( 'POD2::Base' ); }

# subsumes_dir( '/usr/lib/perl/POD2/TLH', 'POD2/TLH' ) is true
sub subsumes_dir {
    my $dir = shift;
    my $tail = shift;
    my @dir_segments = File::Spec->splitdir( $_ );
    return $tail eq join '/', @dir_segments[-2,-1];
}

{
  my $pod2 = POD2::Base->new({ lang => 'tlh' });
  isa_ok( $pod2, 'POD2::Base' );

  is( $pod2->{lang}, 'TLH', 'the right lang' );

  my @dirs = $pod2->pod_dirs({ test => 0 }); # don't test for -d
  is( @dirs, @INC, 'pod dirs searched all over @INC' );
  my @ok = grep { subsumes_dir( $_, 'POD2/TLH' ) } @dirs;
  is( @ok, @INC, 'all pod dirs end with "POD2/TLH"' );

}

{
  my $lib_dir = File::Spec->catdir( 'lib' );
  my $pod2 = POD2::Base->new({ lang => 'pt', inc => [$lib_dir] }); 
  isa_ok( $pod2, 'POD2::Base' );

  is( $pod2->{lang}, 'PT', 'the right lang' );

  my @dirs = $pod2->pod_dirs();
  is( @dirs, 1, 'found one dir' );
  is( $dirs[0], File::Spec->catdir( $lib_dir, 'POD2', 'PT' ), 'at the right place' );

}

package POD2::TLH;

@POD2::TLH::ISA = qw( POD2::Base );

sub search_perlfunc_re {
    return 'Klingon Listing of Functions';
}

package main;

{
  my $lib_dir = File::Spec->catdir( 't', 'lib' );

  my $pod2 = POD2::TLH->new({ inc => [$lib_dir] });
  isa_ok( $pod2, 'POD2::TLH' );
  isa_ok( $pod2, 'POD2::Base' );

  is( $pod2->{lang}, 'TLH', 'the right lang' );

  my @dirs = $pod2->pod_dirs({ test => 0 }); # no test for -d
  is( @dirs, 1, 'guessed one dir' );
  is( $dirs[0], File::Spec->catdir( $lib_dir, 'POD2', 'TLH' ), "at the right place" );

  is( $pod2->search_perlfunc_re, 'Klingon Listing of Functions', 'search_perlfunc_re ok' );

}
