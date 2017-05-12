package SVG::Rasterize::Engine::PangoCairo;
use base SVG::Rasterize::Engine;

use warnings;
use strict;

use 5.008009;

use Cairo;
use Pango;
use Params::Validate qw(:all);

use SVG::Rasterize::Regexes qw(%RE_NUMBER);

# $Id: PangoCairo.pm 6714 2011-05-21 08:55:13Z powergnom $

=head1 NAME

C<SVG::Rasterize::Engine::PangoCairo> - rasterize output using Cairo

=head1 VERSION

Version 0.003007

=cut

our $VERSION = '0.003007';


__PACKAGE__->mk_accessors(qw());

__PACKAGE__->mk_ro_accessors(qw(context
                                width
                                height));

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
            SVG::Rasterize->ex_at_ro("${class}->${field}");
        }
        else {
            return $self->get($field);
        }
    };
}

use constant PI => 3.14159265358979;

###########################################################################
#                                                                         #
#                             Init Process                                #
#                                                                         #
###########################################################################

sub new {
    my ($class, @args) = @_;

    my $self = bless {}, $class;
    $self->init(@args);
    return $self;
}

sub init {
    my ($self, @args) = @_;
    my %args          = validate_with
	(params  => \@args,
	 spec    => {width  => {regex => $RE_NUMBER{p_NNINTEGER}},
		     height => {regex => $RE_NUMBER{p_NNINTEGER}}},
	 on_fail => sub { SVG::Rasterize->ex_pv($_[0]) });

    $self->{width}  = $args{width};
    $self->{height} = $args{height};

    my $surface = ($args{surface_class} || 'Cairo::ImageSurface')->create
	('argb32', $args{width}, $args{height});
    $self->{context} = Cairo::Context->create($surface);

    return $self;
}

###########################################################################
#                                                                         #
#                               Accessors                                 # 
#                                                                         #
###########################################################################

###########################################################################
#                                                                         #
#                                Drawing                                  #
#                                                                         #
###########################################################################

sub _prepare_fill {
    my ($self, $properties) = @_;
    my $context             = $self->{context};

    if(my $fill = $properties->{'fill'}) {
	$context->set_source_rgba($fill->[0] / 256,  # values are clamped
				  $fill->[1] / 256,  # by cairo
				  $fill->[2] / 256,
				  $properties->{'fill-opacity'});

	if($properties->{'fill-rule'} eq 'nonzero') {
	    $context->set_fill_rule('winding');
	}
	elsif($properties->{'fill-rule'} eq 'evenodd') {
	    $context->set_fill_rule('even-odd');
	}
    }

    return;
}

sub _prepare_stroke {
    my ($self, $properties) = @_;
    my $context             = $self->{context};

    if(my $stroke = $properties->{'stroke'}) {
	$context->set_source_rgba($stroke->[0] / 256,  # values are
				  $stroke->[1] / 256,  # clamped by cairo
				  $stroke->[2] / 256,
				  $properties->{'stroke-opacity'});

	$context->set_line_width($properties->{'stroke-width'});

	# could be simplified, but I keep it for homogeinity
	if($properties->{'stroke-linecap'} eq 'butt') {
	    $context->set_line_cap('butt');
	}
	elsif($properties->{'stroke-linecap'} eq 'round') {
	    $context->set_line_cap('round');
	}
	if($properties->{'stroke-linecap'} eq 'square') {
	    $context->set_line_cap('square');
	}

	# could be simplified, but I keep it for homogeinity
	if($properties->{'stroke-linejoin'} eq 'miter') {
	    $context->set_line_join('miter');
	}
	elsif($properties->{'stroke-linejoin'} eq 'round') {
	    $context->set_line_join('round');
	}
	if($properties->{'stroke-linejoin'} eq 'bevel') {
	    $context->set_line_join('bevel');
	}

	$context->set_miter_limit($properties->{'stroke-miterlimit'});

	my @dash = ($properties->{'stroke-dashoffset'});
	if($properties->{'stroke-dasharray'}) {
	    push(@dash, @{$properties->{'stroke-dasharray'}});
	}
	$context->set_dash(@dash);
    }

    return;
}

