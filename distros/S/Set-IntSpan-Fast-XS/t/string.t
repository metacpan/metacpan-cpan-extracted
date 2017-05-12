use strict;
use warnings;
use Test::More;
use Set::IntSpan::Fast::XS;

my @schedule;

BEGIN {
  @schedule = (
    {
      name => 'Simple as_string',
      in   => [ 1, 1, 3, 3, 5, 5 ],
      out  => '1,3,5',
    },
    {
      name => 'Range as_string',
      in   => [ 1, 2, 5, 6 ],
      out  => '1-2,5-6',
    },
    {
      name => 'Different separator',
      in   => [ 1, 1, 3, 3, 5, 5 ],
      opts => { sep => ';' },
      out  => '1;3;5',
    },
    {
      name => 'Different range',
      in   => [ 1, 2, 5, 6 ],
      opts => { range => ':' },
      out  => '1:2,5:6',
    },
    {
      name => 'Different range, sep, quotemeta, negatives',
      in   => [ 1, 2, 5, 6, -10, -5 ],
      opts => { sep => '|', range => '*' },
      out  => '-10*-5|1*2|5*6',
    },
    {
      name => 'Simple parsing',
      in   => '100,200,300,400',
      out  => [ 100, 100, 200, 200, 300, 300, 400, 400 ]
    },
    {
      # Looks odd, should work
      name => 'Negative number',
      in   => '-10-10,-30--20',
      out  => [ -30, -20, -10, 10 ]
    },
    {
      name => 'Set sep',
      in   => '1-3;5-9;12;14',
      opts => { sep => ';' },
      out  => [ 1, 3, 5, 9, 12, 12, 14, 14 ]
    },
    {
      name => 'Set range',
      in   => '1>3,5>9,12,14',
      opts => { range => '>' },
      out  => [ 1, 3, 5, 9, 12, 12, 14, 14 ]
    },
    {
      name => 'Set range, sep',
      in   => '1>3*5>9*12*14',
      opts => { range => '>', sep => '*' },
      out  => [ 1, 3, 5, 9, 12, 12, 14, 14 ]
    },
  );

  plan tests => scalar( @schedule ) * 4;
}

for my $test ( @schedule ) {
  my $name = $test->{name};
  ok my $set = Set::IntSpan::Fast::XS->new(), "$name: set created OK";
  ok my $nset = Set::IntSpan::Fast::XS->new(),
   "$name: second set created OK";
  my $in  = $test->{in};
  my @opt = ();
  push @opt, $test->{opts} if $test->{opts};

  if ( 'ARRAY' eq ref $in ) {
    $set->add_range( @$in );
    my $want = $test->{out};
    my $got  = $set->as_string( @opt );
    is $got, $want, "$name: as_string OK";
    $nset->add_from_string( @opt, $want );
    ok $nset->equals( $set ), "$name: parse output from as_string OK";
  }
  else {
    $set->add_from_string( @opt, $in );
    $nset->add_range( @{ $test->{out} } );
    unless ( ok $nset->equals( $set ), "$name: parse matches" ) {
      diag "expected: ", $nset->as_string, "\n";
      diag "     got: ", $set->as_string,  "\n";
    }
    pass "$name: padding" for 1 .. 1;
  }
}
