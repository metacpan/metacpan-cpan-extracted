###############################################################################
#Map.pm
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

Data::Sofu::Map - A Sofu Map

=head1 DESCRIPTION

Provides a interface similar to the original SofuD (sofu.sf.net)

=head1 Synopsis 

	require Data::Sofu::Map;
	my $map = Data::Sofu::Map->new();
	$map->setAttribute("foo","bar");
	print $map->value("foo")->toString();
	$tree = Data::Sofu::loadfile("1.sofu");
	$tree->opApply(sub {print $_[0],"\n"}); #Prints all keys

=head1 SYNTAX

This Module is pure OO, exports nothing

=cut

package Data::Sofu::Map;

use strict;
use warnings;
require Data::Sofu::Object;
require Data::Sofu;
use Carp;
our $VERSION="0.3";
our @ISA = qw/Data::Sofu::Object/;

=head1 METHODS

Also look at C<Data::Sofu::Object> for methods, cause Map inherits from it

=head2 new([DATA])
Creates a new C<Data::Sofu::Map> and returns it

Converts DATA to appropriate Objects if DATA is given. DATA has to be a Hash or a hashlike structure.

	$env = Data::Sofu::Map->new(%ENV);

=cut 


sub new {
	my $self={};
	bless $self,shift;
	$self->{Map}={};
	$self->{Order}=[];
	if (@_) {
		$self->set(@_);
	}
	return $self;
}

=head2 set(DATA) 

Sets the contents of the Map to match a Hash.

	$map->set(%ENV);

=cut
#use Data::Dumper;
sub set {
	my $self=shift;
	local $_;
	my $temp=shift;
	my $order=shift;
	foreach (values %$temp) {
		$_=Data::Sofu::Object->new($_);
	}
	$self->{Order}=$order;
	$self->{Map}=$temp;
	#print (Data::Dumper->Dump([$temp]));
}

=head2 object(KEY) 

