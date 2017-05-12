package Zoo::Resource::Animal;
use Moose;
with 'Sloth::Resource';

has '+path' => ( default => '/animal/:name/' );

1;
