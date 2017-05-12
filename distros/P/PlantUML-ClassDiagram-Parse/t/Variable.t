use strict;
use warnings;
use utf8;
use Test::More;
use PlantUML::ClassDiagram::Class::Variable;

my $CLASS = 'PlantUML::ClassDiagram::Class::Variable';
BEGIN { use_ok 'PlantUML::ClassDiagram::Class::Variable' };

subtest "normal" => sub {
    my $fixture = 'foo';

    my $method = $CLASS->build($fixture);
    is ($method->get_name, 'foo', 'name');
    is ($method->get_attribute, '', 'attribute');
};

done_testing;
