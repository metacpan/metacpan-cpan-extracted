#
# Copyright (c) 2008-2009 Pan Yu (xiaocong@vip.163.com). 
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

package Money::Chinese;

use 5.006;
use strict;
use vars qw($VERSION);

$VERSION = '1.10';

use Carp;

my @Chinese = qw( Áã Ò¼ ·¡ Èþ ËÁ Îé Â½ Æâ °Æ ¾Á );

sub new {
	my $class = shift;
	my $type = ref($class) || $class;
	my $arg_ref = { @_ };
	
	my $self = bless {}, $type;
	$self;
}

sub convert {
	my $self = shift;
	my $money = shift;
	
	# replace comma and space
	$money =~ s/[,(?:\s)+]//g;
	
	croak "An Arabic numeral with the format of 'xxxx.xx' is expected"
		unless ($money =~ /^(?:\d)+(?:\.(?:\d)+)?$/);
	croak "A non zero Arabic numeral is expected" if ($money == 0);
	
	$self->{integer} = undef;
	$self->{decimal} = undef;
	$self->{Chinese_integer} = undef;
	$self->{Chinese_decimal} = undef;
	
	($self->{integer}, $self->{decimal}) = split /\./, $money;
	
	$self->_integer if ($self->{integer} != 0);
	$self->_decimal if (defined $self->{decimal} && $self->{decimal} != 0);
	$self->_print;
}

sub _print {
	my $self = shift;
	my $result;
	
	$result = $self->{Chinese_integer} if ($self->{integer} != 0);
	if (defined $self->{decimal} && $self->{decimal} != 0) {
		$result .= $self->{Chinese_decimal};
	}else{
		$result .= 'Õû';
	}
	return $result;
}

sub _decimal {
	my $self = shift;
	my ($cent, @cent);
	
	$cent[0] = substr( $self->{decimal}, 0 , 1 );
	$cent[1] = substr( $self->{decimal}, 1 , 1 ) if (length($self->{decimal}) != 1);
	$cent = ($cent[0] == 0)? $Chinese[0]:$Chinese[$cent[0]] . '½Ç';
	$cent .= $Chinese[$cent[1]] . '·Ö' if ($cent[1]);
	
	$self->{Chinese_decimal} = $cent;
}

sub _integer {
	my $self = shift;
	my (@digit, @result, $result);
	my $money = $self->{integer};
	
	for (my $i = 0; length($money) > 0; $i++) {
		$digit[$i] = substr( $money, -4 , 4 );
		substr( $money, -4 , 4 ) = '';
		$digit[$i] = '0'x(4 - length($digit[$i])) . $digit[$i] if (length($digit[$i]) != 4);
	}
	
	my $i = 0;
	foreach (@digit) {
		$i++;
		next if ($_ eq '0000');
		m/(\d)(\d)(\d)(\d)/;
		my $cn;
		my $tail = '';
		$cn = ($1 == 0)? $Chinese[0]:$Chinese[$1] . "Çª";
		$cn .= ($2 == 0)? $Chinese[0]:$Chinese[$2] . "°Û";
		$cn .= ($3 == 0)? $Chinese[0]:$Chinese[$3] . "Ê°";
		$cn .= ($4 == 0)? '':$Chinese[$4];
		if ($i%2 == 0) {
			$tail = 'Íò';
			$tail .= 'Áã' if ($4 == 0);
		}
		if($i > 2) {
			$tail .= 'ÒÚ';
			$tail .= 'Áã' if ($4 == 0);
			$tail =~ s/ÁãÒÚ/ÒÚ/;
		}
		$cn =~ s/(?:Áã)+$//;
		unshift (@result, "$cn$tail");
	}
	$result = join '',@result;
	$result =~ s/(?:Áã){2,}/Áã/g;
	$result =~ s/^(?:Áã)+//;
	
	$result =~ s/(?:Áã)+$//;
	$result .= 'Ôª';
	
	$self->{Chinese_integer} = $result;
}


1;

__END__

=head1 NAME

Money::Chinese - Converting Arabic numerals into Chinese

=head1 SYNOPSIS

  use Money::Chinese;
  
  $object = Money::Chinese->new;
  
  $Chinese = $object->convert('100030.46');

=head1 DESCRIPTION

The function of B<Money::Chinese> is converting Arabic numerals into Chinese.


=head1 ACKNOWLEDGEMENTS

A special thanks to Larry Wall <larry@wall.org> for convincing me that
no development could be made to the Perl community without everyone's contribution.
I also appreciate my wife Fu Na, who works for a finacial institution, 
have been helping me work through problems besides technical issues.

=head1 AUTHOR

Pan Yu <xiaocong@vip.163.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2009 by Pan Yu. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
