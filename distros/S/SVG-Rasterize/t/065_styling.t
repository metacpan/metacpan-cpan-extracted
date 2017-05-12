#!perl -T
use strict;
use warnings;

use Test::More tests => 74;

use SVG;
use Test::Exception;
use SVG::Rasterize;

sub set_property {
    my $rasterize;
    my $svg;
    my $hook;
    my @expected;

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('stroke-width' => '9pt');
    is($svg->firstChild->attrib('stroke-width'), '9pt', 'check attrib');
    $hook      = sub {
	my ($rasterize, %state_args) = @_;
	if($state_args{node_name} eq 'svg') {
	    is($state_args{node_attributes}->{'stroke-width'}, '9pt',
	       'xsl stroke-width');
	}
	return %state_args;
    };
    $rasterize->before_node_hook($hook);
    $rasterize->rasterize(svg => $svg);

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('stroke-width' => '9pt');
    $svg->firstChild->attrib('id'           => 'svg');
    $svg->group(id => 'g01');
    is($svg->firstChild->attrib('stroke-width'), '9pt', 'check attrib');
    is($svg->firstChild->attrib('id'), 'svg', 'check attrib');
    $hook = sub {
	my ($rasterize, %state_args) = @_;
	if($state_args{node_attributes}->{id} eq 'svg') {
	    is($state_args{node_attributes}->{'stroke-width'}, '9pt',
	       'xsl stroke-width');
	}
	if($state_args{node_attributes}->{id} eq 'g01') {
	    ok(!defined($state_args{node_attributes}->{'stroke-width'}),
	       'xsl stroke-width not on group');
	}
	return %state_args;
    };
    $rasterize->before_node_hook($hook);
    $hook = sub {
	my ($render, $state) = @_;
	if($state->node_attributes->{id} eq 'svg') {
	    is($state->properties->{'stroke-width'}, 11.25,
	       'property stroke-width on svg');
	}	
	if($state->node_attributes->{id} eq 'g01') {
	    is($state->properties->{'stroke-width'}, 11.25,
	       'property stroke-width on g01');
	}	
    };
    $rasterize->start_node_hook($hook);
    $rasterize->rasterize(svg => $svg);

    $svg->group(id => 'g02', 'stroke-width' => '10px');
    @expected = ('svg', 'g01', 'g02');
    $hook = sub {
	my ($render, $state) = @_;
	is($state->node_attributes->{id}, shift(@expected),
	   'expected id');
	if($state->node_attributes->{id} eq 'svg') {
	    is($state->properties->{'stroke-width'}, 11.25,
	       'property stroke-width on svg');
	}	
	if($state->node_attributes->{id} eq 'g01') {
	    is($state->properties->{'stroke-width'}, 11.25,
	       'property stroke-width on g01');
	}	
	if($state->node_attributes->{id} eq 'g02') {
	    is($state->properties->{'stroke-width'}, 10,
	       'property stroke-width on g02');
	}	
    };
    $rasterize->start_node_hook($hook);
    $rasterize->rasterize(svg => $svg);

    $svg->group(id => 'g03', 'stroke-width' => '10px',
		style => 'stroke-width:1in');
    @expected = ('svg', 'g01', 'g02', 'g03');
    $hook = sub {
	my ($render, $state) = @_;
	is($state->node_attributes->{id}, shift(@expected),
	   'expected id');
	if($state->node_attributes->{id} eq 'svg') {
	    is($state->properties->{'stroke-width'}, 11.25,
	       'property stroke-width on svg');
	}	
	if($state->node_attributes->{id} eq 'g01') {
	    is($state->properties->{'stroke-width'}, 11.25,
	       'property stroke-width on g01');
	}	
	if($state->node_attributes->{id} eq 'g02') {
	    is($state->properties->{'stroke-width'}, 10,
	       'property stroke-width on g02');
	}	
	if($state->node_attributes->{id} eq 'g03') {
	    is($state->properties->{'stroke-width'}, 90,
	       'property stroke-width on g03');
	}
    };
    $rasterize->start_node_hook($hook);
    $rasterize->rasterize(svg => $svg);
}

