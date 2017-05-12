use strict;
use warnings;

############################################################################
                       package PDL::Graphics::Prima;
############################################################################
our $VERSION = 0.17;   # do not delete these spaces; run update-version.pl
                       # if you change this

# Add automatic support for PDL terminal interactivity
use PDL::Graphics::Prima::ReadLine;
sub import {
	my $class = shift;
	
	# Set up the interactivity, if possible with this terminal
	PDL::Graphics::Prima::ReadLine->setup($PERLDL::TERM)
		if PDL::Graphics::Prima::ReadLine->is_happy_with($PERLDL::TERM);
}

############################################################################
                           package Prima::Plot;
############################################################################

# Prima
use Prima qw(noX11 Application ImageDialog MsgBox Utils Buttons InputLine
			Label);
use base 'Prima::Widget';

# Error reporting
use Carp;

# PDL
use PDL::Lite;
use PDL::NiceSlice;
use PDL::Drawing::Prima;

# library-specific modules whose functionality I need
use PDL::Graphics::Prima::Axis;
use PDL::Graphics::Prima::DataSet;

# Next: use block-comments to describe the purpose of each method.

######################################
# Usage        : ????
# Purpose      : ????
# Arguments    : ????
# Returns      : ????
# Side Effects : none
# Throws       : no exceptions
# Comments     : none
# See Also     : n/a

######################################
# Usage        : Not used directly; this is invoked by Prima's inherited
#              : constructor.
# Purpose      : Sets up a default profile for a graph widget
# Arguments    : The (completely uninitialized) object
# Returns      : a hashref
# Side Effects : none
# Throws       : never
# Comments     : none
# See Also     : init

sub profile_default {
	my %def = %{$_[ 0]-> SUPER::profile_default};

	return {
		%def,
		# default properties follow
		
		# Title basics
		title => '',
		titleSpace => '1line',
		titleFont => { height => '10%height' },
		
		backColor => cl::White,
		
		# replot duration in milliseconds
		replotDuration => 30,
		# Blank profiles for the axes:
		x => {},
		y => {},
		
		# Other important and basic settings
		selectable => 1,
		buffered => 1,
	};
}

######################################
# Usage        : Not used directly; this is invoked by Prima's inherited
#              : constructor.
# Purpose      : Initializes self's data from the profile.
# Arguments    : $self, as yet uninitialized
#              : a list of key => value pairs corresponding to the list of
#              : arguments provided to the constructor, merged with the default
#              : profile.
# Returns      : A list of key => value pairs suitable for a profile hash.
# Side Effects : none
# Throws       : if unable to initialize the x/y axes from their associated
#              : constructor hashrefs
# Comments     : This has a lot of logic for setting defaults. It might not be
#              : a bad idea to refactor some of this out, so that a Plot widget
#              : can be reset to a default state.
# See Also     : profile_default

sub init {
	my $self = shift;
	my %profile = $self->SUPER::init(@_);
	
	# Set the title properties
	$self->_title($profile{title});
	$self->_titleSpace($profile{titleSpace});
	$self->_titleFont(%{$profile{titleFont}});
	
	# Create the x- and y-axis objects, overriding the owner and axis name
	# properties if they are set in the profile.
	for ('x', 'y') {
		if (eval{$profile{$_}->isa('PDL::Graphics::Prima::Axis')}) {
			$self->{$_} = $profile{$_};
			$self->{$_}->owner($self);
			$self->{$_}->name($_);
		}
		elsif (ref ($profile{$_}) eq 'HASH') {
			$self->{$_} = PDL::Graphics::Prima::Axis->create(
				%{$profile{$_}}
				, owner => $self
				, name => $_
			);
		}
		elsif (not ref($profile{$_})) {
			# No ref means scalar; assume it's a label name
			$self->{$_} = PDL::Graphics::Prima::Axis->create(
				label => $profile{$_}
				, owner => $self
				, name => $_
			);
		}
		else {
			croak("Unable to create $_-axis from $profile{$_}");
		}
	}
	
	$self->{timer} = Prima::Timer->create(
		timeout => $profile{replotDuration},
		onTick => sub {
			$_[0]->stop;
			$self->repaint;
		}
	);
	
	# Create an empty dataset array and tie it to the DataSetHash class:
	my %datasets;
	tie %datasets, 'PDL::Graphics::Prima::DataSet::Collection', $self;
	$self->{dataSets} = \%datasets;
	
	# Turn off the axis autoscaling until after we've added the data
	$self->{x}->{initializing} = 1;
	$self->{y}->{initializing} = 1;
	
	# Add datasets. All of the datasets are validated when added as key/value
	# pairs to the tied hash:
	while (my ($key, $value) = each %profile) {
		next unless $key =~ /^-(.+)/;
		# $1 contains the name of the dataset; $value is the dataset itself:
		# working here - catch errors?
		$self->dataSets->{$1} = $value;
	}
	
	# Turn the axis autoscaling back on:
	$self->{x}->{initializing} = 0;
	$self->{y}->{initializing} = 0;
	
	return %profile;
}

sub on_destroy {
	my $self = shift;
	$self->{prop_window}->destroy if exists $self->{prop_window};
}

# This is key: *this* is what triggers autoscaling for the first time
# working here, consider setting sizeMin, sizeMax

sub on_size {
	my $self = shift;
	# Note: order here is important as x needs to access information about y
	# in its calculations
	$self->y->update_edges;
	$self->x->update_edges;
}

my $inf = -PDL->new(0)->log->at(0);


sub collect_collated_min_max_for;
sub pair_down_collation;

sub compute_min_max_for {
	my ($self, $axis_name) = @_;
	
	# Special handling for x-axis stuff:
	my (undef, $y_max_is_auto) = $self->y->max;
	if ($axis_name =~ /x/ and $y_max_is_auto) {
		# First perform all of this on y so that the edge requirements are
		# correctly computed for x-calculations later.
		
		# Perform the collation:
		my ($trimmed_minima, $trimmed_maxima)
			= $self->collect_collated_min_max_for('y');
		return if not defined $trimmed_maxima;
		
		# Perform a round of minimazation:
		my ($min, $max)
			= $self->pair_down_collation('y', $trimmed_minima, $trimmed_maxima);
		
		# Update the axis min/max and redo the pair-down:
		(undef, my $min_auto) = $self->y->min;
		(undef, my $max_auto) = $self->y->max;
		$self->y->_min($min);
		$self->y->_max($max);
		$self->y->recalculate_edge_requirements($self);
		$self->y->_min(lm::Auto) if $min_auto;
		$self->y->_max(lm::Auto) if $max_auto;
	}
	
	# Perform the collation:
	my ($trimmed_minima, $trimmed_maxima)
			= $self->collect_collated_min_max_for($axis_name);
	return if not defined $trimmed_maxima;
	
	return $self->pair_down_collation($axis_name, $trimmed_minima, $trimmed_maxima);
}

sub get_pixel_extent_for;

sub collect_collated_min_max_for {
	my ($self, $axis_name) = @_;
	
	# Get plotting pixel extent, which I'll need to send to the dataSets in
	# order for them to compute their pyramids.
	my $pixel_extent = $self->get_pixel_extent_for($axis_name);
	return if $pixel_extent <= 0;
	
	my $datasets = $self->{dataSets};
	my (@min_collection, @max_collection);
	while (my ($key, $dataset) = each %$datasets) {
		next if $key eq 'widget';
		
		# Accumulate all the collated results
		my ($min, $max) = $dataset->compute_collated_min_max_for($axis_name, $pixel_extent);
		# The collated results should be one dimensional, so no reduction
		# necessary (as opposed to the DataSet code):
		push @min_collection, $min;
		push @max_collection, $max;
	}
	
	return if @min_collection == 0;
	
	# Merge all the data:
	my $collated_min = PDL::cat(@min_collection)->mv(-1,0)->minimum;
	my $collated_max = PDL::cat(@max_collection)->mv(-1,0)->maximum;
	
	# It could be the case that all the values are bad. In that case, insert
	# an entry at zero-pixels corresponding to the current view limits:
	$collated_min(0) .= $self->{$axis_name}->min if $collated_min->isbad->all;
	$collated_max(0) .= $self->{$axis_name}->max if $collated_max->isbad->all;
	
	# Iterativelye pair down the set until we've found the minmax. At this
	# point, we have two arrays with $pixel_extent elements each. Cat an
	# index and what will eventually be a computed value onto the original
	# lists so our slicing keeps track of the padding and original values.
	my $minima = $collated_min->cat($collated_min->sequence, $collated_min);
	my $maxima = $collated_max->cat($collated_max->sequence, $collated_max);

	# Get rid of all the bad values. We know that at least one good value will
	# remain due to the min/max insertion a few lines up.
	my $trimmed_minima = $minima->whereND($minima(:,0;-)->isgood);
	my $trimmed_maxima = $maxima->whereND($maxima(:,0;-)->isgood);
	
	return ($trimmed_minima, $trimmed_maxima);
}

