package Template::Flute::Style::CSS;

use strict;
use warnings;

use CSS::Tiny;

use Template::Flute::Utils;

# names for the sides of a box, as in border-top, border-right, ...
use constant SIDE_NAMES => qw/top right bottom left/;

# default font size - used for the calucation of 1em
use constant FONT_SIZE => '12';

our $VERSION = '0.0081';

# block elements
my %block_elements = (address => 1,
		      blockquote => 1,
		      div => 1,
		      dl => 1,
		      fieldset => 1,
		      form => 1,
		      h1 => 1,
		      h2 => 1,
		      h3 => 1,
		      h4 => 1,
		      h5 => 1,
		      h6 => 1,
		      noscript => 1,
		      ol => 1,
		      p => 1,
		      pre => 1,
		      table => 1,
		      ul => 1);

=head1 NAME

Template::Flute::Style::CSS - CSS parser class for Template::Flute

=head1 VERSION

Version 0.0081

=head1 CONSTRUCTOR

=head2 new

Create Template::Flute::Style::CSS object with the following parameters:

=over 4

=item template

L<Template::Flute::HTML> object.

=item prepend_directory

Directory which is prepended to the CSS path when the
template doesn't reside in a file.

=back

=cut

sub new {
	my ($proto, @args) = @_;
	my ($class, $self);

	$class = ref($proto) || $proto;
	$self = {@args};

	bless ($self, $class);

	if ($self->{template}) {
		$self->{css} = $self->_initialize();
	}

	return $self;
}

