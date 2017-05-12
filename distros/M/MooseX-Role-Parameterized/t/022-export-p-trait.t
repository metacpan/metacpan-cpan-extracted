use strict;
use warnings;
use Test::More 0.88;

BEGIN {
    package MyTrait::Label;
    use MooseX::Role::Parameterized;

    parameter default => (
        is  => 'rw',
        isa => 'Str',
    );

    role {
        my $p = shift;

        has label => (
            is      => 'rw',
            isa     => 'Str',
            default => $p->default,
        );
    };
};

BEGIN {
    package MyApp::MooseX::LabeledAttributes;
    use Moose::Exporter;
    $INC{'MyApp/MooseX/LabeledAttributes.pm'} = 1;

    Moose::Exporter->setup_import_methods(
        class_metaroles => {
            attribute => [ 'MyTrait::Label' => { default => 'no label' } ],
        },
    );
}

do {
    package MyClass::LabeledURL;
    use Moose;
    use MyApp::MooseX::LabeledAttributes;

    has name => (
        is => 'ro',
    );

    has url => (
        is    => 'ro',
        label => 'overridden',
    );

    no Moose;
    no MyApp::MooseX::LabeledAttributes;
};

my $meta = MyClass::LabeledURL->meta;
is($meta->get_attribute('name')->label, 'no label');
is($meta->get_attribute('url')->label, 'overridden');

done_testing;