# Given a collated set of mininam and maxima (from collect_collated_min_max_for)
# this function determines that minimum and maximum necessary for viewing *all*
# the data.

sub pair_down_collation {
	my ($self, $axis_name, $trimmed_minima, $trimmed_maxima) = @_;
	
	my $min_mask = $trimmed_minima->trim_collated_min;
	my $max_mask = $trimmed_maxima->trim_collated_max;
	$trimmed_minima = $trimmed_minima->whereND($min_mask);
	$trimmed_maxima = $trimmed_maxima->whereND($max_mask);
	
	# Compute properly scaled extrema.
	# min_pix and max_pix are the plain pixel paddings needed by the lowest
	# element in the pyramid:
	my ($min_pix, $max_pix) = ($trimmed_minima->at(0,1), $trimmed_maxima->at(0,1));
	# virtual_pixel_extent is the room available to plot the data when the
	# real pixel extent is reduced by the requested pixel padding:
	my $pixel_extent = $self->get_pixel_extent_for($axis_name);
	my $virtual_pixel_extent = $pixel_extent - $min_pix - $max_pix;
	# working here - come up with something better than just croaking.
	die "Internal error: virtual pixel extent is non-positive"
		if $virtual_pixel_extent <= 0;
	# min_data and max_data are the actual min and max values of the data
	# that are supposed to fit within the virtual pixel extent.
	my ($min_data, $max_data)
		= ($trimmed_minima(:,(2))->min, $trimmed_maxima(:,(2))->max);
	
	# It is possible that all the x-data or all the y-data are identical.
	# Check if the current min/max values are identical and return the
	# scaling's response in such a situation:
	return $self->{$axis_name}->scaling->min_max_for_degenerate($min_data)
		if $min_data == $max_data;
	
	# min and max are the final minimal and maximal values that we use for
	# the axis so that all the data can be drawn within the plot.
	my $min = $self->{$axis_name}->scaling->inv_transform($min_data, $max_data
		, -$min_pix/$virtual_pixel_extent);
	my $max = $self->{$axis_name}->scaling->inv_transform($min_data, $max_data
		, 1 + $max_pix/$virtual_pixel_extent);
	# working here - come up with something better than just croaking.
	die "Internal error: min ($min) is greater than max ($max)" if $min > $max;
	
	# We will iterate until we stop removing rows, at which point the lowest
	# level of the pyramid is what we want.
	my $N_rows;
	do {
		$N_rows = $trimmed_minima->dim(0);
		
		# Assuming that the current min/max are roughly correct, compute the
		# updated min/max calculated values:
		$trimmed_minima(:,2)
			.= $self->{$axis_name}->pixels_to_reals(
				$self->{$axis_name}->reals_to_pixels($trimmed_minima(:,0), 1, $min, $max)
					- $trimmed_minima(:,1), 1, $min, $max);
		$trimmed_maxima(:,2)
			.= $self->{$axis_name}->pixels_to_reals(
				$self->{$axis_name}->reals_to_pixels($trimmed_maxima(:,0), 1, $min, $max)
					+ $trimmed_maxima(:,1), 1, $min, $max);
		
		# Trim again:
		$min_mask = $trimmed_minima->trim_collated_min;
		$max_mask = $trimmed_maxima->trim_collated_max;

		$trimmed_minima = $trimmed_minima->whereND($min_mask);
		$trimmed_maxima = $trimmed_maxima->whereND($max_mask);
		
		# Recompute the properly scaled extrema:
		($min_pix, $max_pix) = ($trimmed_minima->at(0,1), $trimmed_maxima->at(0,1));
		$virtual_pixel_extent = $pixel_extent - $min_pix - $max_pix;
		($min_data, $max_data) = ($trimmed_minima->at(0,0), $trimmed_maxima->at(0,0));
		$min = $self->{$axis_name}->scaling->inv_transform($min_data, $max_data
			, -$min_pix/$virtual_pixel_extent);
		$max = $self->{$axis_name}->scaling->inv_transform($min_data, $max_data
			, 1 + $max_pix/$virtual_pixel_extent);
	} while($N_rows != $trimmed_minima->dim(0));
	
	return ($min, $max);
}

sub get_pixel_extent_for {
	my ($self, $axis_name) = @_;
	
	my ($left, $bottom, $right, $top) = $self->get_edge_requirements;
	my $pixel_extent;
	if ($axis_name eq 'x') {
		$pixel_extent = $self->width - $left - $right;
	}
	else {
		$pixel_extent = $self->height - $top - $bottom;
	}
	return $pixel_extent;
}

# This should distinguish between shared space and exclusive space. For
# example, the title requests exclusive space (a height of titleSpace),
# which is added to that shared max shared space requested by both of the
# axes. The return values should be left, bottom, right, top
sub get_edge_requirements {
	my $self = shift;
	my @x_req = $self->x->get_edge_requirements;
	my @y_req = $self->y->get_edge_requirements;
	
	# Merge the two:
	my @requirement = (0, 0, 0, 0);
	my $i = 0;
	foreach my $req (@x_req, @y_req) {
		$requirement[$i] = $req if $requirement[$i] < $req;
		$i++;
		$i %= 4;
	}
	
	$requirement[3] += $self->titleSpace
		if defined $self->{title} and $self->{title} ne '';
	
	return @requirement;
}

######################################
# Usage        : my $title_string = $plot->title; # get
#              : $plot->title('new title');       # set
#              : $plot->title(undef);             # clear
#              : $plot->title('');                # clear
# Purpose      : Gets, sets, or clears the plot's title.
# Arguments    : $self
#              : an optional title string, or an optional undef
# Returns      : In get mode, the title; in set mode, the newly set title.
# Side Effects : Issues a ChangeTitle notification, which will cause the
#              : y-extent of the graph to change when the title goes from unset
#              : to set, or set to unset.
# Throws       : never
# Comments     : None
# See Also     : titleSpace, on_changetitle, draw_plot, ChangeTitle

sub _title {
	$_[0]->{title} = $_[1];
}

sub title {
	return $_[0]->{title} unless $#_;
	$_[0]->_title($_[1]);
	$_[0]->notify('ChangeTitle');
	return $_[0]->{title};
}

sub _titleFont {
	my $self = shift;
	
	# Return a copy of the current font hash if this is a getter
	return %{$self->{titleFont}} if @_ == 0;
	
	# Otherwise store the provided font hash, overwriting the previous one
	$self->{titleFont} = { @_ };
}

sub titleFont {
	$_[0]->notify('ChangeTitle') if @_ > 1;
	goto \&_titleFont;
}

# Assumes that begin_paint or begin_paint_info have already been called.
sub _set_title_font {
	my ($self, $canvas) = (shift, shift);
	
	# Get a copy of the title font hash and process any relative sizes
	my %title_font_hash = $self->_titleFont;
	SETTING: for my $setting ( qw(height width size) ) {
		next SETTING unless exists $title_font_hash{$setting};
		if ($title_font_hash{$setting} =~ /(.*)\%width/) {
			$title_font_hash{$setting} = $canvas->width * $1 / 100;
		}
		elsif ($title_font_hash{$setting} =~ /(.*)\%height/) {
			$title_font_hash{$setting} = $canvas->height * $1 / 100;
		}
		elsif ($title_font_hash{$setting} =~ /(.*)x/) {
			$title_font_hash{$setting} = $canvas->font->{$setting} * $1;
		}
	}
	
	# Set it
	$canvas->font(%title_font_hash);
}

sub _title_font_height {
	my ($self, $canvas) = (shift, shift);
	# Set up the paint info state. This will fail if we're already in paint
	# info state, in which case we will not want to clear it at the end:
	my $will_clear_paint_info = $canvas->begin_paint_info;
	
	# Backup the font, change to the title font, and compute
	my $font = $canvas->font;
	$self->_set_title_font($canvas);
	my $height = $canvas->font->height;
	
	# Restore the widget to the previous state
	$canvas->font($font);
	$canvas->end_paint_info if $will_clear_paint_info;
	
	# All done
	return $height;
}

