package Syntax::Kamelon::Format::Base;

use strict;
use warnings;
use Carp;

use vars qw($VERSION);
$VERSION="0.15";
use base qw(Template);

my $default_template = <<__EOF;
[% IF lineoffset.defined ~%]
	[% linenum = lineoffset ~%]
	[% FOREACH line = content ~%]
		[% linenum  FILTER format('%03d ') ~%]
		[% FOREACH snippet = line ~%]
			[% snippet.tag %][% snippet.text %][% tagend ~%]
		[% END %][% newline ~%]
		[% linenum = linenum + 1 ~%]
	[% END ~%]
[% ELSE ~%]
	[% FOREACH line = content ~%]
		[% FOREACH snippet = line ~%]
			[% snippet.tag %][% snippet.text %][% tagend ~%]
		[% END %][% newline ~%]
	[% END ~%]
[% END ~%]
__EOF

sub new {
   my $class = shift;
   my $engine = shift;
	my %args = (@_);

	my $data = delete $args{data};
	unless (defined $data) { $data = {} }

	my $foldingdepth = delete $args{foldingdepth};
	unless (defined $foldingdepth) { $foldingdepth = 0 }

	my $formattable = delete $args{format_table};
 	unless (defined($formattable)) { 
		my %sub = ();
		for ($engine->AvailableAttributes) {
			$sub{$_} = $_,
		}
		$formattable = \%sub
	}

	my $minfoldsize = delete $args{minfoldsize};
	unless (defined($minfoldsize)) { $minfoldsize = 1 }

	my $newline = delete $args{newline};
	unless (defined($newline)) { $newline = "\n" }

	my $offset = delete $args{lineoffset};

	my $outmet = delete $args{outmethod};
	unless (defined $outmet) { $outmet = "returnscalar" }

	my $tagend = delete $args{tagend};
	unless (defined $tagend) { $tagend = '' }

	my $template = delete $args{template};
	unless (defined $template) { $template = \$default_template }

	my $textfilter = delete $args{textfilter};

	my $ttconfig = delete $args{ttconfig};
	
	if (%args) {
		for (keys %args) {
			warn "unrecognized option: $_"
		}
	}
	my $self;
	if (defined $ttconfig) {
		$self= $class->SUPER::new($ttconfig)
	} else {
		$self= $class->SUPER::new()
	}

	$self->{DATA} = $data;
	$self->{ENGINE} = $engine;
	$self->{FOLDINGDEPTH} = $foldingdepth;
	$self->{LINES} = [];
	$self->{FOLDS} = {};
	$self->{FOLDSTACK} = [];
	$self->{FORMATTABLE} = $formattable;
	$self->{LINEOFFSET} = $offset;
	$self->{MINFOLDSIZE} = $minfoldsize;
	$self->{NEWLINE} = $newline;
	$self->{OUTMETHOD} = $outmet;
	$self->{TAGEND} = $tagend;
	$self->{TEMPLATE} = $template;
	$self->TextFilter($textfilter);

   return $self;
}

sub Data {
	my $self = shift;
	if (@_) { $self->{DATA} = shift }
	return $self->{DATA}
}

sub FindINC {
   my ($self, $file) = @_;
   for (@INC) {
      my $f = $_ . "/$file";
      if (-e $f) {
         return $f;
      }
   }
   return undef;
}

sub FoldBegin {
	my ($self, $region) = @_;
	my $eng = $self->{ENGINE};
	chomp(my $line = $eng->CurrentLine);
	my %op = (
		start => $eng->LineNumber, 
		region => $region, 
		line => $line
	);
	$self->FoldStackPush(\%op);
}

sub FoldEnd {
	my ($self, $region) = @_;
	my $eng = $self->{ENGINE};
	my $endline = $eng->LineNumber;
	my $stacktop = $self->FoldStackTop;
	my $foldingdepth = $self->{FOLDINGDEPTH};
	if (($foldingdepth eq 'all') or ($self->FoldStackLevel <= $foldingdepth)) {
		if (($endline - $stacktop->{start}) >= $self->{MINFOLDSIZE}) {
			my $beginline = delete $stacktop->{start};
			$stacktop->{end} = $endline;
			$stacktop->{depth} = $self->FoldStackLevel;
			$self->{FOLDS}->{$beginline} = $stacktop;
		}
	}
	$self->FoldStackPull;
}

sub Folds {
	my $self = shift;
	return $self->{FOLDS};
}

