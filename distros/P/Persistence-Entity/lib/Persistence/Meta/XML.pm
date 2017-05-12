package Persistence::Meta::XML;

use strict;
use warnings;
use vars qw($VERSION);

use Abstract::Meta::Class ':all';
use Carp 'confess';
use Persistence::Entity::Manager;
use Persistence::Entity ':all';
use Persistence::ORM;
use Persistence::Meta::Injection;
use Persistence::Relationship;
use Persistence::Relationship::ToOne;
use Persistence::Relationship::OneToMany;
use Persistence::Relationship::ManyToMany;
use SQL::Entity::Condition;
use Simple::SAX::Serializer;
use Simple::SAX::Serializer::Handler ':all';


$VERSION = 0.04;

=head1 NAME

Persistence::Meta::XML - Persistence meta object xml injection

=cut

=head1 SYNOPSIS

   use Persistence::Meta::XML;
   my $meta = Persistence::Meta::XML->new(persistence_dir => 'meta/');
   my $entity_manager = $meta->inject('my_persistence.xml');
   #or
   # $meta->inject('my_persistence.xml');
   # my $entity_manager = Persistence::Entity::Manager->manager('manager_name');


=head1 DESCRIPTION

Loads xml files that containt meta persistence definition.

    persistence.xml
    <?xml version="1.0" encoding="UTF-8"?>
    <persistence name="test"  connection_name="test" >
        <entities>
            <entity_file  file="emp.xml"  />
            <entity_file  file="dept.xml" />
        </entities>
        <mapping_rules>
            <orm_file file="Employee.xml" />
            <orm_file file="Department.xml" />
        </mapping_rules>
    </persistence>

    emp.xml
    <?xml version="1.0" encoding="UTF-8"?>
    <entity name="emp" alias="e">
        <primary_key>empno</primary_key>
        <columns>
            <column name="empno" />
            <column name="ename" unique="1" />
            <column name="sal" />
            <column name="job" />
            <column name="deptno" />
        </columns>
        <subquery_columns>
            <subquery_column name="dname" entity="dept" />
        </subquery_columns>
    </entity>

    dept.xml
    <?xml version="1.0" encoding="UTF-8"?>
    <entity name="dept" alias="d">
        <primary_key>deptno</primary_key>
        <columns>
            <column name="deptno" />
            <column name="dname"  unique="1" />
            <column name="loc" />
        </columns>
        <to_many_relationships>
            <relationship target_entity="emp" order_by="deptno, empno">
                <join_column>deptno</join_column>
            </relationship>
        </to_many_relationships>
    </entity>

    Employee.xml
    <?xml version="1.0" encoding="UTF-8"?>
    <orm entity="emp"  class="Employee" >
        <column name="empno"  attribute="id" />
        <column name="ename"  attribute="name" />
        <column name="job"    attribute="job" />
        <column name="dname"  attribute="dept_name" />
        <to_one_relationship  name="dept" attribute="dept" fetch_method="EAGER" cascade="ALL"/>
    </orm>

    Department.xml
    <?xml version="1.0" encoding="UTF-8"?>
    <orm entity="dept"  class="Department" >
        <column name="deptno" attribute="id" />
        <column name="dname" attribute="name" />
        <column name="loc" attribute="location" />
        <one_to_many_relationship  name="emp" attribute="employees" fetch_method="EAGER" cascade="ALL"/>
    </orm>


    package Employee;
    use Abstract::Meta::Class ':all';

    has '$.id';
    has '$.name';
    has '$.job';
    has '$.dept_name';
    has '$.dept' => (associated_class => 'Department');

    package Department;
    use Abstract::Meta::Class ':all';

    has '$.id';
    has '$.name';
    has '$.location';
    has '@.employees' => (associated_class => 'Employee');

    my $meta = Persistence::Meta::XML->new(persistence_dir => $dir);
    my $entity_manager = $meta->inject('persistence.xml');

    my ($dept) = $entity_manager->find(dept => 'Department', name => 'dept3');

    my $enp = Employee->new(id => 88, name => 'emp88');
    $enp->set_dept(Department->new(id => 99, name => 'd99'));
    $entity_manager->insert($enp);

=head1 EXPORT

None

=head2 ATTRIBUTES

=over

=item cache_dir

Containts cache directory.

=cut

has '$.cache_dir';


=item use_cache

Flag that indicates if cache is used.

=cut

has '$.use_cache' => (default => 0);


=item persistence_dir