sub inherit {
    my $rasterize;
    my $svg;
    my $hook;
    my @expected;

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('stroke-width' => '9pt');
    $svg->firstChild->attrib('id'           => 'svg');
    $svg->firstChild->attrib('stroke'       => 'black');
    $svg->group(id             => 'g01',
		'stroke'       => 'none',
		'stroke-width' => ' inherit');
    $hook = sub {
	my ($rasterize, %state_args) = @_;
	if($state_args{node_attributes}->{id} eq 'svg') {
	    is($state_args{node_attributes}->{'stroke-width'}, '9pt',
	       'xsl stroke-width');
	}
	if($state_args{node_attributes}->{id} eq 'g01') {
	    is($state_args{node_attributes}->{'stroke-width'}, 'inherit',
	       'xsl stroke-width explicit inherit');
	    is($state_args{node_attributes}->{'stroke'}, 'none',
	       'xsl stroke explicit none');
	}
	return %state_args;
    };
    $rasterize->before_node_hook($hook);
    $hook = sub {
	my ($render, $state) = @_;
	if($state->node_attributes->{id} eq 'svg') {
	    is($state->properties->{'stroke-width'}, 11.25,
	       'property stroke-width on svg');
	}
	if($state->node_attributes->{id} eq 'g01') {
	    is($state->properties->{'stroke-width'}, 11.25,
	       'property stroke-width on g01');
	    ok(!defined($state->properties->{'stroke'}),
	       'property stroke undefined on g01');
	}
    };
    $rasterize->start_node_hook($hook);
    $rasterize->rasterize(svg => $svg);
}

