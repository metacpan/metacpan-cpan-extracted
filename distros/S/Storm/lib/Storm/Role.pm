package Storm::Role;
{
  $Storm::Role::VERSION = '0.240';
}

use Moose;
use Moose::Exporter;
use Moose::Util::MetaRole;

use Storm::Meta::Attribute::Trait::AutoIncrement;
use Storm::Meta::Attribute::Trait::NoStorm;
use Storm::Meta::Attribute::Trait::ForeignKey;
use Storm::Meta::Attribute::Trait::PrimaryKey;
use Storm::Meta::Attribute::Trait::StormArray;

use Storm::Meta::Column;
use Storm::Meta::Table;

use Storm::Role::Object;
use Storm::Role::Object::Meta::Class;
use Storm::Role::Object::Meta::Attribute;

Moose::Exporter->setup_import_methods(
    also => 'Moose::Role',
    role_metaroles => {
        applied_attribute => [ 'Storm::Role::Object::Meta::Attribute' ],
    }
);

1;

