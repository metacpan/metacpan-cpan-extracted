package SVG::DOM2::Attribute::Path;

use base "XML::DOM2::Attribute";

use strict;
use warnings;
use Carp;

my %imap = (
		m => [qw/x y/],              # move to
		z => [],                     # close path
		l => [qw/x y/],              # line to
		h => ['x'],                  # horz line
		v => ['y'],                  # vert line
		c => [qw/x1 y1 x2 y2 x y/],  # Curveto Cubic Bezier
		s => [qw/x1 y1 x y/],        # Smooth Cubic Bezier
		q => [qw/x1 y1 x y/],        # Curceto Quadratic Bézier
		t => [qw/x y/],              # Smooth Quadratic Bézier
		a => [qw/rx ry xr l s x y/], # Eliptical Arc Curve
);

sub new
{
	my ($proto, %opts) = @_;
	return $proto->SUPER::new(%opts);
}

sub serialise
{
	my ($self) = @_;

	my $lastmode = '';
	my $result = '';
	foreach my $inst ($self->instructions) {
		my %inst = %{$inst};
		$result .= ' ' if length($result);
		my $rel = $inst{'rel'};
		my $mode = $inst{'mode'};
		my @c = @inst{@{$imap{$mode}}};
		$mode = uc($mode) if not $rel;
		$result .= $mode.' ' if $mode ne $lastmode;
		$result .= join(' ', @c) if @c;
		$lastmode = $mode;
	}
	$result =~ s/\s+$//;
	return $result;
}

sub deserialise
{
	my ($self, $path) = @_;

	$path =~ s/(\+|-)/ $1/g;
	$path =~ s/([MmZzLlHhVvCcSsQqTtAa])/ $1 /g;
	$path =~ s/,/ /g;
	$path =~ s/^\s+//;
	$path =~ s/\s+$//;

	my @path = split(/\s+/, $path);
	my @inst;
	my $mode;
	for(my $i = 0; $i <= $#path; $i++) {
		my $s = $path[$i];
		next if not defined($s);
		if(defined($imap{lc($s)})) {
			$mode = $s;
			if(not @{$imap{lc($mode)}}) {
				# Make sure blind instructions are added
				push @inst, _instruction($mode);
			} else {
				next;
			}
		} elsif($s =~ /^\-*\d+\.*\d*$/) {
			# Data for current mode
			my $length = @{$imap{lc($mode)}};
			my $end = $i + $length;
			# Next i if no co-ords to gather
			next if not $end;
			# Add the instruction
			push @inst, _instruction($mode, @path[$i..$end]);
			# Inplicit lineto after moveto
			$mode = 'l' if($mode eq 'm');
			$mode = 'L' if($mode eq 'M');
			$i += $length - 1;
		} else {
			die "Error in path, unexpected instruction '$s' - ".join(', ', keys(%imap))."\n";
		}
	}
	$self->{'path'} = \@inst;
	return $self;
}

sub _instruction
{
    my ($mode, @c) = @_;
    my $reletive = ($mode =~ /A-Z/) ? 1 : 0;
    $mode = lc($mode);
    my %inst = ( mode => $mode, rel => $reletive );
    @inst{@{$imap{$mode}}} = @c if @c;
    return \%inst;
}

sub instructions
{
	my ($self) = @_;
	return @{$self->{'path'}};
}

return 1;
