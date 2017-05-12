#!/usr/bin/perl

use strict;

use Test::More tests => 52;

# TODO - test errors in defining params templates, and errors in invalid args

use_ok('Params::Smart', 0.08, ':all' );

my @Internal = qw( _named );

{
  my %Expected = (
    foo => 1,
    bar => 2,
    bo  => 3,
  );

  my @params = qw(?foo ?bar ?bo );

  my %Vals = Params(@params)->args( %Expected );
  ok($Vals{_named});
  foreach my $internal (@Internal) {
    delete $Vals{$internal};
  }
  ok(eq_hash( \%Expected, \%Vals ), "named parameters");

  %Vals = Params(@params)->args( 1, 2, 3 );
  ok(!$Vals{_named});
  foreach my $internal (@Internal) {
    delete $Vals{$internal};
  }
  ok(eq_hash( \%Expected, \%Vals ), "positional parameters");

  delete $Expected{bo};
  %Vals = Params(@params)->args( 1, 2 );
  ok(!delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "positional parameters");

  %Vals = Params(@params)->args( undef, 2 );
  ok(!delete $Vals{_named});
  my $t = $Expected{foo}; $Expected{foo} = undef;
  #foreach my $key (keys %Vals) { print STDERR "\x23 $key=$Vals{$key} $Expected{$key}\n"; }
  ok(eq_hash( \%Expected, \%Vals ), "positional parameters with undef");
  $Expected{foo} = $t;

  delete $Expected{bar};
  %Vals = Params(@params)->args( 1 );
  ok(!delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "positional parameters");

  delete $Expected{foo};
  %Vals = Params(@params)->args();
  ok(delete $Vals{_named}); # defaults to true if no args
  ok(eq_hash( \%Expected, \%Vals ), "positional parameters");


}

{
  my %Expected = (
    foo => 1,
    bar => 2,
    bo  => 3,
  );

  my @params = qw(foo bar bo );

  my %Vals = Params(@params)->args( %Expected );
  ok(delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "named parameters");

  %Vals = Params(@params)->args( 1, 2, 3 );
  ok(!delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "positional parameters");
}

{
  my %Expected = (
    foo => 1,
    bar => 2,
    bo  => 3,
  );

  my @params = qw(foo ?bar ?bo );

  my %Vals = Params(@params)->args( %Expected );
  ok(delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "named parameters");

  %Vals = Params(@params)->args( 1, 2, 3 );
  ok(!delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "positional parameters");

  delete $Expected{bo};

  %Vals = Params(@params)->args( %Expected );
  ok(delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "named parameters");

  %Vals = Params(@params)->args( 1, 2 );
  ok(!delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "positional parameters");

  delete $Expected{bar};

  %Vals = Params(@params)->args( %Expected );
  ok(delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "named parameters");

  %Vals = Params(@params)->args( 1 );
  ok(!delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "positional parameters");

}

{
  my %Expected = (
    foo => 1,
    bar => [ 2, 3 ],
  );

  my @params = qw(foo *bar );

  my %Vals = Params(@params)->args( %Expected );
  ok(delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "named parameters (slurp)");

  %Vals = Params(@params)->args( 1, 2, 3 );
  ok(!delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "positional parameters (slurp)");
}

{
  my %Expected = (
    foo => 1,
    bar => 2,
  );

  my @params = qw( bar +?foo );

  my %Vals = Params(@params)->args( -foo => 1, -bar => 2, );
  ok(delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "named parameters (slurp)");

  %Vals = Params(@params)->args( 2 );
  ok(!delete $Vals{_named});
  ok(eq_hash( { bar => 2 }, \%Vals ), "positional parameters (slurp)");
}

{
  my %Expected = (
    foo => 1,
    bar => 2,
  );

  my @params = qw( bar|b +?foo|f );

  my %Vals = Params(@params)->args( f => 1, b => 2, );
  ok(delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "named parameters (slurp)");

  %Vals = Params(@params)->args( 2 );
  ok(!delete $Vals{_named});
  ok(eq_hash( { bar => 2 }, \%Vals ), "positional parameters (slurp)");
}


{
  my @params = (
    { name => 'foo', required => 1, },
  );
  $@ = undef;
  eval {
    my %Vals = Params(@params)->args( foo => 100, bar => 200, );
  };
  ok($@, "expected error");
}

{
  # Test a callback which dynamically adds a new parameter, though
  # it's messy

  my @params = (
    { name => 'baz', required => 1,
    },
    { name => 'foo', required => 0,
      callback => sub {
	my ($self, $name, $val) = @_;
        $self->set_param( { name => 'bar' } );
	return $val;
      }, 
    },
  );

  for my $i (1..2) {

    my %template = ( baz => $i, bar => 1 );
    if ($i == 1) { $template{foo} = 1; }

    my (%Vals1, %Vals2);
    eval { %Vals1 = ParamsNC(@params)->args( %template ); };

    if ($i == 1) {
      ok($Vals1{bar} == 1, "dynamically added parameter");
    } elsif ($i == 2) {
      ok($@ =~ m/unrecognized parameters:\s\"bar\"/, "non-cached parameter template");
    }
  }

  for my $i (1..2) {
    my %template = ( baz => $i, bar => 1 );
    if ($i == 1) { $template{foo} = 1; }

    my (%Vals1, %Vals2);
    eval { %Vals1 = Params(@params)->args( %template ); };

    ok($Vals1{bar} == 1, "dynamically added parameter cached");

  }

}


{

  my @params1 = (
    { name => 'foo', required => 0, },
    { name => 'bar', required => 0, needs => "foo" },
  );

    my (%Vals1, %Vals2);
    eval { %Vals1 = Params(@params1)->args( bar=>1 ); };
    # print STDERR $@;
    ok( $@ =~ m/missing required parameter \"foo\" \(needed by \"bar\"\)/ );
    ok( !defined $Vals1{bar} );

    eval { %Vals2 = Params(@params1)->args( bar=>1, foo => 1 ); };
    ok( defined $Vals2{bar} );
}

{

  my @params1 = (
    { name => 'foo', required => 0, },
    { name => 'baz', required => 0, },
    { name => 'bar', required => 0, needs => [qw(foo baz)] },
  );

    my (%Vals1, %Vals2);
    eval { %Vals1 = Params(@params1)->args( bar=>1, baz => 1 ); };
    # print STDERR $@;
    ok( $@ =~ m/missing required parameter \"foo\" \(needed by \"bar\"\)/ );
    ok( !defined $Vals1{bar} );

    eval { %Vals2 = Params(@params1)->args( bar=>1, foo => 1, baz => 1 ); };
    ok( defined $Vals2{bar} );
}
