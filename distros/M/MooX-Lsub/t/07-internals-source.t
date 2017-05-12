
use strict;
use warnings;

use Test::More tests => 6;

require MooX::Lsub;

# ABSTRACT: Basic moo test

my @last_call;
my $last_caller;

my $fillin = {
  target  => 'Boris',
  options => [],
  has     => sub {
    $last_caller = caller();
    @last_call   = @_;
  },
};

my $code_string = MooX::Lsub->_make_lsub_code($fillin);
note $code_string;
like( $code_string, qr/package\s+Boris;/sxm,     'Gen code has Boris as a package' );
like( $code_string, qr/package\s+MooX::Lsub/sxm, 'Gen code has MooX::Lsub as a package' );

my $code = MooX::Lsub->_make_lsub($fillin);
note explain $code;

{
  local $@;
  my $failed = 1;
  eval {
    $code->( 'robert' => sub { 'hello' } );
    undef $failed;
  };
  ok( !$failed, "No exceptons" ) or diag $@;
}

is_deeply( \@last_call, [ robert =>, is => 'ro', lazy => 1, builder => '_build_robert' ], "Has called with correct values" );
is( $last_caller, 'Boris', "Caller called from package Boris" );

can_ok( 'Boris', '_build_robert' );
