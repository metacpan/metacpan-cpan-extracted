package QWizard::Generator;

use AutoLoader;
use POSIX qw(isprint);
use strict;
our $VERSION = '3.15';
use QWizard::Storage::Memory;
require Exporter;
use File::Temp qw(tempfile);
use IO::File;

@QWizard::Generator::ISA = qw(Exporter);
@QWizard::Generator::EXPORT = qw(qwdebug qwpref);

our $AUTOLOAD;

# just a base class.
#
# functions to implement:
#  radio

# default do-nothing subroutines.  These are optional in sub-generators.
sub do_question_end {}
sub start_questions {}
sub end_questions {}
sub do_pass {};

sub new {
    die "should not be called directly\n";
}

sub init_default_storage {
    my $self = shift;
    $self->{'datastore'} = new QWizard::Storage::Memory();
    $self->{'prefstore'} = new QWizard::Storage::Memory();
    $self->{'tmpdir'} = "/tmp" if (!$self->{'tmpdir'});
}

# widgets that have fallbacks to more minimal widgets:
sub do_textbox {
    my $self = shift;
    $self->do_entry(@_);
}

sub do_paragraph {
    my $self = shift;
    $self->do_label(@_);
}

our $have_gd_graph = eval { require GD::Graph::lines; };
our $have_chart_graph = eval { require Chart::Lines; };

our $def_width = 400;
our $def_height = 400;

