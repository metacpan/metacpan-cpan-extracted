use Test2::V0 -no_srand => 1;
use String::Template;
use Time::Piece 1.17;

$ENV{TZ} = 'UTC'; # override so test in local TZ will succeed

if($^O eq 'MSWin32') {
  Time::Piece::_tzset();
}

subtest 'expand' => sub {

  my @TestCases =
  (
      {
          Name     => 'Simple, nothing replaced',
          Template => 'foo',
          Fields   => {},
          Correct  => 'foo'
      },
      {
          Name     => '1 replace',
          Template => '<foo>',
          Fields   => { foo => 12 },
          Correct  => '12'
      },
      {
          Name     => '1 replace, with whitespace',
          Template => '  <foo> ',
          Fields   => { foo => 12, ignored => 72},
          Correct  => '  12 '
      },
      {
          Name     => '2 replaces',
          Template => '  <foo>  <bar>',
          Fields   => { foo => 12, bar => 72},
          Correct  => '  12  72'
      },
      {
          Name     => 'Missing field',
          Template => '  <foo>  <bar>',
          Fields   => { foo => 12, ignored => 72},
          Correct  => '  12  '
      },
      {
          Name     => '2 replaces with sprintf format',
          Template => '  <foo>  <bar%04d>',
          Fields   => { foo => 12, bar => 72},
          Correct  => '  12  0072'
      },
      {
          Name     => '2 replaces with date format',
          Template => '  <foo>  <date:%Y-%m-%d> ',
          Fields   => { foo => 12, date => 'May 17, 2008'},
          Correct  => '  12  2008-05-17 '
      },
      {
          Name     => 'date format with :(local) and !(utc)',
          Template => 'local: <date:%Y-%m-%d %H:%M> utc: <date!%Y-%m-%d %H:%M>',
          Fields   => { date => '2008-02-27T17:57:00Z' },
          Correct  => 'local: 2008-02-27 17:57 utc: 2008-02-27 17:57'
      }
  );

  foreach my $t (@TestCases)
  {
    my $exp = expand_string($t->{Template}, $t->{Fields});

    is($exp, $t->{Correct}, $t->{Name});
  }

};

subtest 'case insensitive' => sub {

  my %fields = ( num => 2, str => 'this', date => 'Feb 27, 2008' );

  my $template = "...<num%04d>...<str>...<date:%Y/%m/%d>...\n";

  my $correct = "...0002...this...2008/02/27...\n";

  is( expand_stringi("<this> and <that> and <theother>", { this => 1, that => 2, theother => 3 }),"1 and 2 and 3");
  is( expand_stringi("<This> and <that> and <TheotHer>", { this => 1, tHAT => 2, theother => 3 }),"1 and 2 and 3");
  is( expand_stringi("<tHis> and <that> and <theother>", { this => 1, that => 2, theother => 3 }),"1 and 2 and 3");
  is( expand_stringi("<THIS> and <THAT> and <TheOther>", { this => 1, That => 2, theother => 3 }),"1 and 2 and 3");
  is( expand_stringi("<this> and <that> and <theother>", { this => 1, that => 2, TheOther => 3 }),"1 and 2 and 3");

  is( expand_stringi('hi <date:%Y-%m-%d>', { date => 'May 17, 2008' } ), 'hi 2008-05-17' );


  is (expand_stringi( 'local: <date:%Y-%m-%d %H:%M> utc: <date!%Y-%m-%d %H:%M>',
      { date => '2008-02-27T17:57:00Z' } ),
      'local: 2008-02-27 17:57 utc: 2008-02-27 17:57' );

  is (expand_stringi( 'local: <date:%Y-%m-%d %H:%M> utc: <date!%Y-%m-%d %H:%M>',
      { Date => '2008-02-27T17:57:00Z' } ),
      'local: 2008-02-27 17:57 utc: 2008-02-27 17:57' );

  is (expand_stringi( 'local: <dAte:%Y-%m-%d %H:%M> utc: <DATE!%Y-%m-%d %H:%M>',
      { daTE => '2008-02-27T17:57:00Z' } ),
      'local: 2008-02-27 17:57 utc: 2008-02-27 17:57' );
};

done_testing;
