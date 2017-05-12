use strict;
use warnings;
use utf8;
use Test::More;
use PlantUML::ClassDiagram::Relation;

my $CLASS = 'PlantUML::ClassDiagram::Relation';
BEGIN { use_ok 'PlantUML::ClassDiagram::Relation' };

subtest "<|-- generalization" => sub {
    my $fixture = 'Left <|-- Right';

    my $relation = $CLASS->build($fixture);
    is ($relation->get_name, 'generalization', 'relation name');
    is ($relation->get_from, 'Right', 'from');
    is ($relation->get_to, 'Left', 'to');
};

subtest "--|> generalization" => sub {
    my $fixture = 'Left --|> Right';

    my $relation = $CLASS->build($fixture);
    is ($relation->get_name, 'generalization', 'relation name');
    is ($relation->get_from, 'Left', 'from');
    is ($relation->get_to, 'Right', 'to');
};


subtest "<|.. realization" => sub {
    my $fixture = 'Left <|.. Right';

    my $relation = $CLASS->build($fixture);
    is ($relation->get_name, 'realization', 'relation name');
    is ($relation->get_from, 'Right', 'from');
    is ($relation->get_to, 'Left', 'to');
};

subtest "o-- aggregation" => sub {
    my $fixture = 'Left o-- Right';

    my $relation = $CLASS->build($fixture);
    is ($relation->get_name, 'aggregation', 'relation name');
    is ($relation->get_from, 'Right', 'from');
    is ($relation->get_to, 'Left', 'to');
};

subtest "--o aggregation" => sub {
    my $fixture = 'Left --o Right';

    my $relation = $CLASS->build($fixture);
    is ($relation->get_name, 'aggregation', 'relation name');
    is ($relation->get_from, 'Left', 'from');
    is ($relation->get_to, 'Right', 'to');
};

subtest "*-- composite" => sub {
    my $fixture = 'Left *-- Right';

    my $relation = $CLASS->build($fixture);
    is ($relation->get_name, 'composite', 'relation name');
    is ($relation->get_from, 'Right', 'from');
    is ($relation->get_to, 'Left', 'to');
};

subtest "--* composite" => sub {
    my $fixture = 'Left --* Right';

    my $relation = $CLASS->build($fixture);
    is ($relation->get_name, 'composite', 'relation name');
    is ($relation->get_from, 'Left', 'from');
    is ($relation->get_to, 'Right', 'to');
};

subtest "<-- association " => sub {
    my $fixture = 'Left <-- Right';

    my $relation = $CLASS->build($fixture);
    is ($relation->get_name, 'association', 'relation name');
    is ($relation->get_from, 'Right', 'from');
    is ($relation->get_to, 'Left', 'to');
};

subtest "extract class name" => sub {
    my $fixture = 'PlantUML::ClassDiagram <|-- PlantUML::ClassDiagram::Class';

    my $relation = $CLASS->build($fixture);
    is ($relation->get_name, 'generalization', 'relation name');
    is ($relation->get_from, 'PlantUML::ClassDiagram::Class', 'from');
    is ($relation->get_to, 'PlantUML::ClassDiagram', 'to');
};

subtest "with arrow direction" => sub {
    my $fixture = 'PlantUML::ClassDiagram <|-up- PlantUML::ClassDiagram::Class';

    my $relation = $CLASS->build($fixture);
    is ($relation->get_name, 'generalization', 'relation name');
    is ($relation->get_from, 'PlantUML::ClassDiagram::Class', 'from');
    is ($relation->get_to, 'PlantUML::ClassDiagram', 'to');
};

subtest "with arrow direction" => sub {
    my $fixture = 'PlantUML::ClassDiagram::Class::Method -down-|> PlantUML::ClassDiagram::Class::Base';

    my $relation = $CLASS->build($fixture);
    is ($relation->get_name, 'generalization', 'relation name');
    is ($relation->get_from, 'PlantUML::ClassDiagram::Class::Method', 'from');
    is ($relation->get_to, 'PlantUML::ClassDiagram::Class::Base', 'to');
};

done_testing;
