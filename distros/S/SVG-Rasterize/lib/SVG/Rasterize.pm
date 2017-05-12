package SVG::Rasterize;
use base Class::Accessor;

use warnings;
use strict;

use 5.008009;

use Params::Validate qw(:all);
use Scalar::Util qw(blessed);

use SVG::Rasterize::Regexes qw(:whitespace
                               %RE_PACKAGE
                               %RE_NUMBER
                               %RE_LENGTH
                               %RE_PAINT
                               %RE_PATH
                               %RE_POLY);
use SVG::Rasterize::Exception qw(:all);
use SVG::Rasterize::State::Text;
use SVG::Rasterize::TextNode;

# $Id: Rasterize.pm 6717 2011-05-21 09:21:08Z powergnom $

=head1 NAME

C<SVG::Rasterize> - rasterize C<SVG> content to pixel graphics

=head1 VERSION

Version 0.003008

=cut

our $VERSION = '0.003008';


__PACKAGE__->mk_accessors(qw(normalize_attributes
                             svg
                             width
                             height
                             current_color
                             engine_class
                             engine_args));

__PACKAGE__->mk_ro_accessors(qw(engine
                                width
                                height
                                state));

###########################################################################
#                                                                         #
#                      Class Variables and Methods                        # 
#                                                                         #
###########################################################################

our %IGNORED_NODES        = (comment  => 1,
			     title    => 1,
			     desc     => 1,
			     metadata => 1);

our %DEFER_RASTERIZATION = (text     => 1,
			    textPath => 1);

our %TEXT_ROOT_ELEMENTS  = (text     => 1,
			    textPath => 1);

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

use constant TWO_PI => 6.28318530717959;

our $PX_PER_IN = 90;
our $DPI;  *DPI = \$PX_PER_IN;
our $IN_PER_CM = 1 / 2.54;
our $IN_PER_MM = 1 / 25.4;
our $IN_PER_PT = 1 / 72;
our $IN_PER_PC = 1 / 6;

sub multiply_matrices {
    my $n = pop(@_);
    my $m = pop(@_);

    return [$m->[0] * $n->[0] + $m->[2] * $n->[1],
	    $m->[1] * $n->[0] + $m->[3] * $n->[1],
	    $m->[0] * $n->[2] + $m->[2] * $n->[3],
	    $m->[1] * $n->[2] + $m->[3] * $n->[3],
	    $m->[0] * $n->[4] + $m->[2] * $n->[5] + $m->[4],
	    $m->[1] * $n->[4] + $m->[3] * $n->[5] + $m->[5]];
}

sub _angle {
    shift(@_) if(@_ % 2);
    my ($x1, $y1, $x2, $y2) = @_;
    my $l_prod              = sqrt(($x1**2 + $y1**2) * ($x2**2 + $y2**2));

    return undef if($l_prod == 0);

    my $scalar     = $x1 * $x2 + $y1 * $y2;
    my $cos        = $scalar / $l_prod;
    my $sign       = $x1 * $y2 - $y1 * $x2 > 0 ? 1 : -1;
    my $sin        = $sign * sqrt($l_prod**2 - $scalar**2) / $l_prod;

    $cos = 1  if($cos > 1);
    $cos = -1 if($cos < -1);
    $sin = 1  if($sin > 1);
    $sin = -1 if($sin < -1);

    return atan2($sin, $cos);
}

sub adjust_arc_radii {
    shift(@_) if(@_ % 2 == 0);
    my ($x1, $y1, $rx, $ry, $phi, $x2, $y2) = @_;

    $rx = abs($rx);
    $ry = abs($ry);
    return($rx, $ry) if($rx == 0 or $ry == 0);
    
    my $sin_phi = sin($phi);
    my $cos_phi = cos($phi);
    my $x1_h    = ($x1 - $x2) / 2;
    my $y1_h    = ($y1 - $y2) / 2;
    my $x1_p    =  $cos_phi * $x1_h + $sin_phi * $y1_h;
    my $y1_p    = -$sin_phi * $x1_h + $cos_phi * $y1_h;
    my $lambda  = ($x1_p / $rx) ** 2 + ($y1_p / $ry) ** 2;

    return($rx, $ry, $sin_phi, $cos_phi, $x1_p, $y1_p) if($lambda <= 0);

    my $radicand = 1 / $lambda - 1;
    if($radicand < 0) {
	my $sqrt_lambda = sqrt($lambda);
	$rx       *= $sqrt_lambda;
	$ry       *= $sqrt_lambda;
	$radicand  = 0;
    }

    return($rx, $ry, $sin_phi, $cos_phi, $x1_p, $y1_p, $radicand);
}

sub endpoint_to_center {
    shift(@_) if(@_ % 2 == 0);
    my ($x1, $y1, $rx, $ry, $phi, $fa, $fs, $x2, $y2) = @_;
    my ($sin_phi, $cos_phi, $x1_p, $y1_p, $radicand);

    ($rx, $ry, $sin_phi, $cos_phi, $x1_p, $y1_p, $radicand) =
	adjust_arc_radii($x1, $y1, $rx, $ry, $phi, $x2, $y2);

    return if(!defined($radicand));

    my ($cx_p, $cy_p);
    my $factor;
    if($radicand > 0) {
	$factor = ($fa == $fs ? -1 : 1) * sqrt($radicand);
	$cx_p   =      $factor * $rx / $ry * $y1_p;
	$cy_p   = -1 * $factor * $ry / $rx * $x1_p;
    }
    else {
	$cx_p = 0;
	$cy_p = 0;
    }

    my $x1_c = ($x1 + $x2) / 2;
    my $y1_c = ($y1 + $y2) / 2;
    my $cx   = $cos_phi * $cx_p - $sin_phi * $cy_p + $x1_c;
    my $cy   = $sin_phi * $cx_p + $cos_phi * $cy_p + $y1_c;

    # 0 <= $th1 < 2PI
    my $th1  = _angle(1, 0, ($x1_p - $cx_p) / $rx, ($y1_p - $cy_p) / $ry);
    $th1 += TWO_PI while($th1 < 0);

    # sign of $dth
    my $dth  = _angle(($x1_p - $cx_p) / $rx, ($y1_p - $cy_p) / $ry,
		      (-$x1_p - $cx_p) / $rx, (-$y1_p - $cy_p) / $ry);
    if($fs == 0) { $dth -= TWO_PI while($dth > 0) }
    else         { $dth += TWO_PI while($dth < 0) }
    
    return($cx, $cy, $rx, $ry, $th1, $dth);
}

###########################################################################
#                                                                         #
#                             Init Process                                #
#                                                                         #
###########################################################################

sub new {
    my ($class, @args) = @_;

    my $self = bless {}, $class;
    return $self->init(@args);
}

sub init {
    my ($self, %args) = @_;

    foreach(keys %args) {
	my $meth = $_;
	if($self->can($meth)) { $self->$meth($args{$meth}) }
	else { warn "Unrecognized init parameter $meth.\n" }
    }

    # setting default values
    $self->restore_all_hooks(preserve => 1);
    # false medium font-size other than undef has already caused an
    # exception, therefore ||= is ok:
    $self->{medium_font_size} ||= '12pt';
    # font_size_scale must be set via the accessor such that the
    # font size scale table is created; false other than undef has
    # already caused an exception, therefore ! is ok:
    $self->font_size_scale(1.2) if(!$self->{font_size_scale});

    return $self;
}

sub _initial_viewport {
    my ($self, $node_attributes, $args_ptr) = @_;
    my $matrix                              = [1, 0, 0, 1, 0, 0];
    my @width                               = ();
    my @height                              = ();

    # NB: $node_attributes are not validated and can have any value
    # at this point. However, the values of $args_ptr have been
    # validated.

    # collecting information
    # width
    $width[0] = defined($args_ptr->{width})
	? int($self->map_abs_length($args_ptr->{width}) + 0.5) : undef;
    $self->ex_su_iw($width[0]) if(($width[0] || 0) < 0);

    $width[1] = defined($node_attributes->{width})
	? $node_attributes->{width} : undef;
    if($width[1]) {
	$self->ex_su_iw($width[1])
	    if($width[1] !~ $RE_LENGTH{p_A_LENGTH});
	$width[1] = undef if($width[1] eq '100%');
    }
    if($width[1]) {
	if($width[1] !~ $RE_LENGTH{p_ABS_A_LENGTH}) {
	    $self->ex_us_si("Relative length (different from 100%) for ".
			    "width of root element ($width[1])");
	}
	$width[1] = int($self->map_abs_length($width[1]) + 0.5);
	$self->ex_su_iw($width[1]) if($width[1] < 0);
    }
    
    # height
    $height[0] = defined($args_ptr->{height})
	? int($self->map_abs_length($args_ptr->{height}) + 0.5) : undef;
    $self->ex_su_iw($height[0]) if(($height[0] || 0) < 0);

    $height[1] = defined($node_attributes->{height})
	? $node_attributes->{height} : undef;
    if($height[1]) {
	$self->ex_su_iw($height[1])
	    if($height[1] !~ $RE_LENGTH{p_A_LENGTH});
	$height[1] = undef if($height[1] eq '100%');
    }
    if($height[1]) {
	if($height[1] !~ $RE_LENGTH{p_ABS_A_LENGTH}) {
	    $self->ex_us_si("Relative length (different from 100%) for ".
			    "height of root element ($height[1])");
	}
	$height[1] = int($self->map_abs_length($height[1]) + 0.5);
	$self->ex_su_iw($height[1]) if($height[1] < 0);
    }
    
    # width mapping
    if($width[0]) {
	if($width[1]) { $matrix->[0] = $width[0] / $width[1]  }
	else          { $node_attributes->{width} = $width[0] }
    }
    elsif($width[1]) { $width[0] = $width[1] }
    else             { $width[0] = 0         }

    # same for height
    if($height[0]) {
	if($height[1]) { $matrix->[3] = $height[0] / $height[1]  }
	else           { $node_attributes->{height} = $height[0] }
    }
    elsif($height[1]) { $height[0] = $height[1] }
    else              { $height[0] = 0          }

    $args_ptr->{width}  = $width[0];
    $args_ptr->{height} = $height[0];
    $args_ptr->{matrix} = $matrix;

    return;
}

sub _create_engine {
    my ($self, $args_ptr) = @_;

    # The values of $args_ptr have been validated, but
    # $args_ptr->{engine_args} is only validated to be a HASH
    # reference (if it exists at all).

    my $default           = 'SVG::Rasterize::Engine::PangoCairo';
    my %engine_args       = (width  => $args_ptr->{width},
			     height => $args_ptr->{height},
			     %{$args_ptr->{engine_args} || {}});

    $args_ptr->{engine_class} ||= $default;
    my $load_success = eval "require $args_ptr->{engine_class}";
    if(!$load_success and $args_ptr->{engine_class} ne $default) {
	warn("Unable to load $args_ptr->{engine_class}: $!. ".
	     "Falling back to $default.\n");
	$args_ptr->{engine_class} = $default;
	$load_success = eval "require $args_ptr->{engine_class}";
    }
    if(!$load_success) {
	$self->ex_se_lo($args_ptr->{engine_class}, $!);
    }

    $self->{engine} = $args_ptr->{engine_class}->new(%engine_args);

    return $self->{engine};
}

###########################################################################
#                                                                         #
#                               Accessors                                 # 
#                                                                         #
###########################################################################

sub px_per_in {
    my ($self, @args) = @_;

    if(@args) {
	validate_with(params  => \@args,
		      spec    => [{regex => $RE_NUMBER{p_A_NNNUMBER}}],
		      on_fail => sub { $self->ex_pv($_[0]) });
	$self->{px_per_in} = $args[0];
    }

    return defined($self->{px_per_in}) ? $self->{px_per_in} : $PX_PER_IN;
}

*dpi = \&px_per_in;  &dpi if(0);

