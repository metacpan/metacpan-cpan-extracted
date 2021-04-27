use Test2::V0 -no_srand => 1;
use 5.020;
use experimental qw( postderef );
use Package::Checkpoint;

subtest 'basic' => sub {

  package Basic::Test1 {
    our $foo = 1;
    our @bar = (1,2,3);
    our %bar = ( a => 1 );
    our $baz = [1,2,3];
  }

  my $p = Package::Checkpoint->new('Basic::Test1');
  isa_ok $p, 'Package::Checkpoint';

  $Basic::Test1::foo = 2;
  push $Basic::Test1::baz->@*, 4;
  push @Basic::Test1::bar, 4;
  $Basic::Test1::bar{b} = 2;

  $p->restore;

  is $Basic::Test1::foo, 1;
  is \@Basic::Test1::bar, [1,2,3];
  is $Basic::Test1::baz, [1,2,3];
  is \%Basic::Test1::bar, { a => 1 };

};

done_testing;
