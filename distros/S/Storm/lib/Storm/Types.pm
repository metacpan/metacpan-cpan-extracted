package Storm::Types;
{
  $Storm::Types::VERSION = '0.240';
}
use MooseX::Types -declare => [qw(
    DBIStatementHandle
    MooseAttribute
    MooseMetaTypeConstraint
    SchemaColumn
    SchemaTable
    Storm
    StormAeolus
    StormArrayRef
    StormDeleteQuery
    StormEnabledClassName
    StormEnabledObject
    StormForeignKeyConstraintValue
    StormInsertQuery
    StormLiveObjects
    StormLiveObjectScope
    StormLookupQuery
    StormMetaRelationship
    StormObjectTypeConstraint
    StormPolicyObject
    StormSelectQuery
    StormSource
    StormSourceManager
    StormSQLWhereBoolean
    StormUpdateQuery
)];

use MooseX::Types::Moose qw( ArrayRef ClassName HashRef Object Str );

class_type DBIStatementHandle,
    { class => 'DBI::st' };
    
class_type MooseAttribute,
    { class => 'Moose::Meta::Attribute' };

class_type MooseMetaTypeConstraint,
    { class => 'Moose::Type::TypeConstraint' };

class_type SchemaColumn,
    { class => 'Storm::Meta::Column' };
    
coerce SchemaColumn,
    from Str,
    via { Storm::Meta::Column->new(name => $_) };

coerce SchemaColumn,
    from HashRef,
    via { Storm::Meta::Column->new( %$_ ) };

    
class_type SchemaTable,
    { class => 'Storm::Meta::Table' };
    
coerce SchemaTable,
    from Str,
    via { Storm::Meta::Table->new( name => $_ ) };
    
    
class_type Storm,
    { class => 'Storm' };

coerce Storm,
    from HashRef,
    via { Storm->new( %$_ ) };

coerce Storm,
    from ArrayRef,
    via { Storm->new( source => $_->[0], policy => $_->[1] ) };

class_type StormAeolus,
    { class => 'Storm::Aeolus' };
    
subtype StormArrayRef,
    as ArrayRef;
    
class_type StormDeleteQuery,
    { class => 'Storm::Query::Delete' };

subtype StormEnabledClassName,
    as ClassName,
    where { $_->can('meta') && $_->meta->does_role('Storm::Role::Object') };

subtype StormEnabledObject,
    as Object,
    where { $_->can('meta') && $_->meta->does_role('Storm::Role::Object') };
    
class_type StormInsertQuery,
    { class => 'Storm::Query::Insert' };
    
class_type StormLiveObjects,
    { class => 'Storm::LiveObjects' };
    
class_type StormLiveObjectScope,
    { class => 'Storm::LiveObjects::Scope' };

class_type StormMetaRelationship,
    { class => 'Storm::Meta::Relationship' };

class_type StormLookupQuery,
    { class => 'Storm::Query::Lookup' };
    
type StormObjectTypeConstraint,
    where {
        $_->can( 'class' ) &&
        $_->class &&
        $_->class->can( 'meta' ) &&
        $_->class->meta->does_role( 'Storm::Role::Object' )
    };
    
class_type StormPolicyObject,
    { class => 'Storm::Policy::Object' };
    
coerce StormPolicyObject,
    from ClassName,
    via { $_->Policy };

class_type StormSelectQuery,
    { class => 'Storm::Query::Select' };

class_type StormSource,
    { class => 'Storm::Source' };

coerce StormSource,
    from Str,
    via { Storm::Source->new( $_) };

coerce StormSource,
    from ArrayRef,
    via { Storm::Source->new( @$_) };

class_type StormSourceManager,
    { class => 'Storm::Source::Manager' };
    
subtype StormSQLWhereBoolean,
    as Str,
    where { return $_ =~ /^(?:and|not|or|xor)$/ };

subtype StormForeignKeyConstraintValue,
    as Str,
    where { return $_ =~ /^(?:CASCADE|RESTRICT|NO ACTION|SET NULL)$/i};

class_type StormUpdateQuery,
    { class => 'Storm::Query::Update' };



1;