sub _fill {
    my ($self, $properties) = @_;

    if($properties->{'fill'}) {
	$self->_prepare_fill($properties);
	$self->{context}->fill;
    }
    else {
	$self->{context}->new_path;
    }

    return;
}

sub _stroke {
    my ($self, $properties) = @_;

    if($properties->{'stroke'}) {
	$self->_prepare_stroke($properties);
	$self->{context}->stroke;
    }
    else {
	$self->{context}->new_path;
    }

    return;
}

sub _fill_and_stroke {
    my ($self, $properties) = @_;
    my $context             = $self->{context};

    $context->push_group;

    if($properties->{'fill'}) {
	$self->_prepare_fill($properties);
	$context->fill_preserve;
    }

    if($properties->{'stroke'}) {
	$self->_prepare_stroke($properties);
	my $op = $properties->{'stroke-opacity'};
	if(defined($op) and $op < 1) {
	    $context->save;
	    $context->set_operator('clear');
	    $context->stroke_preserve;
	    $context->restore;
	}
	$context->stroke;
    }
    else {
	$context->new_path;
    }

    $context->pop_group_to_source;
    $context->paint;

    return;
}

sub draw_path {
    my ($self, $state, @instructions) = @_;
    my $context                       = $self->{context};
    
    $context->save;
    $context->set_matrix(Cairo::Matrix->init(@{$state->matrix}));
    
    my @last_control = ();
    foreach(@instructions) {
	if($_->[0] eq 'M') {
	    @last_control = ();
	    $context->move_to($_->[1], $_->[2]);
	    next;
	}
	if($_->[0] eq 'm') {
	    @last_control = ();
	    if($context->has_current_point) {
		$context->rel_move_to($_->[1], $_->[2]);
	    }
	    else {
		$context->move_to($_->[1], $_->[2]);
	    }
	    next;
	}
	if($_->[0] eq 'Z' or $_->[0] eq 'z') {
	    @last_control = ();
	    $context->close_path;
	    next;
	}
	if($_->[0] eq 'L') {
	    @last_control = ();
	    $context->line_to($_->[1], $_->[2]);
	    next;
	}
	if($_->[0] eq 'l') {
	    @last_control = ();
	    $context->rel_line_to($_->[1], $_->[2]);
	    next;
	}
	if($_->[0] eq 'H') {
	    @last_control = ();
	    my @curr = $context->get_current_point;
	    $context->line_to($_->[1], $curr[1]);
	    next;
	}
	if($_->[0] eq 'h') {
	    @last_control = ();
	    $context->rel_line_to($_->[1], 0);
	    next;
	}
	if($_->[0] eq 'V') {
	    @last_control = ();
	    my @curr = $context->get_current_point;
	    $context->line_to($curr[0], $_->[1]);
	    next;
	}
	if($_->[0] eq 'v') {
	    @last_control = ();
	    $context->rel_line_to(0, $_->[1]);
	    next;
	}
	if($_->[0] eq 'C') {
	    $context->curve_to(@$_[1..6]);
	    @last_control = ($_->[3], $_->[4]);
	    next;
	}
	if($_->[0] eq 'c') {
	    my @curr = $context->get_current_point;
	    $context->rel_curve_to(@$_[1..6]);
	    @last_control = ($curr[0] + $_->[3], $curr[1] + $_->[4]);
	    next;
	}
	if($_->[0] eq 'S') {
	    my @coords = (undef, undef, @$_[1..4]);
	    my @curr   = $context->get_current_point;
	    if(@last_control) {
		$coords[0] = 2 * $curr[0] - $last_control[0];
		$coords[1] = 2 * $curr[1] - $last_control[1];
	    }
	    else { ($coords[0], $coords[1]) = @curr }

	    $context->curve_to(@coords);
	    @last_control = ($_->[1], $_->[2]);
	    next;
	}
	if($_->[0] eq 's') {
	    my @coords = (undef, undef, @$_[1..4]);
	    my @curr   = $context->get_current_point;
	    if(@last_control) {
		$coords[0] = $curr[0] - $last_control[0];
		$coords[1] = $curr[1] - $last_control[1];
	    }
	    else { ($coords[0], $coords[1]) = (0, 0) }

	    $context->rel_curve_to(@coords);
	    @last_control = ($curr[0] + $_->[1], $curr[1] + $_->[2]);
	    next;
	}
	if($_->[0] eq 'Q') {
	    my @curr   = $context->get_current_point;
	    my @coords = (1/3 * $curr[0] + 2/3 * $_->[1],
			  1/3 * $curr[1] + 2/3 * $_->[2],
			  2/3 * $_->[1]  + 1/3 * $_->[3],
			  2/3 * $_->[2]  + 1/3 * $_->[4],
			  $_->[3],
			  $_->[4]);

	    $context->curve_to(@coords);
	    @last_control = ($_->[1], $_->[2]);
	    next;
	}
	if($_->[0] eq 'q') {
	    my @curr   = $context->get_current_point;
	    my @coords = ($curr[0] + 2/3 * $_->[1],
			  $curr[1] + 2/3 * $_->[2],
			  $curr[0] + 2/3 * $_->[1] + 1/3 * $_->[3],
			  $curr[1] + 2/3 * $_->[2] + 1/3 * $_->[4],
			  $curr[0] + $_->[3],
			  $curr[1] + $_->[4]);

	    $context->curve_to(@coords);
	    @last_control = ($curr[0] + $_->[1], $curr[1] + $_->[2]);
	    next;
	}
	if($_->[0] eq 'T') {
	    my @curr    = $context->get_current_point;
	    my @control = @curr;
	    if(@last_control) {
		$control[0] = 2 * $curr[0] - $last_control[0];
		$control[1] = 2 * $curr[1] - $last_control[1];
	    }
	    my @coords = (1/3 * $curr[0]    + 2/3 * $control[0],
			  1/3 * $curr[1]    + 2/3 * $control[1],
			  2/3 * $control[0] + 1/3 * $_->[1],
			  2/3 * $control[1] + 1/3 * $_->[2],
			  $_->[1],
			  $_->[2]);

	    $context->curve_to(@coords);
	    @last_control = ($control[0], $control[1]);
	    next;
	}
	if($_->[0] eq 't') {
	    my @curr    = $context->get_current_point;
	    my @control = @curr;
	    if(@last_control) {
		$control[0] = 2 * $curr[0] - $last_control[0];
		$control[1] = 2 * $curr[1] - $last_control[1];
	    }
	    my @coords = (1/3 * $curr[0]    + 2/3 * $control[0],
			  1/3 * $curr[1]    + 2/3 * $control[1],
			  2/3 * $control[0] + 1/3 * ($curr[0] + $_->[1]),
			  2/3 * $control[1] + 1/3 * ($curr[1] + $_->[2]),
			  $curr[0] + $_->[1],
			  $curr[1] + $_->[2]);

	    $context->curve_to(@coords);
	    @last_control = ($control[0], $control[1]);
	    next;
	}
	if($_->[0] eq 'A') {
	    @last_control = ();
	    my @curr = $context->get_current_point;
	    my ($cx, $cy, $rx, $ry, $th1, $dth) =
		SVG::Rasterize::endpoint_to_center(@curr, (@$_)[1..7]);

	    # If nothing comes back it means that a radius is 0
	    # (but then we would not be here because the command
	    # has been switched to a lineto) or start and end are
	    # equal. In this case we do nothing.
	    next if(!defined($cx));

	    my $sin_phi = sin($_->[3]);
	    my $cos_phi = cos($_->[3]);
	    my $matrix  = SVG::Rasterize::multiply_matrices
		($state->{matrix}, [$rx * $cos_phi, -$ry * $sin_phi,
				    $rx * $sin_phi,  $ry * $cos_phi,
				    $cx, $cy]);
	    $context->save;
	    $context->set_matrix(Cairo::Matrix->init(@$matrix));
	    if($dth > 0) {
		$context->arc(0, 0, 1, $th1, $th1 + $dth);
	    }
	    else {
		$context->arc_negative(0, 0, 1, $th1, $th1 + $dth);
	    }
	    $context->restore;
	    next;
	}
	if($_->[0] eq 'a') {
	    @last_control = ();
	    my @curr = $context->get_current_point;
	    my @end  = ($curr[0] + $_->[6], $curr[1] + $_->[7]);  
	    my ($cx, $cy, $rx, $ry, $th1, $dth) =
		SVG::Rasterize::endpoint_to_center
		    (@curr, (@$_)[1..5], @end);

	    # see 'A'
	    next if(!defined($cx));

	    my $sin_phi = sin($_->[3]);
	    my $cos_phi = cos($_->[3]);
	    my $matrix  = SVG::Rasterize::multiply_matrices
		($state->{matrix}, [$rx * $cos_phi, -$ry * $sin_phi,
				    $rx * $sin_phi,  $ry * $cos_phi,
				    $cx, $cy]);
	    $context->save;
	    $context->set_matrix(Cairo::Matrix->init(@$matrix));
	    if($dth > 0) {
		$context->arc(0, 0, 1, $th1, $th1 + $dth);
	    }
	    else {
		$context->arc_negative(0, 0, 1, $th1, $th1 + $dth);
	    }
	    $context->restore;
	    next;
	}
    }

    $self->_fill_and_stroke($state->properties);
    $context->restore;

    return;
}