sub color {
    my $rasterize;
    my $svg;
    my $node;
    my @expected;

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $svg->group(id => 'g01');
    $svg->group(id => 'g02', 'stroke' => 'rgb(20, 255, 1)');
    $svg->group(id => 'g03', 'stroke' => 'rgb(13%, -10%, 120%)',
		style => 'stroke-width:1in');
    @expected = ('svg', 'g01', 'g02', 'g03');
    $rasterize->start_node_hook(sub {
	my ($render, $state) = @_;
	is($state->node_attributes->{id}, shift(@expected),
	   'expected id');
	if($state->node_attributes->{id} eq 'g01') {
	    ok(!defined($state->properties->{'stroke'}),
	       'property stroke is undef on g01');
	}
	if($state->node_attributes->{id} eq 'g02') {
	    is_deeply($state->properties->{'stroke'}, [20, 255, 1],
	       'property stroke on g02');
	}
	if($state->node_attributes->{id} eq 'g03') {
	    is_deeply($state->properties->{'stroke'}, [33, -25, 306],
	       'property stroke on g03');
	    is($state->properties->{'stroke-width'}, 90,
	       'property stroke-width 90 g03');
	}
    });
    $rasterize->rasterize(svg => $svg);

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $svg->group(id => 'g01', 'style' => 'stroke:');
    throws_ok(sub { $rasterize->rasterize(svg => $svg) },
	      qr/process the css property string \'stroke\:\' correctly/,
	      'Error message invalid css property');

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $svg->group(id => 'g01', fill => '#FF00FF');
    $svg->group(id => 'g02', color => '#F0F', fill => 'currentColor');
    $node = $svg->group(id => 'g03', color => 'red');
    $node = $node->group(id => 'g04', fill => 'currentColor');
    $node->group(id => 'g05', color => 'blue');
    $svg->group(id => 'g06', fill => '#010 icc-color(foo, 1, 0.1)');
    $svg->group(id => 'g07', fill => 'rgb(20%, 40%, 60%)');
    $rasterize->start_node_hook(sub {
	my ($rasterize, $state) = @_;
	if($state->node_attributes->{id} eq 'g01') {
	    is_deeply($state->properties->{'fill'}, [255, 0, 255],
	       'property fill on g01');
	}
	if($state->node_attributes->{id} eq 'g02') {
	    is_deeply($state->properties->{'fill'}, [255, 0, 255],
	       'property fill on g02');
	}
	if($state->node_attributes->{id} eq 'g04') {
	    is_deeply($state->properties->{'fill'}, [255, 0, 0],
	       'property fill on g04');
	}
	# not entirely sure, if g05 should inherit the fill color
	# or inherit that the fill color is currentColor
	if($state->node_attributes->{id} eq 'g05') {
	    is_deeply($state->properties->{'fill'}, [255, 0, 0],
	       'property fill on g05, not entirely sure about this');
	}
	if($state->node_attributes->{id} eq 'g06') {
	    is_deeply($state->properties->{'fill'}, [0, 17, 0],
	       'property fill on g06');
	}
	if($state->node_attributes->{id} eq 'g07') {
	    is_deeply($state->properties->{'fill'}, [51, 102, 153],
	       'property fill on g07');
	}
    });
    {
	local $SIG{__WARN__} = sub {};
	$rasterize->rasterize(svg => $svg);
    }

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $svg->group(id => 'g01', stroke => 'rgb(10, 10%, 10)');
    throws_ok(sub { $rasterize->rasterize(svg => $svg) },
	      qr/Invalid color specification/,
	      'Error message invalid color specification');

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $svg->group(id => 'g01', stroke => 'rgb(10%, 10, 10)');
    throws_ok(sub { $rasterize->rasterize(svg => $svg) },
	      qr/Invalid color specification/,
	      'Error message invalid color specification');

    # external current color
    $rasterize = SVG::Rasterize->new(current_color => 'blue');
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $svg->group(id => 'g01', fill => 'currentColor');
    $rasterize->start_node_hook(sub {
	my ($rasterize, $state) = @_;
	if($state->node_attributes->{id} eq 'g01') {
	    is_deeply($state->properties->{'fill'}, [0, 0, 255],
	       'property fill on g01 by external current color');
	}
    });
    $rasterize->rasterize(svg => $svg);

    # external current color
    $rasterize = SVG::Rasterize->new(current_color => 'blue');
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $node = $svg->group(id => 'g01', fill => 'currentColor');
    $node->group(id => 'g02', fill => 'red');
    $rasterize->start_node_hook(sub {
	my ($rasterize, $state) = @_;
	if($state->node_attributes->{id} eq 'g01') {
	    is_deeply($state->properties->{'fill'}, [7, 8, 13],
	       'property fill on g01 by external current color');
	}
	if($state->node_attributes->{id} eq 'g02') {
	    is_deeply($state->properties->{'fill'}, [255, 0, 0],
	       'property fill on g02 overriding current color');
	}
    });
    $rasterize->rasterize(svg => $svg, current_color => 'rgb(7, 8, 13)');
}

sub whitespace {
    my $rasterize;
    my $svg;
    my $hook;
    my @expected;

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $svg->group(id => 'g01', 'stroke' => "\trgb(20, 255, 1) ");
    @expected = ('svg', 'g01');
    $hook = sub {
	my ($render, $state) = @_;
	is($state->node_attributes->{id}, shift(@expected),
	   'expected id');
	if($state->node_attributes->{id} eq 'g01') {
	    is_deeply($state->properties->{'stroke'}, [20, 255, 1],
	       'property stroke on g01');
	}
    };
    $rasterize->start_node_hook($hook);
    $rasterize->rasterize(svg => $svg);

    $rasterize->normalize_attributes(0);
    @expected = ('svg', 'g01');
    $hook = sub {
	my ($render, $state) = @_;
	is($state->node_attributes->{id}, shift(@expected),
	   'expected id');
	if($state->node_attributes->{id} eq 'g01') {
	    is_deeply($state->properties->{'stroke'}, [20, 255, 1],
	       'property stroke on g01 with attribute normalization');
	}
    };
    $rasterize->start_node_hook($hook);
    throws_ok(sub { $rasterize->rasterize(svg => $svg) },
	      qr/stroke/,
	      'without attribute normalization');
}

