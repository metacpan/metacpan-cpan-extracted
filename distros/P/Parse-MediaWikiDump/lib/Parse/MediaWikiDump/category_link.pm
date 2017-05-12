package Parse::MediaWikiDump::category_link;

our $VERSION = '1.0.3';

#you must pass in a fully populated link array reference
sub new {
	my ($class, $self) = @_;

	bless($self, $class);

	return $self;
}

sub from {
	my ($self) = @_;
	return $$self[0];
}

sub to {
	my ($self) = @_;
	return $$self[1];
}

sub sortkey {
	my ($self) = @_;
	return $$self[2];
}

sub timestamp {
	my ($self) = @_;
	return $$self[3];
}

1;