sub _text_layout {
    my ($self, $state, $cdata) = @_;
    my %font_weights           = (100 => 'thin',
				  200 => 'ultralight',
				  300 => 'light',
				  400 => 'normal',
				  500 => 'medium',
				  600 => 'semibold',
				  700 => 'bold',
				  800 => 'ultrabold',
				  900 => 'heavy');

    my $properties = $state->properties;
    my $layout     = Pango::Cairo::create_layout($self->{context});
    my $desc       = Pango::FontDescription->new;
    $desc->set_absolute_size
	(Pango::units_from_double($properties->{'font-size'}));
    $desc->set_family($properties->{'font-family'})
	if($properties->{'font-family'});
    $desc->set_style($properties->{'font-style'})
	if($properties->{'font-style'});
    $desc->set_variant($properties->{'font-variant'})
	if($properties->{'font-variant'});
    $desc->set_weight($font_weights{$properties->{'font-weight'}})
	if($properties->{'font-weight'});
    $desc->set_stretch($properties->{'font-stretch'})
	if($properties->{'font-stretch'});
    $layout->set_font_description($desc);
    $layout->set_text($cdata);

    return $layout;
}

sub text_width {
    my ($self, $state, $cdata) = @_;

    return 0 if(!$cdata);

    my $context = $self->{context};
    $context->save;

    $context->set_matrix(Cairo::Matrix->init(@{$state->matrix}));
    my $layout  = $self->_text_layout($state, $cdata);
    my $extents = $layout->get_pixel_extents;

    $context->restore;
    return $extents->{width};
}

