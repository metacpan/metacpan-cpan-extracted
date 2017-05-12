package String::Markov;

# ABSTRACT: A Moo-based, text-oriented Markov Chain module

our $VERSION = 0.009;

use 5.010;
use Moo;
use namespace::autoclean;

use Unicode::Normalize qw(normalize);
use List::Util qw(sum);

has normalize => (is => 'rw', default => sub { 'C' });
has do_chomp  => (is => 'rw', default => sub { 1 });
has null      => (is => 'ro', default => sub { "\0" });
has stable    => (is => 'ro', default => sub { 1 });
has order     => (is => 'ro', isa => sub {
	die "Need an integer greater than zero" if !$_[0] || $_[0] =~ /\D/;
}, default => sub { 2 });

has ['split_sep','join_sep'] => (
	is => 'rw',
	default => sub { undef }
);

has ['transition_count','row_sum'] => (
	is => 'ro',
	isa => sub { die "Need a hash ref" if ref $_[0] ne 'HASH'; },
	default => sub { {} }
);

around BUILDARGS => sub {
	my ($orig, $class, @arg) = @_;
	my %ahash;

	%ahash = @arg == 1 ? %{$arg[0]} : @arg;

	my $sep = delete $ahash{sep} // '';
	die "ERR: sep argument must be scalar; did you mean to set split_sep instead?" if ref $sep;
	$ahash{split_sep} //= $sep;
	$ahash{join_sep}  //= $sep;

	return $class->$orig(\%ahash);
};

sub join_prob {
	my ($self, $orig_prob) = @_;
	my %p;

	@p{@{$orig_prob->[0]}} = @{$orig_prob->[1]};

	return \%p;
}

sub split_prob {
	my ($self, $orig_prob) = @_;

	if ($self->stable) {
		my @k = sort keys %$orig_prob;
		return [
			\@k,
			[@{$orig_prob}{@k}],
		];
	} else {
		return [
			[keys %$orig_prob],
			[values %$orig_prob],
		];
	}
}

sub split_all_prob {
	my $self = shift;
	my $tc = $self->transition_count;
	my $nt = {};

	while (my ($state, $prob) = each %$tc) {
		$nt->{$state} = $self->split_prob($prob);
	}

	%$tc = %$nt;
}

sub split_line {
	my ($self, $sample) = @_;
	if (my $norm = $self->normalize) {
		$sample = normalize($norm, $sample);
	}
	return split($self->split_sep, $sample);
}

