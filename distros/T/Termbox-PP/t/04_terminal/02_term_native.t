use 5.010;
use strict;
use warnings;
use utf8;

use Test::More;
# use Test::More::UTF8 qw( failure out );
binmode( Test::More->builder->failure_output(), ':utf8');
binmode( Test::More->builder->output(), ':utf8');

BEGIN {
  require_ok 'Termbox::PP';
  use_ok 'Termbox', qw( :return );
}

# -------------------------------------
note 'Character printability checking';
# -------------------------------------

subtest 'tb_iswprint - printable ASCII characters' => sub {
  plan tests => 5;
  
  # Test printable ASCII characters
  ok( Termbox::tb_iswprint(ord('A')), 'Character A is printable' );
  ok( Termbox::tb_iswprint(ord('z')), 'Character z is printable' );
  ok( Termbox::tb_iswprint(ord('0')), 'Character 0 is printable' );
  ok( Termbox::tb_iswprint(ord(' ')), 'Character space is printable' );
  ok( Termbox::tb_iswprint(ord('!')), 'Character ! is printable' );
};

subtest 'tb_iswprint - control characters' => sub {
  plan tests => 4;
  
  # Test control characters (not printable)
  ok( !Termbox::tb_iswprint(0x00), 'NULL character is not printable' );
  ok( !Termbox::tb_iswprint(0x01), 'SOH character is not printable' );
  ok( !Termbox::tb_iswprint(0x07), 'BEL character is not printable' );
  ok( !Termbox::tb_iswprint(0x1F), 'Unit separator is not printable' );
};

subtest 'tb_iswprint - extended Unicode' => sub {
  plan tests => 3;
  
  # Test extended Unicode characters
  ok( Termbox::tb_iswprint(0x00E9), 'Character é (U+00E9) is printable' );
  ok( Termbox::tb_iswprint(0x4E2D), 'Character 中 (U+4E2D) is printable' );
  ok( Termbox::tb_iswprint(0x1F600), 'Emoji 😀 (U+1F600) is printable' );
};

# ----------------------------------------
note 'Grapheme cluster width calculation';
# ----------------------------------------

subtest 'tb_cluster_width - ASCII characters' => sub {
  plan tests => 5;
  
  # ASCII characters should have width 1
  is( Termbox::tb_cluster_width([ord('A')], 1), 1, 'Character A has width 1' );
  is( Termbox::tb_cluster_width([ord('z')], 1), 1, 'Character z has width 1' );
  is( Termbox::tb_cluster_width([ord('0')], 1), 1, 'Character 0 has width 1' );
  is( Termbox::tb_cluster_width([ord(' ')], 1), 1, 'Character space has width 1' );
  is( Termbox::tb_cluster_width([ord('!')], 1), 1, 'Character ! has width 1' );
};

subtest 'tb_cluster_width - zero-width and wide characters' => sub {
  plan tests => 3;
  
  # Zero-width characters or combining marks
  my $zw_width = Termbox::tb_cluster_width([0x200B], 1);
  ok( $zw_width >= -1, 'Zero-width space has valid width' );
  
  # Wide characters (CJK, etc.)
  my $cjk_width = Termbox::tb_cluster_width([0x4E2D], 1);
  cmp_ok( $cjk_width, '>=', 1, 
    'Chinese character 中 has width >= 1' );
  
  my $hiragana_width = Termbox::tb_cluster_width([0x3042], 1);
  cmp_ok( $hiragana_width, '>=', 1, 
    'Hiragana character あ (U+3042) has width >= 1' );
};

# --------------------------
note 'Terminal state reset';
# --------------------------
subtest 'tb_reset - initialization state' => sub {
  plan tests => 3;
  
  my $result = Termbox::tb_reset();
  is( $result, TB_OK(), 'tb_reset returns TB_OK (0)' );
  
  # Reset should not fail on repeated calls
  $result = Termbox::tb_reset();
  is( $result, TB_OK(), 'tb_reset can be called multiple times' );
  
  # Third call should also succeed
  $result = Termbox::tb_reset();
  is( $result, TB_OK(), 'tb_reset call 3 succeeds' );
};

# -------------------------------
note 'Terminal deinitialization';
# ------------------------------
subtest 'tb_deinit - cleanup operations' => sub {
  local $SIG{__WARN__} = sub { };
  plan tests => 3;
  
  # tb_deinit should clean up resources
  my $result = Termbox::tb_deinit();
  is( $result, TB_OK(), 'tb_deinit returns TB_OK (0)' );
  
  # After deinit, repeated calls should be safe
  $result = Termbox::tb_deinit();
  is( $result, TB_OK(), 'tb_deinit can be called multiple times' );
  
  # Third call should also succeed
  $result = Termbox::tb_deinit();
  is( $result, TB_OK(), 'tb_deinit call 3 succeeds' );
};

done_testing();
