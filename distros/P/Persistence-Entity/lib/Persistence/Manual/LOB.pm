use strict;
use warnings;

use vars qw($VERSION);

$VERSION = 0.03;

=head1 NAME

Persistence::Manual::LOB - Large objects attributes persisitence.

=head1 INTRODUCTION

This manual explains how to create map between LOBs database column and object attributes.

=head1 ENTITY

At the first stage lets define entity that represents logical unit of data in the database.

    my $photo_entity = Persistence::Entity->new(
        name    => 'photo',
        alias   => 'ph',
        primary_key => ['id'],
        columns => [
            sql_column(name => 'id'),
            sql_column(name => 'name', unique => 1),
        ],
        lobs => [
            sql_lob(name => 'blob_content', size_column => 'doc_size'),
        ]
    );

LOBs column if defined by sql_lob method that takes
name - column name that stores a lob
size_column - column name that sotres the lob size.


=head1 OBJECT TO RELATIONAL DATABASE MAPPING

At the second state we have to define mapping between object and sql entity.
We are using lob method that teks LOB column name, attribute , fetch method as parameters.

    package Photo;

    use Abstract::Meta::Class ':all';
    use Persistence::ORM ':all';
    entity 'photo';

    column 'id'   => has('$.id');
    column 'name' => has('$.name');
    lob    'blob_content' => (attribute => has('$.image'), fetch_method => LAZY);

=over

=item XML Mapping File

If you do not want to interact directly with ORM or Entity meta protocol to declare map between your class and entity,
or entity and database you can alternatively use an XML mapping file to declare this metadata.

Perl class

    package Photo;
    use Abstract::Meta::Class ':all';
    has '$.id';
    has '$.name';
    has '$.image';

XML injection of the persistence metadata.

    use Persistence::Meta::XML;
    my $meta = Persistence::Meta::XML->new(persistence_dir => 'meta/');
    $meta->inject('persistence.xml');

XML definitions:

    persistence.xml
    <?xml version="1.0" encoding="UTF-8"?>
    <persistence name="test"  connection_name="test" >
        <entities>
            <entity_file  file="photo.xml"  />
        </entities>
        <mapping_rules>
            <orm_file file="Photo.xml" />
        </mapping_rules>
    </persistence>

    photo.xml
    <?xml version="1.0" encoding="UTF-8"?>
    <entity name="photo" alias="p">
        <primary_key>id</primary_key>
        <columns>
            <column name="id" />
            <column name="name" unique="1" />
        </columns>
        <lobs>
            <lob name="blob_content" size_column="doc_size" />
        </lobs>
    </entity>

    Photo.xml
    <?xml version="1.0" encoding="UTF-8"?>
    <orm entity="photo"  class="Photo" >
        <column name="id"  attribute="id" />
        <column name="name"  attribute="name" />
        <lob name="blob_content" attribute="image" fetch_method="LAZY" />
    </orm>

=back

=cut
