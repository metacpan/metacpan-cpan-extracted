use strict;
use warnings;

package OD::Prometheus::Set;
$OD::Prometheus::Set::VERSION = '0.006';
use v5.24;
use Moose;
use LWP::UserAgent;
use Data::Printer;
use Scalar::Util qw(looks_like_number reftype);
use List::Util qw( sum );
use OD::Prometheus::Metric;

=head1 NAME

OD::Prometheus::Set - A set of Prometheus metrics

=head1 VERSION

version 0.006

=cut

use overload
	'@{}'	=> sub { $_[0]->metrics }
;

has metrics => (
        is		=> 'ro',
        isa		=> 'ArrayRef[OD::Prometheus::Metric]',
        default		=> sub { [] },
);


sub push {
	push shift->metrics->@*, @_
}

sub size {
	sum( map { $_->size } $_[0]->metrics->@* ) // 0 # we do this to make sure we always get a number
}

sub is_empty {
	$_[0]->size == 0
}

sub pop {
	pop $_[0]->metrics->@*
}

sub item {
	$_[0]->metrics->[ $_[1] ]
}

sub to_string {
	join("\n",map { $_->to_string } $_[0]->metrics->@*)
}

sub find {
	my $self	= shift // die 'incorrect call';
	my $metric	= shift // die 'incorrect call';
	my $attrs	= shift // {};
	my $value	= shift;

	my $rs = OD::Prometheus::Set->new;
	
	LOOP:
	for my $item ( $self->metrics->@* ) {
		next LOOP unless $metric eq $item->metric_name;
		for my $attr (keys $attrs->%*) {
			next LOOP unless exists( $item->labels->{ $attr } );
			next LOOP unless $attrs->{ $attr } eq $item->labels->{ $attr }
		}
		if( defined( $value ) ) {
			#say STDERR "Comparing ".$value." with ".$item->value;
			if( looks_like_number( $value ) ) {
				#say STDERR "Comparing as numbers";
				next LOOP unless $value == $item->value
			}
			else {
				#say STDERR "Comparing as strings";
				next LOOP unless $value eq $item->value
			}
		}
		$rs->push( $item )
	}
	return $rs
}

sub each {
	my $self	= shift // die 'incorrect call';
	my $func	= shift // die 'incorrect call';
	die '2nd argument must be a subroutine reference' unless reftype( $func ) eq 'CODE';
	for ( $self->metrics->@* ) {
		$func->()
	}
}	

sub value {
	die 'Please do not call value on a Set that does not have exactly 1 item' unless $_[0]->size == 1;
	$_[0]->item(0)->value
}


1;