######################################
# Usage        : my $title_space = $plot->titleSpace; # get
#              : $plot->titleSpace(40);               # set
#              : $plot->titleSpace('10% - 5px');      # set
#              : $plot->title(0);                     # hide
#              : $plot->title(undef);                 # hide
# Purpose      : Gets or sets the plot's titleSpace.
# Arguments    : $self
#              : an optional title height in pixels
# Returns      : In get mode, the titleSpace; in set mode, the new height
# Side Effects : Issues a ChangeTitle notification, which will cause the
#              : y-extent of the graph to change.
# Throws       : when the new titleSpace is not a nonnegative integer
# Comments     : An argument of undef is treated as zero, and stored as such.
#              : Note that this mechanism is not very powerful at the moment.
#              : It is likely to be extended to allow for specification in terms
#              : of canvas height or width, em-width, and other parameters. See
#              : PDL::Graphics::Prima::PlotType::Annotation's spec_string
#              : handling to get an idea for what I have in mind.
# See Also     : title, on_changetitle, draw_plot, ChangeTitle

my %allowed_entries = map {$_ => 1} qw(pixels canvas_pct lines);
my $float_point_regex = qr/[-+]?([0-9]*\.?[0-9]+|[0-9]+\.[0-9]*)([eE][-+]?[0-9]+)?/;
sub _titleSpace {
	my ($self, $new_space) = @_;
	$new_space = 0 if not defined $new_space;
	
	# special-cases for a subref or nonnegative integer: just set it
	if (ref($new_space) eq ref(sub{})
		or ref($new_space) eq ref('scalar') and $new_space =~ /^\d+$/
	) {
		$self->{titleSpace} = $new_space;
		return;
	}
	# Special case for hashref: check and set if it passes
	if (ref($new_space) eq 'HASH') {
		# Make sure the entries are valid
		for my $key (keys %$new_space) {
			croak("titleSpace hash has invalid key $key")
				unless $allowed_entries{$key};
		}
		# Good to go; set it
		$self->{titleSpace} = $new_space;
		return;
	}
	
	# Otherwise we have a height spec to parse
	my $spec = {};
	$new_space =~ s/\s+//g;
	$new_space = lc $new_space;

	if ($new_space =~ s/($float_point_regex)lines?//) {
		$spec->{lines} = $1;
	}
	if ($new_space =~ s/($float_point_regex)\%//) {
		$spec->{canvas_pct} = $1 / 100;
	}
	if ($new_space =~ s/($float_point_regex)px//) {
		$spec->{pixels} = $1;
	}
	if (length($new_space) > 0) {
		croak("Unknown fragment in titleSpace specification: $new_space");
	}
	
	# All done parsing.
	$self->{titleSpace} = $spec;
}

sub titleSpace {
	my $self = shift;
	
	# Handle the setter case
	if (@_) {
		$self->_titleSpace(@_);
		$self->notify('ChangeTitle');
		return $self->titleSpace;
	}
	
	# OK, the rest of this is for the getter code
	
	# First the simple one: a plain number
	return $self->{titleSpace} unless ref($self->{titleSpace});
	
	# Next the subref, which requires an invocation:
	return $self->titleSpace->($self)
		if ref($self->{titleSpace}) eq ref(sub{});
	
	# We can only reach here if we have a hashref, which requires calculation
	my $spec_hash = $self->{titleSpace};
	my $titleSpace = 0;
	$titleSpace += $spec_hash->{pixels} if exists $spec_hash->{pixels};
	$titleSpace += $spec_hash->{canvas_pct} * $self->height
		if exists $spec_hash->{canvas_pct};
	$titleSpace += $self->_title_font_height($self) * $spec_hash->{lines}
		if exists $spec_hash->{lines};
	
	return $titleSpace;
}

sub dataSets {
	# Return the (tied) hash ref if called as a getter:
	return $_[0]->{dataSets} unless $#_;
	# If called as a setter, copy all the values. This may seem inefficient,
	# but it automatically performs all the data validation for me:
	my ($self, %new_data) = @_;
	
	# Clear the dataset (except the widget key, whick never disappears):
	%{$self->{dataSets}} = ();
	
	# Add each dataset individually, to ensure the validation does what it's
	# supposed to do:
	while(my ($key, $dataset) = each %new_data) {
		$self->{dataSets}->{$key} = $dataset;
	}
	
	# Don't need to issue a notification because that already happened with
	# the above assignments.
	#$self->notify('ChangeData');
}

sub get_image {
	my $self = shift;
	
	# Build a prima image canvas and draw to it:
	my $image = Prima::Image->create(
		height => $self->height,
		width => $self->width,
		font => $self->font,
		backColor => $self->backColor,
	) or die "Can't create an image!\n";
	$image->begin_paint or die "Can't draw on image";
	$image->clear;
	$self->paint_with_widgets($image);
	$image->end_paint;
	return $image;
}

use Prima::PS::Drawable;
use Prima::FileDialog;
use Prima::Drawable::Subcanvas;

sub save_to_postscript {
	# Get the filename as an argument, or from the save-as dialog.
	my ($self, $filename) = @_;
	
	unless ($filename) {
		my $save_dialog = Prima::SaveDialog-> new(
			defaultExt => 'eps',
			filter => [
				['Encapsulated Postscript files' => '*.eps'],
				['All files' => '*'],
			],
		);
		# Return if they cancel out:
		return unless $save_dialog->execute;
		# Otherwise get the filename:
		$filename = $save_dialog->fileName;
		# Provide a default extension
		$filename .= '.eps' unless $filename =~ /\.eps$/;
	}
	unlink $filename if -f $filename;
	
	# Calculate width and height using the (hopefully standard) rule that
	# 100px = 72pt = 1in. This doesn't quite work right, still. Compare the
	# output of the pathological-sizing.pl script to the original raster window.
	my $scaling_ratio = 72.27 / 100;
	my $width = $self->width * $scaling_ratio;
	my $height = $self->height * $scaling_ratio;
	# Create the postscript canvas and plot to it:
	my $ps = Prima::PS::Drawable-> create( onSpool => sub {
			open my $fh, ">>", $filename;
			print $fh $_[1];
			close $fh;
		},
		pageSize => [$width, $height],
		pageMargins => [0, 0, 0, 0],
		isEPS => 1,
		useDeviceFontsOnly => 1,
	);
	$ps->resolution($self->resolution);
	$ps->font(height => $self->font->height);
	
	$ps->begin_doc
		or do {
			my $message = "Error generating Postscript output: $@";
			if (defined $::application) {
				Prima::MsgBox::message($message, mb::Ok);
				carp($message);
			}
			else {
				croak($message);
			}
		};
	
	$self->paint_with_widgets($ps);
	$ps->end_doc;
}

# A routine to save the current plot to a rasterized file:
sub save_to_file {
	# Get the filename as an argument or from a save-as dialog.
	my ($self, $filename) = @_;
	
	# Get the image
	my $image = $self->get_image;
	
	# If they didn't specify a filename, run a dialog to get it:
	unless ($filename) {
		my $dlg = Prima::ImageSaveDialog-> create;
	
		$dlg->save($image);
		return;
	}
	
	# If they specified a filename, simply save it:
	$image-> save($filename)
		or do {
			my $message = "Error generating figure output: $@";
			if (defined $::application) {
				Prima::MsgBox::message($message, mb::Ok);
				carp($message);
			}
			else {
				croak($message);
			}
		};
}

sub copy_to_clipboard {
	my $self = shift;
	my $image = $self->get_image;
	
	my $clipboard = $::application->Clipboard;
	$clipboard->open;
	$clipboard->clear;
	$clipboard->image($image);
	$clipboard->close;
}

# For a change in title, recompute the autoscaling and issue an immediate
# repaint. Replotting is not appropriate here as replotting issues a timer
# event that may not get triggered if the event loop isn't running (i.e.
# we're in the PDL shell without ReadLine integration).
sub on_changetitle {
	my $self = shift;
	$self->x->update_edges;
	$self->y->update_edges;
	$self->notify('Paint');
	# If running in the PDL shell, clear the event queue so this hits
	# immediately
	$::application->yield if defined $PERLDL::TERM;
}

# Sets up a timer in self that eventually calls the paint notification:
sub on_replot {
	my ($self) = @_;
	return if $self->{timer}->get_active;
	$self->{timer}->start;
}

# for now, this is a replica of the above:
*on_changedata = \&on_changetitle;

#################
# Notifications #
#################
# Add a new notification_type for each of the notifications just defined.
{
	# Keep the notifications hash in its own lexically scoped block so that
	# other's can't mess with it.
	my %notifications = (
		%{Prima::Widget-> notification_types()},
		# working here - choose a better signal type?
		'Replot' => nt::Default,
		map { ("Change$_" => nt::Default) } qw(Title Data),
	);
	
	sub notification_types { return \%notifications }
}

