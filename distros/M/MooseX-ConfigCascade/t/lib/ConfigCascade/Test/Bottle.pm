package ConfigCascade::Test::Bottle;

use Moose;
with 'MooseX::ConfigCascade';

has label => (is => 'rw', isa => 'ConfigCascade::Test::Label', default => sub{
    ConfigCascade::Test::Label->new;
});
has glass_type => (is => 'rw', isa => 'Int', default => 5);


# these should be unaffected:
has top => (is => 'ro', isa => 'ConfigCascade::Test::BottleTop', default => sub { ConfigCascade::Test::BottleTop->new });
has style => (is => 'rw', isa => 'HashRef', default => sub{{ "design from package key" => "design from package value" }});



1;
