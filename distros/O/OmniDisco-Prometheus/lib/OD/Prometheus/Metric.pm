use strict;
use warnings;

package OD::Prometheus::Metric;
$OD::Prometheus::Metric::VERSION = '0.006';
use v5.24;
use Moose;
use Data::Printer;
use Regexp::Common qw(number delimited);
use Scalar::Util qw(reftype);

=head1 NAME

OD::Prometheus::Metric - Class representing a Prometheus metric

=head1 VERSION

version 0.006

=cut


has metric_name	=> (
	is	=> 'ro',
	isa	=> 'Str',
	required=> 1,
);

has values	=> (
	is	=> 'ro',
	isa	=> 'ArrayRef[ArrayRef]',
	required=> 1,
);

has labels	=> (
	is	=> 'ro',
	isa	=> 'HashRef[Str]',
	required=> 1,
	default	=> sub { {} },
);

has type	=> (
	is	=> 'ro',
	isa	=> 'Str',
	default	=> 'untyped', #see https://prometheus.io/docs/instrumenting/exposition_formats/
);

has docstring	=> (
	is	=> 'ro',
	isa	=> 'Str',
);

sub BUILDARGS {
	my $class = shift;
	if ( @_ == 1 && !ref $_[0] ) {
		my $r = $class->parse( $_[0] );
		return $r
	}
	else {
		my %temphash = @_;
		if( @_ == 4 && exists $temphash{ line }  && exists $temphash{ comments }  ) {
			%temphash = $class->parse( $temphash{ line } , @{ $temphash{ comments } } )->%*;
		}
		# case where value is supplied instead of values
		if( exists $temphash{ value } ) {
			exists( $temphash{ values } ) && die 'Please do not set value and values at the same time';
			$temphash{ values } = [ [ $temphash{ timestamp } // time, $temphash{ value } ] ];
			delete $temphash{ value }
		}
		# case where line and comments are supplied to new
		return \%temphash
	}
}

sub value {
	die 'Please do not call value when object contains multiple values. Use the is_multi method to test and call values if true' if $_[0]->is_multi;
	$_[0]->first->[1]
};

sub timestamp {
	die 'Please do not call timestamp when object contains multiple values. Use the is_multi method to test and, if true, get the timestamps from the values method directly' if $_[0]->is_multi;
	$_[0]->first->[0];
}

sub first {
	$_[0]->values->[0]
}

sub size {
	scalar $_[0]->values->@*
}

sub is_multi {
	$_[0]->size > 1
}

sub valuehash {
	my @a = map { $_->[0] => $_->[1] } $_[0]->values->@* ;
	return { @a }
}

sub ordered {
	[ sort { $a->[0] <=> $b->[0] } $_[0]->values->@* ]
}

sub latest_elem {
	$_[0]->ordered->[-1]
}

sub latest {
	$_[0]->latest_elem->[1]
}

sub latest_timestamp {
	$_[0]->latest_elem->[0]
}

sub earliest_elem {
	$_[0]->ordered->[0]
}

sub earliest {
	$_[0]->earliest_elem->[1]
}

sub earliest_timestamp {
	$_[0]->earliest_elem->[0]
}

sub to_string {
	(defined( $_[0]->docstring )? '# HELP '.encode_str( $_[0]->docstring )."\n" : '' ).'# TYPE '.$_[0]->type."\n".
	join("\n", map { 
			$_[0]->metric_name.
			( ($_[0]->labels->%*)? '{'.join(',',map { $_.'='.$_[0]->get_label( $_ ) } (sort keys $_[0]->labels->%*)).'}' : '' ).' '.
			$_->[1].' '.$_->[0]
		}
		sort { $a->[0] <=> $b->[0] } ( $_[0]->values->@* )
	) 
}

sub get_label {
	my $self	= shift // die 'incorrect call';
	my $label	= shift // die 'incorrect call';
	die "Label $label does not exist" if( !exists( $self->labels->{ $label } ) );
	my $value = $self->labels->{ $label };
	$value = encode_str( $value );
	return '"'.$value.'"';
}

# use to pass from prometheus string to internal (Perl) string
sub decode_str {
	my $str = shift // die 'incorrect call';
	$str =~ s/\\n/\n/g; # \n becomes a real newline
	$str =~ s/\\\\/\\/g; # escaped backslash (\\) becomes a real backslash
	$str =~ s/\\"/"/g; # \" becomes a plain "
	return $str
}

sub encode_str {
	my $str = shift // die 'incorrect call';
	$str =~ s/\\/\\\\/g; # every backslash is encoded as \\
	$str =~ s/"/\\"/g; # double quotes " are escaped
	$str =~ s/\n/\\n/g; # newlines are replaced by \n
	return $str
}
	
	
sub parse {
	my $class	= shift // die 'incorrect call';
	my $str		= shift // die 'incorrect call';
	my @comments	= @_;

	my $ret = {};

	for my $comment ( @comments ) {
		if( $comment =~ /
			#
			\s*
			TYPE
			\s+
			(?<metric_name>[a-zA-Z_][a-zA-Z0-9_]*)
			\s+
			(?<type>counter|gauge|histogram|summary|untyped)
			\s* $/x ) {
			$ret->{ type } = $+{ type }
		}
		elsif( $comment =~ /
			#
			\s*
			HELP
			\s+
			(?<metric_name>[a-zA-Z_][a-zA-Z0-9_]*)
			\s+
			(?<docstring>.*)
			$/x ) {
			$ret->{ docstring } = decode_str( $+{ docstring } );
		}
	}


	#p $ret;

	if( $str =~ /
		^
		(?<metric_name>[a-zA-Z_][a-zA-Z0-9_]*)
		(?:{(?<labels>.*)\s*,*\s*})*
		\s+
		(?<value>(?:$RE{num}{real}|NaN|\+Inf|-Inf))
		(?: \s+ (?<timestamp>\d+) )*
		\s*
		$	
	/x) {
		$ret->{ metric_name } = $+{ metric_name };
		$ret->{ value } = $+{ value }; #TODO: Must consult https://golang.org/pkg/strconv/ to make sure we parse -Inf,+Inf,Nan
		$ret->{ timestamp } = $+{ timestamp } if exists $+{ timestamp };
		my $labels = {};
		if( exists $+{ labels } ) {
			my @labelstrs = split(/\s*,\s*/,$+{ labels });
			for my $labelstr ( @labelstrs ) {
				#### say $labelstr;
				if( $labelstr =~ /
						^
						(?<label_name>[a-zA-Z_][a-zA-Z0-9_]*) #capture $1
						\s* = \s*
						$RE{delimited}{-delim=>'"'}{-keep} # $2 entire,$3 opening ",$4 content between ",escape is by default \
						/x) {
					my $label_name = $+{ label_name };
					$labels->{ $label_name } = decode_str( $4 );
				}
				else {
					die "Cannot parse labelstr: $labelstr"
				}
			}
		}
		$ret->{ labels } = $labels
	}
	else {
		die 'Cannot parse this string: '.$str
	}

	return $ret		
}

=head1 COPYRIGHT & LICENSE
 
Copyright 2018 Athanasios Douitsis, all rights reserved.
 
This program is free software; you can use it
under the terms of Artistic License 2.0 which can be found at 
http://www.perlfoundation.org/artistic_license_2_0
 
=cut

1;
