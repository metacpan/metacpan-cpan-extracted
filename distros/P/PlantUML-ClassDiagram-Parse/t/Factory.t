use strict;
use warnings;
use utf8;
use Test::More;
use PlantUML::ClassDiagram::Class::Factory;
my $CLASS = 'PlantUML::ClassDiagram::Class::Factory';

BEGIN { use_ok 'PlantUML::ClassDiagram::Class::Factory'};

my $fixtures = +[
    +{
        string => 'foo()',
        expect => 'PlantUML::ClassDiagram::Class::Method',
        description => 'normal method',
    },
    +{
        string => '{static} foo()',
        expect => 'PlantUML::ClassDiagram::Class::Method',
        description => 'static method',
    },
    +{
        string => '{abstract} foo()',
        expect => 'PlantUML::ClassDiagram::Class::Method',
        description => 'abstract method',
    },
    +{
        string => 'foo',
        expect => 'PlantUML::ClassDiagram::Class::Variable',
        description => 'normal variable',
    },
    +{
        string => '--',
        expect => undef,
        description => 'separator line',
    },
    +{
        string => '==',
        expect => undef,
        description => 'separator double line',
    },
    +{
        string => '__',
        expect => undef,
        description => 'separator under line',
    },
    +{
        string => '.. separate text ..',
        expect => undef,
        description => 'separator dots with text',
    },
    +{
        string => "'comment'",
        expect => undef,
        description => 'comment',
    },
];

subtest "create" => sub {
    for my $fixture (@$fixtures){
        my $got = $CLASS->create($fixture->{string});
        if (defined $fixture->{expect}) {
            isa_ok ($got, $fixture->{expect}, $fixture->{description});
        }
        else {
            is ($got, $fixture->{expect}, $fixture->{description});
        }
    }
};

done_testing;