sub dasharray {
    my $rasterize;
    my $svg;
    my $hook;
    my @expected;

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $svg->group(id => 'g01', 'stroke-dasharray' => '3,4');
    @expected = ('svg', 'g01');
    $hook = sub {
	my ($render, $state) = @_;
	is($state->node_attributes->{id}, shift(@expected),
	   'expected id');
	if($state->node_attributes->{id} eq 'g01') {
	    is_deeply($state->properties->{'stroke-dasharray'},
		      [3, 4],
		      'property stroke on g01');
	}
    };
    $rasterize->start_node_hook($hook);
    $rasterize->rasterize(svg => $svg);

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $svg->group(id => 'g01', 'stroke-dasharray' => '1in, 40px');
    @expected = ('svg', 'g01');
    $hook = sub {
	my ($render, $state) = @_;
	is($state->node_attributes->{id}, shift(@expected),
	   'expected id');
	if($state->node_attributes->{id} eq 'g01') {
	    is_deeply($state->properties->{'stroke-dasharray'},
		      [90, 40],
		      'property stroke on g01');
	}
    };
    $rasterize->start_node_hook($hook);
    $rasterize->rasterize(svg => $svg);

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $svg->group(id => 'g01', 'stroke-dasharray' => '1in,40px, 12');
    @expected = ('svg', 'g01');
    $hook = sub {
	my ($render, $state) = @_;
	is($state->node_attributes->{id}, shift(@expected),
	   'expected id');
	if($state->node_attributes->{id} eq 'g01') {
	    is_deeply($state->properties->{'stroke-dasharray'},
		      [90, 40, 12, 90, 40, 12],
		      'property stroke on g01');
	}
    };
    $rasterize->start_node_hook($hook);
    $rasterize->rasterize(svg => $svg);

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $svg->group(id => 'g01', 'stroke-dasharray' => '1in,-40px');
    throws_ok(sub { $rasterize->rasterize(svg => $svg) },
	      qr/Negative value \(\-40\) in stroke\-dasharray/,
	      'negative value in dasharray');
}

sub style_as_hash {
    my $rasterize;
    my $svg;
    my $hook;
    my @expected;

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $svg->group(id => 'g01', style => {'stroke-width' => '1in'});
    @expected = ('svg', 'g01');
    $hook = sub {
	my ($rasterize, $state) = @_;
	is($state->node_attributes->{id}, shift(@expected),
	   'expected id');
	if($state->node_attributes->{id} eq 'g01') {
	    is($state->properties->{'stroke-width'}, 90,
	       'property stroke-width 90 g01');
	}
    };
    $rasterize->start_node_hook($hook);
    $rasterize->rasterize(svg => $svg);

    $rasterize = SVG::Rasterize->new;
    $svg       = SVG->new(width => 400, height => 300);
    $svg->firstChild->attrib('id' => 'svg');
    $svg->group(id    => 'g01',
		style => {'stroke-width' => '1in',
			  'stroke'       => 'black'});
    @expected = ('svg', 'g01');
    $hook = sub {
	my ($rasterize, $state) = @_;
	is($state->node_attributes->{id}, shift(@expected),
	   'expected id');
	if($state->node_attributes->{id} eq 'g01') {
	    is($state->properties->{'stroke-width'}, 90,
	       'property stroke-width 90 g01');
	    is_deeply($state->properties->{'stroke'},
		      [0, 0, 0],
		      'property stroke processed black g01');
	}
    };
    $rasterize->start_node_hook($hook);
    $rasterize->rasterize(svg => $svg);
}

set_property;
inherit;
color;
whitespace;
dasharray;
style_as_hash;
