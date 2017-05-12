package SVG::Rasterize::State::Text;
use base SVG::Rasterize::State;

use warnings;
use strict;

use 5.008009;

use List::Util qw(sum);
use Scalar::Util qw(weaken);
use Params::Validate qw(:all);
use SVG::Rasterize::Exception qw(:all);
use SVG::Rasterize::Regexes qw(:attributes);

# $Id: Text.pm 6709 2011-05-21 07:46:34Z powergnom $

=head1 NAME

C<SVG::Rasterize::State::Text> - state of a text/text content node

=head1 VERSION

Version 0.003008

=cut

our $VERSION = '0.003008';


__PACKAGE__->mk_accessors(qw());

__PACKAGE__->mk_ro_accessors(qw(text_atoms
                                x_buffer
                                y_buffer
                                dx_buffer
                                dy_buffer
                                rotate_buffer));

###########################################################################
#                                                                         #
#                      Class Variables and Methods                        # 
#                                                                         #
###########################################################################

sub make_ro_accessor {
    my($class, $field) = @_;

    return sub {
        my $self = shift;

        if (@_) {
            my $caller = caller;
            $self->ex_at_ro("${class}->${field}");
        }
        else {
            return $self->get($field);
        }
    };
}

###########################################################################
#                                                                         #
#                             Init Process                                #
#                                                                         #
###########################################################################

sub process_node_extra {
    my ($self) = @_;
    my $founder;

    # process position attributes
    my $attributes = $self->node_attributes;
    foreach(qw(x y dx dy rotate)) {
	if(defined($attributes->{$_})) {
	    $self->{$_.'_buffer'} = 
		[map { $self->map_length($_) }
		 split($RE_LENGTH{LENGTHS_SPLIT}, $attributes->{$_})];
	}
    }

    # collect position information
    if($self->node_name eq '#text' and my $cdata = $self->cdata) {
	my $ancestor = $self->parent;
	my $buffers  = {'x'    => [],
			'y'    => [],
			dx     => [],
			dy     => [],
			rotate => []};
	while(1) {
	    $self->ex_co_pt if(!defined($ancestor));
	    foreach(keys %$buffers) {
		my $name = $_.'_buffer';
		if(defined(my $content = $ancestor->$name)) {
		    push(@{$buffers->{$_}}, $content);
		}
	    }
	    if($SVG::Rasterize::TEXT_ROOT_ELEMENTS{$ancestor->node_name}) {
		$founder = $ancestor;
		last;
	    }
	    else {
		$ancestor = $ancestor->parent;
	    }
	}

	# split cdata into atoms
	my @atoms = ();
	while($cdata) {
	    my $found = 0;
	    my $atom  = {state => $self};
	    weaken $atom->{state};
	  BUFFER:
	    foreach(keys %$buffers) {
		while(@{$buffers->{$_}}) {
		    # there are still levels possibly with data
		    if(@{$buffers->{$_}->[0]}) {
			# there are still entries, so we take one
			if($_ eq 'rotate') {
			    # rotate receives special behaviour:
			    # If there are too few elements on one
			    # level then the last one is used. We
			    # only go to the next level if this one
			    # never had elements. This is
			    # implemented here by never shifting the
			    # last remaining element.
			    $atom->{$_} = @{$buffers->{$_}->[0]} > 1
				? shift(@{$buffers->{$_}->[0]})
				: $buffers->{$_}->[0]->[0];
			}
			else {
			    $atom->{$_} = shift(@{$buffers->{$_}->[0]});
			}
			$found      = 1;
			next BUFFER;
		    }
		    else {
			# this level is empty, discard and try next
			shift(@{$buffers->{$_}});
		    }
		}
		# if we arrive here we have not found anything
		$atom->{$_} = undef;
	    }

	    # If we have found something we create a new atom.
	    # Otherwise we attach the rest of the string to the last
	    # atom.
	    if($found) {
		$atom->{cdata} = substr($cdata, 0, 1, '');
		if(defined($atom->{x}) or defined($atom->{y})) {
		    # new absolute position creates new chunk;
		    # this implies a new block
		    $atom->{new_chunk} = 1;
		}
		push(@atoms, $atom);
	    }
	    elsif(!@atoms) {
		$atom->{cdata} = $cdata;
		$cdata = '';
		
		# We are at the first atom. Under certain
		# circumstances, we need to start a new block.
		# TODO: user $founder's last atom to check whether
		# ‘glyph-orientation-horizontal’ or
		# ‘glyph-orientation-vertical’ have changed. Maybe
		# I should split whenever this is set explicitly
		# and remerge later if it doesn't have an effect?
		
		push(@atoms, $atom);
	    }
	    else {
		$atoms[-1]->{cdata} .= $cdata;
		$cdata = '';
	    }
	}

	$self->add_text_atoms(@atoms);
    }
}

