use warnings;
use strict;

use Test::Pod tests => 23;

pod_file_ok('lib/Persistence/Entity.pm', "should have POD for lib/Persistence/Entity.pm file");
pod_file_ok('lib/Persistence/Entity/Query.pm', "should have POD for lib/Persistence/Entity/Query.pm");
pod_file_ok('lib/Persistence/Entity/Manager.pm', "should have POD for lib/Persistence/Entity/Manager.pm");
pod_file_ok('lib/Persistence/Meta/XML.pm', "should have POD for lib/Persistence/Meta/XML.pm");
pod_file_ok('lib/Persistence/Meta/Injection.pm', "should have POD for lib/Persistence/Meta/Injection.pm");
pod_file_ok('lib/Persistence/Relationship/ManyToMany.pm', "should have POD for lib/Persistence/Relationship/ManyToMany.pm");
pod_file_ok('lib/Persistence/Relationship/OneToMany.pm', "should have POD for lib/Persistence/Relationship/OneToMany.pm");
pod_file_ok('lib/Persistence/Relationship/ToOne.pm', "should have POD for lib/Persistence/Relationship/ToOne.pm");
pod_file_ok('lib/Persistence/ValueGenerator.pm', "should have POD for lib/Persistence/ValueGenerator.pm");
pod_file_ok('lib/Persistence/Relationship.pm', "should have POD for lib/Persistence/Relationship.pm");
pod_file_ok('lib/Persistence/ORM.pm', "should have POD for lib/Persistence/ORM.pm");
pod_file_ok('lib/Persistence/LOB.pm', "should have POD for lib/Persistence/LOB.pm");
pod_file_ok('lib/Persistence/Fetchable.pm', "should have POD for lib/Persistence/Fetchable.pm");
pod_file_ok('lib/Persistence/Attribute.pm', "should have POD for lib/Persistence/Attribute.pm");
pod_file_ok('lib/Persistence/Attribute/AMCAdapter.pm', "should have POD for lib/Persistence/Attribute/AMCAdapter.pm");
pod_file_ok('lib/Persistence/ValueGenerator/TableGenerator.pm', "should have POD for lib/Persistence/ValueGenerator/TableGenerator.pm");
pod_file_ok('lib/Persistence/ValueGenerator/SequenceGenerator.pm', "should have POD for lib/Persistence/ValueGenerator/SequenceGenerator.pm");
pod_file_ok('lib/Persistence/Manual.pm', "should have POD for lib/Persistence/Manual.pm");
pod_file_ok('lib/Persistence/Manual/Introduction.pm', "should have POD for lib/Persistence/Manual/Introduction.pm");
pod_file_ok('lib/Persistence/Manual/EntityManager.pm', "should have POD for lib/Persistence/Manual/EntityManager.pm");
pod_file_ok('lib/Persistence/Manual/Relationship.pm', "should have POD for lib/Persistence/Manual/Relationship.pm");
pod_file_ok('lib/Persistence/Manual/LOB.pm', "should have POD for lib/Persistence/Manual/LOB.pm");
pod_file_ok('lib/Persistence/Manual/ValueGenerator.pm', "should have POD for lib/Persistence/Manual/ValueGenerator.pm");


