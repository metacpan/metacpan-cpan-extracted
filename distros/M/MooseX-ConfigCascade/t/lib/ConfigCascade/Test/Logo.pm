package ConfigCascade::Test::Logo;

use Moose;
with 'MooseX::ConfigCascade';


has company_name => (is => 'rw', isa => 'Str', default => 'company_name from package');
has slogan => (is => 'ro', isa => 'Str', default => 'slogan from package');
has colors => (is => 'rw', isa => 'HashRef', default => sub{{ "colors from package key" => "colors from package value" }});

# these should be unaffected:
has designers => (is => 'rw', isa => 'ArrayRef', default => sub{[ "designers from package value" ]});
has width => (is => 'rw', isa => 'Num', default => 20.2);
has height => (is => 'rw', isa => 'Int', default => 10);


1;



    