sub in_per_cm {
    my ($self, @args) = @_;

    if(@args) {
	validate_with(params  => \@args,
		      spec    => [{regex => $RE_NUMBER{p_A_NNNUMBER}}],
		      on_fail => sub { $self->ex_pv($_[0]) });
	$self->{in_per_cm} = $args[0];
    }

    return defined($self->{in_per_cm}) ? $self->{in_per_cm} : $IN_PER_CM;
}

sub in_per_mm {
    my ($self, @args) = @_;

    if(@args) {
	validate_with(params  => \@args,
		      spec    => [{regex => $RE_NUMBER{p_A_NNNUMBER}}],
		      on_fail => sub { $self->ex_pv($_[0]) });
	$self->{in_per_mm} = $args[0];
    }

    return defined($self->{in_per_mm}) ? $self->{in_per_mm} : $IN_PER_MM;
}

sub in_per_pt {
    my ($self, @args) = @_;

    if(@args) {
	validate_with(params  => \@args,
		      spec    => [{regex => $RE_NUMBER{p_A_NNNUMBER}}],
		      on_fail => sub { $self->ex_pv($_[0]) });
	$self->{in_per_pt} = $args[0];
    }

    return defined($self->{in_per_pt}) ? $self->{in_per_pt} : $IN_PER_PT;
}

sub in_per_pc {
    my ($self, @args) = @_;

    if(@args) {
	validate_with(params  => \@args,
		      spec    => [{regex => $RE_NUMBER{p_A_NNNUMBER}}],
		      on_fail => sub { $self->ex_pv($_[0]) });
	$self->{in_per_pc} = $args[0];
    }

    return defined($self->{in_per_pc}) ? $self->{in_per_pc} : $IN_PER_PC;
}

sub map_abs_length {
    my ($self, @args) = @_;

    my ($number, $unit);
    if(@args < 2) {
	validate_with(params  => \@args,
		      spec    => [{regex => $RE_LENGTH{p_A_LENGTH}}],
		      on_fail => sub { $self->ex_pv($_[0]) });
	($number, $unit) =
	    $args[0] =~ /^($RE_NUMBER{A_NUMBER})($RE_LENGTH{UNIT}?)$/;
    }
    else { ($number, $unit) = @args }  # bypasses validation!

    my $dpi = $self->px_per_in;
    if(!$unit)           { return $number }
    elsif($unit eq 'em') { $self->ex_pm_rl($number.$unit) }
    elsif($unit eq 'ex') { $self->ex_pm_rl($number.$unit) }
    elsif($unit eq 'px') { return $number }
    elsif($unit eq 'pt') { return $number * $self->in_per_pt * $dpi }
    elsif($unit eq 'pc') { return $number * $self->in_per_pc * $dpi }
    elsif($unit eq 'cm') { return $number * $self->in_per_cm * $dpi }
    elsif($unit eq 'mm') { return $number * $self->in_per_mm * $dpi }
    elsif($unit eq 'in') { return $number * $dpi }
    elsif($unit eq '%')  { $self->ex_pm_rl($number.$unit) }
}

sub medium_font_size {
    my ($self, @args) = @_;

    if(@args) {
	validate_with(params  => \@args,
		      spec    => [{type  => SCALAR,
				   regex => $RE_LENGTH{p_ABS_A_LENGTH}}],
		      on_fail => sub { $self->ex_pv($_[0]) });
	$self->ex_pm_mf_ne($args[0])
	    if($self->map_abs_length($args[0]) <= 0);
	$self->{medium_font_size}->{default} = $args[0];
    }

    return $self->{medium_font_size}->{default};
}

sub _generate_font_size_scale_table {
    my ($self) = @_;
    my $scale  = $self->{font_size_scale}->{default};

    $self->{_font_size_scale_table} ||= {};
    $self->{_font_size_scale_table}->{default} =
        {'xx-small' => 1 / $scale**3,
	 'x-small'  => 1 / $scale**2,
	 'small'    => 1 / $scale,
	 'medium'   => 1,
	 'large'    => $scale,
	 'x-large'  => $scale**2,
	 'xx-large' => $scale**3};
}

sub font_size_scale {
    my ($self, @args) = @_;

    if(@args) {
	validate_with(params  => \@args,
		      spec    => [{type  => SCALAR,
				   regex => $RE_NUMBER{p_A_NNNUMBER}}],
		      on_fail => sub { $self->ex_pv($_[0]) });
	$self->{font_size_scale}->{default} = $args[0];
	$self->_generate_font_size_scale_table;
    }

    return $self->{font_size_scale}->{default};
}

sub absolute_font_size {
    my ($self, $name) = @_;
    my $table         = $self->{_font_size_scale_table}->{default};

    return undef if(!defined($name));
    return($self->map_abs_length($self->{medium_font_size})
	   * $table->{$name});
}

sub relative_font_size {
    my ($self, $name, $reference_size) = @_;

    if($name eq 'smaller') {
	$self->ex_us_pl("Relative font sizes (e.g. 'smaller')");
    }
    elsif($name eq 'larger') {
	$self->ex_us_pl("Relative font sizes (e.g. 'smaller')");
    }
    else { return undef }
}

###########################################################################
#                                                                         #
#                                 Hooks                                   # 
#                                                                         #
###########################################################################

sub before_node_hook {
    my ($self, @args) = @_;

    if(@args) {
	validate_with(params  => \@args,
		      spec    => [{type => CODEREF|UNDEF}],
		      on_fail => sub { $self->ex_pv($_[0]) });
	$self->{before_node_hook} = $args[0];
    }

    return $self->{before_node_hook} || sub {};
}

sub restore_before_node_hook {
    my ($self) = @_;

    $self->{before_node_hook} ||= sub {
	shift(@_);
	return @_;
    };

    return;
}

sub start_node_hook {
    my ($self, @args) = @_;

    if(@args) {
	validate_with(params  => \@args,
		      spec    => [{type => CODEREF|UNDEF}],
		      on_fail => sub { $self->ex_pv($_[0]) });
	$self->{start_node_hook} = $args[0];
    }

    return $self->{start_node_hook} || sub {};
}

sub restore_start_node_hook {
    shift(@_)->{start_node_hook} = undef;
}

sub end_node_hook {
    my ($self, @args) = @_;

    if(@args) {
	validate_with(params  => \@args,
		      spec    => [{type => CODEREF|UNDEF}],
		      on_fail => sub { $self->ex_pv($_[0]) });
	$self->{end_node_hook} = $args[0];
    }

    return $self->{end_node_hook} || sub {};
}

sub restore_end_node_hook {
    shift(@_)->{end_node_hook} = undef;
}

sub in_error_hook {
    my ($self, @args) = @_;

    if(@args) {
	validate_with(params  => \@args,
		      spec    => [{type => CODEREF|UNDEF}],
		      on_fail => sub { $self->ex_pv($_[0]) });
	$self->{in_error_hook} = $args[0];
    }

    return $self->{in_error_hook} || sub {};
}

sub restore_in_error_hook {
    my ($self) = @_;

    $self->{in_error_hook} ||= sub {
	my ($self, $state) = @_;
	my $engine         = $self->engine or return;
	my $width          = $engine->width;
	my $height         = $engine->height;
	my $min            = $width < $height ? $width : $height;
	my $edge           = $min / 8;
	my $properties     = $state->properties;

	$properties->{'fill'}         = [90, 90, 90];
	$properties->{'fill-opacity'} = 0.6;
	
	my $i = 0;
	while($i * $edge < $width) {
	    my $j = $i % 2;
	    while($j * $edge < $height) {
		$engine->draw_path($state,
				   ['M', $i*$edge, $j*$edge],
				   ['h', $edge],
				   ['v', $edge],
				   ['h', -$edge],
				   ['z']);
		$j += 2;
	    }
	    $i++;
	}

	return;
    };

    return;
}

sub restore_all_hooks {
    my ($self, @args) = @_;
    my %args          = validate_with
	(params  => \@args,
	 spec    => {preserve => {type     => UNDEF|SCALAR,
				  optional => 1}},
	 on_fail => sub { $self->ex_pv($_[0]) });

    my @hooks = qw(before_node_hook
                   start_node_hook
                   end_node_hook
                   in_error_hook);

    foreach(@hooks) {
	next if($args{preserve} and $self->{$_});
	my $meth = "restore_$_";
	$self->$meth;
    }
}

###########################################################################
#                                                                         #
#                                Drawing                                  #
#                                                                         #
###########################################################################

################################## Paths ##################################

sub _split_path_data {
    my ($self, $d)    = @_;
    my @sub_path_data = grep { /\S/ } split(qr/$WSP*([a-zA-Z])$WSP*/, $d);
    my @instructions  = ();
    my $in_error      = 0;

    my $arg_sequence;
  INSTR_SEQ:
    while(@sub_path_data) {
	my $key = shift(@sub_path_data);

	if($key eq 'M' or $key eq 'm') {
	    if(!@sub_path_data) {
		$in_error = 1;
		last INSTR_SEQ;
	    }
	    $arg_sequence = shift(@sub_path_data);

	    while($arg_sequence) {
		if($arg_sequence =~ $RE_PATH{MAS_SPLIT}) {
		    push(@instructions, [$key, $1, $2]);
		    $arg_sequence = $3;

		    # subsequent moveto cmds are turned into lineto
		    $key = 'L' if($key eq 'M');
		    $key = 'l' if($key eq 'm');
		}
		else {
		    $in_error = 1;
		    last INSTR_SEQ;
		}
	    }
	    next;
	}
	if($key eq 'Z' or $key eq 'z') {
	    push(@instructions, [$key]);
	    next;
	}
	if($key eq 'L' or $key eq 'l') {
	    if(!@sub_path_data) {
		$in_error = 1;
		last INSTR_SEQ;
	    }
	    $arg_sequence = shift(@sub_path_data);

	    while($arg_sequence) {
		if($arg_sequence =~ $RE_PATH{LAS_SPLIT}) {
		    push(@instructions, [$key, $1, $2]);
		    $arg_sequence = $3;
		}
		else {
		    $in_error = 1;
		    last INSTR_SEQ;
		}
	    }
	    next;
	}
	if($key eq 'H' or $key eq 'h') {
	    if(!@sub_path_data) {
		$in_error = 1;
		last INSTR_SEQ;
	    }
	    $arg_sequence = shift(@sub_path_data);

	    while($arg_sequence) {
		if($arg_sequence =~ $RE_PATH{HLAS_SPLIT}) {
		    push(@instructions, [$key, $1]);
		    $arg_sequence = $2;
		}
		else {
		    $in_error = 1;
		    last INSTR_SEQ;
		}
	    }
	    next;
	}
	if($key eq 'V' or $key eq 'v') {
	    if(!@sub_path_data) {
		$in_error = 1;
		last INSTR_SEQ;
	    }
	    $arg_sequence = shift(@sub_path_data);

	    while($arg_sequence) {
		if($arg_sequence =~ $RE_PATH{VLAS_SPLIT}) {
		    push(@instructions, [$key, $1]);
		    $arg_sequence = $2;
		}
		else {
		    $in_error = 1;
		    last INSTR_SEQ;
		}
	    }
	    next;
	}
	if($key eq 'C' or $key eq 'c') {
	    if(!@sub_path_data) {
		$in_error = 1;
		last INSTR_SEQ;
	    }
	    $arg_sequence = shift(@sub_path_data);

	    while($arg_sequence) {
		if($arg_sequence =~ $RE_PATH{CAS_SPLIT}) {
		    push(@instructions, [$key, $1, $2, $3, $4, $5, $6]);
		    $arg_sequence = $7;
		}
		else {
		    $in_error = 1;
		    last INSTR_SEQ;
		}
	    }
	    next;
	}
	if($key eq 'S' or $key eq 's') {
	    if(!@sub_path_data) {
		$in_error = 1;
		last INSTR_SEQ;
	    }
	    $arg_sequence = shift(@sub_path_data);

	    while($arg_sequence) {
		if($arg_sequence =~ $RE_PATH{SCAS_SPLIT}) {
		    push(@instructions, [$key, $1, $2, $3, $4]);
		    $arg_sequence = $5;
		}
		else {
		    $in_error = 1;
		    last INSTR_SEQ;
		}
	    }
	    next;
	}
	if($key eq 'Q' or $key eq 'q') {
	    if(!@sub_path_data) {
		$in_error = 1;
		last INSTR_SEQ;
	    }
	    $arg_sequence = shift(@sub_path_data);

	    while($arg_sequence) {
		if($arg_sequence =~ $RE_PATH{QBAS_SPLIT}) {
		    push(@instructions, [$key, $1, $2, $3, $4]);
		    $arg_sequence = $5;
		}
		else {
		    $in_error = 1;
		    last INSTR_SEQ;
		}
	    }
	    next;
	}
	if($key eq 'T' or $key eq 't') {
	    if(!@sub_path_data) {
		$in_error = 1;
		last INSTR_SEQ;
	    }
	    $arg_sequence = shift(@sub_path_data);

	    while($arg_sequence) {
		if($arg_sequence =~ $RE_PATH{SQBAS_SPLIT}) {
		    push(@instructions, [$key, $1, $2]);
		    $arg_sequence = $3;
		}
		else {
		    $in_error = 1;
		    last INSTR_SEQ;
		}
	    }
	    next;
	}
	if($key eq 'A' or $key eq 'a') {
	    if(!@sub_path_data) {
		$in_error = 1;
		last INSTR_SEQ;
	    }
	    $arg_sequence = shift(@sub_path_data);

	    while($arg_sequence) {
		if($arg_sequence =~ $RE_PATH{EAAS_SPLIT}) {
		    if($1 == 0 or $2 == 0) {
			# 0 radius: turn into lineto
			push(@instructions,
			     [($key eq 'A' ? 'L' : 'l'), $6, $7]);
		    }
		    else {
			push(@instructions,
			     [$key, $1, $2, $3, $4, $5, $6, $7]);
		    }
		    $arg_sequence = $8;
		}
		else {
		    $in_error = 1;
		    last INSTR_SEQ;
		}
	    }
	    next;
	}

	# If we arrive here we are in trouble.
	$in_error = 1;
	last INSTR_SEQ;
    }

    return($in_error, @instructions);
}

