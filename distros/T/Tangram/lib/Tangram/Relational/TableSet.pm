package Tangram::Relational::TableSet;

use strict;
use Tangram::Schema;
use constant TABLES => 0;
use constant SORTED_TABLES => 1;
use constant KEY => 2;

sub new
  {
	my $class = shift;
	my %seen;
	my @tables = grep { !$seen{$_}++ } @_;
	my @sorted_tables = sort @tables;

	return bless [ \@tables, \@sorted_tables, "@sorted_tables" ], $class;
  }

sub key
  {
	return shift->[KEY];
  }

sub tables
  {
	@{ shift->[TABLES] }
  }

sub is_improper_superset
  {
	my ($self, $other) = @_;
	my %other_tables = map { $_ => 1 } $other->tables();

	for my $table ($self->tables()) {
	  delete $other_tables{$table};
	  return 1 if keys(%other_tables) == 0;
	}

	return 0;
  }

1;
