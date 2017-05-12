package Orx::Chyck;
use base qw(Oryx::Class);

our $schema = {
     attributes => [{name => 'namefirst', type=> 'String', }],
     associations => [{ role => 'skirt',  class => 'Orx::Skirt', type => 'Reference' }],
};

1;