sub draw_text {
    my ($self, $state, $x, $y, $rotate, $cdata) = @_;

    return if(!$cdata);

    my $properties = $state->properties;
    my $context    = $self->{context};
    $context->save;

    $context->set_matrix(Cairo::Matrix->init(@{$state->matrix}));
    my $layout   = $self->_text_layout($state, $cdata);
    my $extents  = $layout->get_pixel_extents;
    my $baseline = Pango::units_to_double($layout->get_baseline);
    $context->translate($x, $y);
    $context->rotate(($rotate || 0) * PI / 180);
    $context->translate(0 ,-$baseline);
    
    if($properties->{stroke}) {
	Pango::Cairo::layout_path($context, $layout);
	$self->_fill_and_stroke($properties);
    }
    else {
	$self->_prepare_fill($properties);
	Pango::Cairo::show_layout($context, $layout);
    }

    $context->restore;
    return;
}

sub write {
    my ($self, @args) = @_;

    my %args = validate_with
	(params  => \@args,
	 spec    => {type      => {regex => qr/^(?:png)$/},
		     file_name => {type  => SCALAR}},
	 on_fail => sub { SVG::Rasterize->ex_pv($_[0]) });

    if($args{type} eq 'png') {
	if(!$args{file_name}) {
	    warn("Unable to write png file. No file name specified.\n");
	    return undef;
	}

	$self->{context}->show_page;
	$self->{context}->get_target->write_to_png($args{file_name});
    }
    else {
	warn "Unknown output type ($args{type}).\n";
    }

    return;
}