Directory for xml meta persistence definition.

=cut

has '$.persistence_dir';


=item persistence_dir

Contains directory of xml files that contain persistence object definition.

=cut


=item injection

=cut

has '$.injection';


=back

=head2 METHODS

=over

=item initialise

=cut

sub initialise {
    my ($self) = @_;
    $self->set_cache_dir($self->persistence_dir)
        if ($self->use_cache && ! $self->cache_dir);
}


=item inject

Injects persistence xml definition.
Takes xml file definition


    my $meta = Persistence::Meta::XML->new(persistence_dir => $dir);
    my $entity_manager = $meta->inject('persistence.xml');


=cut

sub inject {
    my ($self, $file) = @_;
    my $injection;
    my $prefix_dir = $self->persistence_dir;
    my $file_name = $prefix_dir . $file;
    if($self->use_cache) {
        my $cached_injection = Persistence::Meta::Injection->load_from_cache($self, $file_name);
        $injection = $cached_injection
            if $cached_injection && $cached_injection->can_use_cache;
    }

    $injection ||= Persistence::Meta::Injection->new;
    $self->set_injection($injection);
    unless ($injection->cached_version) {
        $injection->add_file_stat($file_name);
        my $xml = $self->persistence_xml_handler;
        $xml->parse_file($prefix_dir . $file);
    }
    $self->injection->load_persistence_context($self, $file);
}


=item persistence_xml_handler

Retunds xml handlers that will transform the persistence xml into objects.
Persistence node is mapped to the Persistence::Entity::Manager;

    <!ELEMENT persistence (entities+,mapping_rules*, value_generators*)>
    <!ATTLIST persistence name #REQUIRED>
    <!ATTLIST persistence connection_name #REQUIRED>
    <!ELEMENT entities (entity_file+)>
    <!ELEMENT entity_file (filter_condition_value+ .dml_filter_value) >
    <!ATTLIST entity_file file id order_index>
    <!ELEMENT mapping_rules (orm_file+)>
    <!ATTLIST mapping_rules file>
    <!ELEMENT value_generators (sequence_generator*, table_generator*)>
    <!ELEMENT sequence_generator>
    <!ATTLIST sequence_generator name sequence_name allocation_size>
    <!ELEMENT table_generator>
    <!ATTLIST table_generator name table primary_key_column_name primary_key_column_value value_column allocation_size>

    <?xml version='1.0' encoding='UTF-8'?>
    <persistence name="test"  connection_name="test" >
        <entities>
            <entity_file file="emp.xml"  />
            <entity_file file="dept.xml"  />
        </entities>
        <mapping_rules>
            <orm_file file="Employee" />
        </mapping_rules>
        <value_generators>
            <sequence_generator name="pk_generator" sequence_name="cust_seq" allocation_size="1" />
            <table_generator name="pk_generator" table="primary_key_generator" primary_key_column_name="pk_column" primary_key_column_value="empno" value_column="alue_column" allocation_size="20" />
        </value_generators>
    </persistence>



=cut

sub persistence_xml_handler {
    my ($self) = @_;
    my $xml = Simple::SAX::Serializer->new;
    $self->add_xml_persistence_handlers($xml);
    $xml;
}


=item add_xml_persistence_handlers

Adds persistence xml handlers/
Takes Simple::SAX::Serializer object as parameter.

=cut

sub add_xml_persistence_handlers {
    my ($self, $xml) = @_;
    my $temp_data = {};
    $xml->handler('persistence', root_object_handler('Persistence::Entity::Manager' , sub {
        my ($result) = @_;
        my $injection = $self->injection;
        $injection->set_entity_manager($result);
        $injection->set_orm_files(\@{$temp_data->{orm}});
        $injection->set_entities_files(\@{$temp_data->{entities}});
        $injection->set_sequence_generators(\@{$temp_data->{sequence_generators}});
        $injection->set_table_generators(\@{$temp_data->{table_generators}});
        delete $temp_data->{$_} for qw(entities orm sequence_generators table_generators);
        $result;
    })),

    $xml->handler('entities', ignore_node_handler());
    $xml->handler('value_generators', ignore_node_handler());
    $xml->handler('to_many_relationships', ignore_node_handler());
    $xml->handler('entity_file', custom_array_handler($temp_data, undef, undef, 'entities'));
    $xml->handler('filter_condition_values', hash_handler());
    $xml->handler('dml_filter_values', hash_handler());
    $xml->handler('mapping_rules', ignore_node_handler());
    $xml->handler('orm_file', custom_array_handler($temp_data, undef, undef, 'orm'));
    $xml->handler('sequence_generator', custom_array_handler($temp_data, undef, undef, 'sequence_generators'));
    $xml->handler('table_generator', custom_array_handler($temp_data, undef, undef, 'table_generators'));
}


