use v5.40.0;
use common::sense;
use feature 'signatures';

use lib 'lib';

use Test::More;
use Mojo::PrettyTidy::Diff qw(unified_diff);

subtest 'no diff for identical input' => sub {
  my $diff = unified_diff( old => "alpha\nbeta\n",
                           new => "alpha\nbeta\n", );

  is $diff, '', 'identical input returns empty diff';
};

subtest 'single hunk with default context' => sub {
  my $diff = unified_diff(
                           old       => "one\ntwo  \nthree\nfour\nfive\n",
                           new       => "one\ntwo\nthree\nfour\nfive\n",
                           old_label => 'old.txt',
                           new_label => 'new.txt', );

  like $diff,   qr/^--- old\.txt$/m,         'has old header';
  like $diff,   qr/^\+\+\+ new\.txt$/m,      'has new header';
  like $diff,   qr/^\@\@ -2,4 \+2,4 \@\@$/m, 'has hunk header';
  unlike $diff, qr/^ one$/m,   'does not include leading line outside hunk';
  like $diff,   qr/^-two  $/m, 'shows removed line';
  like $diff,   qr/^\+two$/m,  'shows added line';
  like $diff,   qr/^ three$/m, 'includes trailing context';

  # Optional extra checks since the current implementation includes these too.
  like $diff, qr/^ four$/m, 'includes additional context line';
  like $diff, qr/^ five$/m, 'includes additional context line';
};

subtest 'two distant changes produce two hunks' => sub {
  my $old = join "\n", qw(
      line1
      line2
      line3
      line4
      line5
      line6
      line7
      line8
      line9
      line10
      line11
      line12
  ), '';

  my $new = join "\n",
      (
        'line1', 'line2 changed',  'line3',  'line4',
        'line5', 'line6',          'line7',  'line8',
        'line9', 'line10 changed', 'line11', 'line12',
        '', );

  my $diff = unified_diff(
                           old       => $old,
                           new       => $new,
                           old_label => 'old.txt',
                           new_label => 'new.txt',
                           context   => 1, );

  my @hunks = $diff =~ /^\@\@ .* \@\@$/mg;
  is scalar( @hunks ), 2, 'two distant changes produce two hunks';

  like $diff, qr/^-line2$/m,           'first changed line removed';
  like $diff, qr/^\+line2 changed$/m,  'first changed line added';
  like $diff, qr/^-line10$/m,          'second changed line removed';
  like $diff, qr/^\+line10 changed$/m, 'second changed line added';
};

subtest 'nearby changes merge into one hunk' => sub {
  my $old = join "\n", qw(
      a
      b
      c
      d
      e
      f
      g
  ), '';

  my $new = join "\n",
      ( 'a', 'b changed', 'c', 'd changed', 'e', 'f', 'g', '', );

  my $diff = unified_diff(
                           old       => $old,
                           new       => $new,
                           old_label => 'old.txt',
                           new_label => 'new.txt',
                           context   => 1, );

  my @hunks = $diff =~ /^\@\@ .* \@\@$/mg;
  is scalar( @hunks ), 1, 'nearby changes merge into one hunk';

  like $diff, qr/^-b$/m,          'first nearby change removed';
  like $diff, qr/^\+b changed$/m, 'first nearby change added';
  like $diff, qr/^-d$/m,          'second nearby change removed';
  like $diff, qr/^\+d changed$/m, 'second nearby change added';
};

subtest 'context zero suppresses unchanged lines around change' => sub {
  my $diff = unified_diff(
                           old       => "alpha\nbeta\ncharlie\n",
                           new       => "alpha\nbeta changed\ncharlie\n",
                           old_label => 'old.txt',
                           new_label => 'new.txt',
                           context   => 0, );

  like $diff, qr/^\@\@ -2 \+2 \@\@$/m,
      'has compact hunk header for zero context';
  unlike $diff, qr/^ alpha$/m,   'does not include leading unchanged context';
  unlike $diff, qr/^ charlie$/m, 'does not include trailing unchanged context';
  like $diff,   qr/^-beta$/m,    'shows removed changed line';
  like $diff,   qr/^\+beta changed$/m, 'shows added changed line';
};

done_testing;

