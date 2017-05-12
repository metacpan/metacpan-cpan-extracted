#!perl -T
use strict;
use warnings;

# $Id: 080_text.t 6649 2011-04-30 05:30:57Z powergnom $

use Test::More tests => 234;

use SVG;
use Test::Exception;
use SVG::Rasterize;

sub state_cdata {
    my $rasterize;
    my $svg;
    my $node;

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $node = $svg->group(id => 'g01');
    $node->text(id => 'te01')->cdata('Hello World');
    $rasterize->start_node_hook(sub {
	my ($rasterize, $state) = @_;
	if($state->node_name eq '#text') {
	    is($state->cdata, 'Hello World', 'cdata arrived at State');
	}
    });
    $rasterize->rasterize(svg => $svg);
}

sub font_properties {
    my $rasterize;
    my $svg;
    my $node;

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(id => 'svg', width => 400, height => 300);
    $svg->svg(id => 'svg01', 'font-size' => 'humangous');
    throws_ok(sub { $rasterize->rasterize(svg => $svg) },
	      qr/font\-size/,
	      'invalid font-size');

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $node = $svg->text(id => 'te01', 'font-size' => 'large');
    $node->cdata('Hello World');
    $rasterize->start_node_hook(sub {
	my ($rasterize, $state) = @_;
	if($state->node_attributes->{id}) {
	    if($state->node_attributes->{id} eq 'te01') {
		is($state->properties->{'font-size'}, 18,
		   'font-size large');
	    }
	}
    });
    $rasterize->rasterize(svg => $svg);

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(id => 'svg', width => 400, height => 300);
    $svg->svg(id => 'svg01', 'font-weight' => 'superfat');
    throws_ok(sub { $rasterize->rasterize(svg => $svg) },
	      qr/font\-weight/,
	      'invalid named font-weight');

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(id => 'svg', width => 400, height => 300);
    $svg->svg(id => 'svg01', 'font-weight' => 350);
    throws_ok(sub { $rasterize->rasterize(svg => $svg) },
	      qr/font\-weight/,
	      'invalid numerical font-weight');

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $node = $svg->text(id => 'te01', 'font-weight' => 'bold');
    $node->cdata('Hello World');
    $rasterize->start_node_hook(sub {
	my ($rasterize, $state) = @_;
	if($state->node_attributes->{id}) {
	    if($state->node_attributes->{id} eq 'te01') {
		is($state->properties->{'font-weight'}, 700,
		   'font-weight 700 (bold)');
	    }
	}
    });
    $rasterize->rasterize(svg => $svg);

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $node = $svg->text(id => 'te01', 'font-weight' => '300');
    $node->cdata('Hello World');
    $rasterize->start_node_hook(sub {
	my ($rasterize, $state) = @_;
	if($state->node_attributes->{id}) {
	    if($state->node_attributes->{id} eq 'te01') {
		is($state->properties->{'font-weight'}, 300,
		   'font-weight 300');
	    }
	}
    });
    $rasterize->rasterize(svg => $svg);

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(id => 'svg', width => 400, height => 300);
    $svg->svg(id => 'svg01', 'font-stretch' => 'so wide');
    throws_ok(sub { $rasterize->rasterize(svg => $svg) },
	      qr/font\-stretch/,
	      'invalid font-stretch');

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $node = $svg->text(id => 'te01', 'font-stretch' => 'ultra-condensed');
    $node->cdata('Hello World');
    $rasterize->start_node_hook(sub {
	my ($rasterize, $state) = @_;
	if($state->node_attributes->{id}) {
	    if($state->node_attributes->{id} eq 'te01') {
		is($state->properties->{'font-stretch'}, 'ultra-condensed',
		   'font-stretch ultra-condensed');
	    }
	}
    });
    $rasterize->rasterize(svg => $svg);
}

