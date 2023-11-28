use strict;
use warnings;


package Neo4j_Test::Path;
sub isa { $_[1] eq 'Neo4j::Types::Path' }

sub elements {
	grep { defined }
	map { ( $_[0]->{n}[$_], $_[0]->{r}[$_] ) }
	( 0 .. @{$_[0]->{n}} - 1 )
}

sub nodes { @{shift->{n}} }
sub relationships { @{shift->{r}} }

sub new {
	my ($class, $params) = @_;
	my $elements = $params->{elements};
	my @n = grep {$_->isa('Neo4j::Types::Node')} @$elements;
	my @r = grep {$_->isa('Neo4j::Types::Relationship')} @$elements;
	bless { n => \@n, r => \@r }, $class;
}


1;
