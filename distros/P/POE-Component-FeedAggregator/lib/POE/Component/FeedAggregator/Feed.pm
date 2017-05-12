package POE::Component::FeedAggregator::Feed;
BEGIN {
  $POE::Component::FeedAggregator::Feed::AUTHORITY = 'cpan:GETTY';
}
BEGIN {
  $POE::Component::FeedAggregator::Feed::VERSION = '0.902';
}
# ABSTRACT: A Feed specification for POE::Component::FeedAggregator

use Moose;

has sender => (
	isa => 'POE::Session',
	is => 'ro',
	required => 1,
);

has url => (
	isa => 'Str',
	is => 'ro',
	required => 1,
);

has name => (
	isa => 'Str',
	is => 'ro',
	required => 1,
	default => sub {
		my $self = shift;
		my $name = $self->url;
		$name =~ s/\W/_/g;
		return $name;
	},
);

has ignore_first => (
	isa => 'Bool',
	is => 'ro',
	required => 1,
	default => sub { 1 },
);

has delay => (
	isa => 'Int',
	is => 'ro',
	required => 1,
	default => sub { 1200 },
);

has entry_event => (
	isa => 'Str',
	is => 'ro',
	required => 1,
	default => sub { 'new_feed_entry' },
);

has max_headlines => (
	isa => 'Int',
	is => 'ro',
	required => 1,
	default => sub { 100 },
);

1;
__END__
=pod

=head1 NAME

POE::Component::FeedAggregator::Feed - A Feed specification for POE::Component::FeedAggregator

=head1 VERSION

version 0.902

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by L<Raudssus Social Software|http://www.raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