sub process_character_positions {
    my $rasterize;
    my $svg;
    my $node;

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $node = $svg->group(id => 'g01');
    $node->text(id => 'te01',
		x  => 10);
    $node->text(id => 'te02',
		x  => '10 20,30 , 40');
    $node->text(id     => 'te03',
		'x'    => '10',
	        'y'    => '10, 30',
                dx     => '1 -1, 3.1',
		dy     => 0,
		rotate => '5, 5 6.5');
    $rasterize->start_node_hook(sub {
	my ($rasterize, $state) = @_;
	if($state->node_attributes->{id} eq 'te01') {
	    is_deeply($state->x_buffer, [10], 'x_buffer single value');
	}
	if($state->node_attributes->{id} eq 'te02') {
	    is_deeply($state->x_buffer, [10, 20, 30, 40],
		      'x_buffer multiple values');
	    ok(!defined($state->y_buffer), 'no y_buffer');
	}
	if($state->node_attributes->{id} eq 'te03') {
	    is_deeply($state->x_buffer, [10], 'x_buffer');
	    is_deeply($state->y_buffer, [10, 30], 'y_buffer');
	    is_deeply($state->dx_buffer, [1, -1, 3.1], 'dx_buffer');
	    is_deeply($state->dy_buffer, [0], 'dy_buffer');
	    is_deeply($state->rotate_buffer, [5, 5, 6.5], 'rotate_buffer');
	}
    });
    $rasterize->rasterize(svg => $svg);
}