Return an attribute identified by KEY of this Map.

	$o = $env->object("PATH");
	if ($o->isList()) {
		...
	}
	elsif ($o->isValue()) {
	...

Note: Changing the returned Object will change the Map as well. (OO 101)

=cut 

sub object {
	my $self=shift;
	my $k=shift;
	if (exists $self->{Map}->{$k}) {
		return $self->{Map}->{$k};
	}
	die "Requested object $k doesn't exists in this Map";
}

=head2 remAttribute(KEY) 

Deletes an Attribute from this Map.

	$env->remAttribute("OSTYPE");

=cut 

sub remAttribute {
	my $self=shift;
	my $k=shift;
	local $_;
	#@{$self->{Order}} = grep {$_ ne $k} @{$self->{Order}}; #Not needed, orderedKeys does that for all keys at once.
	delete $self->{Map}->{$k};
	return;
}

=head2 setAttribute(KEY, OBJECT)

Replaces/creates an Attribute in this Map identified by KEY and sets it to OBJECT.

	$env->setAttribute("PATH", Data::Sofu::List->new(split/:/,$env->value("PATH")->toString()));

=cut

sub setAttribute {
	my $self=shift;
	my $k=shift;
	push @{$self->{Order}},$k unless $self->{Map}->{$k};
	$self->{Map}->{$k}=Data::Sofu::Object->new(shift);
	return;
}

=head2 hasAttribute(KEY)

Return a true value if this Map has an Attribute identified by KEY

	if ($env->hasAttribute("Lines")) {
		print "X" x $env->value("Lines")->toInt();

=cut

sub hasAttribute {
	my $self=shift;
	my $k=shift;
	return exists $self->{Map}->{$k};
}

=head2 hasValue(KEY) 

Returns 1 if this Map has an Attribute called KEY and this Attribute is a C<Data::Sofu::Value>.

	$env->hasValue("PATH") === $env->hasAttribute("PATH") and $env->object("PATH")->isValue();

Note: Return 0 if the Object is not a Value and under if the Element doesn't exist at all.

=cut

sub hasValue {
	my $self=shift;
	my $k=shift;
	return $self->{Map}->{$k}->isValue() if exists $self->{Map}->{$k};
	return undef;
}

=head2 hasMap(KEY) 

Returns 1 if this Map has an Attribute called KEY and this Attribute is a C<Data::Sofu::Map>.

	$env->hasMap("PATH") === $env->hasAttribute("PATH") and $env->object("PATH")->isMap();

Note: Return 0 if the Object is not a Value and under if the Element doesn't exist at all.

=cut

sub hasMap {
	my $self=shift;
	my $k=shift;
	return $self->{Map}->{$k}->isMap() if exists $self->{Map}->{$k};
	return undef;
}

=head2 hasList(KEY) 

Returns 1 if this Map has an Attribute called KEY and this Attribute is a C<Data::Sofu::List>.

	$env->hasList("PATH") === $env->hasAttribute("PATH") and $env->object("PATH")->isList();

Note: Return 0 if the Object is not a Value and under if the Element doesn't exist at all.

=cut

sub hasList {
	my $self=shift;
	my $k=shift;
	return $self->{Map}->{$k}->isList() if exists $self->{Map}->{$k};
	return undef;
}

=head2 list(KEY)

Returns the Object at the key called KEY as a C<Data::Sofu::List>.

Dies if the Object is not a Data::Sofu::List.
	
	$env->list("PATH") === $env->object("PATH")->asList()

=cut

sub list {
	my $self=shift;
	return $self->object(shift(@_))->asList();
}

=head2 map(KEY)

Returns the Object at the key called KEY as a C<Data::Sofu::Map>.

Dies if the Object is not a Data::Sofu::Map.
	
	$env->map("PATH") === $env->object("PATH")->asMap()

=cut

sub map {
	my $self=shift;
	return $self->object(shift(@_))->asMap();
}

=head2 value(KEY)

Returns the Object at the key called KEY as a C<Data::Sofu::Value>.

Dies if the Object is not a Data::Sofu::Value.
	
	$env->value("PATH") === $env->object("PATH")->asValue()

=cut

sub value {
	my $self=shift;
	return $self->object(shift(@_))->asValue();
}

=head2 asMap()

Returns itself, used to make sure this Map is really a Map (C<Data::Sofu::List> and C<Data::Sofu::Value> will die if called with this method)

=cut

sub asMap {
	return shift;
}

=head2 asHash()

Perl only

Returns this Map as a real perl Hash.

=cut

sub asHash {
	my $self=shift;
	return %{$$self{Map}};
}

=head2 isMap()

Returns 1

=cut

sub isMap {
	return 1;
}

=head2 next()

Returns the next Key, Value pair in no specific order. Used to iterate over the Map.

If called in list context it returns the (Key, Value) as a list, in scalar context it returns [Key, Value] as an Arrayref and in Void Context it resets the Iterator.

	while (my ($k,$v) = $env->next()) {
		last if $k eq "PATH";
		print "$k = ".$v->asValue()->ToString()."\n";
	}
	$env->next() #Reset Iterator

=cut

sub next {
	my $self=shift;
	if (defined wantarray) {
		return CORE::each(%{$self->{Map}}) if wantarray;
		return [CORE::each(%{$self->{Map}})];
	}
	keys(%{$self->{Map}});
	return;
}

=head2 each()

Returns the next Key, Value pair in no specific order. Used to iterate over the Map.

If called in list context it returns the (Key, Value) as a list, in scalar context it returns [Key, Value] as an Arrayref and in Void Context it resets the Iterator.

	while (my ($k,$v) = $env->each()) {
		last if $k eq "PATH";
		print "$k = ".$v->asValue()->ToString()."\n";
	}
	$env->each() #Reset Iterator

=cut

sub each {
	my $self=shift;
	if (defined wantarray) {
		return CORE::each(%{$self->{Map}}) if wantarray;
		return [CORE::each(%{$self->{Map}})];
	}
	keys(%{$self->{Map}});
	return;
}

=head2 length()

Returns the length of this Map

Warning: Resets the Iterator.

=cut


sub length {
	my $self=shift;
	return scalar keys %{$self->{Map}};
}

=head2 opApply(CODE)

Takes a Subroutine and iterates with it over the Map. Values and Keys can't be modified.

The Subroutine takes two Arguments: first is the Key and second is the Value.

	$env->opApply(sub {
		print "Key = $_[0], Value = ",$_[1]->asValue->toString(),"\n";
	});

Note: The Values are Objects, so they still can be changed, but not replaced.

=cut

sub opApply {
	my $self=shift;
	my $code=shift;
	croak("opApply needs a Code Reference") unless ref $code and lc ref $code eq "code";
	while (my ($k,$v) = CORE::each(%{$self->{Map}})) { 
		$code->($k,$v);
	}
}


=head2 opApplyDeluxe(CODE)

Perl only.

Takes a Subroutine and iterates with it over the Map. Keys can't be modified, but Values can.

The Subroutine takes two Arguments: first is the Key and second is the Value.

	my $i=0;
	$env->opApplyDeluxe(sub {
		$_[1]=new Data::Sofu::Value($i++);
	});

Note: Please make sure every replaced Value is a C<Data::Sofu::Object> or inherits from it.

=cut


sub opApplyDeluxe {
	my $self=shift;
	my $code=shift;
	croak("opApplyDeluxe needs a Code Reference") unless ref $code and lc ref $code eq "code";
	while (my $k = CORE::each(%{$self->{Map}})) { 
		$code->($k,$self->{Map}->{$k}); #Aliasing the Value of the Map, so it can be changed....
	}
}

=head2 storeComment(TREE,COMMENT)

Stores a comment in the Object if TREE is empty, otherwise it propagades the Comment to all its Values

Should not be called directly, use importComments() instead.

=cut

sub storeComment {
	my $self=shift;
	my $tree=shift;
	my $comment=shift;
	#print "Tree = $tree, Comment = @{$comment}\n";
	if ($tree eq "" or $tree eq "=") {
		#print "Setting to $comment\n";
		$self->{Comment}=$comment;
	}
	else {
		#print "Setting to $comment on $tree\n";
		my ($key,$tree) = split(/\-\>/,$tree,2);
		$tree="" unless $tree;
		$key=Data::Sofu::Sofukeyunescape($key);
		$self->{Map}->{$key}->storeComment($tree,$comment) if $self->{Map}->{$key};
	}

}

=head2 orderedKeys()

Return all Keys of the Map in insertion Order

=cut

sub orderedKeys {
	my $self=shift;
	local $_;
	my @order = grep {exists $self->{Map}->{$_}} @{$self->{Order}}; #Check if all keys are still there.
	my %seen=();
	@seen{@order}=(1) x @order;
	return (@order,grep !$seen{$_},keys %{$self->{Map}});
}

=head2 stringify(LEVEL, TREE)

Returns a string representing this Map and all its children.

Runs string(LEVEL+1,TREE+keyname) on all its values.

=cut

sub stringify {
	my $self=shift;
	my $level=shift;
	my $tree=shift;
	my $str="{" if $level;
	$level-=1 if $level < 0;
	$str.=$self->stringComment();
	$str.="\n";
	#foreach my $key (keys %{$self->{Map}}) {
	foreach my $key ($self->orderedKeys()) {
		$str.=$self->indent($level);
		$str.=Data::Sofu::Sofukeyescape($key);
		$str.=" = ";
		$str.=$self->{Map}->{$key}->string($level+1,$tree."->".Data::Sofu::Sofukeyescape($key));
	}
	$str.=$self->indent($level-1) if $level > 1;
	$str.="}\n" if $level;
	return $str;
}



=head2 binaryPack(ENCODING, BYTEORDER, SOFUMARK)

Returns a String containing the binary representaion of this Map (according the Sofu Binary File Format)

Look at C<Data::Sofu::Binary> for the Parameters.

Note: This uses C<Data::Sofu::Binary::Bin0200> as a only packer.

=cut

sub binaryPack {
	require Data::Sofu::Binary;
	my $self = shift;
	my $bin=Data::Sofu::Binary->new("000_002_000_000"); #Use this Version, the next Version will
	my $str=$bin->packHeader(@_);
	$str.=$self->packComment($bin);
	%Data::Sofu::Object::OBJ=($self=>"->");
	#foreach my $key (keys %{$self->{Map}}) {
	foreach my $key ($self->orderedKeys()) {
		$str.=$bin->packText($key);
		#$str.=$bin->packData($self->{Map}->{$key},Data::Sofu::Sofukeyescape($key));
		$str.=$self->{Map}->{$key}->binary("->".Data::Sofu::Sofukeyescape($key),$bin);
	}
	return $str;
}

=head2 binarify(TREE,BINARY DRIVER)

Returns the binary version of this Map and all its children using the BINARY DRIVER. Don't call this one, use binaryPack instead

=cut

sub binarify {
	my $self=shift;
	my $tree=shift;
	my $bin=shift;
	my $str=$bin->packType(3);
	$str.=$self->packComment($bin);
	$str.=$bin->packLong(scalar keys %{$self->{Map}});
	#foreach my $key (keys %{$self->{Map}}) {
	foreach my $key ($self->orderedKeys()) {
		my $kkey = Data::Sofu::Sofukeyescape($key);
		$str.=$bin->packText($key);
		$str.=$self->{Map}->{$key}->binary("$tree->$kkey",$bin);
	}
	return $str;
}

=head1 BUGS

This only supports the 2 Argument version of opApply, I have no idea how to find out if a codereference takes 2 or 1 Arguments.

=head1 SEE ALSO

L<Data::Sofu>, L<Data::Sofu::Binary>, L<Data::Sofu::Object>, L<Data::Sofu::List>, L<Data::Sofu::Value>, L<Data::Sofu::Undefined>, L<http://sofu.sf.net>

=cut 

1;