sub Foldingdepth {
	my $self = shift;
	if (@_) {
		my $f = shift;
		my $cf = $self->{FOLDINGDEPTH};
		if (($f ne $cf) and (($f eq 0) or ($cf eq 0))){
			$self->{FOLDINGDEPTH} = $f;
			$self->{ENGINE}->ClearLexers;
		}
	}
	return $self->{FOLDINGDEPTH};
}

sub FoldStackLevel {
	my $self = shift;
	my $stack = $self->{FOLDSTACK};
	my $size = @$stack;
	return $size
}

sub FoldStackPull {
	my $self = shift;
	my $stack = $self->{FOLDSTACK};
	return shift @$stack
}

sub FoldStackPush {
	my $self = shift;
	my $stack = $self->{FOLDSTACK};
	unshift @$stack, shift;
}

sub FoldStackTop {
	my $self = shift;
	my $stack = $self->{FOLDSTACK};
	return $stack->[0]
}

sub Format {
	my $self = shift;
	my $out = '';
	my $outmet = $self->{OUTMETHOD};
	if ($outmet eq 'returnscalar') {
		$outmet = \$out
	}
	my $template = $self->{TEMPLATE};
	$self->process($template, $self->GetData, $outmet)  || do {
		my $error = $self->error();
		print STDERR "error type: ", $error->type(), "\n";
		print STDERR "error info: ", $error->info(), "\n";
		print STDERR $error, "\n";
	};
	return $out
}

sub FormatTable {
	my $self = shift;
	my $key = shift;
	if (defined $key) {
		my $t = $self->{FORMATTABLE};
		if (@_) { $t->{$key} = shift; }
		if (exists $t->{$key}) {
			return $t->{$key};
		}
	}
	return undef
}

sub GetData {
	my $self = shift;
	my $dt = $self->{DATA};
	my %data = (%$dt,
		folds => $self->{FOLDS},
		content => $self->{LINES},
		lineoffset => $self->{LINEOFFSET},
		newline => $self->{NEWLINE},
		tagend => $self->{TAGEND},
	);
	return \%data;
}

sub LineOffset {
	my $self = shift;
	if (@_) { $self->{LINEOFFSET} = shift }
	return $self->{LINEOFFSET}
}

sub Lines {
	my $self = shift;
	return $self->{LINES}
}

sub MinFoldSize {
	my $self = shift;
	if (@_) { $self->{MINFOLDSIZE} = shift }
	return $self->{MINFOLDSIZE}
}

sub OutMethod {
	my $self = shift;
	if (@_) { $self->{OUTMETHOD} = shift }
	return $self->{OUTMETHOD}
}

sub Parse {
	my $self = shift;
	my @line = ();
	while (@_) {
		my $text = shift;
		my $call = $self->{PREPROCESSOR};
		$text = &$call($self, $text);
		my %tok = (
			text => $text,
			tag => shift,
		);
		push @line, \%tok
	}
	my $fl = $self->{LINES};
	push @$fl, \@line
}

sub PreProcessOff {
	my ($self, $text) = @_;
	return $text
}

sub PreProcessOn {
	my ($self, $text) = @_;
	return $self->Process($self->{TEXTFILTER}, { text => $text })
}

sub Process {
	my ($self, $template, $data) = @_;
	my $out = '';
	$self->process($template, $data, \$out)  || do {
		my $error = $self->error();
		print STDERR "error type: ", $error->type(), "\n";
		print STDERR "error info: ", $error->info(), "\n";
		print STDERR $error, "\n";
	};
	return $out
}

sub Reset {
	my $self = shift;
	$self->{FOLDS} = {};
	$self->{FOLDSTACK} = [];
	$self->{LINES} = [];
}

sub TagEnd {
	my $self = shift;
	if (@_) { $self->{TAGEND} = shift }
	return $self->{TAGEND}
}

sub Template {
	my $self = shift;
	if (@_) { $self->{TEMPLATE} = shift }
	return $self->{TEMPLATE}
}

sub TextFilter {
	my $self = shift;
	if (@_) {
		my $filt = shift;
		if (defined $filt) {
			$self->{PREPROCESSOR} = $self->can('PreProcessOn')
		} else {
			$self->{PREPROCESSOR} = $self->can('PreProcessOff')
		}
		$self->{TEXTFILTER} = $filt
	}
	return $self->{TEXTFILTER}
}

1;
__END__