1;

__END__

=head1 SYNOPSIS

  # explicit construction (unusual)
  use SVG::Rasterize::Engine::PangoCairo;
  my $engine = SVG::Rasterize::Engine::PangoCairo->new
      (width  => 640, height => 480);

=head1 DESCRIPTION

This class provides a rasterization backend for
L<SVG::Rasterize|SVG::Rasterize> based on the L<Cairo|Cairo> and
L<Pango|Pango> libraries.

This class is only instantiated by the L<rasterize
method|SVG::Rasterize/rasterize> of C<SVG::Rasterize>.

This documentation focues on this specific implementation. For a
more general description of the engine interface see
L<SVG::Rasterize::Engine|SVG::Rasterize::Engine>.

=head1 INTERFACE

=head2 Constructors

=head3 new

  SVG::Rasterize::Engine::PangoCairo->new(%args)

Creates a new C<SVG::Rasterize::Engine::PangoCairo> object and calls
C<init(%args)>. If you subclass
C<SVG::Rasterize::Engine::PangoCairo> overload C<init>, not C<new>.

=head3 init

  $cairo->init(%args)

If you overload C<init>, your method should also call this one.
It initializes the attributes L<width|/width> and L<height|/height>
which are mandatory parameters and have to be non-negative integers.

Other backends are also required to validate their init parameters
because the L<engine_args|SVG::Rasterize/engine_args> hash given by
the user to C<SVG::Rasterize> is handed over to the C<new>
constructor of the engine class without validation.

=head2 Public Attributes

=head2 Methods for Developers

See <SVG::Rasterize::Engine|SVG::Rasterize::Engine>.

=head3 draw_path

=head3 text_width

=head3 draw_text

=head3 write

  $engine->write(%args)

Writes the rendered image to a file.

B<Example:>

  $engine->write(type => 'png', file_name => 'foo.png');

C<type> and C<file_name> are the only supported parameters at the
moment and the only supported type is "png". If C<file_name> has a
false value, no output is written and a warning is issued. Besides
that, C<file_name> is not validated at all. Make sure that you
provide a sane value (whatever that means to you).


=head1 DIAGNOSTICS

=head2 Exceptions

=head2 Warnings


=head1 INTERNALS

=head2 Internal Methods

These methods are just documented for myself. You can read on to
satisfy your voyeuristic desires, but be aware of that they might
change or vanish without notice in a future version.

=over 4

=item * _prepare_fill

=item * _prepare_stroke

=item * _fill

=item * _stroke

=item * _fill_and_stroke

=item * make_ro_accessor

This piece of documentation is mainly here to make the C<POD>
coverage test happy. C<SVG::Rasterize::State> overloads
C<make_ro_accessor> to make the readonly accessors throw an
exception object (of class C<SVG::Rasterize::Exception::Attribute>)
instead of just croaking.

=back

=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Lutz Gehlen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