sub _process_path {
    my ($self, $state, %args) = @_;
    my $path_data             = $state->node_attributes->{d};

    return if($args{queued});
    return if(!$path_data);

    my ($in_error, @instructions) = $self->_split_path_data($path_data);
    my $result = $self->{engine}->draw_path($state, @instructions);
    
    if($in_error) { $self->ie_at_pd($path_data) }
    else          { return $result              }
}

############################### Basic Shapes ##############################

sub _process_rect {
    my ($self, $state, %args) = @_;

    return if($args{queued});

    my $attributes = $state->node_attributes;
    my $x          = $state->map_length($attributes->{x} || 0);
    my $y          = $state->map_length($attributes->{y} || 0);
    my $w          = $attributes->{width};
    my $h          = $attributes->{height};
    my $rx         = $attributes->{rx};
    my $ry         = $attributes->{ry};

    $w = $state->map_length($w);
    $h = $state->map_length($h);
    $self->ie_at_re_nw($w) if($w < 0);
    $self->ie_at_re_nh($h) if($h < 0);
    return if(!$w or !$h);

    if(defined($rx)) {
	$rx = $state->map_length($rx);
	$self->ie_at_re_nr($rx) if($rx < 0);
	$ry = $rx if(!defined($ry));
    }
    if(defined($ry)) {
	$ry = $state->map_length($ry);
	$self->ie_at_re_nr($ry) if($ry < 0);
	$rx = $ry if(!defined($rx));
    }

    $rx = $ry = 0 if(!$rx or !$ry);
    $rx = $w / 2 if($rx > $w / 2);
    $ry = $h / 2 if($ry > $h / 2);

    my $engine = $self->{engine};
    if($engine->can('draw_rect')) {
	return $engine->draw_rect($state, $x, $y, $w, $h, $rx, $ry);
    }
    else {
	if($rx) {
	    return $engine->draw_path
		($state,
		 ['M', $x, $y + $ry],
		 ['a', $rx, $ry, 0, 0, 1, $rx, -$ry],
		 ['h', $w - 2*$rx],
		 ['a', $rx, $ry, 0, 0, 1, $rx, $ry],
		 ['v', $h - 2*$ry],
		 ['a', $rx, $ry, 0, 0, 1, -$rx, $ry],
		 ['h', -($w - 2*$rx)],
		 ['a', $rx, $ry, 0, 0, 1, -$rx, -$ry],
		 ['Z']);
	}
	else {
	    return $engine->draw_path
		($state,
		 ['M', $x, $y],
		 ['h', $w],
		 ['v', $h],
		 ['h', -$w],
		 ['Z']);
	}
    }
}

sub _process_circle {
    my ($self, $state, %args) = @_;

    return if($args{queued});

    my $attributes = $state->node_attributes;
    my $cx         = $state->map_length($attributes->{cx} || 0);
    my $cy         = $state->map_length($attributes->{cy} || 0);
    my $r          = $attributes->{r};

    $r = $state->map_length($r);
    $self->ie_at_ci_nr($r) if($r < 0);
    return if(!$r);

    my $engine = $self->{engine};
    if($engine->can('draw_circle')) {
	return $engine->draw_circle($state, $cx, $cy, $r);
    }
    else {
	return $engine->draw_path
	    ($state,
	     ['M', $cx + $r, $cy],
	     ['A', $r, $r, 0, 1, 1, $cx, $cy - $r],
	     ['A', $r, $r, 0, 0, 1, $cx + $r, $cy],
	     ['Z']);
    }
}

sub _process_ellipse {
    my ($self, $state, %args) = @_;

    return if($args{queued});

    my $attributes = $state->node_attributes;
    my $cx         = $state->map_length($attributes->{cx} || 0);
    my $cy         = $state->map_length($attributes->{cy} || 0);
    my $rx         = $attributes->{rx};
    my $ry         = $attributes->{ry};

    $rx = $state->map_length($rx);
    $ry = $state->map_length($ry);
    $self->ie_at_el_nr($rx) if($rx < 0);
    $self->ie_at_el_nr($ry) if($ry < 0);
    return if(!$rx or !$ry);

    my $engine = $self->{engine};
    if($engine->can('draw_ellipse')) {
	return $engine->draw_ellipse($state, $cx, $cy, $rx, $ry);
    }
    else {
	return $engine->draw_path
	    ($state,
	     ['M', $cx + $rx, $cy],
	     ['A', $rx, $ry, 0, 1, 1, $cx, $cy - $ry],
	     ['A', $rx, $ry, 0, 0, 1, $cx + $rx, $cy],
	     ['Z']);
    }
}

sub _process_line {
    my ($self, $state, %args) = @_;

    return if($args{queued});

    my $attributes = $state->node_attributes;
    my $x1         = $state->map_length($attributes->{x1} || 0);
    my $y1         = $state->map_length($attributes->{y1} || 0);
    my $x2         = $state->map_length($attributes->{x2} || 0);
    my $y2         = $state->map_length($attributes->{y2} || 0);

    my $engine = $self->{engine};
    if($engine->can('draw_line')) {
	return $engine->draw_line($state, $x1, $y1, $x2, $y2);
    }
    else {
	return $engine->draw_path
	    ($state, ['M', $x1, $y1], ['L', $x2, $y2]);
    }
}

sub _process_polyline {
    my ($self, $state, %args) = @_;

    return if($args{queued});

    my $points_str = $state->node_attributes->{points};

    return if(!$points_str);

    my @points;
    while($points_str) {
	if($points_str =~ $RE_POLY{POINTS_SPLIT}) {
	    push(@points, [$1, $2]);
	    $points_str = $3;
	}
	else { last }
    }

    my $engine = $self->{engine};
    my $result;
    if($engine->can('draw_polyline')) {
	$result = $engine->draw_polyline($state, @points);
    }
    else {
	$result = $engine->draw_path
	    ($state,
	     ['M', @{shift(@points)}],
	     map { ['L', @$_] } @points);
    }

    if($points_str) { $self->ie_at_po($state->node_attributes->{points}) }
    else            { return $result }
}

sub _process_polygon {
    my ($self, $state, %args) = @_;

    return if($args{queued});

    my $points_str = $state->node_attributes->{points};

    return if(!$points_str);

    my @points;
    while($points_str) {
	if($points_str =~ $RE_POLY{POINTS_SPLIT}) {
	    push(@points, [$1, $2]);
	    $points_str = $3;
	}
	else { last }
    }

    my $engine = $self->{engine};
    my $result;
    if($engine->can('draw_polygon')) {
	$result = $engine->draw_polygon($state, @points);
    }
    else {
	$result = $engine->draw_path
	    ($state,
	     ['M', @{shift(@points)}],
	     (map { ['L', @$_] } @points),
	     ['Z']);
    }

    if($points_str) { $self->ie_at_po($state->node_attributes->{points}) }
    else            { return $result }
}

################################### Text ##################################

sub _process_cdata {
    my ($self, $state, %args) = @_;

    return if($args{queued});

    foreach(sort { $a->{atomID} <=> $b->{atomID} } @{$state->text_atoms}) {
	$self->{engine}->draw_text($state,
				   $_->{x}, $_->{y}, $_->{rotate},
				   $_->{cdata});
    }

    return;
}

sub _process_tspan {}

sub _process_text {
    my ($self, $state, %args) = @_;

    return if($args{queued});

    my $text_atoms = $state->text_atoms;

    return if(!$text_atoms or !@$text_atoms);

    my $attributes = $state->node_attributes;

=for bidi reordering

    my $blockID     = 0;
    my @block_atoms = grep { $_->{blockID} == $blockID } @$text_atoms;
    while(@block_atoms) {
	

	$blockID++;
	@block_atoms = grep { $_->{blockID} == $blockID } @$text_atoms;
    }

=cut

    # The following section will have to be revised in depth for
    # right-to-left and particularly for top-to-bottom text.

    # init variables with first chunk
    my $chunkID     = 0;
    my @chunk_atoms = grep { $_->{chunkID} == $chunkID } @$text_atoms;

    # init current text position
    # Note that the atom properties are also set to 0 if undefined.
    # This means that for the first atom of the first chunk, x and
    # y are always set even if we do not have a text_width method.
    my $ctp_x = $chunk_atoms[0]->{x} ||= 0;
    my $ctp_y = $chunk_atoms[0]->{y} ||= 0;

    my $engine = $self->{engine};
    eval { $engine->text_width($state, '') };
    my $can_text_width =
	SVG::Rasterize::Exception::Setting->caught ? 0 : 1;

    # loop through chunks (@chunk_atoms is updated at end of loop)
    while(@chunk_atoms) {
	my $x = 0;
	my $y = 0;

	if($can_text_width) {
	    foreach(@chunk_atoms) {
		my $width = $self->{engine}->text_width
		    ($_->{state}, $_->{cdata});
	    
		$_->{offset}       = [$x, $y];
		$_->{displacement} =
		    [defined($width) ? ($_->{dx} || 0) + $width : undef,
		     ($_->{dy} || 0)];
		$x += $_->{displacement}->[0];
		$y += $_->{displacement}->[1];
	    }

	    # TODO: What to do if right-to-left?
	    if(!$attributes->{'text-anchor'} or
	       $attributes->{'text-anchor'} eq 'start')
	    {
		# nothing to do for left-to-right
	    }
	    elsif($attributes->{'text-anchor'} eq 'middle') {
		$ctp_x -= $x / 2;
		$ctp_y -= $y / 2;  # unsure if this is what we want
	    }
	    else {
		# attribute validation should have made sure that
		# it must be 'end' now
		$ctp_x -= $x;
		$ctp_y -= $y;  # unsure if this is what we want
	    }

	    foreach(@chunk_atoms) {
		$_->{x} = $ctp_x + $_->{offset}->[0];
		$_->{y} = $ctp_y + $_->{offset}->[1];
	    }
	}

	$chunkID++;
	@chunk_atoms = grep { $_->{chunkID} == $chunkID } @$text_atoms;
	if(@chunk_atoms) {
	    $ctp_x = $chunk_atoms[0]->{x} || ($ctp_x + $x);
	    $ctp_y = $chunk_atoms[0]->{y} || ($ctp_y + $y);
	}
    }

    return;
}

