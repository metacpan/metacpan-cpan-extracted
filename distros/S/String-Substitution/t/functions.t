# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use String::Substitution ();

# [pattern, replacement, {in => [sub1, sub2, finalsub], nosub => []}, (# of warnings for uninitialized)]
my @tests = (
  ['(e)(.)',     '$1-$2-', {hello => ['he-l-lo']}],
  ['.+(e)(.).+', '$1-$2-', {hello => ['e-l-']}],
  ['el',         '',       {hello => ['hlo']}],
  ['\s+',        '_',      {hello => [], 'he ll o' => ['he_ll o', 'he_ll_o'], '  ' => ['_']}],
  [' ',          '_',      {hello => [], 'he ll o' => ['he_ll o', 'he_ll_o'], '  ' => ['_ ', '__']}],
  ['^\d{1,3}$', '', {'1',     ['']}],
  ['^\d{1,3}$', '', {'12',    ['']}],
  ['^\d{1,3}$', '', {'123',   ['']}],
  ['^\d{1,3}$', '', {'1234',  []}],
  ['^\d{1,3}$', '', {'12345', []}],
  ['^\d{0,3}$', '', {'1',     ['']}],
  ['^\d{0,3}$', '', {'12',    ['']}],
  ['^\d{0,3}$', '', {'123',   ['']}],
  ['^\d{0,3}$', '', {'1234',  []}],
  ['^\d{0,3}$', '', {'12345', []}],
  [qr'(^(; )+|(; ?)+$)', '', {
    '; Hi; ; There; ; ' => ['Hi; ; There; ; ', 'Hi; ; There'],
    'Hi; ; ; There; ; ' => ['Hi; ; ; There'],
    '; ; Hi; ; There' => ['Hi; ; There']
  }],
  [qr'(; ){2,}', '; ', {'Hi; There', => [], 'Hi; ; There' => ['Hi; There'], 'Hi; ; ; There' => ['Hi; There']}],
  [qr'^[Rr](.)?d$', 'gr$1$1n', {'Rd' => ['grn'], 'red' => ['green'], rod => ['groon']}, 2],
  [qr'^[Rr](.?)d$', 'gr$1$1n', {'Rd' => ['grn'], 'red' => ['green'], rud => ['gruun']}],
  # in this case, goober actually does a substitution, just happens to end up the same
  [qr'(o)(.)',      '$1$2$3',  {'giblet' => [], 'goober' => ['goober']}, 1],
  [qr'([a-z])oo', '${1}00', {'goober' => ['g00ber'], 'floo goo noo' => ['fl00 goo noo', 'fl00 g00 noo', 'fl00 g00 n00']}],
  [qr'0', '', {'0' => [''], '1' => []} ],
  [qr'(hello)', '$1 there, you', {'hell' => [], 'hello' => ['hello there, you'], 'hellos' => ['hello there, yous']}],
  [qr'^0$', '0-0-0 0:0:0', {0 => ['0-0-0 0:0:0'], 20101228 => []} ],
  [qr'(\d{4})(\d{2})(\d{2})', '$1/$2/$3 00:00:00', {20101228 => ['2010/12/28 00:00:00'], 201012 => []} ],

  [qr/b o o/x,  'yah', {'b o o' => [], 'boo' => ['yah'], 'BoO' => []}],
  [qr/b o o/xi, 'yah', {'b o o' => [], 'boo' => ['yah'], 'BoO' => ['yah']}],

  ['(e)(.)',     '$1-$2-', {hello => ['he-l-lo']}],
  # in single quotes 1 backslash is the same as 2
  # these two are equal:
  ['(e)(.)',     '\$1-$2-',  {hello => ['h$1-l-lo']}],
  ['(e)(.)',     '\\$1-$2-', {hello => ['h$1-l-lo']}],

  # from now on double them:
  ['(e)(.)',     '$1-\\\\$2-',   {hello => ['he-\\l-lo']}],
  ['(e)(.)',     '\\$1-\\\\$2-', {hello => ['h$1-\\l-lo']}],
  ['(e)(.)',     '$1-\\\\\\$2-', {hello => ['he-\\$2-lo']}],
  ['(e)(.)',     '\\\\$1-\\\\\\$2-',   {hello => ['h\\e-\\$2-lo']}],
  ['(e)(.)',     '\\\\\\$1-\\\\\\$2-', {hello => ['h\\$1-\\$2-lo']}],
  ['(e)(.)',     '$1-\\\\\\\\$2-',   {hello => ['he-\\\\l-lo']}],
  ['(e)(.)',     '$1-\\\\\\\\\\$2-', {hello => ['he-\\\\$2-lo']}],
  ['(e)(.)',     '$\\1-\\\\\\\\\\$2-',     {hello => ['h$1-\\\\$2-lo']}],
  ['(e)(.)',     '\\$\\1-\\\\\\\\\\$2-',   {hello => ['h$1-\\\\$2-lo']}],
  ['(e)(.)',     '\\\\$\\1-\\\\\\\\\\$2-', {hello => ['h\\$1-\\\\$2-lo']}],

  # explicitly test the POD example:
  ['t(h)e', '-$1-',        {the => ['-h-']}],
  ['t(h)e', '-\\$1-',      {the => ['-$1-']}],
  ['t(h)e', '-\\\\$1-',    {the => ['-\\h-']}],
  ['t(h)e', '-\\\\\\$1-',  {the => ['-\\$1-']}],
  ['t(h)e', '-\\x\\$1-',   {the => ['-x$1-']}],
  ['t(h)e', '-\\x\\\\$1-', {the => ['-x\\h-']}],

  # $0 is not a regexp match group
  ['t(h)e', '-$1-$0-',     {the => ['-h-$0-']}],
  ['t(h)e', '-$1-\\$0-',   {the => ['-h-$0-']}],
  ['t(h)e', '-$1-\\\\$0-', {the => ['-h-\\$0-']}],

  # lots of groups:
  #  1   2 3      4  5  6  7  8    9  10    1112  13  14   15   16
  [q[(i) (h(a)ve) (g)(r)(e)(e)(n) w(a)(ter)m(e(l))(on)(s). (d)o (you)],
    '${16} ${14}${11}${12} $3 ${5}$6${15} /\\\\/\\\\${11}${13} for \\$6? or $\\7',
    { 'i have green watermelons. do you?' =>
     ['you sell a red /\\/\\elon for $6? or $7?']}],

  ['t(h)e', sub { "cherry" }, {the => ['cherry'], 'the the' => ['cherry the', 'cherry cherry']}],
  ['t(h)e', sub { uc $_[1] }, {the => ['H'], 'the the' => ['H the', 'H H']}],
  ['(t(h)e)', sub { ucfirst $_[1] . uc $2 }, {the => ['TheH'], 'the the' => ['TheH the', 'TheH TheH']}],
  ['^(the)', sub { (my $t = $1) =~ s/([a-z])/\U$1/g; "\$_[1] $_[1] \$1 $1 $t" }, {the => ['$_[1] the $1 e THE']}],
  ['([a-z]+)', sub { (my $t = $1) =~ s/(.)/ord($1)/ge; "$_[1] ($1) => $t" }, {mod => ['mod (d) => 109111100']}],
  ['([a-z]+)', sub { scalar reverse uc $1 }, {the => ['EHT'], 'the-the' => ['EHT-the', 'EHT-EHT']}],
  ['(\w+)', sub { join('', ('!') x length $_[1]) }, {'the' => ['!!!'], 'the-the' => ['!!!-the', '!!!-!!!']}],

  # Test a match that contains a false value ('0').
  ['(\d)', '$1', {'0' => ['0'], '1' => ['1']}],
);

