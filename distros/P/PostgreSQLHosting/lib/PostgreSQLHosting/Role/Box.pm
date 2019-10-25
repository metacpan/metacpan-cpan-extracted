package PostgreSQLHosting::Role::Box;
use Moo::Role;
use strictures 2;

requires '_build_' . $_ for qw(private_ip public_ip _provider);
requires 'remove';

1;


