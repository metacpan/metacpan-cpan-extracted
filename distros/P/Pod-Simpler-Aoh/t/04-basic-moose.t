#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Pod::Simpler::Aoh' ) || print "Bail out!\n";
}

subtest 'hash options' => sub {
     test_value({
        get => 7,
        identifier => 'head1',
        title => 'BUILDING CLASSES WITH MOOSE',
        content => q{Moose makes every attempt to provide as much convenience as possible during class construction/definition, but still stay out of your way if you want it to. Here are a few items to note when building classes with Moose.

When you use Moose, Moose will set the class's parent class to Moose::Object, unless the class using Moose already has a parent class. In addition, specifying a parent with extends will change the parent class.

Moose will also manage all attributes (including inherited ones) that are defined with has. And (assuming you call new, which is inherited from Moose::Object) this includes properly initializing all instance slots, setting defaults where appropriate, and performing any type constraint checking or coercion.}
    }); 

};

done_testing();

sub test_value {
    my $args = shift;

    my $parser = Pod::Simpler::Aoh->new();
    $parser->parse_from_file( 't/data/moose.pod' );

    my $values = $parser->get($args->{get});
    
    my @fields = qw(identifier content title);
    foreach my $field (@fields) {
        is($values->{$field}, $args->{$field}, "correct value for $field - get $args->{get}");
    }
}

1;
