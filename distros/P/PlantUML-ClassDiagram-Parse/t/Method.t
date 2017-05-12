use strict;
use warnings;
use utf8;
use Test::More;

my $CLASS = 'PlantUML::ClassDiagram::Class::Method';
BEGIN { use_ok 'PlantUML::ClassDiagram::Class::Method' };

subtest "normal" => sub {
    my $fixture = 'foo()';

    my $method = $CLASS->build($fixture);
    is ($method->get_name, 'foo', 'name');
    is ($method->get_attribute, '', 'attribute');
    ok (!$method->is_abstract, 'is_abstract');
    ok (!$method->is_static, 'is_static');
};

subtest "static method" => sub {
    my $fixture = '{static} foo()';

    my $method = $CLASS->build($fixture);
    is ($method->get_name, 'foo', 'name');
    is ($method->get_attribute, 'static', 'attribute');
    ok (!$method->is_abstract, 'is_abstract');
    ok ($method->is_static, 'is_static');
};

subtest "abstract method" => sub {
    my $fixture = '{abstract} foo()';

    my $method = $CLASS->build($fixture);
    is ($method->get_name, 'foo', 'name');
    is ($method->get_attribute, 'abstract', 'attribute');
    ok ($method->is_abstract, 'is_abstract');
    ok (!$method->is_static, 'is_static');
};

done_testing;
