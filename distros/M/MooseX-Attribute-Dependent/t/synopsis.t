package MyApp::Types;
use MooseX::Attribute::Dependency;
use List::Util 1.33 ();

BEGIN { MooseX::Attribute::Dependency::register({
       name               => 'SmallerThan',
       message => 'The value must be smaller than %s',
       constraint         => sub {
           my ($attr_name, $params, @related) = @_;
           return List::Util::all { $params->{$attr_name} < $params->{$_} } @related;
       },
   }
); }

package MyClass;
use Moose;
use MooseX::Attribute::Dependent;

has small => ( is => 'rw', dependency => SmallerThan['large'] );
has large => ( is => 'rw' );

package main;
use Test::Most;

dies_ok { MyClass->new( small => 10, large => 1) };
lives_ok { MyClass->new( small => 1, large => 10) };

done_testing;
