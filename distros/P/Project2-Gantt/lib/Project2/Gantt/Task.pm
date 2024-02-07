package Project2::Gantt::Task;

use Mojo::Base -base,-signatures;

use Time::Piece;

our $DATE = '2024-02-05'; # DATE
our $VERSION = '0.011';

has parent      => undef;
has start       => sub { _makeDate(shift) };
has end         => sub { _makeDate(shift) };
has description => undef;
has color       => undef;
has resources   => sub { [] };

sub new {
	my $self = shift->SUPER::new(@_);
	if ( not defined $self->description ) {
		die "Task must have description!";
	}
	if ( not defined $self->start and not defined $self->end ) {
		die "Must provide task dates!";
	}
	$self->start(_makeDate($self->start));
	$self->end(_makeDate($self->end));
	return $self;
}

sub _makeDate($date) {
	return $date if $date->isa('Time::Piece');
	my $add = "";
	$add = " 00:00:00" if $date !~ /\:/;
	my $fulldate = $date.$add;
	return Time::Piece->strptime($fulldate,'%Y-%m-%d %H:%M:%S');
}

sub addResource($self,$resource) {
	push @{$self->resources}, $resource;
}

sub _handleDates($self) {
	my $parent  = $self->parent;
	if ( not defined $parent->start or $parent->start > $self->start ) {
		$parent->start($self->start);
	}
	if( not defined $parent->end or $parent->end < $self->end ) {
		$parent->end($self->end);
	}
	$parent->_handleDates();
}

1;
