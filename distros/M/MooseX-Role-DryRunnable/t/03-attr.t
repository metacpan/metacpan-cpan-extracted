use Test::More tests => 3;

subtest "should do nothing if not in dry run mode (using attributes)" => sub {
  plan tests => 1;
  
  {
    package Foo;
    use Moose;
    use MooseX::Role::DryRunnable::Attribute;
    with 'MooseX::Role::DryRunnable::Base';

    sub bar :dry_it {
      Test::More::ok(1, "should be called");
    }

    sub is_dry_run { # required !
      0
    }

    sub on_dry_run { # required !
      Test::More::fail("should not be called")
    }

    no Moose;
    1; 
    
    my $foo = Foo->new();
    $foo->bar();
  }
};

subtest "should call on_dry_run if in dry run mode (using attributes)" => sub {
  plan tests => 4;
  
  {
    package Foo2;
    use Moose;
    use MooseX::Role::DryRunnable::Attribute;
    with 'MooseX::Role::DryRunnable::Base' ;

    sub bar :dry_it{
      Test::More::fail("should not be called")
    }

    sub is_dry_run { # required !
      Test::More::isa_ok(shift, 'Foo2');
      Test::More::is(shift, 'bar');
      Test::More::is(scalar(@_),0);
      1
    }

    sub on_dry_run { # required !
      Test::More::ok(1, "should be called");
    }

    no Moose;
    1; 
    
    my $foo = Foo2->new();
    $foo->bar();
  }
};


subtest "can't call on_dry_run if in dry run mode (using attributes) and it is not a MooseX::Role::DryRunnable" => sub {
  plan tests => 1;
  
  eval {
    package Foo3;
    use Moose;
    use MooseX::Role::DryRunnable::Attribute;

    sub bar :dry_it{
      Test::More::fail("should not be called")
    }

    1;
    
    my $foo = Foo3->new();
    $foo->bar();
  };
  is($@,"Should be MooseX::Role::DryRunnable::Base\n");
};