package RSS::Video::Google::Channel;

use strict;
use XML::Simple;

use RSS::Video::Google::Channel::Item;

use constant GENERATOR   => q{RSS::Video::Google};
use constant OPEN_SEARCH => q{http://a9.com/-/spec/opensearchrss/1.0/};
use constant VERSION     => q{2.0};
use constant MEDIA       => q{http://search.yahoo.com/mrss};
use constant XMLDECL     => q{<?xml version="1.0"?>};

use constant ROUTINES => [qw(
	new_item
	items_per_page
	total_results
	start_index
	link
	image
	description
	title
)];

our $VERSION = '0.01';

sub new {
	my $class = shift;
	my %args  = @_;
	my $self = bless {}, $class;
        foreach my $routine (keys %args) {
		if (grep(/^$routine$/, @{&ROUTINES})) {
			$self->$routine($args{$routine});
		}
	}
	return $self;
}

sub new_item {
        my $self = shift;
        my @args = @_;
        if (ref $args[0] eq 'HASH') {
                @args = %{$args[0]};
        }

        my $item = RSS::Video::Google::Channel::Item->new(@args);
        $self->add_item($item);
	return $item;
}

sub add_item {
        my $self = shift;
        my $item = shift;

        return $self->items($self->items, $item);
}

sub items {
	my $self     = shift;
	my @items = @_;
	if (@items) {
		$self->{items} = [@items];
	}
        $self->{items} ||= [];
	return @{$self->{items}};
}

sub generator {
	my $self = shift;
	$self->{generator} = shift if $_[0];
	return $self->{generator} || GENERATOR;
}

sub items_per_page {
	my $self = shift;
	$self->{items_per_page} = shift if $_[0];
	return $self->{items_per_page} || '';
}

sub total_results {
	my $self = shift;
	$self->{total_results} = shift if $_[0];
	return $self->{total_results} || '';
}

sub start_index {
	my $self = shift;
	$self->{start_index} = shift if $_[0];
	return $self->{start_index} || '';
}

sub link {
	my $self = shift;
	$self->{link} = shift if $_[0];
	return $self->{link} || '';
}

sub image {
	my $self = shift;
	$self->{image} = shift if $_[0];
	return $self->{image} || '';
}

sub description {
	my $self = shift;
	$self->{description} = shift if $_[0];
	return $self->{description} || '';
}

sub title {
	my $self = shift;
	$self->{title} = shift if $_[0];
	return $self->{title} || '';
}

sub hashref {
	my $self = shift;
	return {
		description               => [ $self->description ],
		title                     => [ $self->title ],
		item                      => [ map {$_->hashref} $self->items ],
		image                     => [ $self->image ],
		'openSearch:itemsPerPage' => [ $self->items_per_page ],
		'openSearch:totalResults' => [ $self->total_results ],
		'openSearch:startIndex'   => [ $self->start_index ],
		link                      => [ $self->link ],
		generator                 => [ $self->generator ],
	};
}

1;
__END__

=head1 NAME

RSS::Video::Google::Channel - A google channel. Most defaults alread set.

=head1 SYNOPSIS

  use RSS::Video::Google::Channel;
  
  ..but don't do this. Use RSS::Video::Google instead.

=head1 AUTHOR

Jeff Anderson, jeff@pvrcanada.com

=head1 SEE ALSO

RSS::Video::Google

=cut