###########################################################################
#                                                                         #
#                               Accessors                                 # 
#                                                                         #
###########################################################################

###########################################################################
#                                                                         #
#                             Retrieve Data                               #
#                                                                         #
###########################################################################

###########################################################################
#                                                                         #
#                              Change Data                                # 
#                                                                         #
###########################################################################

sub add_text_atoms {
    my ($self, @atoms) = @_;

    validate_with
	(params  => \@atoms,
	 spec    => [({type => HASHREF}) x @atoms],
	 on_fail => sub { SVG::Rasterize->ex_pv($_[0]) });

    $self->{text_atoms} ||= [];
    foreach(@atoms) {
	my $lcb = sub {
	    my ($value) = @_;
	    return 1 if(!defined($value));
	    return $value =~ $RE_LENGTH{p_A_LENGTH} ? 1 : 0;
	};
	my $ncb = sub {
	    my ($value) = @_;
	    return 1 if(!defined($value));
	    return $value =~ $RE_NUMBER{p_A_NUMBER} ? 1 : 0;
	};
	validate_with
	    (params  => [%$_],
	     spec    => {state     => {isa   => 'SVG::Rasterize::State'},
			 'x'       => {type      => UNDEF|SCALAR,
				       callbacks => {length => $lcb}},
			 'y'       => {type      => UNDEF|SCALAR,
				       callbacks => {length => $lcb}},
			 dx        => {type      => UNDEF|SCALAR,
				       callbacks => {length => $lcb}},
			 dy        => {type      => UNDEF|SCALAR,
				       callbacks => {length => $lcb}},
			 rotate    => {type      => UNDEF|SCALAR,
				       callbacks => {length => $ncb}},
			 new_chunk => {type      => BOOLEAN,
				       optional  => 1},
			 new_block => {type      => BOOLEAN,
				       optional  => 1},
			 cdata     => {type      => SCALAR}},
	     on_fail => sub { SVG::Rasterize->ex_pv($_[0]) });
	    
	if($SVG::Rasterize::TEXT_ROOT_ELEMENTS{$self->node_name}) {
	    if(@{$self->{text_atoms}}) {
		if($_->{new_chunk}) {
		    $_->{chunkID} = 
			$self->{text_atoms}->[-1]->{chunkID} + 1;
		}
		else {
		    $_->{chunkID} =
			$self->{text_atoms}->[-1]->{chunkID};
		}
		if($_->{new_chunk} or $_->{new_block}) {
		    $_->{blockID} = 
			$self->{text_atoms}->[-1]->{blockID} + 1;
		}
		else {
		    $_->{blockID} =
			$self->{text_atoms}->[-1]->{blockID};
		}
		$_->{atomID} = $self->{text_atoms}->[-1]->{atomID}
		    + length($self->{text_atoms}->[-1]->{cdata});
	    }
	    else {
		$_->{chunkID} = 0;
		$_->{blockID} = 0;
		$_->{atomID}  = 0;
	    }
	}

	push(@{$self->{text_atoms}}, $_);
    }
    
    if($SVG::Rasterize::TEXT_ROOT_ELEMENTS{$self->node_name}) {
	return;
    }
    else {
	my $parent = $self->parent;
	while(1) {
	    $self->ex_co_pt if(!$parent);
	    if($SVG::Rasterize::TEXT_ROOT_ELEMENTS{$parent->node_name}) {
		return $parent->add_text_atoms(@atoms);
	    }
	    else { $parent = $parent->parent }
	}
    }
}

