use Test::More tests => 4;

subtest "should do nothing if not in dry run mode" => sub {
  plan tests => 1;
  
  {
    package Foo;
    use Moose;
    with 'MooseX::Role::DryRunnable' => { 
      methods => [ qw(bar) ]
    };

    sub bar {
      Test::More::pass("should be called");
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

subtest "should call on_dry_run if in dry run mode" => sub {
  plan tests => 1;
  
  {
    package Foo2;
    use Moose;
    with 'MooseX::Role::DryRunnable' => { 
      methods => [ qw(bar) ]
    };

    sub bar {
      Test::More::fail("should not be called")
    }

    sub is_dry_run { # required !
      1
    }

    sub on_dry_run { # required !
      Test::More::pass("should be called");
    }

    no Moose;
    1; 
    
    my $foo = Foo2->new();
    $foo->bar();
  }
};

subtest "should call on_dry_run and pass the correct set of parameters" => sub {
  plan tests => 4;
  
  {
    package Foo3;
    use Moose;
    with 'MooseX::Role::DryRunnable' => { 
      methods => [ qw(bar) ]
    };

    sub bar {
      Test::More::fail("should not be called")
    }

    sub is_dry_run { # required !
      1
    }

    sub on_dry_run { # required !
      my $self = shift;
      my $method = shift;
      Test::More::isa_ok($self,'Foo3');
      Test::More::is($method, 'bar');
      Test::More::is(scalar(@_),1);
      Test::More::is($_[0],123);
    }

    no Moose;
    1; 
    
    my $foo = Foo3->new();
    $foo->bar(123);
  }
};

subtest "should call in_dry_run and pass the name of the method and the argument list" => sub {
  plan tests => 4;
  
  {
    package Foo4;
    use Moose;
    with 'MooseX::Role::DryRunnable' => { 
      methods => [ qw(bar) ]
    };

    sub bar {
      Test::More::fail("should not be called")
    }

    sub is_dry_run { # required !
      my $self = shift;
      my $method = shift;
      Test::More::isa_ok($self,'Foo4');
      Test::More::is($method, 'bar');
      Test::More::is(scalar(@_),1);
      Test::More::is($_[0],123);      
      1
    }

    sub on_dry_run { # required !

    }

    no Moose;
    1; 
    
    my $foo = Foo4->new();
    $foo->bar(123);
  }
};