sub on_paint {
	my ($self, $canvas) = @_;
	
	# We need to handle the case of this canvas not being this widget.
	if (defined $canvas and $canvas != $self) {
		my $setup_paint = ($canvas->get_paint_state != ps::Enabled);
		$canvas->begin_paint if $setup_paint;
		$canvas->clear;
		$self->draw_plot($canvas);
		$canvas->end_paint if $setup_paint;
		return;
	}
	
	# If the paint state is not enabled, issue a repaint, which will ultimately
	# re-invoke this method, but in a paint-enabled state. This achieves the
	# same purpose as something like this:
	#   $self->begin_paint;
	#   $self->on_paint;
	#   $self->end_paint
	# but it does not flicker the way that the above code does.
	return $self->repaint if $self->get_paint_state != 1;
	
	# Otherwise, clear the canvas and invoke our plot drawing routine on ourself
	$self->clear;
	$self->draw_plot($self);
}

# This is the actual functionality for drawing on the canvas. This was once part
# of on_paint, but was pulled out so that it can be overridden by subclasses
# without having to deal with the vagaries of getting the paint state right.
# Again, this is *meant* to be overridden. :-)
sub draw_plot {
	my ($self, $canvas) = @_;
	
	# Get the clipping rectangle for the actual drawing space:
	my ($clip_left, $clip_bottom, $right_edge, $top_edge)
		= $self->get_edge_requirements;
	
	my $ratio = $canvas->height / $self->height;
	
	# The right and top edge values should be subtracted from the width and
	# height, respectively:
	my $clip_right = $canvas->width - $ratio * $right_edge;
	my $clip_top = $canvas->height - $ratio * $top_edge;
	
	# Correct the left and bottom clipping for the canvas ratio
	$clip_left *= $ratio;
	$clip_bottom *= $ratio;
	
	# Clip the widget before we begin drawing
	$canvas->clipRect($clip_left, $clip_bottom, $clip_right, $clip_top);
	
	# Draw the data, sorted by key name:
	foreach my $key (sort keys %{$self->{dataSets}}) {
		next if $key eq 'widget';
		$self->{dataSets}->{$key}->draw($canvas, $ratio);
	}

	# Draw the zoom-rectangle, if there is one
	if (exists $self->{mouse_down_rel}->{mb::Right}) {
		my ($x, $y) = $self->pointerPos;
		my ($x_start_rel, $y_start_rel) = @{$self->{mouse_down_rel}->{mb::Right}};
		my $x_start_pixel = $self->x->relatives_to_pixels($x_start_rel, $ratio);
		my $y_start_pixel = $self->y->relatives_to_pixels($y_start_rel, $ratio);
		$canvas->rectangle($x_start_pixel, $y_start_pixel, $x, $y);
	}
	
	# Draw the axes
	$canvas->clipRect(0, 0, $self->size);
	$self->x->draw($canvas, $clip_left, $clip_bottom, $clip_right, $clip_top, $ratio);
	$self->y->draw($canvas, $clip_left, $clip_bottom, $clip_right, $clip_top, $ratio);
	
	# Draw the title:
	if (defined $self->{title} and $self->{title} ne '') {
		my $backup_font = $canvas->font;
		my ($width, $height) = $canvas->size;
		# Compute the titleSpace before changing anything
		my $titleSpace = $self->titleSpace;
		# Set up the title font
		$self->_set_title_font($canvas);
		
		# Draw the title:
		$canvas->draw_text($self->{title}, 0, $height - $titleSpace * $ratio
				, $width, $height
				, dt::Center | dt::VCenter | dt::NewLineBreak | dt::NoWordWrap
				| dt::UseExternalLeading);
		
		# Reset the font characteristics:
		$canvas->font($backup_font);
	}
}

# For mousewheel events, we zoom in or out. However, if they're over the axes,
# only zoom in or out for that axis.
sub on_mousewheel {
	return unless $_[0]->enabled;
	my ($self, $mods, $x, $y, $dir) = @_;
	my ($width, $height) = $self->size;
	
	# Get the relative x and y positions. When the mouse is over the plot itself
	# this is a number between 0 and 1 for both x and y. When the house is, for
	# example, over the x-axis tick labels, the y value will be less than 0.
	my $rel_x = $self->x->pixels_to_relatives($x);
	my $rel_y = $self->y->pixels_to_relatives($y);
	
	# if the mouse is over the data or the x-axis, zoom in the x-direction,
	# preserving the position of the mouse's x-value:
	if ($rel_x > 0 and $rel_x < 1) {
		# Dir > 0 means zooming in:
		my ($rel_min, $rel_max) = (0, 1);
		if ($dir > 0) {
			$rel_min += $rel_x/5;
			$rel_max -= (1 - $rel_x) / 5;
		}
		else {
			$rel_min -= $rel_x/5;
			$rel_max += (1 - $rel_x) / 5;
		}
		
		# Compute the new min/max values from the axis scaling:
		my $real_min = $self->x->relatives_to_reals($rel_min);
		my $real_max = $self->x->relatives_to_reals($rel_max);
		$self->x->minmax($real_min, $real_max);
	}
	# if the mouse is over the data or the y-axis, zoom in the y-direction:
	if ($rel_y > 0 and $rel_y < 1) {
		# Dir > 0 means zooming in:
		my ($rel_min, $rel_max) = (0, 1);
		if ($dir > 0) {
			$rel_min += $rel_y/5;
			$rel_max -= (1 - $rel_y) / 5;
		}
		else {
			$rel_min -= $rel_y/5;
			$rel_max += (1 - $rel_y) / 5;
		}
		
		# Compute the new min/max values from the axis scaling:
		my $real_min = $self->y->relatives_to_reals($rel_min);
		my $real_max = $self->y->relatives_to_reals($rel_max);
		$self->y->minmax($real_min, $real_max);
	}
	
	$self->notify('Replot');
}

sub get_min_max_for {
	my ($first, $second) = @_;
	return ($first, $second) if $first < $second;
	return ($second, $first);
}

sub on_mousedown {
	return unless $_[0]->enabled;
	my ($self, $down_button, undef, $x, $y) = @_;
	# Store the relative click locations:
	$x = $self->x->pixels_to_relatives($x);
	$y = $self->y->pixels_to_relatives($y);
	foreach (mb::Left, mb::Right, mb::Middle) {
		$self->{mouse_down_rel}->{$_} = [$x, $y] if $down_button & $_;
	}
	$self->{mouse_move_rel} = [$x, $y];
}

sub on_mousemove {
	return unless $_[0]->enabled;
	my ($self, $drag_button, $x_stop_pixel, $y_stop_pixel) = @_;
	
	# Compute the relative and real final mouse locations
	my $x_stop_rel = $self->x->pixels_to_relatives($x_stop_pixel);
	my $y_stop_rel = $self->y->pixels_to_relatives($y_stop_pixel);
	
	# On windows, the drag button is not properly reported. However, it is
	# there is never any issue with failure to report a mouse-down event (like
	# we get with X systems), so if I got here, it is easy enough to adapt.
	if ($^O =~ /MS/) {
		$drag_button = mb::Left if defined $self->{mouse_down_rel}->{mb::Left};
		$drag_button = mb::Right if defined $self->{mouse_down_rel}->{mb::Right};
	}
	
	if ($drag_button & mb::Left) {
		# A left mouse drag actually moves the graph around. Determine the
		# change in relative values, then change the min/max accordingly.
		
		# It sometimes happens that the mouse move event gets triggered
		# without a corresponding mouse down event, such as when I click
		# on the window from *another* application and move my mouse around.
		# If the mouse down coordinates are not known, store the current
		# ones and simply return.
		if (not defined $self->{mouse_down_rel}->{mb::Left}) {
			$self->{mouse_down_rel}->{mb::Left} = [$x_stop_rel, $y_stop_rel];
			return 1;
		}
		
		# working here - per-button mouse click tracking? I ask because sometimes
		# I accidentially click the left mouse button when I'm selecting a zoom
		# rectangle and it messed things up.
		
		# The behavior depends upon where they initially clicked and where the
		# mouse was last, so retrieve both of those values:
		my ($x_down_rel, $y_down_rel) = @{$self->{mouse_down_rel}->{mb::Left}};
		my ($x_start_rel, $y_start_rel) = @{$self->{mouse_move_rel}};
		
		# If the initial click was within the x-boundaries, then the x-values
		# should be adjusted:
		if ($x_down_rel > 0 and $x_down_rel < 1) {
			# Determine the relative change and the adjusted min/max:
			my $dx = $x_stop_rel - $x_start_rel;
			my $new_min = $self->x->relatives_to_reals(-$dx);
			my $new_max = $self->x->relatives_to_reals(1 - $dx);
			
			# Call the non-notifying version. The notifying version causes an
			# immediate redraw that causes the plot to accelerate away in
			# perldl.
			$self->x->_min($new_min);
			$self->x->_max($new_max);
		}
		# If the initial click was within the y-boundaries, then the y-values
		# should be adjusted:
		if ($y_down_rel > 0 and $y_down_rel < 1) {
			# Determine the relative change and the adjusted min/max:
			my $dy = $y_stop_rel - $y_start_rel;
			my $new_min = $self->y->relatives_to_reals(-$dy);
			my $new_max = $self->y->relatives_to_reals(1 - $dy);
			
			# Call the non-notifying version. The notifying version causes an
			# immediate redraw that causes the plot to accelerate away in
			# perldl.
			$self->y->_min($new_min);
			$self->y->_max($new_max);
		}
	}
	
	# Repaint if they're dragging the mouse
	$self->notify('Replot') if $drag_button;

	# Store the intermediate locations:
	$self->{mouse_move_rel} = [$x_stop_rel, $y_stop_rel];
}