=item orm_xml_handler

    <!ELEMENT orm (column+, lob+, to_one_relationship*, one_to_many_relationship*, many_to_many_relationship*)
    <!ATTRLIST orm class entity mop_attribute_adapter>
    <!ELEMENT column>
    <!ATTRLIST column name attribute>
    <!ELEMENT lob name attribute fetch_method>
    <!ELEMENT to_one_relationship>
    <!ATTRLIST to_one_relationship name attribute #REQUIRED>
    <!ATTRLIST to_one_relationship fetch_method (LAZY|EAGER) "LAZY">
    <!ATTRLIST to_one_relationship cascade (NONE|ALL|ON_INSERT|ON_UPDATE|ON_DELETE) "NONE">

    <orm entity="emp"  class="Employee" >
        <column name="empno" attribute="id" />
        <column name="ename" attribute="name" />
        <column name="job" attribute="job" />
        <to_one_relationship name="dept" attribute="depts" fetch_method="LAZY" cascade="ALL">
    </orm>

    many_to_many 'project' => (
        attribute        => has('%.projects' => (associated_class => 'Project'), index_by => 'name'),
        join_entity_name => 'emp_project',
        fetch_method     => LAZY,
        cascade          => ALL,
    );


=item orm_xml_handler

Retunds xml handlers that will transform the orm xml into Persistence::ORM object

=cut

sub orm_xml_handler {
    my ($self) = @_;
    my $xml = Simple::SAX::Serializer->new;
    $self->add_orm_xml_handlers($xml);
    $xml;
}


=item add_orm_xml_handlers

Adds orm xml handler to Simple::SAX::Serializer object.

=cut

sub add_orm_xml_handlers {
    my ($self, $xml) = @_;
    my $temp_data = {};
    $xml->handler('orm', sub {
        my ($this, $element, $parent) = @_;
        my $injection = $self->injection;
        my $orm_mapping = $injection->_orm_mapping;
        my $attributes = $element->attributes;
        my $children_result = $element->children_result || {};
        push @$orm_mapping, {%$attributes}, {%$children_result};
    });
    $xml->handler('column', hash_of_array_handler(undef, undef, 'columns'));
    $xml->handler('lob', hash_of_array_handler(undef, undef, 'lobs'));
    $xml->handler('to_one_relationship', hash_of_array_handler(undef, undef, 'to_one_relationships'));
    $xml->handler('one_to_many_relationship', hash_of_array_handler(undef, undef, 'one_to_many_relationships'));
    $xml->handler('many_to_many_relationship', hash_of_array_handler(undef, undef, 'many_to_many_relationships'));
}


=item entity_xml_handler

