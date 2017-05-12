package Ravenel::Block;

=head1 Ravenel::Block content within a tag

  <r:example_tag color="blue" length="25">
    <p>Default content {color} {length}</p>
    <block id="lucky_day"/>
    <p>It's your lucky day! {color} {length} {color}</p>
  </r:example_tag>

=head2 Quick overview..

This object is what is passed to a rendering routine that encompasses all of the various parsings that the engine has made to get you to this point.  
All of the methods of this object will let you retrieve different portions of a block, and provide an interface to manipulating them.
The one thing you need to be aware of is the special tag "block" that allows you to create a boundary (similar to one that you would use in a checkout line in a grocery story).  This block tag is totally non html compliant.  There is no open or close of a block tag.  I just made it a singleton.  Sorry.  The content that occurs up to the first block tag is the "default" block.  Any method called with no arguments will simply call the default one (keep the simple stuff simple).

=head1 Methods

=head2 get_block

This will return the text that your function will deal with.  In the example above....

    "<p>Default content {color} {length}</p>" = $block_obj->get_block();

While:

    "<p>It's your lucky day! {color} {length} {color}</p>" = $block_obj->get_block('lucky_day');

=head2 get_arguments

These are the arguments passed in to Ravenel::Document.  Keep in mind that altering this structure is a change that will carry forth for the rest of the document.
This adds a fun new angle to the "depth" attribute I talked about back at the beginning (muahah).  For a really trivial example of this check out test24_static.

=head2 get_tag_arguments

These are the arguments to the tag itself, in our example's case...

  { 'color' => 'blue', 'length' => 25 } = $block_obj->get_tag_arguments();

=head2 format

So, let's get a new example first

  <r:example_tag color="blue" length="25" format>
    <p>Default content {color} {length}</p>
    <block id="lucky_day"/>
    <p>It's your lucky day! {color} {length} {color}</p>
  </r:example_tag>

Format will do all your replacements within a block.  For now, things to be replaced are outlined with curly braces.  In the future I might make this user definable.  Here we go.

      '<p>Default content blue 25</p>'           = $block_obj->format( $block_obj->get_tag_arguments() );
      '<p>It's your lucky day! blue 25 blue</p>' = $block_obj->format( $block_obj->get_tag_arguments(), 'lucky_day' );

=head2 get_format_arguments (this is an internal function, that format calls, but I thought I'd mention it)

A tag with "format" as a tag argument will modify the block and generate "format arguments".  It takes an argument, like getting a block.

  [ 'color', 'length' ] = $block_obj->get_format_arguments();

  [ 'color', 'length', 'color' ] = $block_obj->get_format_arguments('lucky_day');

=cut

use strict;
use Data::Dumper;
use fields qw(
	arguments tag_arguments format_arguments
	blocks_by_name content_type 
);

sub new {
	my Ravenel::Block $self = shift;
	my $options             = shift;

	unless ( ref($self) ) {
		$self = fields::new($self);

		if ( ref($options->{'blocks_by_name'}) eq 'HASH' ) {
			$self->{'blocks_by_name'} = $options->{'blocks_by_name'};
		} else {
			$self->{'blocks_by_name'} = {
				'default' => $options->{'blocks_by_name'},
			};
		}
		$self->{'tag_arguments'}    = $options->{'tag_arguments'};
		$self->{'format_arguments'} = $options->{'format_arguments'};
		$self->{'arguments'}        = $options->{'arguments'};
	}
	return $self;
}

sub get_block {
	my Ravenel::Block $self = shift;
	my $block_id            = shift || 'default';

	return $self->{'blocks_by_name'}->{$block_id};
}

sub get_arguments {
	my Ravenel::Block $self = shift;
	return $self->{'arguments'};
}

sub get_tag_arguments {
	my Ravenel::Block $self = shift;
	return $self->{'tag_arguments'};
}

sub get_format_arguments {
	my Ravenel::Block $self = shift;
	my $block_id            = shift || 'default';
	return $self->{'format_arguments'}->{$block_id};
}

sub format {
	my Ravenel::Block $self = shift;
	my $struct              = shift;
	my $block_id            = shift;

	$struct = [ $struct ] if ( ref($struct) eq 'HASH' );

        my $block               = $self->get_block($block_id);
        my $fa                  = $self->get_format_arguments($block_id);

	my $outbound = '';
	foreach my $s ( @{$struct} ) {
        	$outbound .= sprintf($block, map { $s->{$_} } @{$fa});
	}
	return $outbound;
}

1;