1;


__END__

=pod

=head1 DESCRIPTION

Text and text content nodes need special functionality. The hardest
part belongs to the character data nodes, which contain the actual
text. Their characters might have specific position settings, which
may be inherited from upstream C<tspan>, C<text>, or C<textPath>
nodes.

This class implements a L<process_node_extra|/process_node_extra>
method overloading the empty one of
L<SVG::Rasterize::State|SVG::Rasterize::State>. This method splits
character data into atoms where an atom (this term is coined by me
while chunk and block are taken from the C<SVG> specification) is a
sequence of characters that can be handed to the rasterization
engine in one go. Note that the atoms defined here might be split up
further directly before rasterization due to bidirectional text.

=head1 INTERFACE

=head2 Constructors

=head3 new/init

Inherited from L<SVG::Rasterize::State|SVG::Rasterize::State>.

=head2 Public Attributes

=head3 text_atoms

Readonly attribute. Holds the reference to an array of HASH
references. The array is filled during initialization. Each hash has
the following entries:

=over 4

=item * x: explicit x value if given

=item * y: explicit y value if given

=item * dx: explicit dx value if given

=item * dy: explicit dy value if given

=item * rotate: explicit rotate value if given

=item * chunkID: number of the text chunk this atom belongs to

=item * new_chunk

only present for first atom of each chunk, leftover of processing,
should not be used

=item * blockID

number of the independent text block this atom belongs to

=item * new_block

only present for first atom of each block, leftover of processing,
should not be used

=item * atomID

number of the atom, equal to the length of text before this atom
thereby allowing further splitting without renumbering

=item * cdata: the actual characters of this atom

=item * state: weak reference to this object.

=back

=head3 x_buffer

ARRAY reference, list of explicit x positions that this element
still has to offer.

=head3 y_buffer

Same for y.

=head3 dx_buffer

Same for dx.

=head3 dy_buffer

Same for dy.

=head3 rotate_buffer

Same for rotate.


=head2 Methods for Users

None.

=head2 Methods for Developers

=head3 process_node_extra

Overloads the empty method of
L<SVG::Rasterize::State|SVG::Rasterize::State>.

Has two modes of operation. For elements, it saves the position
attributes if present into buffer copies from which they can be
shifted by character data child nodes.

For character data nodes, it splits the string into atoms assigning
position values (if provided by ancestors) to the characters.

=head3 add_text_atoms

Called by L<process_node_extra|/process_node_extra>. Takes a list of
atom HASH references and pushes them to the
L<text_atoms|/text_atoms> list. Calls itself on the ancestor C<text>
or C<textPath> element. At this call, it sets L<chunkID|/chunkID>,
L<blockID|/blockID>, and L<atomID|/atomID>.

=head1 DIAGNOSTICS

=head2 Exceptions

Not documented, yet. Sorry.

=head2 Warnings

Not documented, yet. Sorry.


=head1 INTERNALS

=head2 Internal Methods

These methods are just documented for myself. You can read on to
satisfy your voyeuristic desires, but be aware of that they might
change or vanish without notice in a future version.

=over 4

=item * make_ro_accessor

This piece of documentation is mainly here to make the C<POD>
coverage test happy. C<SVG::Rasterize::State::Text> overloads
C<make_ro_accessor> to make the readonly accessors throw an
exception object (of class C<SVG::Rasterize::Exception::Attribute>)
instead of just croaking.

=back

=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Lutz Gehlen.

This program is free software; you can redistribute it and/or modify
it under the terms of either: the GNU General Public License as
published by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
