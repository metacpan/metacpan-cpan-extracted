package SerialNumber::Sequence;
use Carp;
use strict;
our $VERSION = sprintf "%d.%02d", q$Revision: 1.1.1.1 $ =~ /: (\d+)\.(\d+)/;

sub new {
	my $class = shift;
	my %opt = @_;
	my $self = bless {}, $class;
	$self->prefix('#');
	$self->number_length(1);
	return $self;
}

sub prefix {
	my $self = shift;
	my $prefix = shift;
	if ( defined $prefix ){
		$self->{_PREFIX} = $prefix;
	}
	return $self->{_PREFIX};
}

sub number_length {
	my $self = shift;
	my $length = shift;
	if ( defined $length ){
		$self->{_NUMBER_LENGTH} = int $length;
	}
	return $self->{_NUMBER_LENGTH};
}

sub from_string {
	my $self = shift;
	my $string  = shift;
	my @items = split( /\,/, $string );
	
	my @data;
	foreach my $item ( @items )	{
		if ( $item =~ /\-/ ){
			my ( $from, $to ) = split( /\-/, $item );
#			push @data, [ $self->_string2number($from), $self->_string2number($to) ]; 
			foreach ( $self->_string2number($from) .. $self->_string2number($to) ){
				push @data, $_ ;
			}
		}else{
			push @data, $self->_string2number($item);
		}
	}
	return ( wantarray ) ? @data : \@data;
}

sub from_list {
	my $self = shift;
	my $array_ref = ( ref $_[0] eq 'ARRAY' ) ? $_[0] : [@_] ;
	
	my @ln = sort { $a <=> $b } @$array_ref;
	my @scope;
	my $start = undef;
	my $end = undef;
	foreach (0..$#ln){
		if ( not defined $start ){
			$start = $_;
			$end = $_;
		}else{
			# 数字不连续，则表明当前位置为新段的开始，
			# 所以将之前结束的段保存到缓存中
			# 并当前位置保留为新段数据
			if ( $ln[$_] != $ln[$_-1] + 1 ){
				$end = $_ - 1;
				push @scope, [$start,$end];
				$start = $_;
				$end = $_;
			}
			# 如果这次已经是最后一个 （连续数字段的最后一个，或者新段的第一个）
			# 都只要把他们保存到缓存即可
			if ( $_ == $#ln ){
				$end = $_;
				push @scope, [$start,$end];
			}
		}
	}

	my $string = join( ',',
		map {
			( $$_[0] == $$_[1] )
				? $self->_number2string($ln[$$_[0]])
				: join( '-', ( $self->_number2string($ln[$$_[0]]),
							   $self->_number2string($ln[$$_[1]], without_prefix => 1 ) )
					   );
		} @scope
	);	

	return $string;
}

sub _string2number {
	my $self = shift;
	my $string = shift;
	
	my $prefix = $self->prefix;
	$string =~ s/^$prefix//e;
	my $number = int( $string + 0 );
	
	return $number;
}

sub _number2string {
	my $self = shift;
	my $number = shift;
	my %opt = @_;
	
	my $prefix = $self->prefix;
	my $length = $self->number_length;
	my $string = join ('',
							( $opt{'without_prefix'} ) ? '' : $prefix,
							sprintf("%0".$length."d", $number)
						);
	return $string;
}

1;

__END__

=head1 NAME

SerialNumber::Sequence - make continously serial number sequence to be readable string; and vice verser;

=head1 SYNOPSIS

 use SerialNumber::Sequence;
 my $ss = new SerialNumber::Sequence;
 my $sequence = [23,24,25,26,34,35,36,45,46,79,88];
 $ss->number_length(3);
 my $string = $ss->from_list( $sequence ); # return '#023-026,#034-036,#045-046,#079,#088'
 my @array = $ss->from_string( $string ); # return [23,24,25,26,34,35,36,45,46,79,88]

=head1 DESCRIPTION

Some bill of document has its serialnumber, almostly are continuously. In some situation, we wanner do somthing with a group of these bills, which serial number are not continuously sequence, like this: [23,24,25,26,34,35,36,45,46,79,88], it is not readable for a person, when we print these infomation on invoice, we wanner a readable string to represent that sequence, which should be more short and clearly. So use this module and it will give a string: '#23-26,#34-36,#45-46,#79,#88' according above, of course we supply a method to do reverse-thing.

the prefix '#' and number length can be customized.

=head1 METHODS

=item new() 

 my $ss = new SerialNumber::Sequence;

It's very simple. just copy and paste that.

=item prefix()

 # set/get prefix
 $ss->prefix('@'); # set serialnumber prefix as '@'
 $ss->prefix(); # return '@'

Default is '#'.

=item number_length()

 # set/get number_length
 $ss->number_length(5); # set serialnumber as 5 length number, with prefix '0'
 $ss->number_length(); # return 5;

Default is 1. If serial number is 45567 and set number length to be 8, then after transform, you will get #00045567

=item from_list(@array)

 my $string = $ss->from_list( $array_ref_of_a_sequence );
 my $string = $ss->from_list( @array_of_a_sequence );

give a sequence with array or array ref, and return the readable string.

=item from_string($string)

 my @array = $ss->from_string( $string );
 my $array_ref = $ss->from_string( $string );

give some string like above method returned, return the array which elements are the pure serial number( without prefix string ).

=item _string2number()

private method, transform a single string to a number

=item _number2string()

 $self->_number2string($number, without_prefix => 1 );

private method, transform a single number to a string, if without_prefix => 1, then ignore '#';

=head1 TODO

some more other transform style; some caculation for some sequence plus or minus operation;

=head1 AUTHOR

Chun Sheng <me@chunzi.org>

=head1 COPYRIGHT

Copyright (c) 2004-2005 Chun Sheng. All rights reserved. All wrongs revenged. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
