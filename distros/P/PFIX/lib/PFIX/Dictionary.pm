package PFIX::Dictionary;

use warnings;
use strict;

=head1 NAME

PFIX::Dictionary - Perl FIX dictionnary methods

=cut

use Data::Dumper;

my $fixDico = {};

sub load($) {
	my $ver = shift;

	if ( !defined $fixDico->{$ver} ) {

		require("PFIX/$ver.pm");

		my $f = eval "PFIX::${ver}::getFix()";

		##
		# parse messages and build a hash for faster access
		#
		$f->{hMessages} = {};
		for my $a ( @{ $f->{messages} } ) {
			$f->{hMessages}->{ $a->{msgtype} } = $a;
			$f->{hMessages}->{ $a->{name} }    = $a;
		}

		##
		# parse fields and build a hash for faster access
		#
		$f->{hFields} = {};
		for my $a ( @{ $f->{fields} } ) {
			$f->{hFields}->{ $a->{name} }   = $a;
			$f->{hFields}->{ $a->{number} } = $a;
		}

		##
		# parse components and build a hash for faster access
		#
		$f->{hComponents} = {};
		for my $a ( @{ $f->{components} } ) {
			$f->{hComponents}->{ $a->{name} } = $a;
		}

		$fixDico->{$ver} = $f;
	}

	#print Dumper($fixDico);

}

sub new ($) {
	my $proto = shift;

	my $class = ref($proto) || $proto;
	my $self = {};
	bless( $self, $class );
	$self->{_dict} = $fixDico->{FIX44};

	return $self;
}

sub getMessages($) {
	my $self = shift;
	return $self->{_dict}->{hMessages};
}

sub getMessage($$) {
	my ( $self, $m ) = @_;
	return $self->getMessages()->{$m};
}

sub getMessageName($$) {
	my ( $self, $m ) = @_;
	my $mh = $self->getMessage($m);
	return defined $mh ? $mh->{name} : undef;
}

sub getMessageMsgType($$) {
	my ( $self, $m ) = @_;
	my $mh = $self->getMessage($m);
	return defined $mh ? $mh->{msgtype} : undef;
}

sub getMessageFields($$) {
	my ( $self, $m ) = @_;
	my $mh = $self->getMessage($m);
	return defined $mh ? $mh->{fields} : undef;
}

sub _getMessageOrder($$) {
	my ( $self, $mf ) = @_;
	my @arr;
	return @arr if ! defined $mf;
	for my $e ( @$mf ) {
		if (!defined $e->{component}) {
			push(@arr, $self->getFieldNumber($e->{name}));
		}
		else {
			push(@arr, $self->_getMessageOrder($self->getComponentFields($e->{name})));
		}
		if (defined $e->{group}) {
			push(@arr, $self->_getMessageOrder($e->{group}));
		}
	}
	@arr;
}
	
sub getMessageOrder($$) {
	my ( $self, $m ) = @_;
	my $mf = $self->getMessageFields($m);
	my @arr=$self->_getMessageOrder($self->{_dict}->{header});;
	push(@arr,$self->_getMessageOrder($mf));
	push(@arr,$self->_getMessageOrder($self->{_dict}->{trailer}));
	my %ret;
	for my $i ( 0..scalar(@arr)-1 ) {
		$ret{$arr[$i]}=$i;
	}
	%ret;
}

sub getComponent($$) {
	my ($self, $c) = @_;
	return $self->{_dict}->{hComponents}->{$c};
}

sub getComponentFields($$) {
	my ($self, $c) = @_;
	my $cc=$self->{_dict}->{hComponents}->{$c};
	return defined $cc ? $cc->{fields} : undef;
}

sub getField($$) {
	my ( $self, $f ) = @_;
	return $self->{_dict}->{hFields}->{$f};
}

sub getFieldName($$) {
	my ( $self, $f ) = @_;
	my $fh = $self->getField($f);
	return defined $fh ? $fh->{name} : undef;
}

sub getFieldNumber($$) {
	my ( $self, $f ) = @_;
	return $f if ( $f =~ /^[0-9]+$/ );
	my $fh = $self->getField($f);
	warn("getFieldNumber($f) returning undef") if !defined $fh;
	return defined $fh ? $fh->{number} : undef;
}

