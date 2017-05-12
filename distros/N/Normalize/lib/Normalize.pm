package Normalize;

use warnings;
use strict;
use Math::Round::Var;

=head1 NAME

Normalize - normalize scores between 0 and 1.

=head1 VERSION

Version 0.31

=cut

our $VERSION = '0.31';

=head1 SYNOPSIS

	use Normalize;
	
	my %iq_rate = ('Professor' => 125.12, 'Bender' => 64, 'Dr. Zoidberg' => 28.6, 'Fray' => 13);
	my %weight_rate = ('Professor' => 70.2, 'Bender' => 600, 'Dr. Zoidberg' => 200, 'Fray' => 120);
	my $norm = Normalize->new('round_to' => 0.001);
	
	#larger score is better:
	$norm->normalize_to_max(\%iq_rate);
	print "\n#iq rate: larger iq is better:\n";
	foreach my $key (keys %iq_rate)
	{
		print "$key = $iq_rate{$key}\n";
	}
	
	#iq rate: larger iq is better:
	#1.000	Professor
	#0.512	Bender
	#0.229	Dr. Zoidberg
	#0.104	Fray
	
	#smaller score is better
	$norm->normalize_to_min(\%weight_rate, {min_default => 0.001});
	print "\n#skinny rate: smaller weight is better:\n";
	foreach my $key (sort {$weight_rate{$b} <=> $weight_rate{$a}} keys %weight_rate)
	{
		print "#$weight_rate{$key}\t$key\n";
	}
	##skinny rate: smaller weight is better:
	#1.000	Professor
	#0.585	Fray
	#0.351	Dr. Zoidberg
	#0.117	Bender
	
	#SUMMARY RATE
	my %summary_score = map { $_ => $weight_rate{$_} + $iq_rate{$_} } keys %iq_rate;
	$norm->normalize_to_max( \%summary_score );
	print "\n#summary score:\n";
	foreach my $key (sort {$summary_score{$b} <=> $summary_score{$a}} keys %summary_score)
	{
		print "#$summary_score{$key}\t$key\n";
	}
	#summary score:
	#1.000	Professor
	#0.344	Fray
	#0.315	Bender
	#0.290	Dr. Zoidberg
	
	#Dr. Zoidberg - looser lobster! Quod erat demonstrandum


=head1 DESCRIPTION

This module gives you the ability to normalize score result sets.
Sometimes a larger score is better and sometimes a smaller score is better.
In order to compare the results from different methods? You need a way to 
normalize them: that is, to get them all within the same range and direction.

The normalization functions will take a hash ref {key => score} or array ref [score 1, score 2, ...scaore 3] and return the same ref, but whith scores between 0 and 1.
Each score is scaled according to how close it to the best result, wich will always have a score of 1.

=head1 METHODS

=head2 new(%opts)

	Normalize->new(%opts) - constructor

=head3	%opts
		
round_to - default value 0.01. Rounding precision. For more info see L<Math::Round::Var>

min_default  - by default eq round_to value. Need for prevent delete on zero in normalize_to_min()
		
		
=cut

sub new {
	my $caller = shift;
	my $class  = ref($caller) || $caller;
	my $self   = {};
	bless( $self, $class );
	$self->_init(@_);
	return $self;
}

sub _init {
	my $self = shift;
	$self->set(@_);

	#set default precision
	my $round_to = $self->get('round_to');
	unless ($round_to) {
		$round_to = 0.01;
		$self->set( round_to => $round_to );
	}
	$self->set( 'round_obj' => Math::Round::Var->new($round_to) );
	return $self;
}

=head2 set(%params)

set object params

=cut

sub set {
	my $self = shift;
	my %op   = @_;
	foreach my $k ( keys %op ) {
		$self->{$k} = $op{$k};
	}

	return $self;
}

=head2 get(param_name)

get object param

=cut

sub get {
	my $self = shift;
	my $key  = shift;
	return $self->{$key};
}

=head2 normalize_to_min($score_set_data, %opts)

Each score is scaled according to how close it to the smaller result, wich will always have a score of 1.
$score_set_data - hashref {key1 => score1, key2 => score2,..} or arrayref [score1, score2, ...]
options:

	%opts = (
				min_default => 0.01#by default = round_to value. Need for prevent delete on zero in normalize_to_min()
			)
			
