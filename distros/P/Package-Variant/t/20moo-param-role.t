use strictures 2;
use Test::More;

BEGIN {
  eval { require Moo::Role; 1 }
    or plan skip_all => q{Requires Moo::Role};
}

BEGIN {
  package My::Role::OnOff;

  use Package::Variant
    importing => { 'Moo::Role' => [] },
    subs => [ qw(has before after around) ];

  sub make_variant {
    my ($me, $into, %args) = @_;
    my $name = $args{name};
    has $name => (is => 'rw');
    install "${name}_on" => sub { shift->$name(1); };
    install "${name}_off" => sub { shift->$name(0); };
  }
  $INC{"My/Role/OnOff.pm"} = __FILE__;
}

BEGIN {
  package LightSwitch;

  use My::Role::OnOff;
  use Moo;

  with OnOff(name => 'lights');
}

my $lights = LightSwitch->new;

is($lights->lights, undef, 'Initial state');
is($lights->lights_on, 1, 'Turn on');
is($lights->lights, 1, 'On');
is($lights->lights_off, 0, 'Turn off');
is($lights->lights, 0, 'Off');

done_testing;
