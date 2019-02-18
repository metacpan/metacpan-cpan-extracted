
#!/usr/bin/env perl
use strictures 2;
use Test2::V0;

{
    package My::Class;
    use Moo;

    with 'MooX::Emulate::Class::Accessor::Fast';

    sub BUILD {
        my ($self, $args) = @_;
        return $self;
    }
}

my $i = My::Class->new(totally_random_not_an_attribute => 1);

is(
  $i->{totally_random_not_an_attribute},
  1,
  'Unknown attrs get into hash',
);

done_testing;