sub on_mouseup {
	return unless $_[0]->enabled;
	my ($self, $up_button, $up_mods, $x_stop_pixel, $y_stop_pixel) = @_;
	
	# Remove the previous button record for left and middle buttons:
	if ($up_button & mb::Left) {
		delete $self->{mouse_down_rel}->{mb::Left};
	}
	elsif ($up_button & mb::Middle) {
		delete $self->{mouse_down_rel}->{mb::Middle};
	}
	elsif ($up_button & mb::Right and defined $self->{mouse_down_rel}->{mb::Right}) {
		# Zoom in to the requested rectangle:
		my ($x_start_rel, $y_start_rel) = @{$self->{mouse_down_rel}->{mb::Right}};
		my $x_stop_rel = $self->x->pixels_to_relatives($x_stop_pixel);
		my $y_stop_rel = $self->y->pixels_to_relatives($y_stop_pixel);
		
		# Only rescale if there is a legitimate x- and y- box:
		if ($x_stop_rel != $x_start_rel and $y_stop_rel != $y_start_rel) {
			# Reset the x min/max
			my ($min_rel, $max_rel) = get_min_max_for($x_start_rel, $x_stop_rel);
			# Compute the new min/max values from the axis scaling:
			my $min_real = $self->x->relatives_to_reals($min_rel);
			my $max_real = $self->x->relatives_to_reals($max_rel);
			# Set the new min/max values:
			$self->x->minmax($min_real, $max_real);

			# Reset the y min/max
			($min_rel, $max_rel) = get_min_max_for($y_start_rel, $y_stop_rel);
			# Compute the new min/max values from the axis scaling:
			$min_real = $self->y->relatives_to_reals($min_rel);
			$max_real = $self->y->relatives_to_reals($max_rel);
			# Set the new min/max values:
			$self->y->minmax($min_real, $max_real);
		}
		# Call the popup menu if it 'looks' like a right-click:
		elsif ($x_stop_rel == $x_start_rel and $y_stop_rel == $y_start_rel) {
			$self->popup(Prima::Popup->new(
				items => [
					['~Copy' => sub {
						Prima::Timer->create(
							timeout => 250,
							onTick => sub {
								$_[0]->stop;
								$self->copy_to_clipboard;
							},
						)->start;
					}],
					['Save As ~Postscript...' => sub {
						$self->save_to_postscript;
					}],
					['~Save As...' => sub {
						Prima::Timer->create(
							timeout => 250,
							onTick => sub {
								$_[0]->stop;
								$self->save_to_file;
							},
						)->start;
					}],
					['~Autoscale' => sub {
						$self->x->minmax(lm::Auto, lm::Auto);
						$self->y->minmax(lm::Auto, lm::Auto);
					}],
					['~Properties' => sub {
						$self->set_properties_dialog;
					}],
				],
			));
		}
		# Remove the previous button record, so a zoom rectangle is not drawn:
		delete $self->{mouse_down_rel}->{mb::Right};
	}
}

use Scalar::Util qw(looks_like_number);

sub insert_minmax_input {
	my ($group_box, $method, $axis, $y_pos) = @_;
	$group_box->insert(Label =>
		place => { x => 45, y => $y_pos, height => 25, width => 60, anchor => 'sw' },
		height => 30,
		text => ucfirst($method) . ':',
	);
	# the widgets we are about to add
	my ($auto_button, $inline);
	# lexical state variable to bypass updates if the input line triggered
	# the update
	my $update_inline = 1;
	# initial value and autoscaling state of the axis
	my ($init_val, $is_auto) = $axis->$method;
	
	# Attach an event listener to the axis min/max methods to keep is_auto
	# up-to-date, and ensure that the input line is accurate
	my $notification_idx = $axis->add_notification(ChangeBounds => sub {
		# get the new min or max
		(my $curr_val, $is_auto) = $axis->$method;
		
		$inline->text($curr_val . ($is_auto ? ' (Auto)' : ''))
			if $update_inline;
		$auto_button->enabled(!$is_auto);
	});
	
	no PDL::NiceSlice;
	my $val_is_good = $method eq 'min'	? sub { $_[0] < $axis->max }
										: sub { $_[0] > $axis->min };
	$inline = $group_box->insert(InputLine =>
		place => { x => 110, y => $y_pos, height => 30, width => 280, anchor => 'sw' },
		height => 30,
		text => ($is_auto ? "$init_val (Auto)" : $init_val),
		onEnter => sub {
			if ($is_auto) {
				$_[0]->text(scalar($axis->$method));
			}
		},
		onLeave => sub {
			if ($is_auto) {
				my $value = $axis->$method;
				$_[0]->text("$value (Auto)");
			}
		},
		onKeyDown => sub {
			my ($self, $code, $key) = @_;
			# Only check typed codes, in which case code >= 32
			return if $code < 32;
			# Screen what they typed for being a correct numerical entry
			$self->clear_event() unless chr($code) =~ /[\d.+\-e]/i;
		},
		onKeyUp => sub {
			my ($self, $code, $key) = @_;
			return if $code < 32 && $key != kb::Backspace && $key != kb::Delete;
			my $new_val = $self->text;
			if (looks_like_number($new_val) and $val_is_good->($new_val)
				and $axis->scaling->is_valid_extremum($new_val)
			) {
				# Change the actual axis value
				$update_inline = 0;
				$axis->$method($new_val) if defined $new_val;
				$update_inline = 1;
				
				# Update the color to notify a good entry value
				$self->backColor(cl::White);
			}
			else {
				$self->backColor(0xffdcdc);
				undef($new_val);
			}
			
		},
	);
	use PDL::NiceSlice;
	
	$auto_button = $group_box->insert(Button =>
		text => 'Autoscale',
		place => { x => 395, y => $y_pos, height => 30, width => 100, anchor => 'sw' },
		height => 30,
		onClick => sub { $axis->$method(lm::Auto) },
	);
	$auto_button->enabled(!$is_auto);
	
	return $notification_idx;
}

sub insert_label_input {
	my ($group_box, $axis) = @_;
	$group_box->insert(Label =>
		place => { x => 45, y => 40, height => 25, width => 60, anchor => 'sw' },
		height => 30,
		text => 'Label:',
	);
	my $label_text = $axis->label || '';
	$group_box->insert(InputLine =>
		text => $label_text,
		place => { x => 110, y => 40, height => 30, width => 380, anchor => 'sw' },
		height => 30,
		onKeyUp => sub {
			my $new_label = shift->text;
			if ($new_label ne $label_text) {
				$label_text = $new_label;
				$axis->label($new_label);
			}
		},
	);
}

