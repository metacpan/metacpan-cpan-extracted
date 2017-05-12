package PFIX::Message;

use warnings;
use strict;

use PFIX::Dictionary;

use Data::Dumper;

sub new {
	my ( $proto, %vars ) = @_;

	my $class = ref($proto) || $proto;
	my $self = {};
	bless( $self, $class );

	if ( defined $vars{version} ) {
		PFIX::Dictionary::load( $vars{version} );
	}
	else {
		PFIX::Dictionary::load('FIX44');
	}
	if ( defined $vars{dd} ) {
		$self->{_dd} = $vars{dd};
	}
	else {
		$self->{_dd} = PFIX::Dictionary->new();
	}

	return $self;
}

sub _parseFixArray($$$$$$);

sub _parseFixArray($$$$$$) {
	my ( $self, $arr, $msgType, $gName, $iField, $fields ) = @_;

	my $fixDico = $self->{_dd};
	my $n       = scalar(@$fields);
	my $i       = $iField;
	while ( $i < $n ) {
		my $field = $fields->[$i];
		my ( $k, $v ) = ( $field =~ /^([^=]+)=(.*)$/ );
		if ( defined $arr->{$k} ) {
			return $i if defined $gName;
			warn("Field $k is already in hash!");
		}
		if ( defined $gName ) {
			return $i if !$fixDico->isFieldInGroup( $msgType, $gName, $k );
		}
		$arr->{$k} = $v;
		if ( $k == 8 ) {

			#do nothing
		}
		elsif ( $k == 35 ) {
			$msgType = $v;
		}
		else {
			my $fieldName = $fixDico->getFieldName($k);
			if ( !defined $fieldName ) {
				warn("Did not find field $k in dictionary");
			}
			elsif ( $fixDico->isGroup($k) ) {
				my @elems;
				++$i;
				for my $j ( 1 .. $v ) {
					my %newArr;
					$i = _parseFixArray( $self, \%newArr, $msgType, $k, $i, $fields );
					push( @elems, \%newArr );
				}
				$arr->{$k} = \@elems;
				--$i;
			}
		}
		++$i;
	}
}

sub fromString($$) {
	my ( $self, $s ) = @_;

	return if !defined $s;
	my %arr;
	my @fields = split( "\001", $s );
	my $n = scalar(@fields) - 1;
	_parseFixArray( $self, \%arr, undef, undef, 0, \@fields );

	$self->{_AMSG} = \%arr;
	$self->{_SMSG} = $s;
}

sub resetString($) {
	my $self = shift;
	$self->{_SMSG} = undef;
}

sub __toString($$) {
	my ( $self, $m, $order ) = @_;
	my %newHash;
	while ( my ( $k, $v ) = each(%$m) ) {
		my $o = $order->{$k};
		print "$k ($o) \n";
		if ( ref($v) eq 'ARRAY' ) {
			my @newO;
			for my $g (@$v) {
				my %newH = $self->_toString( $g, $order );
				push( @newO, \%newH );
			}
			$newHash{$o} = { $k => \@newO };
		}
		else {
			$newHash{$o} = { $k => $v };
		}
	}
	%newHash;
}
sub _numeric { $a <=> $b }

sub _toString($$) {
	my ( $self, $m, $order ) = @_;
	my %newHash;
	while ( my ( $k, $v ) = each(%$m) ) {
		my $o = $order->{$k};
		if ( !defined $o ) {
			$o = 1000000 + $k;
		}
		if ( ref($v) eq 'ARRAY' ) {
			my @newArr;
			for my $g (@$v) {
				my $str = $self->_toString( $g, $order );
				push( @newArr, $str );
			}
			$newHash{$o} = { $k => \@newArr };
		}
		else {
			$newHash{$o} = { $k => $v };
		}
	}
	my $retStr;
	for my $k ( sort _numeric keys %newHash ) {
		my $v = $newHash{$k};
		my ( $tag, $val ) = %$v;
		next if ( $tag == 8 || $tag == 9 || $tag == 10 );
		if ( ref($val) eq 'ARRAY' ) {
			$retStr .= "$tag=" . scalar(@$val) . "\001";
			for my $e (@$val) {
				$retStr .= $e;
			}
		}
		else {
			$retStr .= "$tag=$val\001";
		}
	}
	$retStr;
}

sub toString($) {
	my $self = shift;

	return $self->{_SMSG} if defined $self->{_SMSG};

	my $msgtype = $self->getField('MsgType');
	my %order   = $self->{_dd}->getMessageOrder($msgtype);
	my $str     = $self->_toString( $self->{_AMSG}, \%order );
	my $l       = length($str);
	$self->setField( 9, $l );    # BodyLength
	$str = "8=" . $self->getField(8) . "\0019=" . $self->getField(9) . "\001" . $str;

	# calculate checksum
	my $sum = unpack( "%8C*", $str ) % 256;
	$self->setField( 10, sprintf( "%03d", $sum ) );
	$str .= "10=" . $self->getField(10) . "\001";
	$self->{_SMSG} = $str;

	$str;
}

sub toPrint($) {
	my $self = shift;
	my $ret;
	if ( ref($self) eq 'PFIX::Message' ) {
		$self->toString();
		$ret = $self->{_SMSG};
	}
	else {
		$ret = $self;
	}
	$ret =~ s/\001/\|/g;
	$ret;
}

sub getField($$) {
	my ( $self, $f ) = @_;
	$f = $self->{_dd}->getFieldNumber($f) if ( $f !~ /^\d+$/ );
	return if !defined $f;

	my $v = $self->{_AMSG}->{$f};
	if ( ref($v) eq '' ) {
		return $v;
	}
	if ( ref($v) eq 'ARRAY' ) {
		return scalar(@$v);
	}

	undef;
}

sub setField($$$) {
	my ( $self, $f, $v ) = @_;
	$f = $self->{_dd}->getFieldNumber($f);
	return if !defined $f;

	$self->{_AMSG}->{$f} = $v;
	$self->{_SMSG} = undef;
}

sub delField($$) {
	my ( $self, $f ) = @_;

	$f = $self->{_dd}->getFieldNumber($f);
	return if !defined $f;

	delete( $self->{_AMSG}->{$f} ) if defined( $self->{_AMSG}->{$f} );
	$self->{_SMSG} = undef;
}

sub getFloat($$) {
	my ( $self, $f ) = @_;
	my $v = $self->getField($f);
	return defined $v ? $v * 1.0 : 0.0;
}

sub getFieldInGroup($$$$) {
	my ( $self, $g, $n, $f ) = @_;
	$g = $self->{_dd}->getFieldNumber($g) if ( defined $self->{_dd} && $g !~ /^\d+$/ );
	return if !defined $g;

	my $v = $self->{_AMSG}->{$g};
	if ( ref($v) eq 'ARRAY' ) {
		$f = $self->{_dd}->getFieldNumber($f) if ( $f !~ /^\d+$/ );
		return if !defined $f;
		return $v->[$n]->{$f};
	}

	undef;
}

# the end!
1;
