package Test::Siebel::Srvrmgr::Daemon::Action::Check::Component;

use Moose;
use namespace::autoclean;

# this role demands to define the methods below
with 'Siebel::Srvrmgr::Daemon::Action::Check::Component';

__PACKAGE__->meta->make_immutable;