sub insert_scaling_radios {
	my ($group_box, $axis) = @_;
	my $update_radios = 1;
	my ($init_min, $init_max) = $axis->minmax;
	my $linear_radio = $group_box->insert(Radio =>
		place => { x => 80, y => 5, height => 30, width => 30, anchor => 'sw' },
		height => 30,
		onCheck => sub {
			return unless $update_radios;
			$update_radios = 0;
			$axis->scaling(sc::Linear);
			$update_radios = 1;
		},
		text => 'Linear Scaling',
		checked => $axis->scaling eq sc::Linear ? 1 : 0,
	);
	
	my $log_radio = $group_box->insert(Radio =>
		place => { x => 275, y => 5, height => 30, width => 30, anchor => 'sw' },
		height => 30,
		onCheck => sub {
			return unless $update_radios;
			$update_radios = 0;
			$axis->scaling(sc::Log);
			$update_radios = 1;
		},
		text => 'Logarithmic Scaling',
		checked => $axis->scaling eq sc::Log ? 1 : 0,
	);
	$log_radio->enabled(0) unless $init_max > 0 && $init_min > 0;
	
	my $bounds_notification = $axis->add_notification(ChangeBounds => sub {
		# Can't go negative if log scaling is enabled, so negative means
		# we must have linear scaling. As such, only enable/disable the
		# log radio based on negative signs, don't change the radios
		my ($min, $max) = $axis->minmax;
		if ($min <= 0 or $max <= 0) {
			$update_radios = 0;
			$log_radio->enabled(0);
			$update_radios = 1;
		}
		else {
			$update_radios = 0;
			$log_radio->enabled(1);
			$update_radios = 1;
		}
	});
	my $scaling_notification = $axis->add_notification(ChangeScaling => sub {
		return unless $update_radios;
		if ($axis->scaling eq sc::Linear) {
			$update_radios = 0;
			$linear_radio->check;
			$update_radios = 1;
		}
		else {
			$update_radios = 0;
			$log_radio->check;
			$update_radios = 1;
		}
	});
	
	return ($bounds_notification, $scaling_notification);
}

# Builds a modal window to set plotting properties
sub set_properties_dialog {
	my $self = shift;
	
	# If one already exists, bring it back to the front
	if (exists $self->{prop_window}) {
		$self->{prop_window}->select;
		$self->{prop_window}->bring_to_front;
		return;
	}
	
	my $total_height = 0;
	$self->{prop_window} = my $prop_win = Prima::Window->new(
		text => 'Plot Properties', width => 500, height => 380,
		visible => 0,
	);
	$prop_win->insert(Widget =>
		pack => { side => 'top', fill => 'x' },
		height => 10,
	);
	
	# Title input
	my $title_box = $prop_win->insert(GroupBox =>
		pack => { side => 'top', fill => 'x', padx => 10 },
		height => 50,
		text => 'Title',
	);
	my $title_text = $self->title || '';
	$title_box->insert(InputLine =>
		text => $title_text,
		place => {
			x => 5, y => 5,
			relwidth => 1,
			width => -10,
			anchor => 'sw',
		},
		onKeyUp => sub {
			my $new_title = shift->text;
			if ($new_title ne $title_text) {
				$title_text = $new_title;
				$self->title($new_title);
			}
		},
	);
	
	my (@x_notifications, @y_notifications);
	
	# x axis input
	$prop_win->insert(Widget =>
		pack => { side => 'top', fill => 'x' },
		height => 10,
	);
	my $x_box = $prop_win->insert(GroupBox =>
		pack => { side => 'top', fill => 'x' },
		height => 160,
		text => 'X Axis',
	);
	push @x_notifications, insert_minmax_input($x_box, 'min', $self->x, 110);
	push @x_notifications, insert_minmax_input($x_box, 'max', $self->x, 75);
	insert_label_input($x_box, $self->x);
	push @x_notifications, insert_scaling_radios($x_box, $self->x);
	
	# y axis input
	$prop_win->insert(Widget =>
		pack => { side => 'top', fill => 'x' },
		height => 10,
	);
	my $y_box = $prop_win->insert(GroupBox =>
		pack => { side => 'top', fill => 'x' },
		height => 160,
		text => 'Y Axis',
	);
	push @y_notifications, insert_minmax_input($y_box, 'min', $self->y, 110);
	push @y_notifications, insert_minmax_input($y_box, 'max', $self->y, 75);
	insert_label_input($y_box, $self->y);
	push @y_notifications, insert_scaling_radios($y_box, $self->y);
	
	# Close button
	$prop_win->insert(Widget =>
		pack => { side => 'top', fill => 'x' },
		height => 10,
	);
	my $close_button = $prop_win->insert(Button =>
		text => 'Close',
		onClick => sub { $prop_win->close },
		pack => { side => 'right' }
	);
	
	$prop_win->height(10 + 50 + 10 + 160 + 10 + 160 + 10 + 30);
	
	$prop_win->onClose(sub {
		$self->x->remove_notification($_) foreach (@x_notifications);
		$self->y->remove_notification($_) foreach (@y_notifications);
		delete $self->{prop_window};
		# Bring the figure back to the foreground
		$self->select;
		$self->bring_to_front;
	});
	
	# Having finished building it, show the window
	$prop_win->visible(1);
}

1;

__END__

=head1 NAME

PDL::Graphics::Prima - an interactive plotting widget and library for PDL and Prima

=head1 SIMPLE SYNOPSIS

 use PDL::Graphics::Prima::Simple;
 use PDL;
 
 
 # --( Super simple line and symbol plots )--
 
 # Generate some data - a sine curve
 my $x = sequence(100) / 20 + 1;
 my $y = sin($x);
 
 # Draw x/y pairs. Default x-value are sequential:
 line_plot($y);        line_plot($x, $y);
 circle_plot($y);      circle_plot($x, $y);
 triangle_plot($y);    triangle_plot($x, $y);
 square_plot($y);      square_plot($x, $y);
 diamond_plot($y);     diamond_plot($x, $y);
 X_plot($y);           X_plot($x, $y);
 cross_plot($y);       cross_plot($x, $y);
 asterisk_plot($y);    asterisk_plot($x, $y);
 
 # Sketch the sine function for x initially from 0 to 10:
 func_plot(0 => 10, \&PDL::sin);
 
 
 # --( Super simple histogram )--
 
 # PDL hist method returns x/y data
 hist_plot($y->hist);
 my ($bin_centers, $heights) = $y->hist;
 hist_plot($bin_centers, $heights);
 # Even simpler, if of limited use:
 hist_plot($heights);
 
 
 # --( Super simple matrix plots )--
 
 # Generate some data - a wavy pattern
 my $image = sin(sequence(100)/10)
             + sin(sequence(100)/20)->transpose;
 
 # Generate a grayscale image:
 matrix_plot($image);  # smallest is white
 imag_plot($image);    # smallest is black
 
 # Set the x and y coordinates for the image boundaries
 #            left, right,  bottom, top
 matrix_plot([ 0,     1  ], [ 0,     2 ],  $image);
 imag_plot(  [ 0,     1  ], [ 0,     2 ],  $image);
 
 
 # --( More complex plots )--
 
 # Use the more general 'plot' function for
 # multiple DataSets and more plotting features:
 my $colors = pal::Rainbow()->apply($x);
 plot(
     -lines       => ds::Pair($x, $y,
         plotType => ppair::Lines
     ),
     -color_squares => ds::Pair($x, $y + 1,
         colors   => $colors,
         plotType => ppair::Squares(filled => 1),
     ),
     
     x => 'Time',
     y => {
         label   => 'Sine',
         scaling => sc::Log,
     },
 );

=head1 WIDGET SYNOPSIS

 use PDL;
 use Prima qw(Application);
 use PDL::Graphics::Prima;
 
 my $t_data = sequence(6) / 0.5 + 1;
 my $y_data = exp($t_data);
 
 my $wDisplay = Prima::MainWindow->create(
     text  => 'Graph Test',
     size  => [300, 300],
 );
 
 $wDisplay->insert('Plot',
     -function => ds::Func(\&PDL::exp, color => cl::Blue),
     -data => ds::Pair($t_data, $y_data, color => cl::Red),
     pack => { fill => 'both', expand => 1},
 );
 
 run Prima;

=head1 IF YOU ARE NEW

If you are new to PDL::Graphics::Prima, you should begin by reading the
documentation for L<PDL::Graphics::Prima::Simple|PDL::Graphics::Prima::Simple/>.
This module provides a simplified interface for quickly dashing off a few
plots and offers stepping stones to create more complex plots. Often, the
simple interface is sufficient for my simple plotting needs. However,
PDL::Graphics::Prima is actually a widget in the L<Prima GUI toolkit|Prima/>.
If you find that you need to interact more directly with your data and its
visualization, you can build stand-alone GUI applications with the necessary
interaction.

The documentation in this file explains how to use PDL::Graphics::Prima as a
plotting widget.

=head1 DESCRIPTION

