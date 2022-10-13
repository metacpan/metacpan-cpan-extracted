package PAUSE::Packages::Module;
$PAUSE::Packages::Module::VERSION = '0.18';
use 5.8.1;
use Moo 1.006;

has 'name'    => (is => 'ro');
has 'version' => (is => 'ro');

1;
