package ConfigCascade::Test::Book;

use Moose;
with 'MooseX::ConfigCascade';

has pages => (is => 'ro', isa => 'ArrayRef');


1;