PDL::Graphics::Prima is a plotting library for 2D data visualization. The
core of this library is a Plot widget that can be incorporated into Prima
applications. The library produces publication quality static figures, but
its true potential lies in using it as a component in a GUI application.
L<Prima> provides an array of useful interactive widgets and a
simple but powerful event-based programming model. PDL::Graphics::Prima
provides a sophisticated plotting library within this GUI framework, letting
you focus on what you want to visualize rather than the details of how you
would draw it. These tools allow you to build interactive data
visualization and analysis applications with sophisticated plotting and
intuitive user interaction in only a few hundred lines of code.

Like any other widget, a Plot widget can be constructed using the parent
widget's L<insert method|Prima::Widget/insert>. PDL::Graphics::Prima
actually defines the bulk of its functionality in the Prima::Plot package,
so that you can simply say:

 $parent->insert(Plot =>
     place => {
         x => 0, relwidth => 0.5, anchor => 'sw',
         y => 0, relheight => 0.5,
     },
     -data => ds::Pair($t_data, $y_data, color => cl::Red),
     ... etc ...
 );

Prima::Plot (i.e. PDL::Graphics::Prima) is a descendant of the
L<Prima::Widget|Prima::Widget/> class, so everything that you can do with
widgets you can do with plots, including specifying L<event|Prima::Widget/Events>
L<callbacks|Prima::Object/Events> such as L<mouse|Prima::Widget/Mouse> and
L<keyboard|Prima::Widget/Keyboard> interaction. You can specify the means
for placing the plot within a larger parent widget using
L<basic geometry management|Prima::Widget/Geometry>, or the Tk-like
L<pack|Prima::Widget::pack/> or L<place|Prima::Widget::place/> specifiers.
In fact, Prima allows any widget to serve as the container for other widgets,
so you can insert other widgets (i.e. other plots) into a plot. This is how
you create figure insets.

If you want to add new content to a plot or remove content from a plot, you
do this by manipulating the L<dataSet collection|/dataSets>. Axis
L<minima|PDL::Graphics::Prima::Axis/"min, max">,
L<maxima|PDL::Graphics::Prima::Axis/"min, max">,
L<scaling|PDL::Graphics::Prima::Axis/scaling>, and
L<labels|PDL::Graphics::Prima::Axis/label> are handled by
L<axis objects|PDL::Graphics::Prima::Axis/> which you obtain through the
L<x and y axis accessors|/"x, y">. You set and manipulate the
title via the L<title accessor method|/title>.

From the standpoint of basic plot object structure, that's about it!

=head1 Properties

PDL::Graphics::Prima has a number of properties that you can specify in the
constructor and later change through accessor methods.

=head2 title

Sets or gets the string with the figure's title text. To remove an already
set title, specify an empty string or the undefined value. Changing this
issues a L<ChangeTitle> event.

=head2 titleFont

Sets or gets a set of key/value pairs that indicate how the title font should
differ from the widget's font. For example, if you want to have your plot title
rendered in Arial but have all other font properties the same, you could say

 $plot->titleFont( name => 'Arial' );

If you later want to set the style to underlined, you could say this:

 $plot->titleFont( $plot->titleFont, style => fs::Underlined );

Notice that I call C<< $plot->titleFont >> as an I<argument> to the method.
This ensures that the font formatting I have already specified (the Arial font
name) is not wiped out with the font update.

