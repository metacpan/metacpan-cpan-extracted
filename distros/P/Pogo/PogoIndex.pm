# PogoIndex.pm - Alternate hash class which can have plural values
# 2000 Sey Nakajima <sey@jkc.co.jp>
package PogoIndex;
use Pogo;
use Carp;
use strict;

sub keylist {
	my($self) = @_;
	keys %$self;
}
sub getlist {
	my($self, $key) = @_;
	return undef unless exists $self->{$key};
	@{$self->{$key}};
}
sub have {
	my($self, $key, $value) = @_;
	return 0 unless exists $self->{$key};
	return scalar grep Pogo::equal($_, $value), @{$self->{$key}};
}
sub add {
	my($self, $key, $value) = @_;
	$self->{$key} = [] unless exists $self->{$key};
	return if grep Pogo::equal($_, $value), @{$self->{$key}};
	push @{$self->{$key}}, $value;
}
sub del {
	my($self, $key, $value) = @_;
	return unless exists $self->{$key};
	@{$self->{$key}} = grep !Pogo::equal($_, $value), @{$self->{$key}};
}
sub clear {
	my($self, $key) = @_;
	return unless exists $self->{$key};
	@{$self->{$key}} = ();
}

package PogoIndex::Hash;
use vars qw(@ISA);
@ISA = qw(PogoIndex);
sub new {
	my($class, $size, $pogovar) = @_;
	new_tie Pogo::Hash $size, $pogovar, $class;
}

package PogoIndex::Htree;
use vars qw(@ISA);
@ISA = qw(PogoIndex);
sub new {
	my($class, $size, $pogovar) = @_;
	new_tie Pogo::Htree $size, $pogovar, $class;
}

package PogoIndex::Btree;
use vars qw(@ISA);
@ISA = qw(PogoIndex);
sub new {
	my($class, $pogovar) = @_;
	new_tie Pogo::Btree $pogovar, $class;
}

package PogoIndex::Ntree;
use vars qw(@ISA);
@ISA = qw(PogoIndex);
sub new {
	my($class, $pogovar) = @_;
	new_tie Pogo::Ntree $pogovar, $class;
}

1;
__END__

=head1 NAME

PogoIndex - Alternate hash class which can have plural values

=head1 SYNOPSIS

  use PogoIndex;
  $index = new PogoIndex::Btree;
  $index->add('key', 'value1');
  $index->add('key', 'value2');
  @values = $index->getlist('key');  # gets ('value1', 'value2')

=head1 DESCRIPTION

By the Pogo's hash data structures (Pogo::Hash, Pogo::Htree, Pogo::Btree, 
Pogo::Ntree), each key may have only one value. This module provides multi-value
available hash.

=over 4

=head2 Methods

=item $obj = PogoIndex::Hash->new($size);

This class method makes and returns a PogoIndex::Hash object. It's substance is 
a hash reference which is tied to a Pogo::Hash object. $size specifies the size 
of hash entry table. $size can default.

=item $obj = PogoIndex::Htree->new($size);

Same as PogoIndex::Hash->new, but using Pogo::Htree.

=item $obj = PogoIndex::Btree->new;

Same as PogoIndex::Hash->new, but using Pogo::Btree.

=item $obj = PogoIndex::Ntree->new;

Same as PogoIndex::Hash->new, but using Pogo::Ntree.

=item $obj->add($key, $value);

This object method adds the value $value as a value of the key $key.

=item $obj->del($key, $value);

This object method deletes the value $value from the list of values of the key 
$key.

=item $obj->clear($key);

This object method deletes all values of the key $key.
If $key defaults, the hash becomes empty.

=item @values = $obj->getlist($key);

This object method returns a list of all values of key $key.

=item $bool = $obj->have($key, $value);

This object method returns whether the key $key have the value $value.

=item @keys = $obj->keylist;

This object method returns a list of all keys.

=back

=head1 AUTHOR

Sey Nakajima <sey@jkc.co.jp>

=head1 SEE ALSO

Pogo(3).