sub _process_node {
    my ($self, $state, %args) = @_;

    if($state->defer_rasterization && !$args{flush}) {
	$self->{_rasterization_queue} ||= [];
	push(@{$self->{_rasterization_queue}}, $state);
	$args{queued} = 1;
    }

    my $this_node_name = $state->node_name;
    return $self->_process_path($state, %args)
	if($this_node_name eq 'path');
    return $self->_process_rect($state, %args)
	if($this_node_name eq 'rect');
    return $self->_process_circle($state, %args)
	if($this_node_name eq 'circle');
    return $self->_process_ellipse($state, %args)
	if($this_node_name eq 'ellipse');
    return $self->_process_line($state, %args)
	if($this_node_name eq 'line');
    return $self->_process_polyline($state, %args)
	if($this_node_name eq 'polyline');
    return $self->_process_polygon($state, %args)
	if($this_node_name eq 'polygon');
    return $self->_process_cdata($state, %args)
	if($this_node_name eq '#text');
    return $self->_process_tspan($state, %args)
	if($this_node_name eq 'tspan');
    return $self->_process_text($state, %args)
	if($this_node_name eq 'text');

    return;
}

###########################################################################
#                                                                         #
#                             Tree Traversal                              #
#                                                                         #
###########################################################################

sub in_error {
    my ($self, $exception) = @_;
    my $state              = SVG::Rasterize::State->new
	(rasterize       => $self,
	 node_name       => 'g',
	 node_attributes => {},
	 cdata           => undef,
	 child_nodes     => undef);

    $self->in_error_hook->($self, $state);

    die $exception;
}

sub _flush_rasterization_queue {
    my ($self) = @_;

    foreach(@{$self->{_rasterization_queue} || []}) {
	$self->_process_node($_, flush => 1);
    }
    $self->{_rasterization_queue} = undef;

    return;
}

sub _process_normalize_attributes {
    my ($self, $normalize, $attr) = @_;
    my %attributes                = %{$attr || {}};  # copy before
                                                     # manipulation

    if($attributes{style} and ref($attributes{style}) eq 'HASH') {
	my $style = '';
	foreach(keys %{$attributes{style}}) {
	    next if(!defined($attributes{style}->{$_}));
	    $style .= ';' if($style);
	    $style .= sprintf("%s:%s", lc($_), $attributes{style}->{$_});
	}
	$attributes{style} = $style;
    }

    if($normalize) {
	foreach(keys %attributes) {
	    next if(ref($attributes{$_}));
	    $attributes{$_} =~ s/^$WSP*//;
	    $attributes{$_} =~ s/$WSP*$//;
	    $attributes{$_} =~ s/$WSP+/ /g;
	}
    }

    return \%attributes;
}

###########################################################################
#                                                                         #
#                              DOM specific                               #
#                                                                         #
###########################################################################

sub _process_node_object {
    my ($self, $node, %args) = @_;

    my %state_args =
       (node            => $node,
        node_name       => $node->getNodeName,
	node_attributes => $self->_process_normalize_attributes
	    ($args{normalize_attributes}, scalar($node->getAttributes)));

    $state_args{cdata} = $state_args{node_name} eq '#text'
	    ? $node->getData : undef;

    my $child_nodes = $node->getChildNodes;
    if($node->isa('SVG::Element')) {
	# For a SVG::Element we can just take the child nodes
	# directly, because this gives us only the child elements
	# anyway. We have to take care of comments, though.
	# A copy is made to enable manipulation in hooks without
	# changing the node object.
	$state_args{child_nodes} = defined($child_nodes)
	    ? [grep { !$IGNORED_NODES{$_->getNodeName} } @$child_nodes]
	    : undef;

	# extrawurst for text elements in SVG.pm
	if(my $cdata = $node->getData) {
	    $state_args{child_nodes} ||= [];
	    push(@{$state_args{child_nodes}},
		 SVG::Rasterize::TextNode->new(data => $cdata));
	}
    }
    else {
	# For a generic DOM node we only take the children which
	# are either element or text nodes. Note that this excludes
	# comment nodes.
	$state_args{child_nodes} = [];
	foreach(@{$child_nodes || []}) {
	    my $type = $_->getType;
	    next if($type != 1 and $type != 3);
	    next if(!$IGNORED_NODES{$_->getNodeName});
	    push(@{$state_args{child_nodes}}, $_);
	}
    }

    return(%state_args);
}

sub _traverse_object_tree {
    my ($self, %args) = @_;

    # process initial node and establish initial viewport
    my $node       = $args{svg}->getNodeName eq 'document'
	? $args{svg}->firstChild : $args{svg};
    my %state_args = $self->_process_node_object($node, %args);

    # if an external current color has been set we integrate it here
    if(exists($args{current_color})) {
	$state_args{node_attributes}->{color} = $args{current_color};
    }

    $self->_initial_viewport($state_args{node_attributes}, \%args);
    if(!$args{width}) {
	warn "Surface width is 0, nothing to do.\n";
	return;
    }
    if(!$args{height}) {
	warn "Surface height is 0, nothing to do.\n";
	return;
    }

    $self->_create_engine(\%args);

    my @buffer = $self->before_node_hook->($self,
					   %state_args,
					   rasterize => $self,
					   matrix    => $args{matrix});
    $self->ex_ho_bn_on if(!@buffer or @buffer % 2);
    $self->{state} = SVG::Rasterize::State->new(@buffer);
    $self->start_node_hook->($self, $self->{state});
    $self->_process_node($self->{state});

    # traverse the node tree
    my @stack = ();
    while($self->{state}) {
	$node = $self->{state}->shift_child_node;
	if($node) {
	    push(@stack, $self->{state});
	    @buffer = $self->before_node_hook->
		($self,
		 $self->_process_node_object($node, %args),
		 rasterize => $self,
		 parent    => $self->{state});
	    $self->ex_ho_bn_on if(!@buffer or @buffer % 2);
	    $self->{state} = SVG::Rasterize::State->new(@buffer);
	    $self->start_node_hook->($self, $self->{state});
	    $self->_process_node($self->{state});
	}
	else {
	    if($self->{state}->defer_rasterization) {
		my $parent = $self->{state}->parent;
		if(!$parent or !$parent->defer_rasterization) {
		    $self->_flush_rasterization_queue;
		}
	    }
	    $self->end_node_hook->($self, $self->{state});
	    $self->{state} = pop @stack;
	}
    }

    return;
}

###########################################################################
#                                                                         #
#                              SAX specific                               #
#                                                                         #
###########################################################################

sub _parse_svg_file {
    my ($self, %args) = @_;

    $self->ex_us_si('The parsing of SVG files');
}

###########################################################################
#                                                                         #
#                               rasterize                                 #
#                                                                         #
###########################################################################

sub rasterize {
    my ($self, %args) = @_;

    # validate args and process object defaults
    $args{normalize_attributes} = $self->{normalize_attributes}
        if(!exists($args{normalize_attributes})
	   and exists($self->{normalize_attributes}));
    $args{svg}                  = $self->{svg}
        if(!exists($args{svg}) and exists($self->{svg}));
    $args{width}                = $self->{width}
        if(!exists($args{width}) and exists($self->{width}));
    $args{height}               = $self->{height}
        if(!exists($args{height}) and exists($self->{height}));
    $args{current_color}        = $self->{current_color}
        if(!exists($args{current_color})
	   and exists($self->{current_color}));
    $args{engine_class}         = $self->{engine_class}
        if(!exists($args{engine_class}) and exists($self->{engine_class}));
    $args{engine_args}          = $self->{engine_args}
        if(!exists($args{engine_args}) and exists($self->{engine_args}));

    my @args                 = %args;
    my $default_engine_class = 'SVG::Rasterize::Engine::PangoCairo';
    my $svg_callback         = sub {
	my ($value) = @_;

	if(blessed($value)) {
	    foreach('getNodeName',
		    'getAttributes')
	    {
		return 0 if(!$value->can($_));
	    }
	}

	return 1;
    };
    %args = validate_with
	(params => \@args,
	 spec   =>
	     {normalize_attributes => {default   => 1,
				       type      => BOOLEAN},
	      svg                  => {type      => SCALAR | OBJECT,
				       callbacks =>
					   {'svg type' => $svg_callback}},
	      width                => {optional  => 1,
				       type      => SCALAR,
				       regex     =>
					   $RE_LENGTH{p_A_LENGTH}},
	      height               => {optional  => 1,
				       type      => SCALAR,
				       regex     =>
					   $RE_LENGTH{p_A_LENGTH}},
	      current_color        => {optional  => 1,
				       type      => SCALAR,
	                               regex     => $RE_PAINT{p_COLOR}},
	      engine_class         => {default   => $default_engine_class,
				       type      => SCALAR,
				       regex     =>
					   $RE_PACKAGE{p_PACKAGE_NAME}},
	      engine_args          => {optional  => 1,
				       type      => HASHREF}},
	on_fail => sub { $self->ex_pv($_[0]) });

    if(blessed($args{svg})) {
	return $self->_traverse_object_tree(%args);
    }
    else {
	return $self->_parse_svg_file(%args);
    }
}

sub write { return shift(@_)->{engine}->write(@_) }

1;


__END__

=pod

=head1 SYNOPSIS

    use SVG;
    use SVG::Rasterize;

    my $svg = SVG->new(width => 300, height => 200);
    $svg->line(x1 => 10, y1 => 20, x2 => 220, y2 => 150,
               style => {stroke => 'black', stroke-width => '2pt' });

    # add more svg content
    # .
    # .
    # .

    my $rasterize = SVG::Rasterize->new();
    $rasterize->rasterize(svg => $svg);
    $rasterize->write(type => 'png', file_name => 'out.png');


=head1 DESCRIPTION

C<SVG::Rasterize> can be used to rasterize L<SVG|SVG> objects to
pixel graphics (currently png only) building on the L<Cairo|Cairo>
library (by default, other underlying rasterization engines could be
added). The direct rasterization of C<SVG> B<files> might be
implemented in the future, right now you should have a look at
L<SVG::Parser|SVG::Parser> which can generate an L<SVG|SVG> object
from an C<svg> file. See also L<SVG Input|/SVG Input> in the
ADVANCED TOPICS section.

=head2 Motivation

In the past, I have used several programs to rasterize C<SVG>
graphics including L<Inkscape|http://www.inkscape.org/>,
L<Konqueror|http://www.konqueror.org/>, L<Adobe
Illustrator|http://www.adobe.com/products/illustrator/>, and
L<rsvg|http://library.gnome.org/devel/rsvg/stable/>. While
L<Inkscape|http://www.inkscape.org/> was my favourite none of them
made me entirely happy. There were always parts of the standard that
I would have liked to use, but were unsupported.

So finally, I set out to write my own rasterization engine. The
ultimate goal is complete compliance with the requirements for a
C<Conforming Static SVG Viewer> as described in the C<SVG>
specification:
L<http://www.w3.org/TR/SVG11/conform.html#ConformingSVGViewers>.
Obviously, this is a long way to go. I do not know if any support
for the dynamic features of C<SVG> will ever be added. Anyway, the
priority for C<SVG::Rasterize> is accuracy, not speed.

=head2 Status

The following elements are drawn at the moment:

=over 4

=item * C<path>

=item * all basic shapes: C<rect>, C<circle>, C<ellipse>, C<line>,
C<polyline>, C<polygon>.

=item * text/tspan in a limited (and not well tested) way:

=over 4

=item * stroke/fill colors can be set

=item * position can be set, also for individual characters (but no
rotation of individual characters, yet)

=item * alignment via text-anchor

=item * bidirectional text only as far as pango does that
automatically, explicit settings for writing direction are ignored

=item * font-size can be set, but no font-family, font-style etc.

=back

=back

The inheritance of styling properties is implemented. The following
attributes are at least partly interpreted:

=over

=item * C<transform>