sub add_sample {
	my ($self, $sample) = @_;
	my $n     = $self->order;
	my $null  = $self->null;

	my $sref  = ref $sample;
	my @nms = ($null,) x $n;

	if ($sref eq 'ARRAY') {
		push @nms, @$sample;
	} elsif (!$sref) {
		die 'ERR: missing split separator,' if !defined $self->split_sep;
		push @nms, $self->split_line($sample);
	} else {
		die "ERR: bad sample type $sref";
	}

	push @nms, $null;

	my $sep   = $self->join_sep // '';
	my $count = $self->transition_count;
	my $sum   = $self->row_sum;
	for my $i (0 .. ($#nms - $n)) {
		my $cur = join($sep, @nms[$i .. ($i + $n - 1)]);
		my $nxt = $nms[$i + $n];
		my $prob = $count->{$cur};
		if ($prob && ref $prob ne 'HASH') {
			$count->{$cur} = $self->join_prob($prob);
		}
		++$count->{$cur}{$nxt};
		++$sum->{$cur};
	}

	return $self;
}

sub add_files {
	my ($self, @files) = @_;
	my $do_chomp = $self->do_chomp;

	local @ARGV = @files;
	while(my $sample = <>) {
		chomp $sample if $do_chomp;
		$self->add_sample($sample);
	}

	$self->split_all_prob();

	return $self;
}

sub sample_next_state {
	my ($self, @cur_state) = @_;
	die "ERR: wrong amount of state" if @cur_state != $self->order;

	my $count = $self->transition_count;
	my $sum   = $self->row_sum;

	my $cur = join($self->join_sep // '', @cur_state);
	my $thresh = $sum->{$cur};
	return undef if !$thresh;

	$thresh *= rand();

	my $prob = $count->{$cur};
	if (ref $prob ne 'ARRAY') {
		$prob = $self->split_prob($prob);
		$count->{$cur} = $prob;
	}

	my $s = 0;
	my $i = 0;
	my ($k, $v) = @{$prob};
	do {
		$s += $v->[$i];
	} while ($thresh > $s && ++$i);
	return $k->[$i];
}

sub generate_sample {
	my ($self) = @_;

	my $null = $self->null;
	my $n  = $self->order;
	my $sep = $self->join_sep // '';
	my @nm = ($null,) x $n;

	do {
		push @nm, $self->sample_next_state(@nm[-$n .. -1]);
	} while ($nm[-1] ne $null);

	@nm = @nm[$n .. ($#nm-1)];

	return wantarray ?
		@nm :
		defined $self->join_sep ?
			join($sep, @nm) :
			\@nm;

}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

String::Markov - A Moo-based, text-oriented Markov Chain module

=head1 VERSION

version 0.009

=head1 SYNOPSIS

  my $mc = String::Markov->new();

  $mc->add_files(@ARGV);

  print $mc->generate_sample . "\n" for (1..20);


  my $mc = String::Markov->new(order => 1, sep => ' ');

  for my $stanza (@The_Rime_of_the_Ancient_Mariner) {
  	$mc->add_sample($stanza);
  }
  
  print $mc->generate_sample;

=head1 DESCRIPTION

String::Markov is a Moo-based Markov Chain module, designed to easily consume
and produce text.

=head1 ATTRIBUTES

=head2 order

The order of the chain, i.e. how much past state is used to determine the next
state. The default of 2 is reasonable for constructing new names/words when
splitting into characters, or for long-ish works when splitting into words.

=head2 split_sep

How states are split. This value (or I<sep>; see L</new()>) is passed directly
as the first argument to L<perlfunc/split>, so using C<' '> has special
semantics.  Regular expressions will work as well, but be aware that any
matched characters are discarded.

=head2 join_sep

How states are joined. This value (or I<sep>; see L</new()>) is passed as the
first argument of L<perlfunc/join>. In addition, it is used to build keys for
internal hashes. This can cause problems in cases where split_sep() produces
sequences like C<'ae', 'io'>, C<'a', 'ei', 'o'>, or C<'ae', 'i', 'o'>, which
will all turn into C<'aeio'> with the default of C<''>. If I<join_sep> is
C<'*'> instead, then three unique keys result: C<'ae*io'>, C<'a*ei*o'>, and
C<'ae*i*o'>. See L</add_sample()>.

=head2 null

What is used to mark the beginning and end of a sample internally. The default
of C<"\0"> should work for UTF-8 text, but may cause problems with UTF-16 or
other encodings.

=head2 stable

Whether or not to always produce the same results from the same internal state.
If stable is true, then the same random seed (see L<perlfunc/srand>) will
produce identical results for chains created from the same inputs.

=head2 normalize

Whether to normalize Unicode strings. This value, if true, is passed as the
first argument to Unicode::Normalize::normalize. The default C<'C'> should do
what most people expect, but it may be the case that C<'D'> is what you want.
If you're not using Unicode, set this to undef.

=head2 do_chomp

Whether to L<perlfunc/chomp> lines when reading files. See L</add_files()>.

=head1 METHODS

=head2 new()

  # Defaults
  my $mc = String::Markov->new(
  	order     => 2,
  	sep       => '',
  	split_sep => undef,
  	join_sep  => undef,
  	null      => "\0",
	stable    =>  1,
  	normalize => 'C',
	do_chomp  => 1,
  );

The I<sep> argument doesn't correlate to an attribute, but is used to
initialize I<split_sep> and/or I<join_sep> if either is undefined.

See L</ATTRIBUTES>.

=head2 split_line()

This is the method L</add_sample()> calls when it is passed a non-ref argument.
It returns an array of states (usually individual characters or words) that are
used to build the Markov Chain model.

The default implementation is equivalent to:

  sub split_line {
  	my ($self, $sample) = @_;
  	$sample = normalize($self->normalize, $sample) if $self->normalize;
  	return split($self->split_sep, $sample);
  }

This method can be overridden to deal with unusual data.

=head2 add_sample()

This method adds samples to build the Markov Chain model. It takes a single
argument, which can be either a string or an array reference. If the argument
is an array reference, its elements are directly used to update the Markov
Chain. If it is a string, add_sample() uses the split_line() method to create
an array of states, and then updates the Markov Chain.

Note that this function generates hash keys for the transition matrix. The keys
are built according to the I<order>, I<null>, and I<join_sep> attributes, so if
an instance is created with:

  my $mc = String::Markov->new(null => '!', order => 2, join_sep => '*');
  $mc->add_sample($_) for (@sample_lines);

Then the internal transition matrix might look like:

  {
    '!*!' => { 'A' => 5, 'B' => 7, ... }, # Initial state
    '!*A' => { ... },
    '!*B' => { ... },
    ...
    'x*y' => { '!' => 4 },                # always end after 'xy'
    'y*z' => { '!' => 3, 'q' => 2 },      # sometimes end after 'yz'
    ...
  }

=head2 add_files()

This is a simple convenience method, designed to replace code like:

  while(<>) { chomp; $mc->add_sample($_) }

It takes a list of file names as arguments, and adds them line-by-line.

=head2 generate_sample()

This method returns a sequence of states, generated from the Markov Chain using
the Monte Carlo method.

If called in scalar context, the states are joined with I<join_sep> before
being returned.

=head1 SEE ALSO

L<Algorithm::MarkovChain>

=head1 AUTHOR

Grant Mathews <gmathews@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Grant Mathews.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
