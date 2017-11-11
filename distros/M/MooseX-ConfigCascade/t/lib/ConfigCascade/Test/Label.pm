package ConfigCascade::Test::Label;

use Moose;
with 'MooseX::ConfigCascade';

has logo => (is => 'rw', isa => 'ConfigCascade::Test::Logo', default => sub {
    ConfigCascade::Test::Logo->new;
});
has manufacturer => (is => 'ro', isa => 'Str', default => 'manufacturer from package');


# these should be unaffected:
has glue_type => (is => 'rw', isa => 'Int', default => 3);
has suppliers => (is => 'rw', isa => 'ArrayRef', default => sub {[ 'suppliers from package' ]});


1;