sub sum { my $s = 0; $s += $_ for @_; $s }
# sum( (c + m + cc + cm) + ((c loop + m loop + cc loop + cm loop)) * (expected strings)
plan tests => sum(map { map { (2 + 4 + 5) + ((1 + 2 + 2 + 1) * (@$_||1)) } values %{$_->[2]} } @tests);

foreach my $test ( @tests ){
  my ($pattern, $replacement, $hash, $warning) = (@$test, 0);
  while( my ($string, $expectations) = each %$hash ){
    my $nosub;
    # if it's empty, the pattern is expected not to match, so the output should equal the input
    if( @$expectations == 0 ){
      $expectations = [$string];
      $nosub = 1;
    }
    my $expected = $$expectations[-1];

    # ignore 'uninitialized' warnings if we know we're expecting them
    local $SIG{__WARN__} = sub { warn($_[0]) unless $_[0] =~ qr/uninitialized/ && $warning; };

    {
      # copy
      my $s = $string;
      my ($suffix, $gsub_n, $gsub_s, $sub_n, $sub_s) = test_vars('_copy');

      is($gsub_s->($s, $pattern, $replacement), $expected, "$gsub_n: '$s' =~ s{$pattern}{$replacement}");

      $s = $string;
      foreach my $exp ( @$expectations ){ my $orig = $s;
        is($s = $sub_s->($s, $pattern, $replacement), $exp, " $sub_n changed '$orig' => '$exp'");
      }
      is($s, $expected, " $sub_n completed successfully");
    }

    {
      # modify
      my $s = $string;
      my ($suffix, $gsub_n, $gsub_s, $sub_n, $sub_s) = test_vars('_modify');

      my $c = $gsub_s->($s, $pattern, $replacement);
      is($s, $expected, "$gsub_n: '$s' =~ s{$pattern}{$replacement}");
      is($c, ($nosub ? '' : scalar @$expectations), "$gsub_n did expected number of substitutions");

      $s = $string;
      my ($m, $n) = (0, $nosub ? '' : 1);
      foreach my $exp ( @$expectations ){ my $orig = $s;
        is(my $k = $sub_s->($s, $pattern, $replacement), $n, " $sub_n made ${\($n||0)} substitution(s)");
        $m += $k;
        is($s, $exp, " $sub_n changed '$orig' => '$exp' in-place");
      }
      is($s, $expected, " $sub_n completed successfully");
      is($m, ($c||0), " $sub_n did same number of substitutions ($m) as $gsub_n: ($c)");
    }

    {
      my $s = $string;
      my ($suffix, $gsub_n, $gsub_s, $sub_n, $sub_s) = test_vars('_context');

      # copy
      my $copy = $gsub_s->($s, $pattern, $replacement);
      is($copy, $expected, "$gsub_n: '$s' =~ s{$pattern}{$replacement}");
      is($s, $string, "scalar context $gsub_n no modification");

      # modify
      $gsub_s->($s, $pattern, $replacement);
      is($s, $expected, "void context $gsub_n modified variable");

      # copy
      $s = $string;
      foreach my $exp ( @$expectations ){ my $orig = $s;
        my $copy = $sub_s->($s, $pattern, $replacement);
        is($copy, $exp, " $sub_n changed '$orig' => '$exp'");
        is($s, $orig, "scalar context $sub_n no modification");
        $s = $copy;
      }
      is($s, $expected, " $sub_n completed successfully");

      # modify
      $s = $string;
      foreach my $exp ( @$expectations ){ my $orig = $s;
        $sub_s->($s, $pattern, $replacement);
        is($s, $exp, " $sub_n changed '$orig' => '$exp' in-place");
      }
      is($s, $expected, " $sub_n completed successfully");
    }
  }
}

sub test_vars {
  my $suffix = shift;
  return ($suffix, map { ("${_}$suffix", \&{"String::Substitution::${_}$suffix"}) } qw(gsub sub));
}
