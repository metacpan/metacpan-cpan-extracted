package MooseX::HasDefaults::RW;
use Moose ();
use Moose::Exporter;
use Moose::Util::MetaRole;

use MooseX::HasDefaults::Meta::IsRW;

Moose::Exporter->setup_import_methods(
    also => 'Moose',
    class_metaroles => {
        attribute => ['MooseX::HasDefaults::Meta::IsRW'],
    },
);

1;

