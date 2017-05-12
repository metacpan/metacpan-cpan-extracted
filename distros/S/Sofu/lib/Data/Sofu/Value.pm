###############################################################################
#Value.pm
#Last Change: 2009-28-01
#Copyright (c) 2009 Marc-Seabstian "Maluku" Lucksch
#Version 0.3
####################
#This file is part of the sofu.pm project, a parser library for an all-purpose
#ASCII file format. More information can be found on the project web site
#at http://sofu.sourceforge.net/ .
#
#sofu.pm is published under the terms of the MIT license, which basically means
#"Do with it whatever you want". For more information, see the license.txt
#file that should be enclosed with libsofu distributions. A copy of the license
#is (at the time of this writing) also available at
#http://www.opensource.org/licenses/mit-license.php .
###############################################################################


=head1 NAME

Data::Sofu::Value - A Sofu Value

=head1 DESCRIPTION

Provides a interface similar to the original SofuD (sofu.sf.net)

=head1 Synopsis 

	require Data::Sofu::Value;
	my $v = Data::Sofu::Value->new();
	$v->set("Hello World");

=head1 SYNTAX

This Module is pure OO, exports nothing

=cut

package Data::Sofu::Value;

use strict;
use warnings;
require Data::Sofu::Object;
require Data::Sofu::List;
require Data::Sofu::Undefined;
require Data::Sofu;
our @ISA = qw/Data::Sofu::Object/;
our $VERSION="0.3";

=head1 METHODS

Also look at C<Data::Sofu::Object> for methods, cause Value inherits from it

=head2 new([DATA])

Creates a new C<Data::Sofu::Value> and returns it

Converts DATA to a string if DATA is given.

	$val = Data::Sofu::Value->new("Hello World");

=cut 


sub new {
	my $self={};
	bless $self,shift;
	$$self{Value}=undef;
	$$self{Value}="".shift if @_;
	if (@_) {
		return Data::Sofu::List->new($$self{Value},@_);
	}
	return $self if defined $$self{Value};
	return Data::Sofu::Undefined->new();
}

=head2 set(DATA)

Sets the contents of this Value (replaces the old contents).

Note: DATA will be converted to a string.

	$v->set("Foobar");

=cut

sub set {
	my $self=shift;
	$$self{Value}="".shift;
}

=head2 asValue() 

Returns itself, used to make sure this Value is really a Value (Data::Sofu::Map and Data::Sofu::List will die if called with this method)

=cut

sub asValue {
	return shift;
}

=head2 asScalar()

Perl only

Returns this Value as a perl Scalar (same as toString)

=cut

sub asScalar {
	my $self=shift;
	return $$self{Value};
}

=head2 toString()

Returns this as a string

=cut

sub toString {
	my $self=shift;
	return $$self{Value};
}

=head2 toUTF16(), toUTF8(), toUTF32()

Not working in Perl (cause there is no wchar, char, dchar stuff going on, if you need to convert strings use "Encode")

They just return the same as toString()

=cut

#TODO

sub toUTF16 {
	my $self=shift;
	return $$self{Value};
}
sub toUTF8 {
	my $self=shift;
	return $$self{Value};
}
sub toUTF32 {
	my $self=shift;
	return $$self{Value};
}
#/TODO

=head2 toInt()

Return the Value as an Integer 

	$v->toInt() ===  int $v->toString();

=cut

sub toInt {
	my $self=shift;
	return int $$self{Value};
}

=head2 toFloat() 

Return the Value as a Float 

	$v->toFloat() ===  $v->toString()+0;

=cut

sub toFloat {
	my $self=shift;
	return $$self{Value}+0;
}

=head2 toLong()

Return the Value as a Long 

	$v->toLong() ===  int $v->toString();

=cut

sub toLong {
	my $self=shift;
	return int $$self{Value};
}

=head2 toDouble() 

Return the Value as a Double 

	$v->toDouble() ===  $v->toString()+0;

=cut

sub toDouble {
	my $self=shift;
	return $$self{Value}+0;
}

=head2 isValue()

Returns 1

=cut

sub isValue {
	return 1
}


#=head2 string()

#Same as Data::Sofu::Object::string(), but skips the Reference building.

#=cut

#sub string { #No References for Values at this time (just remove this function to enable them
#	my $self=shift;
#	return $self->stringify(@_); 
#}

=head2 stringify(LEVEL,TREE)

Returns a string representation of this Value.

LEVEL and TREE are ignored...

=cut

sub stringify {
	my $self=shift;
	my $level=shift;
	my $tree=shift;
	return "Value = ".Data::Sofu::Sofuescape($$self{Value}).$self->stringComment()."\n" unless $level;
	return Data::Sofu::Sofuescape($$self{Value}).$self->stringComment()."\n";
}

=head2 binarify (TREE,BINARY DRIVER)

Returns the binary version of this Value using the BINARY DRIVER. Don't call this one, use binaryPack instead.

=cut

sub binarify {
	my $self=shift;
	my $tree=shift;
	my $bin=shift;
	my $str=$bin->packType(1);
	$str.=$self->packComment($bin);
	$str.=$bin->packText($$self{Value});
	return $str;
}

=head1 BUGS

most of the methods do the same, because perl does the converting for you.

=head1 SEE ALSO

L<Data::Sofu>, L<Data::Sofu::Binary>, L<Data::Sofu::Object>, L<Data::Sofu::Map>, L<Data::Sofu::Value>, L<Data::Sofu::Undefined>, L<http://sofu.sf.net>

=cut 

1;
