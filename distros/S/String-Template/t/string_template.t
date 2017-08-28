use Test2::V0 -no_srand => 1;
use String::Template qw( :all );

subtest 'basic' => sub {

  my %fields = ( num => 2, str => 'this', date => 'Feb 27, 2008' );

  my $template = "...<num%04d>...<str>...<date:%Y/%m/%d>...\n";

  my $correct = "...0002...this...2008/02/27...\n";

  my $exp = expand_string($template, \%fields);

  is($exp, $correct, "test expand");
};

subtest 'missing values' => sub {

  my $template = "<hello>, <world>";

  my ($hello) = missing_values( $template, { world => 'foo' } );
  is $hello, 'hello', "missing word";

  is missing_values( $template, { hello => "foo", world => "bar" } ), F(), "not missing values";

  is missing_values( $template, { hello => undef, world => "bar" } ), F(), "not missing values";

  is missing_values( $template, { hello => undef, world => "bar" }, 1 ), T(), "missing some values";

  my @lots = missing_values( "<hello%2d> <world!a> <out#x> <there:y>", {} );
  is [ sort @lots ],
     [ qw/hello out there world/ ],
     "missing values with modifiers";
};

subtest 'expand_hash' => sub {

  my @TestCases =
  (
      {
          Hash => 
          {
              X => '<Y>',
              Y => 1
          },
          Correct =>
          {
              X => 1,
              Y => 1
          },
          Status => 1
      },
      {
          Hash => 
          {
              X => '<Y>',
              Y => '<Z>',
              Z => 1
          },
          Correct =>
          {
              X => 1,
              Y => 1,
              Z => 1
          },
          Status => 1
      },
      {
          Hash => 
          {
              X => '<Y>',
              Y => '<Z>',
              Z => 1
          },
          Correct =>
          {
              X => '<Z>',
              Y => 1,
              Z => 1
          },
          Status => undef,
          MaxDepth => 1   
      },
      {
          Hash => 
          {
              X => '<Y>',
          },
          Correct =>
          {
              X => '<Y>'
          },
          Status => undef
      },
  );

  foreach my $t (@TestCases)
  {
      my $status = expand_hash($t->{Hash}, $t->{MaxDepth});

      is($t->{Hash}, $t->{Correct});
      is($status, $t->{Status});
  }
};

subtest 'extended field' => sub {

  my $template = 'I <str{"%s" }>mean literally';

  is expand_string( $template, { str => 'literally' } ),
    'I "literally" mean literally', "Parsed extended field";

  is expand_string( $template, { str => undef } ),
    'I mean literally', "Extended field is treated as a whole";

  is expand_string( '<str{"%s"\}}>', { str => 'foo' } ),
    '"foo"}', "Escaped curly brace";

  is expand_string( '<str{%s}>', { str => 'foo' } ),
    'foo', "Can have tight extended fields";

  is expand_string( $template, { str => undef }, 1 ),
    $template, "Template is unchanged if undefined";

  is expand_string( '<str{--#2}>', { str => 'foobar' }, 1 ),
    '--obar', "Extended substr with undef flag";

  is expand_string( '<str{--#2}>', { str => undef } ),
    q{}, "Extended subtr without undef flag";

  is expand_string( '<str{--#1,3}-->', { str => 'foobar' }, 1 ),
    '--oob--', "Extended field with suffix";
};

subtest 'undef' => sub {

  is(expand_string('...<missing field>...', {}),
                   '......');

  is(expand_string('...<missing field>...', {}, 1),
                   '...<missing field>...');

  is(expand_string('...<missing%02d>...', {}),
                   '......');

  is(expand_string('...<missing%02d>...', {}, 1),
                   '...<missing%02d>...');
};

done_testing;