In addition to the normal font properties (as discussed in L<the Fonts section
of Prima::Drawable|Prima::Drawable/Fonts>, there are also a couple of important
extensions for sizes that I have implemented explicitly for title fonts. You can
specify dynamic font height, size, and width using strings with special
suffixes. These suffixes include:

 <number>%height
 <number>%width
 <number>x

The C<%height> suffix will compute the height, width, or size to be a percentage
of the widget's height, so if you widget is 100 pixels tall, a height
specification of C<10%height> will cause your font height to be 10 pixels. If
you resize your widget to 200 pixels, the title height will automatically scale
to 20 pixels. The third specification specifies a multiple of the widget's font
value, so a height of C<1.5x> will be 1.5 times higher than the widget's default
font size. This way, if you change the size of the font (and therefore the axis
label and tick label sizes), your title font will automatically adjust, too.

The default titleFont is C<< height => '10%height' >>.

Note that Prima's font system does not allow for arbitrary font sizes, so if you
pick a font size of 18 pixels, it may only be able to find a means for rendering the
font as 19 pixels. But usually, Prima can get pretty close.

=head2 titleSpace

Sets or gets the titleSpace property for the plot widget. You can set the
titleSpace property with an integer, a subref, a string, or a hashref. The
string will be parsed into a hashref, so the return value when you query this
property as a getter is going to be an integer, a subref, or a hashref.

If you specify an integer, that will be the number of pixels used to display
the title. This requres the fewest calculations when rendering, and makes sense
if you set the font's height or size to an explicit value rather than a dynamic
one. But this is also the least adaptable way to specify the titleSpace. You
could use this as

 $plot->titleSpace(50);

On the other extreme, you can specify a subref. The subref should accept the
widget as its sole argument and compute and return the titleSpace dynamically.
For example:

 # Set the titleSpace to be the square root of the widget height
 $plot->titleSpace( sub {
     my $widget = shift;
     return sqrt($widget->height);
 });

In the middle, you can specify a dynamic titleSpace with a string representing
a sum of values with special units. An example of such a string looks like this:

 $plot->titleSpace('5% + 1line - 10pixels')

This would lead to a dynamic height of 5% of the canvas height plus the font
height less 10 pixels. You could also specify this with a hashref of

 $plot->titleSpace({
     canvas_percent => 0.05,
     lines          => 1,
     pixels         => -10,
 });

Notice that negative and positive values are allowed, and it is quite possible
that your dynamic calculation will end up with a net negative value (which is
not allowed if you specify a bare integer number of pixels). So, if your title
is just not visible, it may be because you have a faulty titleSpace
specification.

The default titleSpace is C<1line>.

Note that although string speficifications are parsed only once (into a hashref
representation), these dynamic sizes lead to more calculations than a bare pixel
height or subref. If your goal is to have a title with fast rendering times,
which can be important for animations, you should probably avoid dynamic sizes.

=head2 x, y

Obtains the object that controls the settings for the x- or
y-L<axis|PDL::Graphics::Prima::Axis>. For example:

 # Set the x-min to -10 and the y-max to auto-scaling
 $plot->x->min(-10);
 $plot->y->max(lm::Auto);

Actually, these accessors are not hard-coded into the plot library. Rather,
these are the default L<name|Prima::Object>s of the axes. Any object of
type Prima::Component (which is any object in the Prima object heierarchy)
that has a name can be accessed from the parent by using the component's
name as a method on the parent. That is, you can change the name of the
axis and use the new name:

 # Rename the x-axis; be sure it starts with "x", though
 $plot->x->name('xfoo');
 # Change the x-axis' minimum value
 $plot->xfoo->min(-10);
 # This croaks:
 $plot->x->max(20);

This is a L<feature of Prima|Prima::Object/bring>. Eventually, when multiple
x- and y-axes are allowed, this will allow you to transparently access them by
name just like you can access the single x- and y-axes by name at the moment.

=head2 dataSets

This is the means by which you add new content to your plot (apart from
placing sub-figures in there, of course). This either sets or returns the
L<collection|PDL::Graphics::Prima::DataSet/DataSet::Collection> of
L<DataSet|PDL::Graphics::Prima::DataSet>s. The
L<DataSet|PDL::Graphics::Prima::DataSet>s are held in a tied
anonymous hash that you directly manipulate. In order to add a new
L<DataSet|PDL::Graphics::Prima::DataSet>, you can simply modify the anonymous
hash in place using standard Perl hash manipulation functions and techniques.
For example:

 # Add a new DataSet
 $plot->dataSets->{new_data} = ds::Pair(
     $x, $y, plotType => ppair::Squares
 );
 
 # Remove a DataSet
 delete $plot->dataSets->{model};
 
 # Clear the DataSets
 %{$plot->dataSets} = ();

Since the hash is actually tied, L<DataSet|PDL::Graphics::Prima::DataSet>s
that you add will be validated as you add them.


=head1 METHODS

PDL::Graphics::Prima provides a number of methods. Most of these focuse on
generating images of the plot.

=head2 get_image

Returns a L<Prima::Image> of the plot with same dimensions as the plot widget.

=head2 save_to_postscript

Saves the plot with current axis limits to an encapsulated postscript figure.
This method takes an optional filename argument. If no filename is specified,
it pops-up a dialog box to ask the user where and under what name they want
to save the postscript figure.

This functionality will likely be merged into save_to_file, though this
method will remain for backwards compatibility.

=head2 save_to_file

Saves the plot to a raster image file. This method
takes an optional filename argument, deducing the format (and applicable
codec) from the filename. If no filename is specified, it creates a dialog
box asking the user where and under what name they want to save the file.

=head2 copy_to_clipboard

Copies the plot with current axis limits as a bitmap image to the clipboard.
The resulting clipboard entry is suitable for pasting into applications that
know how to handle bitmap images such as LibreOffice or gpaint on Linux,
Microsoft Office or Windows Paint on Windows.

=head1 Events

You can send notifications and hook callbacks for the following events:

=head2 ChangeTitle

Called when the title or titleSpace gets changed

=head2 Replot

Called when the widget needs to replot "real soon", but not immediately.
Immediate replot requests should go in the form of "Paint" events.
In order to prevent the system from getting bogged down by too many
paint requests, replotting kicks off a timer that issues the paint requests
after a brief period (defaults to 30 milliseconds).

=head2 ChangeData

Called when the dataSet container changes (not the datasets themselves, but
the whole container). 

=head1 DRAWING A PLOT TO AN IMAGE

Most L<methods|PDL::Graphics::Prima/METHODS> that are not properties provide
means for generating images from a plot. Sometimes it is useful to draw a plot
on a pre-formed image. Let's look at the different machanisms for doing this.

For a point of comparison, if you simply want a L<raster image|Prima::Image/>
object from a plot, you should simply obtain it from the plot object with
the L<get_image|PDL::Graphics::Prima/get_image> method:

 my $image = $plot->get_image;

However, what if you already have an L<image object|Prima::Image/> upon which
you want to draw your plot? There are at least two circumstances when you might
want to do this: first if you are creating many raster images from plots and
want to avoid memory re-allocations, and second if you have in image with some
annotations on it already. (Beware the first reason: it is likely a premature
optimization.) To draw the plot on an already-formed image, you can use the
L<draw_image|PDL::Graphics::Prima/draw_image> method like so:

 $some_image->begin_paint;
 $some_image->clear;
 ... other painting here ...
 $plot->draw_image($some_image);
 ... more painting ...
 $some_image->end_paint;

The L<draw_image|PDL::Graphics::Prima/draw_image> method is the preferred way to
draw a plot onto a pre-existing image. It gives you a bit more control on how
the painting is invoked: for example, it does not clear the canvas for you. But
with the increased control comes increased manual manipulation: you need to set
the image in the paint-enabled state before invoking it, and you need to clear
the canvas before getting started.

There is one more means for rendering a plot on an image, which arises if you
are invoking the L<Paint Event|Prima::Widget/Paint> from an arbitrary widget
into a canvas. In that case, you should be able to say this:

 $some_widget->notify('Paint', $some_image);
 # This will set up a notification, which will not proces
 # until the next tick in the event loop. If you need the
 # image to be updated immediately, invoke a tick:
 $::application->yield;

Painting on an image by invoking the L<Paint Event|Prima::Widget/Paint> is
similar to the L<draw_image|PDL::Graphics::Prima/draw_image> method, but it
also ensures that your image is in a paint-enabled state, clears the canvas,
and returns the image in a paint-disabled state if that's how it started.
This is usually what you want and expect when invoking the Paint event on a
canvas.

=head2 Caveat: Fonts

Font handling is one of the areas in PDL::Graphics::Prima that is slated to see
some improvement. Until that happens, you will notice that the font size in your
output image is probably not quite what you expect, and if you change the font
face, that may not match, either. To fix the font issues for now, you can set
your image's font attributes based on the widget's, either at image construction
time:

 $image = Prima::Image->new(
   width => $width,
   height => $height,
   font => $plot->font,
 );

or later with the font setter:

 $image->font($plot->font);

=head1 TODO

This is not a perfect plotting library. Here are some of the particularly
annoying issues with it, which I hope to resolve. This is part warning to
you, gentle reader, and part task list for me.

If Prima had an SVG output, I could easily add it as a figure output option.

I have had it on my list for a while to add the facilities to turn off
drawing operations,
temporarily, so that adding a large number of dataSets can be done more
quickly. This would require some sort of interface such as

 $plot->autoupdate(0);
 ... add datasets ...
 $plot->autoupdate(1);

I have hit substantial performance problems when B<adding> over 20 datasets. 
The actual drawing of those datasets and mouse interation is fine, but the
process of just adding them to the plot can be quite sluggish.

The exact pixel position of the left margin depends on the size of the y-tick
labels, which can change during the process of zooming in or out. This means
mouse scroll-wheel action doesn't work exactly as advertised. Well, it does,
now that I've hedged my advertisement. Still, tracking the previous time of
a scroll wheel click and the previous x/y location could make it work
flawlessly.

There is no way to indicate by-hand where the viewport should be. It is
always calculated from the requirements of the tick labels. There is no way
to control the padding on the right side of the plot, either; it is fixed.
All of these should be tweakable.

Singular names => scalars, plural names => piddles is not consistent across
the board. At least not with all of the plotTypes. This can be fixed by
changing singular keys to plurals and quietly accepting singulars for
backwards compatibility, but it hasn't happened yet.

Multiple axes. In the constructor, any property that starts with x would be an
x-axis (x1, x2, etc). You would have to specify an axes with a dataset, though
the default would be the first axis when sorted asciibetically. Axes would have
properties regarding if they are drawn on the top, the bottom, both, etc, and
whether their tick labels are drawn on the top, bottom, etc.

I am very proud of the automatic scaling. Unfortunately, it's complicated
and not yet well documented. Also, it could be even more awesome. It needs to
allow for negative pixel paddings as well as "extra" pixel padding. This
would simply effect how collate_min_max_for_many works and should be a snap
to implement. For what it's worth, the collation code should probably be
rewritten in C.

Automatic scaling should allow for 'next widest tick' in addition to
the current super-tight bounds that it calculates. This would make hard-copy
figures much, much nicer.

=head1 SEE ALSO

Both the L<Perl Data Language|PDL> and the L<Prima GUI Toolkit|Prima> are
amazing and this module would have no reason for existence without both of them.

This module serves as the motivation for L<PDL::Drawing::Prima>, and also would
be unable to function with any efficiency without it.

Other 2D plotting options include L<PDL::Graphics::PGPLOT>,
L<PDL::Graphics::PLplot>, L<PDL::Graphics::Gnuplot>. There may be a few
others. For my part, I also wrote L<PDL::Graphics::Asymptote>, though it is
more of a toy than these other libraries. Search CPAN for more.

For 3D plotting, see PDL's own L<PDL::Graphics::TriD>, as well as
L<PDL::Graphics::Gnuplot> and the low-level bindings in
L<PDL::Graphics::PLplot>.

=head1 AUTHOR

David Mertens (dcmertens.perl@gmail.com)

=head1 ADDITIONAL MODULES

Here is the full list of modules in this distribution:

=over

=item L<PDL::Graphics::Prima|PDL::Graphics::Prima/>

Defines the Plot widget for use in Prima applications

=item L<PDL::Graphics::Prima::Axis|PDL::Graphics::Prima::Axis/>

Specifies the behavior of axes (but not the scaling)

=item L<PDL::Graphics::Prima::DataSet|PDL::Graphics::Prima::DataSet/>

Specifies the behavior of DataSets

=item L<PDL::Graphics::Prima::Limits|PDL::Graphics::Prima::Limits/>

Defines the lm:: namespace

=item L<PDL::Graphics::Prima::Palette|PDL::Graphics::Prima::Palette/>

Specifies a collection of different color palettes

=item L<PDL::Graphics::Prima::PlotType|PDL::Graphics::Prima::PlotType/>

Defines the different ways to visualize your data

=item L<PDL::Graphics::Prima::ReadLine|PDL::Graphics::Prima::ReadLine/>

Encapsulates all interaction with the L<Term::ReadLine> family of
modules.

=item L<PDL::Graphics::Prima::Scaling|PDL::Graphics::Prima::Scaling/>

Specifies different kinds of scaling, including linear and logarithmic

=item L<PDL::Graphics::Prima::Simple|PDL::Graphics::Prima::Simple/>

Defines a number of useful functions for generating simple and not-so-simple
plots

=back

=head1 LICENSE AND COPYRIGHT

Unless otherwise stated, all contributions in code and documentation are
copyright (c) their respective authors, all rights reserved.

Portions of this module's code are copyright (c) 2011 The Board of
Trustees at the University of Illinois.

Portions of this module's code are copyright (c) 2011-2013 Northwestern
University.

Portions of this module's code are copyright (c) 2013-2014 Dickinson
College.

This module's documentation is copyright (c) 2011-2014 David Mertens.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
