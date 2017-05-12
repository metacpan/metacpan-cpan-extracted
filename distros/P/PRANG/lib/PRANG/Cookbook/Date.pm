
package PRANG::Cookbook::Date;
$PRANG::Cookbook::Date::VERSION = '0.18';
use Moose;
use PRANG::Graph;
use PRANG::Cookbook::Role::Date;

with 'PRANG::Cookbook::Role::Date', 'PRANG::Cookbook::Node';

1;