#
# returns a quantized X dataset from a sorted but non-linear x dataset
#
# INPUT points:
#   [[X1, Y1],[X2, Y2]]
# OUTPUT quantized WIDTH number of buckets:
#   [[min(X1), Y1], [min(X1)+(maxx-minx)/WIDTH, YJ]]
#
sub binize_x_data {
    my ($self, $multidata, $q, $width) = @_;
    my ($minx, $maxx);

    my ($newdata, $x, $xlab);

    if (!$q->{'multidata'}) {
	$multidata = [$multidata];
    }

    #  calculates min and max X values from the datasets
    foreach my $data (@$multidata) {
	if (!defined($minx) || $minx > $data->[0][0]) {
	    $minx = $data->[0][0];
	}
	if (!defined($maxx) || $maxx < $data->[$#$data][0]) {
	    $maxx = $data->[$#$data][0];
	}
    }
    my $diff = $maxx - $minx;
    if ($diff == 0) {
	print STDERR "no data to graph (time diff = 0)!\n";
	print STDERR "minx: $minx, maxx: $maxx\n";
	return [[]];
    }
    my $addative = 0;
    foreach my $data (@$multidata) {
	my $numc = $#{$data->[0]};
	foreach my $d (@$data) {
	    my $xval = int($width * (($d->[0] - $minx) / $diff));
	    if (!exists($newdata->[0][$xval])) {
		 $newdata->[0][$xval] = $d->[0];
	    }
	    for ($x = 1; $x <= $numc; $x++) {
		$newdata->[$x + $addative][$xval] = $d->[$x];
	    }
	}
	if (!$addative) {
	    # first row contained the indexes
	    $addative = -1;
	}
	$addative += $numc+1;
    }

    for (my $i = 0; $i <= $#$newdata; $i++) {
	for ($x = 1; $x <= $#{$newdata->[$i]}; $x++) {
	    if (!exists($newdata->[$i][$x])) {
		$newdata->[$i][$x] = $newdata->[$i][$x-1];
	    }
	}
    }

    return $newdata;
}

sub do_graph_data {
    my ($self, $q, $wiz, $p, $data, $gopts) = @_;
    my ($w, $h) = ($def_width, $def_height);
    my @gopts = (
		 bgclr => 'white',
		 transparent => 0,
		 brush_size => 3,
		 max_x_ticks => 10,
		);
    push @gopts, @$gopts if ($gopts);
    my %gopts = @gopts;
    $gopts = \@gopts;
    $w = $gopts{'-width'} if (exists($gopts{'-width'}));
    $h = $gopts{'-height'} if (exists($gopts{'-height'}));

    return if (!$have_chart_graph || !$have_gd_graph);

    $data = $self->binize_x_data($data, $q, $w) if (!$q->{'already_in_bins'});

    if ($have_chart_graph && !$q->{'use_gd_graph'}) {

	my $charttype = "Lines";
	$charttype = $gopts{'-charttype'} if (exists($gopts{'-charttype'}));

	# create the graph
	my $gph = eval("require Chart::$charttype;  return Chart::" . $charttype . '->new($w, $h);');

	# change various plotting conventions from GD::Graph to Chart::Lines
	my %converts =
	  qw(
	     legend            legend_labels
	     x_number_format   f_x_tick
	     y_number_format   f_y_tick
	    );

	foreach my $k (keys(%converts)) {
	    if (exists($gopts{$k})) {
		push @gopts, $converts{$k} => $gopts{$k};
	    }
	}
	# XXX: hack to get around a collision
	push @gopts, 'legend', 'right';

	# XXX: forced options
	push @gopts, skip_x_ticks => ($w/6);

	# set the options to the passed list
	$gph->set(@$gopts) if (defined($gopts));

	# plot everything to a file
	my %hg = %gopts;
	my ($fh, $fname) = $self->create_temp_fh(".png");
	$gph->png($fh, $data);
	
	
	# Ugh...  we should be able to return either data or a file
	# XXX: the sad thing is that later this is probably put into a file
	$fh = new IO::File;
	$fh->open("<$fname");
	my ($fdata, $outdata);
	while ($fh->read($fdata, 512)) {
	    $outdata .= $fdata;
	}
	
	return $outdata;
    }

    if ($have_gd_graph) {
	my $gph = GD::Graph::lines->new($w, $h);
	$gph->set(@$gopts) if (defined($gopts));
	my %hg = %gopts;
	$gph->set_legend(@{$hg{'legend'}}) if (exists($hg{'legend'}));

	my $plot = $gph->plot($data);
	if (!$plot) {
	    print STDERR "plot: " . $gph->error . "\n";
	    return;
	}
	
	return $plot->png ||
	  print STDERR "do_graph_data error: $gph->error\n";
    }
}

# Default storage = variable space

sub qwparam {
    my $self = shift;
    return $self->{'datastore'}->access(@_);
}

sub backup_params {
    my $self = shift;
    if ($#{$self->{'backupvars'}} > ($self->{'maxbackups'} || 10)) {
	pop @{$self->{'backupvars'}};
    }
    unshift @{$self->{'backupvars'}}, {%{$self->{'datastore'}->get_all}};
}

sub revert_params {
    my $self = shift;
    shift @{$self->{'backupvars'}};
    if ($#{$self->{'backupvars'}} > -1) {
	$self->{'datastore'}->set_all(shift @{$self->{'backupvars'}});
    } else {
	$self->{'datastore'}->set_all({});

    }
}

#
# called by QWizard::pass_vars() to determine if we not be passing on
# particular variables.
#
sub skip_storage {
    my ($self, $skiptok) = @_;
    if (exists($self->{'delete_tokens'}) &&
	exists($self->{'delete_tokens'}{$skiptok})) {
	delete $self->{'delete_tokens'}{$skiptok};
	return 1;
    }
    return 0;
}

#
# potentially called by post_answers primary code to forget about a
# particular variable and not pass it on to forward screens.
#
sub forget_param {
    my $self = shift;
    map { $self->{'datastore'}->set($_,'');
	  $self->{'delete_tokens'}{$_} = 1
      } @_;
}

sub do_hidden {
    my ($self, $wiz, $name, $val) = @_;
    $self->{'datastore'}->set($name, $val);
}

sub clear_params {
    my $self = shift;
    $self->{'datastore'}->reset();
    @{$self->{'backupvars'}} = ();
}

sub get_handler {
    my ($self, $type, $q) = @_;
    use Data::Dumper;
    if (exists($self->{'typemap'}{$type})) {
	return $self->{'typemap'}{$type};
    }
}

sub add_handler {
    my ($self, $type, $fn, $argdef) = @_;
    $self->{'typemap'}{$type}{'function'} = $fn;
    $self->{'typemap'}{$type}{'argdef'} = $argdef;
}

sub get_supported_tags {
    my ($self) = @_;
    return keys(%{$self->{'typemap'}});
}

sub print_handler_tags {
    my ($self, $tokformat, $nameformat, $endtext) = @_;
    $tokformat = "  %-20s %-10s\n" if (!$tokformat);
    $nameformat = "%s arguments:\n" if (!$nameformat);
    foreach my $t (sort keys(%{$self->{'typemap'}})) {
	printf($nameformat, $t);
	foreach my $arg (@{$self->{'typemap'}{$t}{'argdef'}}) {
	    next if ($arg->[0] eq 'forced');
	    my @tagargs = @$arg;
	    if ($#tagargs == 0) {
		push @tagargs, "single";
	    } else {
		my $swapit = $tagargs[0];
		$tagargs[0] = $tagargs[1];
		$tagargs[1] = $swapit;
	    }
	    printf($tokformat, @tagargs);
	}
	print $endtext if ($endtext);
    }
}

#
# argdef format:  
# [
#   [ TYPE, NAMEorSPECIAL, DEFAULT],
#   ...
# ]
sub get_arguments {
    my ($self, $wiz, $q, $argdef, $default) = @_;
    my @args;
    for (my $i = 0; $i <= $#$argdef; $i++) {
	if (ref($argdef->[$i]) ne 'ARRAY') {
	    print STDERR "malformed argument definition: $argdef->[$i]\n";
	    push @args, undef;
	    next;
	}
	my $def = $argdef->[$i];
	if ($def->[0] eq 'default') {
	    push @args, $default;
	} elsif ($def->[0] eq 'forced') {
	    push @args, $def->[1];
	} elsif ($def->[0] eq 'values,labels') {
	    push @args, $wiz->get_values_and_labels($q, $def->[1])
	} elsif ($def->[0] eq 'multi') {
	    if (exists($q->{$def->[1]})) {
		push @args, $wiz->get_values($q->{$def->[1]});
	    } else {
		push @args, $def->[2];
	    }
	} elsif ($def->[0] eq 'single') {
	    if (exists($q->{$def->[1]})) {
		push @args, $wiz->get_value($q->{$def->[1]});
	    } else {
		push @args, $def->[2];
	    }
	} elsif ($def->[0] eq 'norecurse') {
	    if (exists($q->{$def->[1]})) {
		push @args, $wiz->get_value($q->{$def->[1]}, 1);
	    } else {
		push @args, $def->[2];
	    }
	} elsif ($def->[0] eq 'norecursemulti') {
	    if (exists($q->{$def->[1]})) {
		push @args, $wiz->get_values($q->{$def->[1]}, 1);
	    } else {
		push @args, $def->[2];
	    }
	} elsif ($def->[0] eq 'labels') {
	    if (exists($q->{$def->[1]})) {
		push @args, $wiz->get_labels($q);
	    } else {
		push @args, $def->[2];
	    }
	} elsif ($def->[0] eq 'noexpand') {
	    if (exists($q->{$def->[1]})) {
		push @args, $q->{$def->[1]};
	    } else {
		push @args, $def->[2];
	    }
	} else {
	    print STDERR "unknown argument type: $def->[0]\n";
	}
    }
    return \@args;
}

# preferences

sub qwpref {
    my $self = shift;
    return $self->{'prefstore'}->access(@_);
}

# file uploads

sub qw_upload_fh {
    my ($self) = shift;
    my ($it);
    my $ret;
    if (ref($self) =~ /QWizard/) {
	$it = shift;
    } else {
	$it = $self;
    }

    my $fh = new IO::File();
    $fh->open("<" . $self->qwparam($it));

    return $fh;
}

# this is overriden by the HTML handler to return a pointer to a temp file 
sub qw_upload_file {
    my ($self) = shift;
    my ($it);
    my $ret;
    if (ref($self) =~ /QWizard/) {
	$it = shift;
    } else {
	$it = $self;
    }

    return $self->qwparam($it);
}

######################################################################
## convenience functions

sub make_displayable {
    my ($self, $str);
    if ($#_ > 0) {
	($self, $str) = @_;
    } else {
	($str) = @_;
    }

    if (defined($str) && $str ne '' && !isprint($str)) {
	$str = "0x" . (unpack("H*", $str))[0];
    }
    return $str;
}

######################################################################
## temporary file handling

sub create_temp_fh {
    my ($self, $sfx) = @_;
    mkdir($self->{'tmpdir'}) if (! -d $self->{'tmpdir'});
    my ($fh, $filename) = tempfile("qwHTMLXXXXXX", SUFFIX => $sfx,
				   DIR => $self->{'tmpdir'} || "/tmp/");
    return ($fh, $filename);
}


## temporary file creation if needed by child classes
sub create_temp_file {
    my ($self, $sfx, $data) = @_;

    my ($fh, $filename) = $self->create_temp_fh($sfx);

    if (ref($data) eq 'IO::File' || ref($data) eq 'Fh') {
	while (<$data>) {
	    print $fh $_;
	}
    } else {
	print $fh $data;
    }
    $fh->close();

    return $filename;
}

######################################################################
# image path handling
#

sub find_image_path {
    my ($self, $file) = @_;

    # return it if it's already a fullyqualified path
    # XXX: win32 issues
    return if (!defined($file));
    return $file if ($file eq '' || $file =~ /^\//);

    # get a path list
    my $paths = $self->{'imgpaths'};
    $paths = [$paths] if (ref($paths) ne 'ARRAY');

    # search the paths till we get a hit.
    foreach my $path (@$paths) {
	if (-f "$path/$file") {
	    return "$path/$file";
	}
    }

    return;
}

######################################################################
# accelerator base functions
#

# removes at least the first _ from the label
sub remove_accelerator {
    my $text = shift;
    $text =~ s/_//;
    return $text;
}

# erases memory of auto_accelerators already used
sub initialize_auto_accelerator {
    my $self = shift;

    $self->{'auto_accelerators'} = 
      # reserved set
      {
       N => 1,          # Next
       B => 1,          # Back
       R => 1,          # Refresh
      };
}

# Adds in an accelerator to a app if it doesn't exist
sub add_accelerator {
    my ($self, $text) = @_;
    return $text if ($self->{'no_auto_accelerators'});
    return $text if ($text =~ s/^!//); # reserve ! as a don't-accelerate this
    my $accelmap = $self->{'auto_accelerators'};
    return $text if ($text =~ /(_)/ && exists($accelmap->{$1}));
    my @lets = split(//,$text);
    for (my $i = 0; $i <= $#lets; $i++) {
	if ($lets[$i] =~ /[a-zA-Z]/ && !exists($accelmap->{lc($lets[$i])})) {
	    $accelmap->{lc($lets[$i])} = 1;
	    $lets[$i] = '_' . $lets[$i];
	    return join("",@lets);
	}
    }
    return $text;
}





## dummy functions for overriding if needed by child classes

# called once in the very beginning
sub start_primaries {}
# called once at the very end
sub end_primaries {}
# called once before first primary
sub do_top_bar {}
# called once before first primary
sub do_left_side {}
# called once after last primary
sub do_right_side {}
# called once per primary per screen:
sub start_main_section {}
# called once per primary per screen:
sub end_main_section {}
# called once before first primary on screen:
sub start_center_section {}
# called once after last primary on screen:
sub end_center_section {}
# called once after qwizard is completely finished; should remove windows, etc.
sub finished {}
# called to display a progress window
sub set_progress {}


## All other missing functions are errors

sub AUTOLOAD {
    my $sub = $AUTOLOAD;
    my $mod = $AUTOLOAD;
    $mod =~ s/::[^:]*$//;
    $sub =~ s/.*:://;

    die "FATAL PROBLEM: Your widget generator \"$mod\" doesn't support the \"$sub\" function";
}

1;
__END__
