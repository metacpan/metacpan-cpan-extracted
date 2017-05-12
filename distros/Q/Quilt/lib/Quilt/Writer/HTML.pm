#
# Copyright (C) 1997 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: HTML.pm,v 1.1.1.1 1997/10/22 21:35:09 ken Exp $
#

package Quilt::Writer::HTML;
@Quilt::Writer::HTML::ISA
    = qw{Quilt::Context};

use strict;
use vars qw{$entity_maps};

use Text::EntityMap;
use Quilt::Context;

my $entity_maps = undef;

sub new {
    my ($type, %init) = @_;

    if (!defined $init{file_handle}) {
	if (!defined %FileHandle::) {
	    require FileHandle;
	    import FileHandle;
	}

	# default to stdout
	$init{file_handle} = FileHandle->new ('>-');
    }

    # XXX this probably shouldn't be here
    # note the conversion of `sdata_dirs' list to an anonymous array to
    # make a single argument
    if (!defined $entity_maps) {
	$entity_maps = Quilt::Writer::Ascii::load_char_maps ('.2ab', [ Text::EntityMap::sdata_dirs() ]);
    }

    my ($self) = {
	current => [{}],
	file_handle => $init{file_handle},
	entity_map => $entity_maps,
    };

    bless ($self, $type);

    $self->push ({
	inline => 0,
    });

    return ($self);
}

sub space_before  { return ($_[0]->{'current'}[-1]{'space_before'}); }
sub space_after   { return ($_[0]->{'current'}[-1]{'space_after'}); }
sub first_line_start_indent
                  { return ($_[0]->{'current'}[-1]{'first_line_start_indent'}); }
sub start_indent  { return ($_[0]->{'current'}[-1]{'start_indent'}); }
sub end_indent    { return ($_[0]->{'current'}[-1]{'end_indent'}); }
sub line_width    { return ($_[0]->{'current'}[-1]{'line_width'}); }
sub lines         { return ($_[0]->{'current'}[-1]{'lines'}); }
sub quadding      { return ($_[0]->{'current'}[-1]{'quadding'}); }
sub inline        { return ($_[0]->{'current'}[-1]{'inline'}); }

sub set_space_before  { return ($_[0]->{'current'}[-1]{'space_before'} = $_[1]); }
sub set_space_after   { return ($_[0]->{'current'}[-1]{'space_after'} = $_[1]); }
sub set_first_line_start_indent
                      { return ($_[0]->{'current'}[-1]{'first_line_start_indent'} = $_[1]); }
sub set_start_indent  { return ($_[0]->{'current'}[-1]{'start_indent'} = $_[1]); }
sub set_end_indent    { return ($_[0]->{'current'}[-1]{'end_indent'} = $_[1]); }
sub set_line_width    { return ($_[0]->{'current'}[-1]{'line_width'} = $_[1]); }
sub set_lines         { return ($_[0]->{'current'}[-1]{'lines'} = $_[1]); }
sub set_quadding      { return ($_[0]->{'current'}[-1]{'quadding'} = $_[1]); }
sub set_inline        { return ($_[0]->{'current'}[-1]{'inline'} = $_[1]); }

1;