sub getFieldType($$) {
	my ( $self, $f ) = @_;
	my $fh = $self->getField($f);
	return defined $fh ? $fh->{type} : undef;
}


##
# returns true if given field is found in the structure.
sub _isFieldInStructure($$$);

sub _isFieldInStructure($$$) {
	my ( $self, $m, $f ) = @_;
	return 0 if ( !defined $m || !defined $f );
	my $fn = $self->getFieldName($f);
	return 0 if !defined $fn;

	for my $f2 ( @{$m} ) {

		#print "checking if $fn eq " . $f2->{name} . "\n";
		##
		# found the field? return 1. Beware that if the element is a component then we don't accept
		# it as a valid field of the structure.
		return 1 if ( $f2->{name} eq $fn && !defined $f2->{component} );

		##
		# if the field is a group then scan all elements of the group
		if ( defined $f2->{group} ) {
			return 1 if $self->_isFieldInStructure( $f2->{group}, $fn ) == 1;
		}

		##
		# if the field is a component, we need to go to the component hash and check out its
		# composition.
		if ( defined $f2->{component} ) {
			return 1 if $self->_isFieldInStructure( $self->getComponentFields($f2->{name}), $fn ) == 1;
		}
	}

	return 0;
}

sub isFieldInHeader($$) {
	my ( $self, $f ) = @_;
	my $s = $self->{_dict}->{header};
	return $self->_isFieldInStructure( $s, $f );
}

sub isFieldInTrailer($$) {
	my ( $self, $f ) = @_;
	my $s = $self->{_dict}->{trailer};
	return $self->_isFieldInStructure( $s, $f );
}

##
# returns true if given field is a member of the given message
# $dict->isFieldInMessage('NewOrderSingle', 'Symbol')  -> returns 1
# $dict->isFieldInMessage('NewOrderSingle', 'NoLegs')  -> returns 0
# a recursive search into group members and components is performed.
sub isFieldInMessage($$$) {
	my ( $self, $m, $f ) = @_;
	my $s = $self->getMessage($m);
	return 0 if !defined $s;
	return $self->_isFieldInStructure( $s->{fields}, $f );
}

##
# returns 1 if given field is a group header field
# $dict->isGroup('NoAllocs')  -> returns 1
# $dict->isGroup('Symbol')    -> returns 0
sub isGroup($$) {
	my ( $self, $f ) = @_;
	my $ff = $self->getField($f);
	return defined $ff ? $ff->{type} eq 'NUMINGROUP' : 0;
}

sub _getGroupInStructure($$$) {
	my ($self,$s, $gn) = @_;
	
	my $ret;
	##
	# parse each field in the structure, and ....
	for my $e ( @{$s} ) {
		# we found the group name 
		return $e->{group} if ($e->{name} eq $gn && defined $e->{group});
		
		# stop at each group header
		if (defined $e->{group}) {
			# and research recursively
			$ret = $self->_getGroupInStructure($e->{group},$gn);
			return $ret if defined $ret;
		}
		
		# if we run into a component we need to check that out too
		if (defined $e->{component}) {
			$ret = $self->_getGroupInStructure($self->getComponentFields($e->{name}), $gn);
			return $ret if defined $ret;
		}
	}
	undef;
}

##
# return a ref on group of a message, this then allows us to work on the group elements.
# $d->getGroupInMessage('D','NoAllocs')
# will return a ref on the NoAllocs group allowing us to then parse it
#
# Looks recursively into groups of groups if needed.
sub getGroupInMessage($$$) {
	my ( $self, $m, $g ) = @_;
	my $s = $self->getMessageFields($m);
	return undef if !defined $s;
	my $gn = $self->getFieldName($g);
	return undef if !defined($gn);
	
	return undef if ! $self->isGroup($g);

	return $self->_getGroupInStructure( $s, $gn );
}


##
# returns true if given field is a member of the given group of given message.
sub isFieldInGroup($$$$) {
	my ( $self, $m, $g, $f ) = @_;

	my $gn = $self->getFieldName($g);
	return 0 if !defined $gn;
	return 0 if !$self->isGroup($gn);
	my $fn = $self->getFieldName($f);
	return 0 if !defined $fn;

	my $msg = $self->getGroupInMessage( $m, $g );
	return 0 if !defined $msg;
	return $self->_isFieldInStructure($msg, $fn);
}

1;