sub _initialize {
	my ($self) = @_;
	my (@ret, $css_file, $css);

	# create CSS::Tiny object
	$css = new CSS::Tiny;

	# search for external stylesheets
	for my $ext ($self->{template}->root()->get_xpath(qq{//link})) {
		if ($ext->att('rel') eq 'stylesheet'
			&& $ext->att('type') eq 'text/css') {
			if ($self->{template}->file) {
				$css_file = Template::Flute::Utils::derive_filename
					($self->{template}->file, $ext->att('href'), 1);
			}
			elsif ($self->{prepend_directory}) {
				$css_file = join('/', $self->{prepend_directory},
								 $ext->att('href'));
			}
			else {
				$css_file = $ext->att('href');
			}
			
			unless ($css->read($css_file)) {
				die "Failed to parse CSS file $css_file: " . $css->errstr() . "\n";
			}
		}
	}
	
	# search for inline stylesheets
	push (@ret, $self->{template}->root()->get_xpath(qq{//style}));
	
	for (@ret) {
		unless ($css->read_string($_->text())) {
			die "Failed to parse inline CSS: " . $css->errstr() . "\n";
		}
	}
	
	return $css;
}

=head1 METHODS

=head2 properties

Builds CSS properties based on the following parameters:

=over 4

=item selector

CSS selector.

=item class

CSS class.

=item id

CSS id.

=item tag

HTML tag.

=item inherit

CSS properties to inherit from.

=back

=cut

sub properties {
	my ($self, %parms) = @_;
	my (@ids, @classes, @tags, $props);

	# inherit from parent element
	if (exists $parms{inherit}) {
		$props = $self->inherit($parms{inherit});
	}
	
	# defaults
    unless (exists $props->{color}) {
        $props->{color} = 'black';
    }
    
    unless (exists $props->{font}->{size}) {
        $props->{font}->{size} = FONT_SIZE;
    }

	if (defined $parms{tag} && $parms{tag} =~ /\S/) {
		@tags = split(/\s+/, $parms{tag});

		if (@tags) {
		    for my $tag (@tags) {
			$self->_build_properties($props, $tag);

			if (($parms{tag} eq 'strong' || $parms{tag} eq 'b')
			    && ! exists $props->{font}->{weight}) {
			    $props->{font}->{weight} = 'bold';
			}
		}

            if ($parms{tag} eq 'p') {
                # add automagic margin of 1em
                for (qw/top bottom/) {
                    unless ($props->{margin}->{$_}) {
                        $props->{margin}->{$_} = $props->{font}->{size};

                        if ($props->{font}->{size} =~ /^[0-9.]+$/) {
                            $props->{margin}->{$_} .= 'pt';
                        }
                    }
                }
            }
            
		    if (! $props->{display} && exists $block_elements{$tags[0]} ) {
			$props->{display} = 'block';
		    }	
		}
	}
	
	if (defined $parms{id} && $parms{id} =~ /\S/) {
		@ids = split(/\s+/, $parms{id});

		for my $id (@ids) {
			$self->_build_properties($props, "#$id");
		}
	}

	if (defined $parms{class} && $parms{class} =~ /\S/) {
		@classes = split(/\s+/, $parms{class});

		for my $class (@classes) {
			$self->_build_properties($props, ".$class");
			for (@tags) {
				$self->_build_properties($props, "$_.$class");
			}
		}
	}

	if (defined $parms{selector} && $parms{selector} =~ /\S/) {
		$self->_build_properties($props, $parms{selector});
	}

	$props->{display} ||= 'inline';

	$self->_expand_properties($props);

	return $props;
}

=head2 descendant_properties

Builds descendant CSS properties based on the following parameters:

=over 4

=item parent

Parent properties.

=item class

CSS class.

=item id

CSS id.

=item tag

HTML tag.

=back

=cut

sub descendant_properties {
	my ($self, %parms) = @_;
	my (@ids, @classes, @selectors, $regex, $sel, @tags, %selmap);

	if (ref($parms{parent}) eq 'HASH') {
		%selmap = %{$parms{parent}};
	}

	if (defined $parms{id} && $parms{id} =~ /\S/) {
		@ids = split(/\s+/, $parms{id});

		for my $id (@ids) {
			$regex = qr{^#$id\s+};
			@selectors = $self->_grep_properties($regex);

			for (@selectors) {
				$sel = substr($_, length($id) + 2);
				$selmap{$sel} = $_;
			}
		}
	}
	
	if (defined $parms{class} && $parms{class} =~ /\S/) {
		@classes = split(/\s+/, $parms{class});

		for my $class (@classes) {
			$regex = qr{^.$class\s+};
			@selectors = $self->_grep_properties($regex);

			for (@selectors) {
				$sel = substr($_, length($class) + 2);
				$selmap{$sel} = $_;
			}
		}
	}
	elsif (defined $parms{tag} && $parms{tag} =~ /\S/) {
		@tags = split(/\s+/, $parms{tag});
			
		for my $tag (@tags) {
			$regex = qr{^$tag\s+};
			@selectors = $self->_grep_properties($regex);
			
			for (@selectors) {
				$sel = substr($_, length($tag) + 1);
				$selmap{$sel} = $_;
			}
		}
	}
	
	return \%selmap;
}

sub _grep_properties {
	my ($self, $sel_regex) = @_;
	my (@selectors);

	@selectors = grep {/$sel_regex/} keys %{$self->{css}};

	return @selectors;
}

sub _build_properties {
	my ($self, $propref, $sel) = @_;
	my ($props_css, $sides);
	my (@specs, $value);
	
	$props_css = $self->{css}->{$sel};

	# background: all possible values in arbitrary order
	# attachment,color,image,position,repeat

	if ($value = $props_css->{background}) {
		@specs = split(/\s+/, $value);

		for (@specs) {
			# attachment
			if (/^(fixed|scroll)$/) {
				$propref->{background}->{attachment} = $1;
				next;
			}
			# color (switch later to one of Graphics::ColorNames modules)
			if (/^(\#[0-9a-f]{3,6})$/) {
				$propref->{background}->{color} = $1;
				next;
			}

		}
	}

	for (qw/attachment color image position repeat/) {
		if ($value = $props_css->{"background-$_"}) {
			$propref->{background}->{$_} = $value;
		}
	}
	
	# border
	if ($value = $props_css->{border}) {
		my ($width, $style, $color) = split(/\s+/, $value);
	
		$propref->{border}->{all} = {width => $width,
			style => $style,
			color => $color};
	}
	
	# border-width, border-style, border-color
	for my $p (qw/width style color/) {
		if ($value = $props_css->{"border-$p"}) {
			$sides = $self->_by_sides($value);

			$propref->{border}->{all}->{$p} = $sides->{all};
			
			for (SIDE_NAMES) {
				$propref->{border}->{$_}->{$p} = $sides->{$_} || $sides->{all};
			}
		}
	}
	
	# border sides		
	for my $s (qw/top bottom left right/) {
		if ($value = $props_css->{"border-$s"}) {
			my ($width, $style, $color) = split(/\s+/, $value);

			$propref->{border}->{$s} = {width => $width,
				style => $style,
				color => $color};
		}

		for my $p (qw/width style color/) {
			if ($value = $props_css->{"border-$s-$p"}) {
				$propref->{border}->{$s}->{$p} = $value;
			}
		}
	}

	# clear
	if ($props_css->{clear}) {
		$propref->{clear} = $props_css->{clear};
	}
	elsif (! $propref->{clear}) {
		$propref->{clear} = 'none';
	}
	
	# color
	if ($props_css->{color}) {
		$propref->{color} = $props_css->{color};
	}

	# display
	if ($props_css->{display}) {
	    $propref->{display} = $props_css->{display};
	}

	# float
	if ($props_css->{float}) {
		$propref->{float} = $props_css->{float};
	}
	elsif (! $propref->{float}) {
		$propref->{float} = 'none';
	}
	
	# font
	if ($props_css->{'font-size'}) {
		$propref->{font}->{size} = $props_css->{'font-size'};
	}
	if ($props_css->{'font-family'}) {
	    $propref->{font}->{family} = ucfirst(lc($props_css->{'font-family'}));
	}
	if ($props_css->{'font-style'}) {
	    $propref->{font}->{style} = ucfirst(lc($props_css->{'font-style'}));
	}
	if ($props_css->{'font-weight'}) {
		$propref->{font}->{weight} = $props_css->{'font-weight'};
	}

	# height
	if ($props_css->{'height'}) {
		$propref->{height} = $props_css->{height};
	}

    # min-height
	if ($props_css->{'min-height'}) {
		$propref->{min_height} = $props_css->{'min-height'};
	}
    
	# line-height
	if ($props_css->{'line-height'}) {
		$propref->{'line_height'} = $props_css->{'line-height'};
	}

	# list-style
	if ($props_css->{'list-style'}) {
		$propref->{'list_style'} = $props_css->{'list-style'};
	}
	
	# margin
	if (exists $props_css->{'margin'}) {
		$sides = $self->_by_sides($props_css->{'margin'});

		for (SIDE_NAMES) {
			$propref->{margin}->{$_} = $sides->{$_} || $sides->{all};
		}
	}

	# margin sides
	for (SIDE_NAMES) {
		if (exists $props_css->{"margin-$_"}
			&& $props_css->{"margin-$_"} =~ /\S/) {
			$propref->{margin}->{$_} = $props_css->{"margin-$_"};
		}
	}
	
	# padding
	if ($props_css->{'padding'}) {
		$sides = $self->_by_sides($props_css->{'padding'});

		for (SIDE_NAMES) {
			$propref->{padding}->{$_} = $sides->{$_} || $sides->{all};
		}
	}

	# padding sides
	for (SIDE_NAMES) {
		if (exists $props_css->{"padding-$_"}
			&& $props_css->{"padding-$_"} =~ /\S/) {
			$propref->{padding}->{$_} = $props_css->{"padding-$_"};
		}
	}

	# text
	if ($props_css->{'text-align'}) {
		$propref->{text}->{align} = $props_css->{'text-align'};
	}
	if ($props_css->{'text-decoration'}) {
		$propref->{text}->{decoration} = $props_css->{'text-decoration'};
	}
	if ($props_css->{'text-transform'}) {
		$propref->{text}->{transform} = $props_css->{'text-transform'};
	}
	
	# transform
	for (qw/transform -webkit-transform -moz-transform -o-transform -ms-transform/) {
	    my ($prop_value, @frags);

            if ($prop_value = $props_css->{$_}) {
		@frags = split(/\s+/, $prop_value);

		for my $value (@frags) {
		    if ($value =~ s/^\s*rotate\(((-?)\d+(\.\d+)?)\s*deg\)\s*$/$1/) {
			if ($2) {
			    # negative angle
			    $propref->{rotate} = 360 + $value;
			}
			else {
			    $propref->{rotate} = $value;
			}
		    }
		    elsif ($value =~ /translate([xy])?\((.*?)(,(.*?))?\)/i) {
			if (lc($1) eq 'x') {
			    # translateX value
			    $propref->{translate}->{x} = $2;
			}
			elsif (lc($1) eq 'y') {
			    # translateY value
			    $propref->{translate}->{y} = $2;
			}
			else {
			    # translate value (x and optionally y)
			    $propref->{translate}->{x} = $2;
			    
			    if ($4) {
				$propref->{translate}->{y} = $4;
			    }
			}
		    }
		}

		last;
            }
        }

	# vertical-align
	if ($props_css->{'vertical-align'}) {
	    $propref->{vertical_align} = $props_css->{'vertical-align'};
	}

	# width
	if ($props_css->{'width'}) {
		$propref->{width} = $props_css->{width};
	}

    # min-width
    if ($props_css->{'min-width'}) {
        $propref->{min_width} = $props_css->{'min-width'};
    }
    
	return $propref;
}

sub _expand_properties {
    my ($self, $props) = @_;

    # border sides		
    for my $s (SIDE_NAMES) {
	for my $p (qw/width style color/) {
	    next if exists $props->{border}->{$s}->{$p};
	    $props->{border}->{$s}->{$p} =  $props->{border}->{all}->{$p};    
	}
    }
}

sub inherit {
	my ($self, $inherit) = @_;
	my (%props);

	# font
	if ($inherit->{font}) {
		%{$props{font}} = %{$inherit->{font}};
	}

	# line height
	if ($inherit->{line_height}) {
		$props{line_height} = $inherit->{line_height};
	}

	# text
	if ($inherit->{text}) {
		$props{text} = $inherit->{text};
	}
	
	return \%props;
}

# helper functions

sub _by_sides {
	my ($self, $value) = @_;
	my (@specs, %sides);

	@specs = split(/\s+/, $value);

	if (@specs == 1) {
		# all sides		
		$sides{all} = $specs[0];
	} elsif (@specs == 2) {
		# top/bottom, left/right
		$sides{top} = $sides{bottom} = $specs[0];
		$sides{left} = $sides{right} = $specs[1];
	} elsif (@specs == 3) {
		# top, left/right, bottom
		$sides{top} = $specs[0];
		$sides{left} = $sides{right} = $specs[1];
		$sides{bottom} = $specs[2];
	} elsif (@specs == 4) {
		# top, right, bottom, left
		$sides{top} = $specs[0];
		$sides{right} = $specs[1];
		$sides{bottom} = $specs[2];
		$sides{left} = $specs[3];
	}

	return \%sides;

}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-flute-style-css at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Flute-Style-CSS>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Flute::Style::CSS

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Flute-Style-CSS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Flute-Style-CSS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Flute-Style-CSS>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Flute-Style-CSS/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;

