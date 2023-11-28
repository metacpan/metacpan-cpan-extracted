#!perl
use strict;
use warnings;
use lib qw(lib t/lib);

use Test::More 0.88;
use Test::Neo4j::Types;
use Test::Warnings 0.010 qw(:no_end_test);
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';

use Neo4j_Test::Node;
use Neo4j_Test::Rel;
use Neo4j_Test::Path;


# Verify that the testing tools accept correct implementations of
# Neo4j structural types.

plan tests => 3 + 2 + $no_warnings;


# The Neo4j_Test packages are simple Neo4j::Types implementations.
# They intentionally use slightly unusual data structures in order
# to confirm that the internals of the testing tool don't depend
# on details like that.

neo4j_node_ok 'Neo4j_Test::Node', \&Neo4j_Test::Node::new, 'simple node';

neo4j_relationship_ok 'Neo4j_Test::Rel', \&Neo4j_Test::Rel::new, 'simple rel';

neo4j_path_ok 'Neo4j_Test::Path', \&Neo4j_Test::Path::new, 'simple path';


# These 'extended' packages add the optional element ID methods.

neo4j_node_ok 'Neo4j_Test::NodeExt', \&Neo4j_Test::NodeExt::new, 'Neo4j 5 node';

neo4j_relationship_ok 'Neo4j_Test::RelExt', \&Neo4j_Test::RelExt::new, 'Neo4j 5 rel';


done_testing;


package Neo4j_Test::NodeExt;
use parent 'Neo4j_Test::Node';

sub element_id {
	my $self = shift;
	return $self->[3] if defined $self->[3];
	warnings::warnif 'Neo4j::Types', 'eid unavailable';
	return $self->id;
}
sub new {
	my $self = shift->SUPER::new(@_);
	push @$self, pop->{element_id};
	return $self;
}


package Neo4j_Test::RelExt;
use parent 'Neo4j_Test::Rel';

sub element_id {
	my $self = shift;
	return $self->[5] if defined $self->[5];
	warnings::warnif 'Neo4j::Types', 'eid unavailable';
	return $self->id;
}
sub start_element_id {
	my $self = shift;
	return $self->[6] if defined $self->[6];
	warnings::warnif 'Neo4j::Types', 'start eid unavailable';
	return $self->start_id;
}
sub end_element_id {
	my $self = shift;
	return $self->[7] if defined $self->[7];
	warnings::warnif 'Neo4j::Types', 'end eid unavailable';
	return $self->end_id;
}
sub new {
	my ($class, $params) = @_;
	my $self = $class->SUPER::new($params);
	push @$self, (
		$params->{element_id},
		$params->{start_element_id},
		$params->{end_element_id},
	);
	return $self;
}
