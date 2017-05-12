package Ravenel::Tag::Replace;

use base 'Ravenel::Tag';
use fields qw(sub_attribute);

use strict;
use Carp qw(cluck confess);
use Ravenel::Document;
use Data::Dumper;

sub new {
        my Ravenel::Tag::Replace $self = shift;
        my $option                     = shift;

	unless ( ref($self) ) {
		$self = fields::new($self);
		$self->SUPER::new($option);
	}
	$self->{'parent_document'} = $option->{'parent_document'};

	return $self;
}

sub expand {
	my Ravenel::Tag::Replace $self = shift;
	my Ravenel::Document $doc      = $self->{'parent_document'};

	# so, I'll need to change the action, and then call super
	$self->{'action'} = "Ravenel:Tag:Replace:render";
	$self->SUPER::expand();
	return;
}

sub _replace_block {
	my $ib     = shift;
	my $struct = shift;

	confess("Expected a hash, received: " . ref($struct)) if ( ref($struct) ne 'HASH' );

	foreach my $k ( keys(%{$struct}) ) {
		if ( ref($struct->{$k}) eq 'ARRAY' ) {
			my $hack_array = join(' ',  @{$struct->{$k}});
			$ib =~ s/\{$k\}/$hack_array/g;
		} elsif ( ref($struct->{$k}) eq 'HASH' ) {
			#my $hack_hash  = join(' ', map { $_, $struct->{$k}->{$_} } keys(%{$struct->{$k}}));
			$ib =~ s/\{$k}//g; # XXX for now, I don't think we should be delving into hashes
		} else {
			$ib =~ s/\{$k\}/$struct->{$k}/g;
		}
	}

	return $ib;
}

sub render {
        my $class                    = shift if ( $_[0] eq __PACKAGE__ );
        my Ravenel::Block $block_obj = shift;
        my $block                    = $block_obj->get_block();

	if ( my $b = $block_obj->get_block() ) {
		my $struct;
		if ( my $leaf = $block_obj->{'tag_arguments'}->{'leaf'} ) {
			my $name = $block_obj->{'tag_arguments'}->{'name'};
			confess("'leaf' attribute defined ($leaf) with no 'name' to go off of in replace tag!") if ( not $name );
			confess("'leaf' defined ($leaf), but value of 'name' ($name) is not a hash!") if ( ref($block_obj->{'arguments'}->{$name}) ne 'HASH' );

			$struct = $block_obj->{'arguments'}->{$name}->{$leaf};

		} elsif ( my $name = $block_obj->{'tag_arguments'}->{'name'} ) {
			if ( ref($block_obj->{'arguments'}) eq 'HASH' ) {
				$struct = $block_obj->{'arguments'}->{$name};
			} else {
				confess("You have a 'name' ($name) on your replace tag, but 'arguments' is a " . ref($block_obj->{'arguments'}) . " not a hash.");
			}
		} else {
			$struct = $block_obj->{'arguments'};
		}

		my $content = '';
		if ( ref($struct) eq 'ARRAY' ) {
			foreach my $s ( @{$struct} ) {
				$content .= &_replace_block($b, $s);
			}
		} elsif ( ref($struct) eq 'HASH' ) {
			$content .= &_replace_block($b, $struct);
		}

		return $content;
		
	} else {
		my $content = '';
		foreach my $f ( values(%{$block_obj->{'tag_arguments'}}) ) {
			if ( $block_obj->{'arguments'}->{$f} ) { # XXX refactor
				$content = $block_obj->{'arguments'}->{$f};
			}
		}
		return $content;
	}
	return;
}

1;
