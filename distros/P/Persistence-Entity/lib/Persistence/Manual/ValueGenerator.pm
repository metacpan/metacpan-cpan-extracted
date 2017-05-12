use strict;
use warnings;

use vars qw($VERSION);

$VERSION = 0.01;

=head1 NAME

Persistence::Manual::ValueGenerator - The primary key value generator.

=head1 INTRODUCTION

This manual explains how to generate the primary key for your entity.

Use can use value generator that based on database table - L<Persistence::ValueGenerator::TableGenerator>
or you can use database sequenc - L<Persistence::ValueGenerator::SequenceGenerator>

At first stage toy have to generate value generator,
then at the second stage add generator association to entity definition.

=head1 VALUE_GENERATOR

Lets defined value generator to the following table:

   CREATE emp(empno number, ename varchar2(100), deptno number);

=head2 Table generator

   # for that instance you need to add the following table
   # CREATE TABLE seq_generator(pk_column VARCHAR2(30), value_column double)

   use Persistence::ValueGenerator::TableGenerator ':all';

   table_generator 'pk_generator' => (
        entity_manager_name      => $entity_manager_name,
        table                    => 'primary_key_generator',
        schema                   => '',
        primary_key_column_name  => 'pk_column',
        primary_key_column_value => 'empno',
        value_column             => 'value_column',
        allocation_size          =>  20,
   );

=over

=item table

Table name of the generator table.

=item primary_key_column_name

Name of the column that identifies the specific table primary key you are generating for.

=item primary_key_column_value

Used to match up with the primary key you are generating for.

=item value_column

Specifies the name of the column that will hold the counter for the generated primary key.

=item allocation_size

Defined how much the counter will be incremented when entity queries the table for a new value,
This feature is to cache subsequent sequence's values so that it doesn't have to go to the database every time it needs a new ID.

=back

=head2 Sequence generator

    # for that instance you need to add the following sequence
    #CREATE SEQUENCE emp_seq;

    use Persistence::ValueGenerator::SequenceGenerator ':all';

    sequence_generator 'emp_gen' => (
        entity_manager_name  => $entity_manager_name,
        sequence_name        => 'cust_seq',
        allocation_size      =>  1,
    );

=head1 ENTITY

After defining generator the only thing that need be done is to add value_generator property
to the entity definition. In our case we have to add hash ref where the key represents primary key
colunm, value - name of value generator.

    my $emp_entity = Persistence::Entity->new(
        name             => 'emp',
        alias            => 'ep',
        primary_key      => ['empno'],
        columns          => [
            sql_column(name => 'empno'),
            sql_column(name => 'ename', unique => 1),
        ],
        value_generators => {empno => 'emp_gen'},
    );

=cut

=head1 XML Mapping File

If you do not want to interact directly with value generator or Entity definition
you can alternatively use an XML mapping file to declare this metadata.

XML injection of the persistence metadata.

    use Persistence::Meta::XML;
    my $meta = Persistence::Meta::XML->new(persistence_dir => 'meta/');
    $meta->inject('persistence.xml');

XML definitions:

    persistence.xml
    <?xml version="1.0" encoding="UTF-8"?>
    <persistence name="test"  connection_name="test" >
        <entities>
            <entity_file  file="emp.xml"  />
        </entities>
        <value_generators>
            <sequence_generator name="emp_seq" sequence_name="emp_seq" allocation_size="1" />
            <table_generator name="pk_generator" table="seq_generator" primary_key_column_name="pk_column" primary_key_column_value="empno" value_column="value_column" allocation_size="20" />
        </value_generators>
    </persistence>

    emp.xml
    <?xml version="1.0" encoding="UTF-8"?>
    <entity name="emp" alias="e">
        <primary_key>empno</primary_key>
        <columns>
            <column name="empno" />
            <column name="ename" unique="1" />
        </columns>
        <value_generator column="empno">pk_generator</value_generator>
    </entity>

=cut