=item * C<viewBox>

=item * C<preserveAspectRatio>

=item * C<style>

=item * C<fill> and all associated properties

=item * C<stroke> and all associated properties

=back

I hope that the interface described here will be largely stable.
However, this is not guaranteed. Some features are documented as
likely to change, but everything is subject to change at this early
stage.

Here is my current view of the next part of the roadmap:

=over 4

=item Version 0.004

=over 4

=item * completion of text basics

=back

=item Version 0.005

=over 4

=item * support for C<SVG> files

=item * relative units

=back

=item Version 0.006

=over 4

=item * clipping paths

=item * css sections and files?

=back

=item Version 0.007

=over 4

=item * symbol/use

=item * C<tref> and such

=back

=item Version 0.008

=over 4

=item * gradients and patterns

=item * masks

=back

=back


=head1 INTERFACE

=head2 Constructors

=head3 new

  $rasterize = SVG::Rasterize->new(%args)

Creates a new C<SVG::Rasterize> object and calls
L<init(%args)|/init>. If you subclass C<SVG::Rasterize> overload
L<init|/init>, not C<new>.

L<init|/init> goes through the arguments given to C<new>. If a
method of the same name exists it is called with the respective
value as argument. This can be used for attribute
initialization. Some of the values can be also given to
L<rasterize|/rasterize> to temporarily override the attribute
values. The values of these overridable attributes are only
validated once they are used by L<rasterize|/rasterize>.

The most commonly used arguments are:

=over 4

=item * svg (optional): A C<DOM> object to render.

=item * width (optional): width (in pixels) of the generated output
image

=item * height (optional): height (in pixels) of the generated
output image.

=back


=head2 Public Attributes

=head3 svg

Holds the C<DOM> object to render. It does not have to be an
L<SVG|SVG> object, but it has to offer certain C<DOM> methods (see
L<SVG Input|/SVG Input> for details).

=head3 width

The width of the generated output in pixels.

=head3 height

The height of the generated output in pixels.

=head3 current_color

The color which is used if an C<SVG> element's C<fill> or C<stroke>
property is set to C<currentColor> and the C<color> property has not
been set directly. Setting C<current_color> has the same effect as
if the root C<SVG> element's C<color> property was set to the same
value. See
L<http://www.w3.org/TR/SVG11/painting.html#SpecifyingPaint> for the
background of this.

=head3 medium_font_size

C<SVG> supports keywords from C<xx-small> to C<xx-large> for the
C<font-size> attribute. A numerical value for C<medium> as well as a
scaling factor between neighboring values is supposed to be set by
the user agent. C<SVG::Rasterize> uses a default value of
C<12pt>. This default value can be adjusted by setting this
attribute. A new value has to be an absolute length larger than
C<0>.

=head3 font_size_scale

Read about C<medium_font_size> above first. C<font_size_scale>
holds the factor between neighboring C<font-size> values, e.g.
between C<large> and C<x-large>. The default value is C<1.2>.

There are other attributes that influence unit conversions,
white space handling, and the choice of the underlying rasterization
engine. See L<ADVANCED TOPICS|/ADVANCED TOPICS>.


=head2 Class Attributes

=head3 %IGNORED_NODES

Defaults to

  %IGNORED_NODES = (comment  => 1,
                    title    => 1,
                    desc     => 1,
                    metadata => 1);

A C<SVG> node with a name that is a key in this hash with a true
value is ignored including all its children. If you, for example
set

  $SVG::IGNORED_NODES{text} = 1;

then all text nodes will be ignored.

Do not unset the defaults above or you are likely to get into
trouble.

=head2 Methods for Users

=head3 rasterize

  $rasterize->rasterize(%args)

Traverses through the given C<SVG> content and renders the
output. Does not return anything.

B<Examples:>

  $rasterize->rasterize(svg => $svg);
  $rasterize->rasterize(svg => $svg, width => 640, height => 480);
  $rasterize->rasterize(svg => $svg, engine_class => 'My::Class');

Supported parameters:

=over 4