Retunds xml handlers that will transform the enity xml into Persistence::Entity

    <!ELEMENT entity (primary_key*, indexes?, columns?, lobs?, subquery_columns?,
    filter_condition_value+ .dml_filter_value+, to_one_relationships? to_many_relationships?, value_generators*)>
    <!ATTLIST entity id name alias unique_expression query_from schema order_index>
    <!ELEMENT primary_key (#PCDATA)>
    <!ELEMENT indexes (index+)>
    <!ELEMENT index (index_columns+)>
    <!ATTLIST index name hint>
    <!ELEMENT index_columns (#PCDATA)>
    <!ELEMENT columns (column+) >
    <!ELEMENT lobs (lob+) >
    <!ELEMENT subquery_columns (subquery_column+)>
    <!ELEMENT subquery_column>
    <!ATTLIST subquery_column entity name>
    <!ELEMENT column>
    <!ATTLIST column id name unique expression case_sensitive queryable insertable updatable>
    <!ELEMENT lob>
    <!ATTLIST lob id name siz_column>
    <!ELEMENT filter_condition_values (#PCDATA)>
    <!ATTLIST filter_condition_values name #REQUIRED>
    <!ELEMENT dml_filter_values (#PCDATA)>
    <!ATTLIST dml_filter_values name #REQUIRED>
    <!ELEMENT to_one_relationships (relationship+)>
    <!ELEMENT to_many_relationships (relationship+)>
    <!ELEMENT relationship (join_columns*, condition?)>
    <!ATTLIST relationship  name target_entity order_by>
    <!ELEMENT join_columns (#PCDATA)>
    <!ELEMENT condition (condition+) >
    <!ATTLIST condition operand1  operator operand2 relation>
    <!ELEMENT value_generators (#PCDATA)>

    For instnace.
    <?xml version="1.0" encoding="UTF-8"?>
    <entity name="emp" alias="e">
        <primary_key>empno</primary_key>
        <indexes>
            <index name="emp_idx_empno" hint="INDEX_ASC(e emp_idx_empno)">
                <index_column>ename</index_column>
            </index>
            <index name="emp_idx_ename">
                <index_column>empno</index_column>
            </index>
        </indexes>
        <columns>
            <column name="empno" />
            <column name="ename" />
        </columns>
        <lobs>
            <lob name="blob_content" size_column="doc_size" />
         </lobs>
        <subquery_columns>
            <subquery_column name="dname" entity_id="dept" />
        </subquery_columns>
        <to_one_relationships>
            <relationship target_entity="dept">
                <join_column>deptno</join_column>
            </relationship>
        </to_one_relationships>
    </entity>

=cut

sub entity_xml_handler {
    my ($self) = @_;
    my $xml = Simple::SAX::Serializer->new;
    $self->add_entity_xml_handlers($xml);
    $xml;
}


=item add_entity_xml_handlers

Adds entity xml handler to the Simple::SAX::Serializer object.

=cut

sub add_entity_xml_handlers {
    my ($self, $xml) = @_;
    my $temp_data = {};
    $xml->handler('entity', root_object_handler('Persistence::Entity' , sub {
        my ($result) = @_;
        my $id = $result->id;
        my $injection = $self->injection;
        my $entities_subquery_columns = $injection->_entities_subquery_columns;
        my $entities_to_many_relationships = $injection->_entities_to_many_relationships;
        my $entities_to_one_relationships = $injection->_entities_to_one_relationships;
        $entities_subquery_columns->{$id} = \@{$temp_data->{subquery_columns}};
        $entities_to_many_relationships->{$id} = \@{$temp_data->{to_many_relationships}};
        $entities_to_one_relationships->{$id} = \@{$temp_data->{to_one_relationships}};
        delete $temp_data->{$_} for qw(subquery_columns to_many_relationships to_one_relationships);
        $result;
    })),
    $xml->handler('columns', hash_item_of_child_value_handler());
    $xml->handler('columns/column', array_of_objects_handler(\&sql_column));
    $xml->handler('lobs', hash_item_of_child_value_handler());
    $xml->handler('lobs/lob', array_of_objects_handler(\&sql_lob));
    $xml->handler('indexes', hash_item_of_child_value_handler());
    $xml->handler('index', array_of_objects_handler(\&sql_index));
    $xml->handler('index_column', array_handler('columns'));
    $xml->handler('primary_key', array_handler());
    $xml->handler('value_generator', hash_handler('value_generators', 'column'));
    $xml->handler('filter_condition_values', hash_handler());
    $xml->handler('dml_filter_values', hash_handler());
    $xml->handler('subquery_columns', ignore_node_handler());
    $xml->handler('subquery_column', custom_array_handler($temp_data, undef, undef, 'subquery_columns'));
    $xml->handler('to_one_relationships', ignore_node_handler());
    $xml->handler('to_many_relationships', ignore_node_handler());
    $xml->handler('to_many_relationships/relationship', custom_array_handler($temp_data, undef, undef, 'to_many_relationships'));
    $xml->handler('to_one_relationships/relationship', custom_array_handler($temp_data, undef, undef, 'to_one_relationships'));
    $xml->handler('join_column', array_handler('join_columns'));
    $xml->handler('condition', object_handler('SQL::Entity::Condition'));
    $xml->handler('condition/condition', hash_of_object_array_handler('SQL::Entity::Condition', undef, undef, 'conditions'));
}


=item cache_file_name

Returns fulle path to cache file, takes persistence file name.

=cut

sub cache_file_name {
    my ($self, $file) = @_;
    my ($file_name) = $file =~ /([\w]+)\.xml$/i;
    $self->cache_dir . $file_name .'.cache';
}


1;

__END__

=back

=head1 TOO DO

Add caching of xml.

=head1 SEE ALSO

L<Simple::SAX::Handler>

=head1 COPYRIGHT AND LICENSE

The Persistence::Meta::Xml module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas,adrian@webapp.strefa.pl

=cut
