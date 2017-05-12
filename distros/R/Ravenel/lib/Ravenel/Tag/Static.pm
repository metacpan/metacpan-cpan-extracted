package Ravenel::Tag::Static;

use base 'Ravenel::Tag';
use fields qw(static_content);
use strict;
use Ravenel::Document;
use Data::Dumper;

sub new {
	my Ravenel::Tag::Static $self = shift;
	my $option                    = shift;

	unless ( ref($self) ) {
                $self = fields::new($self);

		$self->{'start_pos'}       = $option->{'start_pos'};
		$self->{'end_pos'}         = $option->{'end_pos'} if ( $option->{'end_pos'} );
		$self->{'parent_document'} = $option->{'parent_document'};
		$self->expand();
	}
	return $self;
}

sub expand {
	my Ravenel::Tag::Static $self = shift;
	if ( not $self->{'inner_block'} ) {
		$self->calculate_inner_block();
	}
	return $self->{'inner_block'};
}

sub calculate_inner_block {
        my Ravenel::Tag::Static $self = shift;

        my $content = $self->{'parent_document'}->{'document'};

	if ( $self->{'end_pos'} ) {
        	$self->{'inner_block'} = substr($content, $self->{'start_pos'}, $self->{'end_pos'} - $self->{'start_pos'});
	} else {
        	$self->{'inner_block'} = substr($content, $self->{'start_pos'});
	}
	return;
}

sub parent_tags_all_higher_depth { return 1; }

1;