sub split_into_atoms {
    my $rasterize;
    my $svg;
    my $node;
    my $text;
    my @expected_cdata;
    my @expected_chunks;
    my @expected_blocks;

    ok(1);
    ok(1, '==== split into atoms ====');
    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $node = $svg->group(id => 'g01');
    $node = $node->text(id => 'te01');
    $node->cdata('foo');
    $rasterize->end_node_hook(sub {
	my ($rasterize, $state) = @_;
	if(!$state->node_attributes->{id}) {
	    if($state->node_name eq '#text') {
		my $text_atoms = $state->text_atoms;
		ok(defined($text_atoms),
		   'text_atoms defined for cdata state object');
		is(ref($text_atoms), 'ARRAY',
		   'text_atoms ARRAY reference');
		is(@$text_atoms, 1, 'there is 1 atom');
		ok(defined($text_atoms->[0]), 'atom is defined');
		is(ref($text_atoms->[0]), 'HASH',
		   'atom is HASH reference');
		is($text_atoms->[0]->{cdata}, 'foo', 'cdata foo');
		is($text_atoms->[0]->{chunkID}, 0, 'chunkID 0');
		is($text_atoms->[0]->{blockID}, 0, 'blockID 0');
		is($text_atoms->[0]->{atomID},  0, 'atomID 0');
	    }
	}
	elsif($state->node_attributes->{id} eq 'te01') {
	    my $text_atoms = $state->text_atoms;
	    ok(defined($text_atoms),
		   'text_atoms defined for text state object');
	    is(ref($text_atoms), 'ARRAY',
	       'text_atoms ARRAY reference');
	    is(@$text_atoms, 1, 'there is 1 atom');
	    is($text_atoms->[0]->{cdata}, 'foo', 'cdata foo');
	}
    });
    $rasterize->rasterize(svg => $svg);

    ok(1);
    ok(1, '---- text with tspan ----');
    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $node = $svg->group(id => 'g01');
    $node = $node->text(id => 'te01');
    $node = $node->tspan(id => 'ts01');
    $node->cdata('bar');
    $rasterize->end_node_hook(sub {
	my ($rasterize, $state) = @_;
	if(!$state->node_attributes->{id}) {
	    if($state->node_name eq '#text') {
		my $text_atoms = $state->text_atoms;
		ok(defined($text_atoms),
		   'text_atoms defined for cdata state object');
		is(ref($text_atoms), 'ARRAY',
		   'text_atoms ARRAY reference');
		is(@$text_atoms, 1, 'there is 1 atom');
		ok(defined($text_atoms->[0]), 'atom is defined');
		is(ref($text_atoms->[0]), 'HASH',
		   'atom is HASH reference');
		is($text_atoms->[0]->{cdata}, 'bar', 'cdata bar');
		is($text_atoms->[0]->{chunkID}, 0, 'chunkID 0');
		is($text_atoms->[0]->{blockID}, 0, 'blockID 0');
		is($text_atoms->[0]->{atomID},  0, 'atomID 0');
	    }
	}
	elsif($state->node_attributes->{id} eq 'te01') {
	    my $text_atoms = $state->text_atoms;
	    ok(defined($text_atoms),
	       'text_atoms defined for text state object');
	    is(ref($text_atoms), 'ARRAY',
	       'text_atoms ARRAY reference');
	    is(@$text_atoms, 1, 'there is 1 atom');
	    is($text_atoms->[0]->{cdata}, 'bar', 'cdata bar');
	}
    });
    $rasterize->rasterize(svg => $svg);

    ok(1);
    ok(1, '---- text with two tspans ----');
    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $node = $svg->group(id => 'g01');
    $text = $node->text(id => 'te01');
    $node = $text->tspan(id => 'ts01');
    $node->cdata('baz');
    $node = $text->tspan(id => 'ts02');
    $node->cdata('qux');
    $rasterize->end_node_hook(sub {
	my ($rasterize, $state) = @_;
	if(!$state->node_attributes->{id}) {
	    if($state->node_name eq '#text') {
		if($state->cdata and $state->cdata eq 'baz') {
		    my $text_atoms = $state->text_atoms;
		    ok(defined($text_atoms),
		       'text_atoms defined for cdata state object');
		    is(ref($text_atoms), 'ARRAY',
		       'text_atoms ARRAY reference');
		    is(@$text_atoms, 1, 'there is 1 atom');
		    ok(defined($text_atoms->[0]), 'atom is defined');
		    is(ref($text_atoms->[0]), 'HASH',
		       'atom is HASH reference');
		    is($text_atoms->[0]->{cdata}, 'baz', 'cdata baz');
		    is($text_atoms->[0]->{chunkID}, 0, 'chunkID 0');
		    is($text_atoms->[0]->{blockID}, 0, 'blockID 0');
		    is($text_atoms->[0]->{atomID},  0, 'atomID 0');
		}
		elsif($state->cdata and $state->cdata eq 'qux') {
		    my $text_atoms = $state->text_atoms;
		    ok(defined($text_atoms),
		       'text_atoms defined for cdata state object');
		    is(ref($text_atoms), 'ARRAY',
		       'text_atoms ARRAY reference');
		    is(@$text_atoms, 1, 'there is 1 atom');
		    ok(defined($text_atoms->[0]), 'atom is defined');
		    is(ref($text_atoms->[0]), 'HASH',
		       'atom is HASH reference');
		    is($text_atoms->[0]->{cdata}, 'qux', 'cdata qux');
		    is($text_atoms->[0]->{chunkID}, 0, 'chunkID 0');
		    is($text_atoms->[0]->{blockID}, 0, 'blockID 0');
		    is($text_atoms->[0]->{atomID},  3, 'atomID 3');
		}
	    }
	}
	elsif($state->node_attributes->{id} eq 'te01') {
	    my $text_atoms = $state->text_atoms;
	    ok(defined($text_atoms),
	       'text_atoms defined for text state object');
	    is(ref($text_atoms), 'ARRAY',
	       'text_atoms ARRAY reference');
	    is(@$text_atoms, 2, 'there are 2 atoms');
	    is($text_atoms->[0]->{cdata}, 'baz', 'cdata baz');
	    is($text_atoms->[0]->{atomID}, 0, 'atomID 0');
	    is($text_atoms->[1]->{cdata}, 'qux', 'cdata qux');
	    is($text_atoms->[1]->{atomID}, 3, 'atomID 3');
	}
    });
    $rasterize->rasterize(svg => $svg);
    
    ok(1);
    ok(1, '---- dx, y, and direct cdata mixed with tspans ----');
    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $node = $svg->group(id => 'g01');
    $text = $node->text(id => 'te01');
    $node = $text->tspan(id => 'ts01');
    $node->cdata('foo');
    $node = $text->tspan(id => 'ts02', dx => 10);
    $node->cdata('bar');
    $node = $text->tspan(id => 'ts03', 'y' => -30);
    $node->cdata('baz');
    $text->cdata('qux');
    $rasterize->end_node_hook(sub {
	my ($rasterize, $state) = @_;
	if(!$state->node_attributes->{id}) {
	    if($state->node_name eq '#text') {
		if($state->cdata and $state->cdata eq 'foo') {
		    my $text_atoms = $state->text_atoms;
		    ok(defined($text_atoms),
		       'text_atoms defined for cdata state object');
		    is(ref($text_atoms), 'ARRAY',
		       'text_atoms ARRAY reference');
		    is(@$text_atoms, 1, 'there is 1 atom');
		    ok(defined($text_atoms->[0]), 'atom is defined');
		    is(ref($text_atoms->[0]), 'HASH',
		       'atom is HASH reference');
		    is($text_atoms->[0]->{cdata}, 'foo', 'cdata foo');
		    is($text_atoms->[0]->{chunkID}, 0, 'chunkID 0');
		    is($text_atoms->[0]->{blockID}, 0, 'blockID 0');
		    is($text_atoms->[0]->{atomID},  0, 'atomID 0');
		}
		elsif($state->cdata and $state->cdata eq 'bar') {
		    my $text_atoms = $state->text_atoms;
		    ok(defined($text_atoms),
		       'text_atoms defined for cdata state object');
		    is(ref($text_atoms), 'ARRAY',
		       'text_atoms ARRAY reference');
		    is(@$text_atoms, 1, 'there is 1 atom');
		    ok(defined($text_atoms->[0]), 'atom is defined');
		    is(ref($text_atoms->[0]), 'HASH',
		       'atom is HASH reference');
		    is($text_atoms->[0]->{cdata}, 'bar', 'cdata bar');
		    is($text_atoms->[0]->{dx}, 10, 'dx 10');
		    is($text_atoms->[0]->{chunkID}, 0, 'chunkID 0');
		    is($text_atoms->[0]->{blockID}, 0, 'blockID 0');
		    is($text_atoms->[0]->{atomID},  3, 'atomID 3');
		}
		elsif($state->cdata and $state->cdata eq 'baz') {
		    my $text_atoms = $state->text_atoms;
		    ok(defined($text_atoms),
		       'text_atoms defined for cdata state object');
		    is(ref($text_atoms), 'ARRAY',
		       'text_atoms ARRAY reference');
		    is(@$text_atoms, 1, 'there is 1 atom');
		    ok(defined($text_atoms->[0]), 'atom is defined');
		    is(ref($text_atoms->[0]), 'HASH',
		       'atom is HASH reference');
		    is($text_atoms->[0]->{cdata}, 'baz', 'cdata baz');
		    ok(!defined($text_atoms->[0]->{dx}), 'no dx setting');
		    is($text_atoms->[0]->{y}, -30, 'y -30');
		    is($text_atoms->[0]->{chunkID}, 1, 'chunkID 1');
		    is($text_atoms->[0]->{blockID}, 1, 'blockID 1');
		    is($text_atoms->[0]->{atomID},  6, 'atomID 6');
		}
		elsif($state->cdata and $state->cdata eq 'qux') {
		    my $text_atoms = $state->text_atoms;
		    ok(defined($text_atoms),
		       'text_atoms defined for cdata state object');
		    is(ref($text_atoms), 'ARRAY',
		       'text_atoms ARRAY reference');
		    is(@$text_atoms, 1, 'there is 1 atom');
		    ok(defined($text_atoms->[0]), 'atom is defined');
		    is(ref($text_atoms->[0]), 'HASH',
		       'atom is HASH reference');
		    is($text_atoms->[0]->{cdata}, 'qux', 'cdata qux');
		    ok(!defined($text_atoms->[0]->{dx}), 'no dx setting');
		    ok(!defined($text_atoms->[0]->{y}), 'no y setting');
		    is($text_atoms->[0]->{chunkID}, 1, 'chunkID 1');
		    is($text_atoms->[0]->{blockID}, 1, 'blockID 1');
		    is($text_atoms->[0]->{atomID},  9, 'atomID 9');
		}
	    }
	}
	elsif($state->node_attributes->{id} eq 'te01') {
	    my $text_atoms = $state->text_atoms;
	    ok(defined($text_atoms),
	       'text_atoms defined for text state object');
	    is(ref($text_atoms), 'ARRAY',
	       'text_atoms ARRAY reference');
	    is(@$text_atoms, 4, 'there are 2 atoms');
	    is($text_atoms->[0]->{cdata}, 'foo', 'cdata foo');
	    is($text_atoms->[1]->{cdata}, 'bar', 'cdata bar');
	    is($text_atoms->[2]->{cdata}, 'baz', 'cdata baz');
	    is($text_atoms->[3]->{cdata}, 'qux', 'cdata qux');
	}
    });
    $rasterize->rasterize(svg => $svg);

    ok(1);
    ok(1, '---- text with multiple dx ----');
    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $node = $svg->group(id => 'g01');
    $node = $node->text(id => 'te01', dx => '0 1 2');
    $node->cdata('foobar');
    $rasterize->end_node_hook(sub {
	my ($rasterize, $state) = @_;
	if(!$state->node_attributes->{id}) {
	    if($state->node_name eq '#text') {
		my $text_atoms = $state->text_atoms;
		ok(defined($text_atoms),
		   'text_atoms defined for cdata state object');
		is(ref($text_atoms), 'ARRAY',
		   'text_atoms ARRAY reference');
		@expected_cdata = ('f', 'o', 'obar');
		is(@$text_atoms, scalar(@expected_cdata),
		   sprintf('there are %d atoms', scalar(@expected_cdata)));
		for(my $i=0;$i<@expected_cdata;$i++) {
		    ok(defined($text_atoms->[$i]), 'atom is defined');
		    is(ref($text_atoms->[$i]), 'HASH',
		       'atom is HASH reference');
		    is($text_atoms->[$i]->{cdata}, $expected_cdata[$i],
		       "cdata $expected_cdata[$i]");
		    is($text_atoms->[$i]->{chunkID}, 0, 'chunkID 0');
		    is($text_atoms->[$i]->{blockID}, 0, 'blockID 0');
		}
	    }
	}
	elsif($state->node_attributes->{id} eq 'te01') {
	    my $text_atoms = $state->text_atoms;
	    ok(defined($text_atoms),
		   'text_atoms defined for text state object');
	    is(ref($text_atoms), 'ARRAY',
	       'text_atoms ARRAY reference');
	    @expected_cdata = ('f', 'o', 'obar');
	    is(@$text_atoms, scalar(@expected_cdata),
	       sprintf('there are %d atoms', scalar(@expected_cdata)));
	    for(my $i=0;$i<@expected_cdata;$i++) {
		ok(defined($text_atoms->[$i]), 'atom is defined');
		is(ref($text_atoms->[$i]), 'HASH',
		   'atom is HASH reference');
		is($text_atoms->[$i]->{cdata}, $expected_cdata[$i],
		   "cdata $expected_cdata[$i]");
		is($text_atoms->[$i]->{chunkID}, 0, 'chunkID 0');
		is($text_atoms->[$i]->{blockID}, 0, 'blockID 0');
	    }
	}
    });
    $rasterize->rasterize(svg => $svg);

    ok(1);
    ok(1, '---- text with multiple x ----');
    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $node = $svg->group(id => 'g01');
    $node = $node->text(id => 'te01', x => '0 1 2');
    $node->cdata('foobar');
    $rasterize->end_node_hook(sub {
	my ($rasterize, $state) = @_;
	if(!$state->node_attributes->{id}) {
	    if($state->node_name eq '#text') {
		my $text_atoms = $state->text_atoms;
		ok(defined($text_atoms),
		   'text_atoms defined for cdata state object');
		is(ref($text_atoms), 'ARRAY',
		   'text_atoms ARRAY reference');
		is(@$text_atoms, 3, 'there are 3 atoms');
		is($text_atoms->[0]->{cdata},   'f', "cdata f");
		is($text_atoms->[0]->{x},       0,   "x 0");
		is($text_atoms->[0]->{chunkID}, 0,   "chunkID 0");
		is($text_atoms->[0]->{blockID}, 0,   "blockID 0");
		is($text_atoms->[0]->{atomID},  0,   'atomID 0');

		is($text_atoms->[1]->{cdata},    'o', "cdata o");
		is($text_atoms->[1]->{x},         1,  "x 1");
		is($text_atoms->[1]->{new_chunk}, 1,  'new chunk');
		is($text_atoms->[1]->{chunkID},   1,  "chunkID 1");
		is($text_atoms->[1]->{blockID},   1,  "blockID 1");
		is($text_atoms->[1]->{atomID},    1,  'atomID 1');

		is($text_atoms->[2]->{cdata},    'obar', "cdata obar");
		is($text_atoms->[2]->{x},         2,  "x 2");
		is($text_atoms->[2]->{new_chunk}, 1,  'new chunk');
		is($text_atoms->[2]->{chunkID},   2,  "chunkID 2");
		is($text_atoms->[2]->{blockID},   2,  "blockID 2");
		is($text_atoms->[2]->{atomID},    2,  'atomID 2');
	    }
	}
	elsif($state->node_attributes->{id} eq 'te01') {
	    my $text_atoms = $state->text_atoms;
	    ok(defined($text_atoms),
		   'text_atoms defined for text state object');
	    is(ref($text_atoms), 'ARRAY',
	       'text_atoms ARRAY reference');
	    @expected_cdata = ('f', 'o', 'obar');
	    is(@$text_atoms, scalar(@expected_cdata),
	       sprintf('there are %d atoms', scalar(@expected_cdata)));
	    for(my $i=0;$i<@expected_cdata;$i++) {
		ok(defined($text_atoms->[$i]), 'atom is defined');
		is(ref($text_atoms->[$i]), 'HASH',
		   'atom is HASH reference');
		is($text_atoms->[$i]->{cdata}, $expected_cdata[$i],
		   "cdata $expected_cdata[$i]");
	    }
	}
    });
    $rasterize->rasterize(svg => $svg);

    ok(1);
    ok(1, '---- text with tspan position inheritance ----');
    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $node = $svg->group(id => 'g01');
    $text = $node->text(id => 'te01', dy => '1 2 3 4 5 6');
    $node = $text->tspan(id => 'ts01', dy => '7 8');
    $node->cdata('foo');
    $node = $text->tspan(id => 'ts02');
    $node->cdata('bar');
    $rasterize->end_node_hook(sub {
	my ($rasterize, $state) = @_;
	if($state->node_name eq '#text' and $state->cdata eq 'foo') {
	    my $text_atoms = $state->text_atoms;
	    ok(defined($text_atoms),
	       'text_atoms defined for cdata state object');
	    is(ref($text_atoms), 'ARRAY',
	       'text_atoms ARRAY reference');
	    is(@$text_atoms, 3, 'there is 3 atom');
	    is($text_atoms->[0]->{cdata},   'f', 'cdata f');
	    is($text_atoms->[0]->{dy},      7,    'dy 7');
	    is($text_atoms->[0]->{chunkID}, 0,    'chunkID 0');
	    is($text_atoms->[0]->{blockID}, 0,    'blockID 0');
	    is($text_atoms->[0]->{atomID},  0,    'atomID 0');
	    is($text_atoms->[1]->{cdata},   'o',  'cdata o');
	    is($text_atoms->[1]->{dy},      8,    'dy 8');
	    is($text_atoms->[1]->{chunkID}, 0,    'chunkID 0');
	    is($text_atoms->[1]->{blockID}, 0,    'blockID 0');
	    is($text_atoms->[1]->{atomID},  1,    'atomID 1');
	    is($text_atoms->[2]->{cdata},   'o',  'cdata o');
	    is($text_atoms->[2]->{dy},      1,    'dy 1');
	    is($text_atoms->[2]->{chunkID}, 0,    'chunkID 0');
	    is($text_atoms->[2]->{blockID}, 0,    'blockID 0');
	    is($text_atoms->[2]->{atomID},  2,    'atomID 2');
	}
	if($state->node_name eq '#text' and $state->cdata eq 'bar') {
	    my $text_atoms = $state->text_atoms;
	    ok(defined($text_atoms),
	       'text_atoms defined for cdata state object');
	    is(ref($text_atoms), 'ARRAY',
	       'text_atoms ARRAY reference');
	    is(@$text_atoms, 3, 'there is 3 atom');
	    is($text_atoms->[0]->{cdata},   'b', 'cdata b');
	    is($text_atoms->[0]->{dy},      2,    'dy 2');
	    is($text_atoms->[0]->{chunkID}, 0,    'chunkID 0');
	    is($text_atoms->[0]->{blockID}, 0,    'blockID 0');
	    is($text_atoms->[0]->{atomID},  3,    'atomID 3');
	    is($text_atoms->[1]->{cdata},   'a',  'cdata a');
	    is($text_atoms->[1]->{dy},      3,    'dy 3');
	    is($text_atoms->[1]->{chunkID}, 0,    'chunkID 0');
	    is($text_atoms->[1]->{blockID}, 0,    'blockID 0');
	    is($text_atoms->[1]->{atomID},  4,    'atomID 4');
	    is($text_atoms->[2]->{cdata},   'r',  'cdata r');
	    is($text_atoms->[2]->{dy},      4,    'dy 4');
	    is($text_atoms->[2]->{chunkID}, 0,    'chunkID 0');
	    is($text_atoms->[2]->{blockID}, 0,    'blockID 0');
	    is($text_atoms->[2]->{atomID},  5,    'atomID 5');
	}
    });
    $rasterize->rasterize(svg => $svg);
}

state_cdata;
font_properties;
process_character_positions;
split_into_atoms;