=item * svg (optional): C<DOM> object to rasterize. If not specified
the value of the L<svg|/svg> attribute is used. One of them has to
be set. It does not have to be a L<SVG|SVG> object, but it has to
provide a certain set of C<DOM> methods (see L<SVG Input|/SVG
Input>.

The element can be any valid C<SVG> element, e.g. C<< <svg> >>, C<<
<g> >>, or even just a basic shape element or so.

=item * width (optional): width of the target image in pixels,
temporarily overrides the L<width|/width> attribute.

=item * height (optional): height of the target image in pixels,
temporarily overrides the L<height|/height> attribute.

=item * current_color (optional): default color for C<stroke> and
C<fill> properties specified as C<currentColor>, temporarily
overrides the L<current_color|/current_color> attribute.

=item * engine_class (optional): alternative engine class to
L<SVG::Rasterize::Engine::PangoCairo|SVG::Rasterize::Engine::PangoCairo>,
temporarily overrides the C<engine_class> attribute. See
L<SVG::Rasterize::Engine|SVG::Rasterize::Engine> for details on the
interface. The value has to match the regular expression
L<p_PACKAGE_NAME|SVG::Rasterize::Regexes/%RE_PACKAGE>.

=item * engine_args (optional): arguments for the constructor of the
rasterization engine, temporarily overriding the C<engine_args>
attribute (NB: in the future, this behaviour might be changed such
that the two hashes are merged and only the values given here
override the values in the attribute C<engine_args>; however, at the
moment, the whole hash is temporarily replaced if the parameter
exists). The width and height of the output image can be set in
several ways. The following values for the width are used with
decreasing precedence (the same hierarchy applies to the height):

=over 4

=item 1. C<< engine_args->{width} >>, given to C<rasterize>

=item 2. C<< $rasterize->engine_args->{width} >>

=item 3. C<width>, given to C<rasterize>

=item 4. C<< $rasterize->width >>

=item 5. the width attribute of the root C<SVG> object.

=back

=item * normalize_attributes (optional): Influences L<White Space
Handling|/White Space Handling>, temporarily overrides the
C<normalize_attributes> attribute. Defaults to 1.

=back

If C<width> (the same applies to C<height>) is 0 it is treated as
not set. If you encounter any scenario where you would wish an
explicit size of 0 to be treated in some other way let me know.

If C<width> and/or C<height> are not specified they have to have
absolute values in the root C<SVG> element. If both the root C<SVG>
element and the C<rasterize> method have width and/or height
settings then the C<rasterize> parameters determine the size of the
output image and the specified C<SVG> viewport is mapped to this
image taking the C<viewBox> and C<preserveAspectRatio> attributes
into account if they are present. See
L<http://www.w3.org/TR/SVG11/coords.html#ViewportSpace> for details.

The user can influence the rasterization process via hooks. See the
L<Hooks|/Hooks> section below.

=head3 write

  $rasterize->write(%args)

Writes the rendered image to a file.

B<Example:>

  $rasterize->write(type => 'png', file_name => 'foo.png');

The supported parameters depend on the rasterization backend. The
C<write> method hands all parameters over to the backend. See
L<write|SVG::Rasterize::Engine::PangoCairo/write> in
C<SVG::Rasterize::Engine::PangoCairo> for an example.

=head1 ADVANCED TOPICS

=head2 C<SVG> Input

In principle, C<SVG> input could be present as a kind of C<XML> tree
object or as stringified C<XML> document. Therefore
C<SVG::Rasterize> might eventually offer the following options:

=over 4

=item 1. The input data are provided in form of a L<SVG|SVG> object
tree generated by the user.

=item 2. The input data are a L<SVG|SVG> object tree generated from
a file by L<SVG::Parser|SVG::Parser> or a similar piece of software.

=item 3. The input data are an object tree generated by a generic
C<XML> parser and offer a C<DOM> interface.

=item 4. The input data are stringified C<XML> data in a file.

=item 5. The input data are stringified C<XML> data read from a file
handle. This case is different from the previous one because a file
can be read multiple times in order to collect referenced C<SVG>
fragments.

=back

Currently, the first three options are at least partly
implemented. I will not work on the other ones before a substantial
subset of C<SVG> is supported. If the last two options will ever get
implemented they will be designed to enable the rendering of files
which are too large for the first options. Because it is harder to
deal with cross-references in these cases, chances are that it will
always be faster to use option 2. or 3. if this is possible.

Option 1. is the best tested one by far. However, option 2. should
be very similar. To use option 3., the node objects have to provide
at least the following C<DOM> methods:

=over 4

=item * C<getType>

=item * C<getNodeName>

=item * C<getAttributes>

=item * C<getData>

=item * C<getChildNodes>

=back

Unfortunately, option 3. cannot be treated completely in the same
way as options 1. and 2. due to the peculiarity of L<SVG|SVG> to
treat C<CDATA> sections in a special way and not as child nodes of
the element. C<SVG::Rasterize> tries to support both L<SVG|SVG>
object trees and generic C<DOM> trees, but this is neither well
tested nor a main priority at the moment. Please report if you find
C<SVG::Rasterize> not cooperating with your favourite C<DOM> parser.

=head2 Units

C<SVG> supports the absolute units C<px>, C<pt>, C<pc>, C<cm>,
C<mm>, C<in>, and the relative units C<em>, C<ex>, and C<%>.
Lengths can also be given as numbers without unit which is then
interpreted as C<px>. See
L<http://www.w3.org/TR/SVG11/coords.html#Units>.

C<SVG::Rasterize> stores default values for unit conversion ratios
as class variables. You can either change these values or the
corresponding object variables. If you have only one
C<SVG::Rasterize> object both approaches have the same effect.

The default values are listed below. Except C<px_per_in>, they
are taken from the C<CSS> specification. See
L<http://www.w3.org/TR/2008/REC-CSS2-20080411/syndata.html#length-units>.
The default for C<px_per_in> is arbitrarily set to 90.

Currently, the relative units listed above are not supported by
C<SVG::Rasterize>.

Unit conversions:

=over 4

=item * px_per_in

Pixels per inch. Defaults to 90.

=item * dpi

Alias for L<px_per_in|/px_per_in>. This is realized via a typeglob
copy:

  *dpi = \&px_per_in

=item * in_per_cm

Inches per centimeter. Defaults to 1/2.54. This is the
internationally defined value. I do not see why I should prohibit
a change, but it would hardly make sense.

=item * in_per_mm

Inches per millimeter. Defaults to 1/25.4. This is the
internationally defined value. I do not see why I should prohibit
a change, but it would hardly make sense.

=item * in_per_pt

Inches per point. Defaults to 1/72. According to [1], this default
was introduced by the C<Postscript> language. There are other
definitions. However, the C<CSS> specification is quite firm about
it.

=item * in_per_pc

Inches per pica. Defaults to 1/6. According to the C<CSS>
specification, 12pc equal 1pt.

=item * map_abs_length

  $number = $rasterize->map_abs_length($length)
  $number = $rasterize->map_abs_length($number, $unit)

This method takes a length and returns the corresponding value
in C<px> according to the conversion ratios above. Surrounding
white space is not allowed.

B<Examples:>

  $x = $rasterize->map_abs_length('5.08cm');  # returns 180
  $x = $rasterize->map_abs_length(10);        # returns 10
  $x = $rasterize->map_abs_length(10, 'pt')   # returns 12.5
  $x = $rasterize->map_abs_length('  1in ');  # error
  $x = $rasterize->map_abs_length('50%')      # error

The unit has to be absolute, C<em>, C<ex>, and C<%> trigger an
exception. See L<map_length|SVG::Rasterize::State/map_length>
in C<SVG::Rasterize::State>.

There are two different interfaces. You can either pass one string
or the number and unit separately. NB: In the second case, the input
is not validated. This interface is meant for situations where the
length string has already been parsed (namely in
L<map_length|SVG::Rasterize::State/map_length> in
C<SVG::Rasterize::State>) to avoid duplicate validation. The number
is expected to be an L<A_NUMBER|SVG::Rasterize::Regexes/LIST OF
EXPRESSIONS> and the unit to be a
L<UNIT|SVG::Rasterize::Regexes/LIST OF EXPRESSIONS>. However, it is
still checked if the unit is absolute.

=back

The corresponding class attributes are listed below. Note that these
values are not validated. Take care that you only set them to
numbers.

=over 4

=item * PX_PER_IN

Defaults to 90.

=item * DPI

Alias for C<PX_PER_IN>. This is realized via a typeglob copy

  *DPI = \$PX_PER_IN

=item * IN_PER_CM

Defaults to 1/2.54.

=item * IN_PER_MM

Defaults to 1/25.4.

=item * IN_PER_PT

Defaults to 1/72.

=item * IN_PER_PC

Defaults to 1/6.

=back

=head2 Hooks

The L<rasterize|/rasterize> method traverses through the C<SVG> tree
and creates an L<SVG::Rasterize::State|SVG::Rasterize::State> object
for each node (node means here element or text node if relevant,
attributes are not treated as nodes). Hooks allow you to execute
your own subroutines at given steps of this traversal. However, the
whole hook business is experimental at the moment and likely to
change. If you use any of the existing hooks or wish for other ones
you may want to let me know because this will certainly influence
the stability and development of this interface.

Right now, to set your own hooks you can set one of the following
attributes to a code reference of your choice.

Currently, there are four hooks:

=over 4

=item * before_node_hook

Executed at encounter of a new node right before the new
L<SVG::Rasterize::State|SVG::Rasterize::State> object is created.
It is called as an object method and receives the hash that would be
passed to the L<SVG::Rasterize::State|SVG::Rasterize::State>
constructor. It contains the elements listed below. A custom
C<before_node_hook> is expected to return a hash of the same form
which will then be handed over to the
L<SVG::Rasterize::State|SVG::Rasterize::State> constructor. The
default C<before_node_hook> just returns the input hash.

The argument hash always contains the following elements:

=over 4

=item * C<rasterize>: the C<SVG::Rasterize> object

=item * C<node>: the node object

=item * C<node_name>: the C<DOM> node name

=item * C<node_attributes>: the attributes as HASH reference,
already L<normalized|/White Space Handling>

=item * C<cdata>: string or C<undef>

=item * C<child_nodes>: ARRAY reference with node objects or
C<undef>.

=back

In addition, it may contain the following elements:

=over 4

=item * C<matrix>: ARRAY reference with six numbers (see
L<multiply_matrices|/multiply_matrices>); this element is present
when processing the root node

=item * C<parent>: the parent
L<SVG::Rasterize::State|SVG::Rasterize::State> object; this element
is present when B<not> processing the root node.

=back

=item * start_node_hook

Executed right after creation of the
L<SVG::Rasterize::State|SVG::Rasterize::State> object. The
attributes have been parsed,
L<properties|SVG::Rasterize::State/properties> and
L<matrix|SVG::Rasterize::State/matrix> have been set etc. The method
receives the C<SVG::Rasterize> object and the
L<SVG::Rasterize::State|SVG::Rasterize::State> object as parameters.

=item * end_node_hook

Executed right before a
L<SVG::Rasterize::State|SVG::Rasterize::State> object runs out of
scope because the respective node is done with. The method receives
the C<SVG::Rasterize> object and the
L<SVG::Rasterize::State|SVG::Rasterize::State> object as parameters.

=item * in_error_hook

Executed right before C<die> when the document is in error (see L<In
error|/In error> below. Receives the C<SVG::Rasterize> object and a
newly created L<SVG::Rasterize::State|SVG::Rasterize::State> object
as parameters.

=back

B<Examples:>

  $rasterize->start_node_hook(sub { ... })

Some hooks have non-trivial defaults. Therefore C<SVG::Rasterize>
provides the following methods to restore the default behaviour:

=over 4

=item * restore_before_node_hook

=item * restore_start_node_hook

=item * restore_end_node_hook

=item * restore_in_error_hook

=item * restore_all_hooks

Calls all the other C<restore...> methods. Takes an optional named
parameter C<preserve>. If this is set to a C<true> value then only
hooks are restored which are undefined. This is only documented for
completeness, I do not see why you should need it. This option only
exists such that the method can be used to initialize the hooks at
construction time and preserve hooks that have been set by the user
via an init parameter.

=back

=head2 Rasterization Backend

C<SVG::Rasterize> does not render pixel graphics itself. By default,
it uses the L<cairo|http://www.cairographics.org/> library through
its L<Perl bindings|Cairo>. However, the interface could also be
implemented by other backends. In the future, it will be documented
in L<SVG::Rasterize::Engine|SVG::Rasterize::Engine>. Currently, the
interface has to be considered unstable, though, and the
documentation is sparse.

=head3 engine_class

This attribute defaults to C<SVG::Rasterize::Engine::PangoCairo>. It
can be set as an object attribute or temporarily as a parameter to
the L<rasterize|/rasterize> method.

=head3 engine_args

This attribute can hold a HASH reference. The corresponding hash is
given to the constructor of the rasterization engine when it is
called by L<rasterize|/rasterize>. C<engine_args> can be set as an
object attribute or temporarily as a parameter to the
L<rasterize|/rasterize> method.

=head3 engine

  $rasterize->engine

This attribute holds the interface object to the rasterization
backend, by default a
L<SVG::Rasterize::Engine::PangoCairo|SVG::Rasterize::Engine::PangoCairo>
object. The object is created by the L<rasterize|/rasterize> method.

The attribute is readonly, but, of course, you are able to
manipulate the object directly via its methods. However, this is
not part of the normal workflow and you do this on your own risk
;-).

=head2 White Space Handling

The C<XML> specification
(L<http://www.w3.org/TR/2006/REC-xml11-20060816/#AVNormalize>)
states that an attribute value unless it is of the type CDATA shall
be normalized such that leading and trailing white space is removed
and internal white space is flattened to single space characters.
C<XML> entities can complicate this normalization, see the
specification for details.

If the C<SVG> tree to be rasterized by C<SVG::Rasterize> comes out
of an parsed C<XML> document then the parser should have performed
this normalization already. However, the tree might also be
constructed directly using the L<SVG|SVG> module. In order to
prevent C<SVG::Rasterization> from choking on an attribute like
C<stroke-width="2pt "> it performs by default an additional
normalization run:

  $value =~ s/^$WSP*//;
  $value =~ s/$WSP*$//;
  $value =~ s/$WSP+/ /g;

where

  $WSP = qr/[\x{20}\x{9}\x{D}\x{A}]/;  # space, tab, CR, LF

To prevent this normalization, you can set the
C<normalize_attributes> attribute (as object attribute or as
parameter to L<rasterize|/rasterize>) to a false value.

=head2 C<SVG> Validation

C<SVG::Rasterize> is not an C<SVG> validator. It does check a lot of
things including the validity of the element hierarchy, the required
presence and absence of attributes and the values of all attributes
it interpretes plus some that it does not interprete. However, it
does not (and probably will never) claim to detect all errors in an
C<SVG> document.

=head2 Attributes and Methods for Developers

=head3 state

Readonly attribute. Holds the current
L<SVG::Rasterize::State|SVG::Rasterize::State> object during tree
traversal. Not internal because it is used by exception methods
to retrieve the current state object (in order to store it in the
exception object for debugging purposes).

=head3 init

  $rasterize->init(%args)

If you overload C<init>, your method should also call this one.

For each given argument, C<init> calls the accessor with the same
name to initialize the attribute. If such an accessor (or in fact,
any method of that name) does not exist a warning is printed and the
argument is ignored. Readonly attributes that are allowed to be set
at initialization time are set separately at the beginning.

=head3 in_error

Expects an exception object or error message. Creates a fresh
L<SVG::Rasterize::State|SVG::Rasterize::State> object (without any
transform etc.) and calls L<in_error_hook|/in_error_hook> (which by
default draws a translucent checkerboard across the image). After
that, it dies with the given message.

Before you call C<in_error> directly, check out
L<SVG::Rasterize::Exception|SVG::Rasterize::Exception>.

=head3 absolute_font_size

  $size = $rasterize->absolute_font_size('x-large')

Returns the current numerical value (in user units) corresponding to
a given absolute font size keyword. The method is designed also to
be used to check if a given string is an absolute font size keyword
at all. Therefore it returns C<undef> if the input value is C<undef>
or not an absolute font size keyword.

=head3 relative_font_size

  $size = $rasterize->relative_font_size('larger')

NB: Currently, this method throws an exception if a relative font
size keyword is given saying that these keywords are not supported,
yet. The following describes the future behaviour.

Returns the current numerical value (in user units) corresponding to
a given relative font size keyword. The method is designed also to
be used to check if a given string is an relative font size keyword
at all. Therefore it returns C<undef> if the input value is C<undef>
or not an relative font size keyword.

=head2 Class Methods

=head3 multiply_matrices

2D affine transformation can be represented by 3 x 3 matrices
of the form:

  ( a  c  e )
  ( b  d  f )
  ( 0  0  1 )

In this case, the concatenation of such transformations is
represented by canonical matrix multiplication. This method takes
two ARRAY references of the form C<[a, b, c, d, e, f]> whose entries
correspond to the matrix entries above and returns an ARRAY
reference with 6 entries representing the product matrix.

The method can be called either as subroutine or as class
method or as object method:

  $product = multiply_matrices($m, $n)
  $product = SVG::Rasterize->multiply_matrices($m, $n)
  $product = $rasterize->multiply_matrices($m, $n)

Note that C<multiply_matrices> does not perform any input check. It
expects that you provide (at least) two ARRAY references with (at
least) 6 numbers each. If you pass more parameters then the last two
are used. If they contain more than 6 entries then the first 6 are
used.

=head3 endpoint_to_center

  @result = endpoint_to_center(@input)
  @result = SVG::Rasterize->endpoint_to_center(@input)
  @result = $rasterize->endpoint_to_center(@input)

Rasterization engines like
L<SVG::Rasterize::Engine::PangoCairo|SVG::Rasterize::Engine::PangoCairo>
might use center parameterization instead of endpoint
parameterization of an elliptical arc (see
L<http://www.w3.org/TR/SVG11/implnote.html#ArcImplementationNotes>).
This method calculates the center parameters from the endpoint
parameters given in a C<SVG> path data string. As indicated above,
it can be called as a subroutine or a class method or an object
method. The required parameters are:

=over 4

=item * x coordinate of the starting point

=item * y coordinate of the starting point

=item * radius in x direction

=item * radius in y direction

=item * angle by which the ellipse is rotated with respect to the
positive x axis (in radiant, not degrees)

=item * large arc flag

=item * sweep flag

=item * x coordinate of the end point

=item * y coordinate of the end point.

=back

If the reparameterization cannot be computed an empty list is
returned. This can have two possible reasons. Either one of the
radii is equal (with respect to machine precision) to 0 or the start
and end point of the arc are equal (with respect to machine
precision). The first case should have been checked before (note
that no rounding problems can occur here because no arithmetics is
done with the passed values) because in this case the arc should be
turned into a line. In the second case, the arc should just not be
drawn. Be aware that this latter case includes a full ellipse. This
means that a full ellipse cannot be drawn as one arc. The C<SVG>
specification is very clear on that point. However, an ellipse can
be drawn as two arcs.

Note that the input values are not validated (e.g. if the values are
numbers, if the flags are either 0 or 1 and so on). It is assumed
that this has been checked before.  Furthermore, it is not checked
if the radii are very close to 0 or start and end point are nearly
equal.

A list of the following parameters is returned (unless an empty
list is returned due to the reasons mentioned above):

=over 4

=item * x coordinate of the center

=item * y coordinate of the center

=item * radius in x direction

This value might have been increased to make the ellipse big enough
to connect start and end point. If it was negative the absolute
value has been used (so the return value is always positive).

=item * radius in y direction

This value might have been increased to make the ellipse big enough
to connect start and end point. If it was negative the absolute
value has been used (so the return value is always positive).

=item * start angle in radiant

=item * sweep angle (positive or negative) in radiant.

=back


=head3 adjust_arc_radii

  @result = adjust_arc_radii(@input)
  @result = SVG::Rasterize->adjust_arc_radii(@input)
  @result = $rasterize->adjust_arc_radii(@input)

The C<SVG> specification requires that the radii of an elliptic arc
are increased automatically if the given values are too small to
connect the given endpoints (see
L<http://www.w3.org/TR/SVG11/implnote.html#ArcImplementationNotes>).
This situation can arise from rounding errors, but also for example
during an animation. Moreover, if a given radius is negative then
the absolute value is to be used. This method takes care of these
adjustments and returns the new values plus some intermediate values
that might be useful for callers, namely
L<endpoint_to_center|/endpoint_to_center>.

In detail, it requires the following parameters:

=over 4

=item * x coordinate of the starting point

=item * y coordinate of the starting point

=item * radius in x direction

=item * radius in y direction

=item * angle phi by which the ellipse is rotated with respect to the
positive x axis (in radiant)

=item * x coordinate of the end point

=item * y coordinate of the end point.

=back

Note that the input values are not validated (e.g. if the values are
numbers etc.). It is assumed that this has been checked before.
Furthermore, it is not checked if the radii are very close to C<0>
or start and end point are nearly equal.

The following values are guaranteed to be returned:

=over 4

=item * adjusted absolute value of the radius in x direction

=item * adjusted absolute value of the radius in y direction

=back

This is all if one of the radii is equal to 0. Otherwise, the
following additional values are returned:

=over 4

=item * sin(phi)

=item * cos(phi)

=item * x_1' (see C<SVG> specification link above)

=item * y_1' (see C<SVG> specification link above)

=item * 1 / Lambda - 1

This value is only returned if Lambda is greater than 0 which is
equivalent (assuming exact arithmetics) to the end point of the arc
being different from the starting point. Lambda is the value
calculated in equation (F.6.6.2) of the specification (see link
above). 1 / Lambda - 1 is equal to the radicand in equation
(F.6.5.2).

=back


=head1 EXAMPLES

There are a few example scripts in the C<examples> directory of the
tar ball. However, they rather illustrate the currently supported
C<SVG> subset than options of C<SVG::Rasterize>. In order to run the
example scripts, you need to have the L<SVG|SVG> module installed
which is formally only required for testing.


=head1 DIAGNOSTICS

=head2 Error processing

The C<SVG> documentation specifies how C<SVG> interpreters
should react to certain incidents. The relevant section can be
found here:
L<http://www.w3.org/TR/SVG11/implnote.html#ErrorProcessing>.

This section describes how some of these instructions are
implemented by C<SVG::Rasterize> and how it reacts in some other
situations in which the specification does not give instructions.

=head3 In error

According to the C<SVG> specification (see
L<http://www.w3.org/TR/SVG11/implnote.html#ErrorProcessing>, a
document is "in error" if:

=over 4

=item * "the content does not conform to the C<XML 1.0>
specification, such as the use of incorrect C<XML> syntax"

C<SVG::Rasterize> currently does not parse C<SVG> files and will
therefore not detect such an error.

=item * "an element or attribute is encountered in the document
which is not part of the C<SVG DTD> and which is not properly
identified as being part of another namespace"

Currently, C<SVG::Rasterize> will also reject elements that B<are>
properly identified as being part of another namespace.

=item * "an element has an attribute or property value which is not
permissible according to this specification"

This is checked for those attributes and properties that are
currently supported by C<SVG::Rasterize>. Values that are currently
ignored may or may not be checked.

=item * "Other situations that are described as being I<in error> in
this specification"

=back

In these cases, the rendering is supposed to stop before the
incriminated element. Exceptions are C<path>, C<polyline>, and
C<polygon> elements which are supposed to be partially rendered up
to the point where the error occurs.

Furthermore, a "highly perceivable indication of error shall
occur. For visual rendering situations, an example of an indication
of error would be to render a translucent colored pattern such as a
checkerboard on top of the area where the C<SVG> content is
rendered."

In C<SVG::Rasterize> this is done by the
L<in_error_hook|/in_error_hook>. By default, it indeed draws a
translucent (C<rgb(45, 45, 45)> with opacity C<0.6>) checkerboard
with 8 fields along the width or height (whichever is shorter). This
behaviour can be changed by setting the
L<in_error_hook|/in_error_hook>. Setting the hook to C<undef> or
C<sub {}> will disable the process.

=head3 C<SVG::Rasterize> exceptions

When C<SVG::Rasterize> encounters a problem it usually throws an
exception. The cases where only a warning is issued a rare. This
behaviour has several reasons:

=over 4

=item * If the document is in error (see section above) the C<SVG>
specification requires that the rendering stops.

=item * In case of failed parameter validation,
L<Params::Validate|Params::Validate> expects the code execution to
stop. One could work around this in an onerous and fragile way, but
I will not do this.

=item * Often there is no good fallback without knowing what the
user intended to do. In these cases, it is better to just bail out
and let the user fix the problem himself.

=item * A too forgiving user agent deludes the user into bad
behaviour. I think that if the rules are clear, a program should
enforce them rather strictly.

=back

The exceptions are thrown in form of objects. See
L<Exception::Class|Exception::Class> for a detailed description. See
L<below|/Exceptions> for a description of the classes used in this
distribution. All error messages are described in
L<SVG::Rasterize::Exception|SVG::Rasterize::Exception>.

=head3 Invalid and numerically unstable values

There are situations where certain values cannot be dealt with,
e.g. denominators of 0 or negative radicands. Examples are skews of
90 degrees or elliptical arcs where one radius is 0. In these
situations, C<SVG::Rasterize> checks for these cases and acts
accordingly. Great care is taken to check directly those values
which are used as denominator, radicand etc. and not some
mathematically equivalent expression which might evaluate to a
slightly different value due to rounding errors. However, it is not
checked if such an expression is very close to a critical value
which might render the processing numerically unstable. I do not
want to impose a certain notion of "too close" on C<SVG>
authors. Instead it is left to them to check for these border
cases. However, the underlying rasterization engine might still
impose boundaries.

=head2 Exceptions

C<SVG::Rasterize> currently uses the following exception
classes. This framework is experimental and might change
considerably in future versions. See
L<Exception::Class|Exception::Class> on how you can make use of this
framework. See
L<SVG::Rasterize::Exception|SVG::Rasterize::Exception> for a
detailed list of error messages.

=over 4

=item * C<SVG::Rasterize::Exception::Base>

Base class for the others. Defines the state attribute which holds
the current L<SVG::Rasterize::State> object at the time the
exception is thrown.

=item * C<SVG::Rasterize::Exception::InError>

The processing encountered an error in the C<SVG> content.

=item * C<SVG::Rasterize::Exception::Setting>

The exception was triggered by an error during the general
preparation of the processing, e.g. an error during initialization
of the rasterization backend.

=item * C<SVG::Rasterize::Exception::Engine>

The exception was triggered by the rasterization backend
itself. This is specfically used when a bug in an engine
implementation is encountered (e.g. a mandatory method is not
overloaded). It is not restricted to these cases, though.

=item * C<SVG::Rasterize::Exception::Parse>

An error occured during parsing (usually of an attribute value). An
exception of this class always indicates an inconsistency between
validation and parsing of this value and should be reported as a
bug.

=item * C<SVG::Rasterize::Exception::Unsupported>

The document (or user) tried to use a feature that is currently
unsupported.

=item * C<SVG::Rasterize::Exception::Attribute>

Attribute means class attribute here, not C<SVG> attribute. An
example for such an exception is the attempt to change a readonly
attribute.

=item * C<SVG::Rasterize::Exception::ParamsValidate>

A method parameter did not pass a
L<Params::Validate|Params::Validate> check.

=item * C<SVG::Rasterize::Exception::Param>

A method parameter passed the L<Params::Validate|Params::Validate>
check, but is still invalid (an example is that the
L<Params::Validate|Params::Validate> check only included that the
value must be a number, but it also has to be in a certain range
which is checked individually later).

=item * C<SVG::Rasterize::Exception::Return>

A method returned an invalid value (example: the C<before_node_hook>
did not return a hash).

=back

=head2 Warnings

=over 4

=item * "Unrecognized init parameter %s."

You have given a parameter to the L<new|/new> method which does not
have a corresponding method. The parameter is ignored in that case.

=item * "Unable to load %s: %s. Falling back to
SVG::Rasterize::Engine::PangoCairo."

The C<engine_class> you were trying to use for rasterization could
not be loaded. C<SVG::Rasterize> then tries to use its default
backend
L<SVG::Rasterize::Engine::PangoCairo|SVG::Rasterize::Engine::PangoCairo>.
If that also fails, it gives up.

=item * "Surface width is 0, nothing to do."

The width of output image evaluates to C<0>. This value is rounded
to an integer number of pixels, therefore this warning does not mean
that you have provided an explicit number of C<0> (it could also
have been e.g. C<0.005in> at a resolution of C<90dpi>). In this
case, nothing is drawn.

=item * "Surface height is 0, nothing to do."

Like above.

=back


=head1 DEPENDENCIES

=over 4

=item * L<Class::Accessor|Class::Accessor>, version 0.30 or higher

=item * L<Cairo|Cairo>, version 1.061 or higher

The version of the underlying C<C> library has to be at least
1.8.8. This is not automatically fulfilled by installing a
sufficiently high version of the Perl module because the release
cycles are completely decoupled. Regarding the functionality that is
used directly, version 1.2 might actually be sufficient, but version
1.8 was the smallest I got pango (see below) compiled with.

With respect to the module code, the dependency on L<Cairo|Cairo> is
not strict.  The code only requires L<Cairo|Cairo> in case no other
rasterization engine is specified (see documentation for
details). However, if you do not provide a different backend, which
would probably at least require a wrapper written by you, then you
cannot do anything without L<Cairo|Cairo>. Therefore I have included
it as a strict dependency. You could take it out of the Makefile.PL
if you know what you are doing. However, the distribution will not
pass the test suite without L<Cairo|Cairo>.

=item * L<Pango|Pango>, version 1.220 or higher

The version of the underlying C<C> library has to be at least
1.22.4. This is not automatically fulfilled by installing a
sufficiently high version of the Perl module because the release
cycles are completely decoupled.

The rest of what has been said about C<Cairo> above is also true for
C<Pango>. Both are loaded by
L<SVG::Rasterize::Engine::PangoCairo|SVG::Rasterize::Engine::PangoCairo>
and that is only loaded if no other backend has been specified.

=item * L<Params::Validate|Params::Validate>, version 0.91 or higher

=item * L<Scalar::Util|Scalar::Util>, version 1.19 or higher

=item * L<Exception::Class>, version 1.29 or higher

=back

Additionally, testing requires the following modules:

=over 4

=item * L<SVG|SVG>, version 2.37 or higher

=item * L<Test::More|Test::More>, version 0.86 or higher

=item * L<Test::Exception|Test::Exception>, version 0.27 or higher

=item * L<Test::Warn|Test::Warn>, version 0.08 or higher.

=back

=head1 BUGS AND LIMITATIONS

=head2 Bugs

Please report any bugs or feature requests to C<bug-svg-rasterize at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SVG-Rasterize>. I
will be notified, and then you will automatically be notified of
progress on your bug as I make changes.

=over 4

=item * Rendering of not fully opaque groups

Grouping elements are supposed to be rendered on a temporary canvas
which is then composited into the background (see
L<http://www.w3.org/TR/SVG11/render.html#Grouping>). Currently,
C<SVG::Rasterize> renders each child element of the grouping element
individually. This leads to wrong results if the group has an
opacity setting below 1.

=item * Single character transformation in non-trivial
character-to-glyph mapping scenarios

The specification at
L<http://www.w3.org/TR/SVG/text.html#TSpanElement> describes how
single character transformations in e.g. text elements are supposed
to be carried out when there is not a one to one mapping between
characters and glyphs. Currently, C<SVG::Rasterize> does not abide
by these rules. Where values for C<x>, C<y>, C<dx>, C<dy>, or
C<rotate> are specified on a individual character basis, the string
is broken into part an rasterized piece by piece.

=back


=head2 Limitations

=over 4

=item * Relative units

The relative units C<em>, C<ex>, and C<%> are currently not
supported. Neither are the C<font-size> values C<smaller> and
C<larger>, the C<font-weight> values C<lighter> and C<bolder>, and
the C<font-stretch> values C<narrower> and C<wider>.

=item * C<ICC> colors

C<ICC> color settings for the C<fill> and C<stroke> properties are
understood, but ignored. I do not know enough about color profiles
to foresee how support would look like. Unless requested, C<ICC>
color profiles will probably not be supported for a long time.

=item * C<XML> names

The C<XML> standard is very inclusive with respect to characters
allowed in C<XML> Names and Nmtokens (see
L<http://www.w3.org/TR/2006/REC-xml11-20060816/#xml-names>).
C<SVG::Rasterize> currently only allows the C<ASCII> subset of
allowed characters because I do not know how to build efficient
regular expressions supporting the huge allowed character class.

Most importantly, this restriction affects the C<id> attribute of
any element. Apart from that, it affects C<xml:lang> attributes and
the C<target> attribute of C<a> elements.

=back


=head2 Caveats

=over 4

=item * C<eval BLOCK> and C<$SIG{__DIE__}>

Several methods in this distribution use C<eval BLOCK> statements
without setting a local C<$SIG{__DIE__}>. Therefore, a
C<$SIG{__DIE__}> installed somewhere else can be triggered by
these statements. See C<die> and C<eval> in C<perlfunc> and
C<$^S> in C<perlvar>.

=item * Thread safety

I do not know much about threads and how to make a module thread
safe. No specific measures have been taken to achieve thread
safety of this distribution.

=back


=head1 IMPLEMENTATION NOTES

This documentation is largely for myself. Read on if you are
interested, but this section generally does not contain
documentation on the usage of C<SVG::Rasterize>.

=head2 Deferred Rasterization

Some elements (namely C<text> and C<textPath> elements) can only be
rasterized once their entire content is known (e.g. for alignment
issues). In these situations, the
L<SVG::Rasterize::State|SVG::Rasterize::State> objects representing
the deferred nodes are pushed to a C<_rasterization_queue>. The
content is then only rasterized once the root element of this
subtree is about to run out of scope.


=head1 INTERNALS

=head2 Regular Expressions

All reused regular expressions are located in
L<SVG::Rasterize::Regexes|SVG::Rasterize::Regexes>. In general, they
should be considered as private variables and are documented there
for inspection only. Anyway, most of them are compiled into other
expressions, so changing them would probably not achieve what you
might expect. The expressions listed here are exceptions to this
rule. They are considered part of the interface and you can change
them (at your own risk ;-) ).

=over 4

=item * $package_part (internal)

  qr/[a-zA-Z][a-zA-Z0-9\_]*/

=item * C<$SVG::Rasterize::Regexes::RE_PACKAGE{p_PACKAGE_NAME}>

  qr/^$package_part(?:\:\:$package_part)*$/

Package names given to methods in this distribution, namely the
C<engine_class> parameters have to match this regular expression. I
am not sure which package names exactly are allowed. If you know
where in the Perl manpages or the Camel book this is described,
please point me to it. If this pattern is too strict for your
favourite package name, you can change this variable.

=back

=head2 Internal Attributes

These attributes and the methods below are just documented for
myself. You can read on to satisfy your voyeuristic desires, but be
aware of that they might change or vanish without notice in a future
version.

=over 4

=item * %DEFER_RASTERIZATION

Current value:

  %DEFER_RASTERIZATION = (text     => 1,
                          textPath => 1);

Used by L<SVG::Rasterize::State|/SVG::Rasterize::State> to decide if
rasterization needs to be deferred. See L<Deferred
Rasterization|/Deferred Rasterization> above.

=item * %TEXT_ROOT_ELEMENTS

Current value:

  %TEXT_ROOT_ELEMENTS = (text     => 1,
                         textPath => 1);

Text content elements (like C<tspan>) can inherit position
information from ancestor elements. However, when they find an
element of one of these types they do not have to look further up in
the tree.

=back

=head2 Internal Methods

=over 4

=item * _create_engine

Expects a HASH reference as parameter. No validation is
performed. The entries C<width>, C<height>, and C<engine_class> are
used and expected to be valid if present.

=item * _initial_viewport

Expects two HASH references. The first one contains the node
attributes of the respective element. It has to be defined and a
HASH reference, but the content is assumed to be unvalidated. The
second is expected to be validated. The keys C<width>, C<height>,
and C<matrix> are used. Does not return anything.

=item * _traverse_object_tree

Called by L<rasterize|/rasterize>. Expects a hash with the
rasterization parameters after all substitutions and hierarchies of
defaults have been applied. Handles the traversal of an L<SVG|SVG>
or generic C<DOM> object tree for rasterization.

=item * _process_node_object

Called by C<_traverse_object_tree>. Expects a node object and a hash
with the rasterization parameters. Performs

=over 4

=item * extraction of the node name

This uses the C<getNodeName> C<DOM> method. Takes whatever this
method returns.

=item * extraction and normalization of attributes

This uses the C<getAttributes> C<DOM> method. The return value is
validated as being either C<undef> or a HASH reference. The result
is further processed by
L<_process_normalize_attributes|/_process_normalize_attributes>. The
final result is guaranteed to be a HASH reference.

=item * extraction of child nodes

This uses the C<getChildNodes> C<DOM> method. The return value is
validated as being either C<undef> or an ARRAY reference. A copy
of the array is made to enable addition or removal of child nodes
(by hooks) without affecting the node object.

At this time, ignored nodes are filtered out of the list of child
nodes.

=item * transformation of L<SVG::Element|SVG::Element> character
data into a L<SVG::Rasterize::TextNode|SVG::Rasterize::TextNode>
object (see there for background information).

=back

Returns a list of the following values. The result is not further
validated than listed below.

=over 4

=item * the node name, whatever C<getNodeName> on the object
returned

=item * a HASH reference with the (potentially normalized)
attributes

=item * an ARRAY reference or C<undef> with the list of child node
objects (as returned by C<getChildNodes>).

=back

=item * _parse_svg_file

Called by L<rasterize|/rasterize>. Expects a hash with the
rasterization parameters after all substitutions and hierarchies of
defaults have been applied. Handles the C<SAX> parsing of an C<SVG>
file for rasterization.

This method requires L<XML::SAX|XML::SAX>. This module is not a
formal dependency of the C<SVG::Rasterize> distribution because I do
not want to force users to install it even if they only want to
rasterize content that they have created e.g. using the L<SVG|SVG>
module. This method will raise an exception if L<XML::SAX|XML::SAX>
cannot be loaded.

=item * _process_normalize_attributes

Expects a flag (to indicate if normalization is to be performed) and
a HASH reference. The second parameter can be false, but if it is
C<true> it is expected (without validation) to be a HASH
reference. Makes a copy of the hash and returns it after removing
(if the flag is true) enclosing white space from each value.

Independently of the flag, it processes the C<style> attribute. If
this is a HASH reference it is turned into a string. This means
double work, because it is split into a hash again later by
C<State>, but it is a design decision that C<State> should not see
if the input data came as an object tree or C<XML> string. So this
has to be done, and this seemed to be a good place although this
method was not started for something like that (maybe it should be
renamed).

=item * _flush_rasterization_queue

During L<Deferred Rasterization|/Deferred Rasterization>, nodes
(more precisely: their corresponding
L<SVG::Rasterize::State|SVG::Rasterize::State> objects) are pushed
to a queue. When the element that caused the deferred rasterization
runs out of scope this method flushes the queue and calls the
respective rasterization methods.

Expects nothing, returns nothing.

=item * _generate_font_size_scale_table

Called by L<font_size_scale|/font_size_scale> to generate the font
size scale table based on L<medium_font_size|/medium_font_size> and
L<font_size_scale|/font_size_scale>. The underlying data structure
is designed to support different tables for different font families
(as mentioned in the respective C<CSS> specification), but the
public accessor methods do not support that, yet.

=item * _process_node

Is called for each node, examines what kind of node it is, and calls
the more specific methods. Pushes the
L<SVG::Rasterize::State|SVG::Rasterize::State> object to the
rasterization queue during deferred rasterization.

Expects a C<SVG::Rasterize::State> object and optionally a hash of
options. The important option is C<flush>. Possibly sets the
C<queued> option. All options are passed on to the downstream
method.

=item * _process_path

Expects a L<SVG::Rasterize::State|SVG::Rasterize::State> object and
optionally a hash of options. If the option C<queued> is set to a
true value, nothing is done.

Expects that C<< $state->node_attributes >> have been validated. The
C<d> attribute is handed over to
L<_split_path_data|/_split_path_data> which returns a list of
instructions to render the path. This is then handed over to the
rasterization backend (which has its own expectations).

=item * _angle

  $angle = _angle($x1, $y1, $x2, $y2)
  $angle = SVG::Rasterize->_angle($x1, $y1, $x2, $y2)
  $angle = $rasterize->_angle($x1, $y1, $x2, $y2)

Expects two vectors and returns the angle between them in C<rad>. No
parameter validation is performed. If one of the vectors is C<0>
(and only if it is exactly C<0>), C<undef> is returned.

=item * _split_path_data

Expects a path data string. This is expected (without validation) to
be defined. Everything else is checked within the method.

Returns a list. The first entry is either C<1> or C<0> indicating if
an error has occured (i.e. if the string is not fully valid). The
rest is a list of ARRAY references containing the instructions to
draw the path.

=item * _process_rect

Expects a L<SVG::Rasterize::State|SVG::Rasterize::State> object and
optionally a hash of options. If the option C<queued> is set to a
true value, nothing is done.

Expects that C<< $state->node_attributes >> have been validated.

The rest is handed over to the rasterization backend (which has its
own expectations).

=item * _process_circle

Same es L<_process_rect|/_process_rect>.

=item * _process_ellipse

Same es L<_process_rect|/_process_rect>.

=item * _process_line

Same es L<_process_rect|/_process_rect>.

=item * _process_polyline

Same es L<_process_path|/_process_path>.

=item * _process_polygon

Same es L<_process_path|/_process_path>.

=item * _process_text

Expects a L<SVG::Rasterize::State|SVG::Rasterize::State> object and
optionally a hash of options. If the option C<queued> is set to a
true value, nothing is done.

Expects that C<< $state->node_attributes >> have been
validated. Determines C<text-anchor> and the absolute rasterization
position for each
L<text atom|SVG::Rasterize::State::Text/DESCRIPTION>.

=item * _process_tspan

Currently does not do anything. All text processing is done by
either L<_process_text|/_process_text> or
L<_process_cdata|/_process_cdata>. Might be deleted in the future.

=item * _process_cdata

Expects a L<SVG::Rasterize::State|SVG::Rasterize::State> object and
optionally a hash of options. If the option C<queued> is set to a
true value, nothing is done.

Expects that C<< $state->node_attributes >> have been
validated. Calls the C<draw_text> method of the rasterization engine
on each of its atoms in the right order.

=item * make_ro_accessor

This piece of documentation is mainly here to make the C<POD>
coverage test happy. C<SVG::Rasterize> overloads C<make_ro_accessor>
to make the readonly accessors throw an exception object (of class
C<SVG::Rasterize::Exception::Attribute>) instead of just croaking.

=back

=head1 FOOTNOTES

=over 4

=item * [1] Yannis Haralambous: Fonts & Encodings. O'Reilly, 2007.

Tons of information about what the author calls the "digital space
for writing".

=back

=head1 SEE ALSO

=over 4

=item * L<http://www.w3.org/TR/SVG11/>

=item * L<SVG|SVG>

=item * L<SVG::Parser|SVG::Parser>

=item * L<Cairo|Cairo>

=item * L<Exception::Class|Exception::Class>

=back


=head1 ACKNOWLEDGEMENTS

This distribution builds heavily on the
L<cairo|http://www.cairographics.org/> library and its
L<Perl bindings|Cairo>.


=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Lutz Gehlen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