return same data structure (hashref or arrayref)	

=cut

sub normalize_to_min {
	my $self = shift;
	my ($data) = @_;
	if ( ref($data) eq 'HASH' ) {
		return $self->_hash_small_is_better(@_);
	}
	elsif ( ref($data) eq 'ARRAY' ) {
		return $self->_array_small_is_better(@_);
	}
	return undef;
}

=head2 normalize_to_max($score_set_data)

Each score is scaled according to how close it to the larger result, wich will always have a score of 1.
$score_set_data - hashref {key1 => score1, key2 => score2,..} or arrayref [score1, score2, ...]

return same data structure (hashref or arrayref)	
	
=cut

sub normalize_to_max {
	my $self = shift;
	my ($data) = @_;
	if ( ref($data) eq 'HASH' ) {
		return $self->_hash_max_is_better(@_);
	}
	elsif ( ref($data) eq 'ARRAY' ) {
		return $self->_array_max_is_better(@_);
	}
	return undef;
}

sub _hash_small_is_better {
	my $self = shift;
	my $data = shift;
	my $opt  = shift || {};

	my $min         = undef;
	my $min_default = $opt->{min}
	  || $self->get('min_default')
	  || $self->get('round_to');
	my $rnd = $self->get('round_obj');
	foreach my $d ( keys %$data ) {
		unless ( defined $min ) {
			$min = $data->{$d};
			next;
		}
		$min = $data->{$d} if ( $data->{$d} < $min );
		$min_default = $data->{$d}
		  if ( $data->{$d} && $data->{$d} < $min_default );

	}
	$min ||= $min_default;

	foreach my $d ( keys %$data ) {
		$data->{$d} = $rnd->round( $min / ( $data->{$d} || $min_default ) );
	}
	return $data;
}

sub _array_small_is_better {
	my $self = shift;
	my $data = shift;
	my $opt  = shift || {};

	my $min_default = $opt->{min}
	  || $self->get('min_default')
	  || $self->get('round_to');
	my $rnd = $self->get('round_obj');
	my $min = $data->[0];
	foreach my $d (@$data) {
		$min = $d if ( $d < $min );
		$min_default = $d if ( $d && $d < $min_default );
	}
	$min ||= $min_default;

	foreach my $i ( 0 .. $#$data ) {
		$data->[$i] = $rnd->round( $min / ( $data->[$i] || $min_default ) );
	}
	return $data;
}

sub _hash_max_is_better {
	my $self = shift;
	my $data = shift;

	my $max = undef;
	my $rnd = $self->get('round_obj');
	foreach my $d ( keys %$data ) {
		unless ($max) {
			$max = $data->{$d};
			next;
		}
		$max = $data->{$d} if ( $data->{$d} > $max );

	}

	foreach my $d ( keys %$data ) {
		$data->{$d} = $rnd->round( $data->{$d} / $max );
	}
	return $data;

}

sub _array_max_is_better {
	my $self = shift;
	my $data = shift;

	my $max = undef;
	my $rnd = $self->get('round_obj');
	foreach my $d (@$data) {
		unless ($max) {
			$max = $d;
			next;
		}
		$max = $d if ( $d > $max );

	}

	foreach my $i ( 0 .. $#$data ) {
		$data->[$i] = $rnd->round( $data->[$i] / $max );
	}

	return $data;

}

=head1 SEE ALSO

L<Math::Round::Var> - Variations on rounding.

Idea for this module and normalization Algoritm from book "Programming Collective Intelligence: Building Smart Web 2.0 Applications By Toby Segaran)" L<http://books.google.com/books?id=fEsZ3Ey-Hq4C>

=head1 AUTHOR

Konstantin Kapitanov aka Green Kakadu,  C<perlovik at gmail dot com>

L<http://wiki-linki.ru>

=head1 BUGS

Please report any bugs or feature requests to C<bug-normalize at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Normalize>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Normalize


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Normalize>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Normalize>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Normalize>

=item * Search CPAN

L<http://search.cpan.org/dist/Normalize/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Konstantin Kapitanov, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of Normalize
