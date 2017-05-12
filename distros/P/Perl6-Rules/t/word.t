use Perl6::Rules;

use Test::Simple 'no_plan';

ok( "abc  def" !~ m/abc  def/, 'Literal space nonmatch' );
ok( "abcdef" =~ m/abc  def/, 'Nonspace match' );
ok( "abc  def" =~ m:w/abc  def/, 'Word space match' );
ok( "abc\ndef" =~ m:words/abc  def/, 'Word newline match' );
ok( "abcdef" !~ m:words/abc  def/, 'Word nonspace nonmatch' );
ok( "abc  def" !~ m:words/abc <sp> def/, 'Word explicit space non-match' );
ok( "abc  def" =~ m:words/abc <ws> def/, 'Word explicit space match' );

ok( "abc  !def" !~ m/abc  !def/, 'Literal pre-shriek nonmatch' );
ok( "abc  !def" =~ m:words/abc  !def/, 'Word pre-shriek match' );
ok( "abc!def" =~ m:words/abc  !def/, 'Word nonspace pre-shriek match' );

ok( "abc!  def" !~ m/abc!  def/, 'Literal post-shriek nonmatch' );
ok( "abc!  def" =~ m:words/abc!  def/, 'Word post-shriek match' );
ok( "abc!def" =~ m:words/abc!  def/, 'Word nonspace post-shriek nonmatch' );

ok( "!!  !!" !~ m/!!  !!/, 'Literal multi-shriek nonmatch' );
ok( "!!  !!" =~ m:words/!!  !!/, 'Literal multi-shriek match' );
ok( "!!!!" =~ m:words/!!  !!/, 'Literal nonspace multi-shriek match' );
