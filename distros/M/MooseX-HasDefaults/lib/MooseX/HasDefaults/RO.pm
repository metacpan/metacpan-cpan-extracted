package MooseX::HasDefaults::RO;
use Moose ();
use Moose::Exporter;
use Moose::Util::MetaRole;

use MooseX::HasDefaults::Meta::IsRO;

Moose::Exporter->setup_import_methods(
    also => 'Moose',
    class_metaroles => {
        attribute => ['MooseX::HasDefaults::Meta::IsRO'],
    },
);

1;

