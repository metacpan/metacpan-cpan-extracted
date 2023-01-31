
package PRANG::Cookbook::Location;
$PRANG::Cookbook::Location::VERSION = '0.21';
use Moose;
use PRANG::Graph;
use PRANG::Cookbook::Role::Location;

with 'PRANG::Cookbook::Role::Location', 'PRANG::Cookbook::Node';

1;
