use strict;
use warnings;
package MooseExporter;

use Moose::Exporter;
use Moose::Role ();
use namespace::clean;

Moose::Exporter->setup_import_methods(also => 'Moose::Role');

use constant CAN => [ qw(import) ];
use constant CANT => [ qw(with) ];

1;
