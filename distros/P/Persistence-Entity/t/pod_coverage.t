use strict;
use warnings;

use Test::Pod::Coverage tests => 17;

pod_coverage_ok("Persistence::Entity", "should have Persistence::Entity coverage");
pod_coverage_ok("Persistence::Entity::Query", "should have Persistence::Entity::Query coverage");
pod_coverage_ok("Persistence::Entity::Manager", "should have Persistence::Entity::Manager coverage");
pod_coverage_ok("Persistence::Meta::XML", "should have Persistence::Meta::XML coverage");
pod_coverage_ok("Persistence::Meta::Injection", "should have Persistence::Meta::Injection coverage");
pod_coverage_ok("Persistence::Relationship", "should have Persistence::Relationship coverage");
pod_coverage_ok("Persistence::Relationship::ManyToMany", "should have Persistence::Relationship::ManyToMany coverage");
pod_coverage_ok("Persistence::Relationship::OneToMany", "should have Persistence::Relationship::OneToMany coverage");
pod_coverage_ok("Persistence::Relationship::ToOne", "should have Persistence::Relationship::ToOne coverage");
pod_coverage_ok("Persistence::ORM", "should have Persistence::ORM coverage");
pod_coverage_ok("Persistence::LOB", "should have Persistence::LOB coverage");
pod_coverage_ok("Persistence::Fetchable", "should have Persistence::Fetchable coverage");
pod_coverage_ok("Persistence::Attribute", "should have Persistence::Attribute coverage");
pod_coverage_ok("Persistence::Attribute::AMCAdapter", "should have Persistence::Attribute::AMCAdapter coverage");
pod_coverage_ok("Persistence::ValueGenerator", "should have Persistence::ValueGenerator coverage");
pod_coverage_ok("Persistence::ValueGenerator::TableGenerator", "should have Persistence::ValueGenerator::TableGenerator");
pod_coverage_ok("Persistence::ValueGenerator::SequenceGenerator", "should have Persistence::ValueGenerator::SequenceGenerator");
