package Pogo;

use Carp;
use overload;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw();
$VERSION = '0.10';

bootstrap Pogo $VERSION;

# Preloaded methods go here.

# get root Btree object
# $ref = $pogoobj->root_tie;
sub root_tie {
	my $self = shift;
	my $class = ref $self;
	croak "Pogo object required" if !ref($self) || !$self->isa('Pogo');
	tie my %var, $class, $self->root;
	\%var;
}
# tie %root, 'Pogo', $rootobj;
sub TIEHASH {
	my($class, $obj) = @_;
	$obj;
}

#-----------------
# NOT method below
#-----------------
# ($reftype, $class, $tiedclass) = Pogo::type_of($pogovar);
sub type_of {
	my($var) = @_;
	my($type, $class, $tiedclass);
	if( ref $var ) {
		($class, $type) = ref($var) && 
			overload::StrVal($var) =~ /^(?:(.*)\=)?([^=]*)\(/;
		if( $type eq 'SCALAR' ) {
			$tiedclass = ref tied $$var;
		} elsif( $type eq 'ARRAY' ) {
			$tiedclass = ref tied @$var;
		} elsif( $type eq 'HASH' ) {
			$tiedclass = ref tied %$var;
		}
	}
	($type, $class, $tiedclass);
}

# $obj = Pogo::tied_object($pogovar);
sub tied_object {
	my($var) = @_;
	my($type, $class, $tiedobj);
	if( ref $var ) {
		($class, $type) = ref($var) && 
			overload::StrVal($var) =~ /^(?:(.*)\=)?([^=]*)\(/;
		if( $type eq 'SCALAR' ) {
			$tiedobj = tied $$var;
		} elsif( $type eq 'ARRAY' ) {
			$tiedobj = tied @$var;
		} elsif( $type eq 'HASH' ) {
			$tiedobj = tied %$var;
		}
	}
	return undef unless UNIVERSAL::isa($tiedobj, 'Pogo::Var');
	$tiedobj;
}

# $id = Pogo::object_id($pogovar);
sub object_id {
	my($var) = @_;
	my $obj = tied_object($var);
	$obj ? $obj->object_id : undef;
}

# $result = Pogo::atomic_call(\&func, $pogovar, @args);
sub atomic_call {
	my($func, $var, @args) = @_;
	my $tiedobj = tied_object($var);
	croak "CODE reference required" unless ref($func) eq 'CODE';
	croak "Pogo data required" unless $tiedobj;
	unshift @args, $var;
	$tiedobj->call($func, \@args);
}

# $result = Pogo::equal($pogovar1, $pogovar2);
sub equal {
	my($var1, $var2) = @_;
	my $tiedobj1 = tied_object($var1);
	my $tiedobj2 = tied_object($var2);
	if( $tiedobj1 && $tiedobj2 ) { $tiedobj1->equal($tiedobj2); }
	else { $var1 eq $var2 }
}

# $result = Pogo::wait_modification($pogovar, $sec);
sub wait_modification {
	my($var, $sec) = @_;
	my $tiedobj = tied_object($var);
	croak "Pogo data required" unless $tiedobj;
	$tiedobj->wait_modification($sec);
}

# $root = Pogo::get_root_tie($pogovar);
sub get_root_tie {
	my($var) = @_;
	my $tiedobj = tied_object($var);
	return undef unless $tiedobj;
	$tiedobj->root_tie;
}

# for debug
sub D { 
	my $func = (caller(1))[3]; 
	my $callfunc = (caller(2))[3]; 
	print "$func(@_) from $callfunc\n"; 
}

# internal functions for tie interface 
sub wrap { # &D; # for debug
	my $val = shift;
	my $type = ref $val;
	return $val unless $type;
	my $result;
	if( $val->isa('Pogo::Scalar') ) {
		tie my $tiedvar, $type, $val;
		$result = \$tiedvar;
	} elsif( $val->isa('Pogo::Array') || $val->isa('Pogo::SNArray') ) {
		tie my @tiedvar, $type, $val;
		$result = \@tiedvar;
	} elsif( $val->isa('Pogo::Var') ) {
		tie my %tiedvar, $type, $val;
		$result = \%tiedvar;
	} else {
		croak "Why? $type - No Pogo::* object got";
	}
	my $class = $val->get_class;
	bless $result, $class if $class;
	$result;
}

sub strip { # &D; # for debugging
	my $var = shift;
	return $var unless ref($var);
	my($tieobj, $class, $type);
	($class, $type) = ref($var) && 
		overload::StrVal($var) =~ /^(?:(.*)\=)?([^=]*)\(/;
	return $var if $class && $var->isa('Pogo::Var');
	if( $type eq 'SCALAR' ) {
		$tieobj = tied $$var;
	} elsif( $type eq 'ARRAY' ) {
		$tieobj = tied @$var;
	} elsif( $type eq 'HASH' ) {
		$tieobj = tied %$var;
	} else {
		croak "Only SCALAR/ARRAY/HASH reference is available";
	}
	if( ref($tieobj) && $tieobj->isa('Pogo::Var') ) {
		$tieobj->set_class($class) if $class;
		return $tieobj;
	}
	my $result;
	if( $type eq 'SCALAR' ) {
		$result = tie my $work, 'Pogo::Scalar';
		$work = $$var;
		$result->set_class($class) if $class;
	} elsif( $type eq 'ARRAY' ) {
		$result = tie my @work, 'Pogo::Array', scalar(@$var);
		@work = @$var;
		$result->set_class($class) if $class;
	} elsif( $type eq 'HASH' ) {
		my($hsize) = scalar(%$var) =~ /\d+\/(\d+)/;
		$hsize ||= 256;
		$result = tie my %work, 'Pogo::Hash', $hsize;
		%work = %$var;
		$result->set_class($class) if $class;
	}
	$result;
}

package Pogo::Var;
use Carp;
use strict;

sub root_tie {
	my($self) = @_;
	my $rootobj = $self->root;
	return undef unless $rootobj;
	tie my %var, 'Pogo', $rootobj;
	\%var;
}
sub call {
	my($self, $func, $argref) = @_;
	croak "CODE reference required" unless ref($func) eq 'CODE';
	$argref = [] unless defined $argref;
	croak "ARRAY reference required" unless ref($argref) eq 'ARRAY';
	_call($self, $func, $argref);
}
sub equal {
	my($self, $arg) = @_;
	UNIVERSAL::isa($arg, 'Pogo::Var') ? _equal($self, $arg) : 0;
}
sub import {
	my($class, @arg) = @_;
	no strict 'refs';
	my $hookref = \%{"${class}::HOOK"};
	return unless $hookref;
	for my $method(keys %$hookref) {
		my $subref = $hookref->{$method};
		carp("code reference required"),next unless ref($subref) eq 'CODE';
		my $orgmethod = $class->can($method);
		carp("$method - no such method"),next unless $orgmethod;
		*{"${class}::$method"} = sub { &$subref and &$orgmethod }
	}
}

package Pogo::Scalar;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(Pogo::Var);
# $ref = new_tie Pogo::Scalar [,$pogovar, $blessclass];
sub new_tie {
	my($class, $pogovar, $blessclass) =@_;
	my $var;
	unless( $pogovar ) {
		tie $var, $class;
	} elsif( my $tiedobj = Pogo::tied_object($pogovar) ) {
		tie $var, $class, $class->new($tiedobj);
	} else {
		croak "Pogo variable required";
	}
	if( $blessclass ) {
		tied($var)->set_class($blessclass);
		bless \$var, $blessclass;
	}
	\$var;
}
# tie $var, 'Pogo::Scalar' [,$obj];
sub TIESCALAR {
	my($class, $obj) = @_;
	my $self;
	unless( $obj ) {
		$self = $class->new;
	} elsif( ref($obj) eq $class ) {
		$self = $obj;
	} else {
		croak "$class object required";
	}
	$self;
}
sub FETCH { Pogo::wrap($_[0]->get); }
sub STORE { $_[0]->set(Pogo::strip($_[1])); }

package Pogo::Array;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(Pogo::Var);
# $ref = new_tie Pogo::Array [,$size, $pogovar, $blessclass];
sub new_tie {
	my($class, $size, $pogovar, $blessclass) = @_;
	my @var;
	unless( $pogovar ) {
		tie @var, $class, $size;
	} elsif( my $tiedobj = Pogo::tied_object($pogovar) ) {
		tie @var, $class, $class->new($size, $tiedobj);
	} else {
		croak "Pogo variable required";
	}
	if( $blessclass ) {
		tied(@var)->set_class($blessclass);
		bless \@var, $blessclass;
	}
	\@var;
}
# tie @array, 'Pogo::Array' [,$size_or_obj];
sub TIEARRAY { 
	my($class, $size_or_obj) = @_;
	my $self;
	unless( $size_or_obj ) {
		$self = $class->new;
	} elsif( $size_or_obj =~ /^\d+$/ ) {
		$self = $class->new($size_or_obj);
	} elsif( ref($size_or_obj) eq $class ) {
		$self = $size_or_obj;
	} else {
		croak "size or $class object required";
	}
	$self;
}
sub FETCH  {  Pogo::wrap($_[0]->get($_[1])); }
sub STORE  {  $_[0]->set($_[1], Pogo::strip($_[2])); }
sub FETCHSIZE {  $_[0]->get_size; }
sub STORESIZE {  $_[0]->set_size($_[1]); }
sub EXTEND {  $_[0]->set_size($_[1]); }
sub CLEAR  {  $_[0]->clear; }
sub PUSH   {  $_[0]->push(Pogo::strip($_[1])); }
sub POP    {  Pogo::wrap($_[0]->pop); }
sub SHIFT  {  Pogo::wrap($_[0]->remove(0)); }
sub UNSHIFT {  $_[0]->insert(0, Pogo::strip($_[1])); }
sub splice {
	my($self, $pos, $len, @list) = @_;
	my($alllen, @result);
	$alllen = $self->get_size;
	$pos += $alllen if $pos < 0;
	$pos = 0 if $pos < 0;
	$pos = $alllen if $pos > $alllen;
	$len = 0 if $len < 0;
	$len -= $pos + $len - $alllen if $pos + $len > $alllen;
	while( $len-- > 0 ) { push @result, Pogo::wrap($self->remove($pos)); }
	for(reverse @list) { $self->insert($pos, Pogo::strip($_)); }
	\@result;
}
sub SPLICE { @{$_[0]->call(\&splice, \@_)}; }
# raw utility subroutines
sub getvalues { @{$_[0]->call(\&_getvalues, \@_)}; }
sub _getvalues {
	my $self = shift;
	my @result = $self->get_size ? map {$self->get($_)} (0..$self->get_size-1) :
		();
	\@result;
}
sub exists { $_[0]->call(\&_exists, \@_); }
sub _exists {
	my($self, $value) = @_;
	return unless defined $value;
	return unless $self->get_size;
	if( UNIVERSAL::isa($value, 'Pogo::Var') ) {
		for(0..$self->get_size-1) {
			return 1 if $value->equal($self->get($_));
		}
	} else {
		for(0..$self->get_size-1) {
			return 1 if $value eq $self->get($_);
		}
	}
}
sub add { $_[0]->call(\&_add, \@_); }
sub _add {
	my($self, $value) = @_;
	return unless defined $value;
	return if $self->_exists($value);
	$self->push($value);
	1;
}
sub delete { $_[0]->call(\&_delete, \@_); }
sub _delete {
	my($self, $value) = @_;
	return unless defined $value;
	return unless $self->get_size;
	if( UNIVERSAL::isa($value, 'Pogo::Var') ) {
		for(0..$self->get_size-1) {
			$self->remove($_),return $value if $value->equal($self->get($_));
		}
	} else {
		for(0..$self->get_size-1) {
			$self->remove($_),return $value if $value eq $self->get($_);
		}
	}
}

package Pogo::Harray;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(Pogo::Array);
sub FETCH  { 
	my($self, $arg) = @_;
	my $class;
	if( $arg == 0 && ($class = $self->get_class) && $class->can('FIELDHASH') ) {
		$class->FIELDHASH;
	} else {
		Pogo::wrap($self->get($arg)); 
	}
}

package Pogo::Hash;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(Pogo::Var);
# $ref = new_tie Pogo::Hash [,$size, $pogovar, $blessclass];
sub new_tie {
	my($class, $size, $pogovar, $blessclass) = @_;
	my %var;
	unless( $pogovar ) {
		tie %var, $class, $size;
	} elsif( my $tiedobj = Pogo::tied_object($pogovar) ) {
		tie %var, $class, $class->new($size, $tiedobj);
	} else {
		croak "Pogo variable required";
	}
	if( $blessclass ) {
		tied(%var)->set_class($blessclass);
		bless \%var, $blessclass;
	}
	\%var;
}
# tie %hash, 'Pogo::Hash', [,$size_or_obj];
sub TIEHASH {
	my($class, $size_or_obj) = @_;
	my $self;
	unless( $size_or_obj ) {
		$self = $class->new;
	} elsif( $size_or_obj =~ /^\d+$/ ) {
		$self = $class->new($size_or_obj);
	} elsif( ref($size_or_obj) eq $class ) {
		$self = $size_or_obj;
	} else {
		croak "size or $class object required";
	}
	$self;
}
sub FETCH  { Pogo::wrap($_[0]->get($_[1])); }
sub STORE  { $_[0]->set($_[1], Pogo::strip($_[2])); }
sub EXISTS { $_[0]->exists($_[1]); }
sub DELETE { $_[0]->remove($_[1]); }
sub CLEAR  { $_[0]->clear; }
sub FIRSTKEY { $_[0]->first_key; }
sub NEXTKEY  { $_[0]->next_key($_[1]); }
# raw utility subroutines
sub getkeys { @{$_[0]->call(\&_getkeys, \@_)}; }
sub _getkeys {
	my $self = shift;
	my @result;
	for(my $key = $self->first_key; defined $key; $key = $self->next_key($key)){
		push @result, $key;
	}
	\@result;
}
sub getvalues { @{$_[0]->call(\&_getvalues, \@_)}; }
sub _getvalues {
	my $self = shift;
	my @result;
	for(my $key = $self->first_key; defined $key; $key = $self->next_key($key)){
		push @result, $self->get($key);
	}
	\@result;
}

package Pogo::Htree;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(Pogo::Hash);

package Pogo::Btree;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(Pogo::Hash);
# $ref = new_tie Pogo::Btree [, $pogovar, $blessclass];
sub new_tie {
	my($class, $pogovar, $blessclass) = @_;
	my %var;
	unless( $pogovar ) {
		tie %var, $class;
	} elsif( my $tiedobj = Pogo::tied_object($pogovar) ) {
		tie %var, $class, $class->new($tiedobj);
	} else {
		croak "Pogo variable required";
	}
	if( $blessclass ) {
		tied(%var)->set_class($blessclass);
		bless \%var, $blessclass;
	}
	\%var;
}
# tie %hash, 'Pogo::Btree' [,$obj];
sub TIEHASH {
	my($class, $obj) = @_;
	my $self;
	unless( $obj ) {
		$self = $class->new;
	} elsif( ref($obj) eq $class ) {
		$self = $obj;
	} else {
		croak "$class object required";
	}
	$self;
}

package Pogo::Ntree;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(Pogo::Btree);

package Pogo::SNArray;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(Pogo::Var);
# $ref = new_tie Pogo::SNArray [,$size, $pogovar, $blessclass];
sub new_tie {
	my($class, $size, $pogovar, $blessclass) = @_;
	my @var;
	unless( $pogovar ) {
		tie @var, $class, $size;
	} elsif( my $tiedobj = Pogo::tied_object($pogovar) ) {
		tie @var, $class, $class->new($size, $tiedobj);
	} else {
		croak "Pogo variable required";
	}
	if( $blessclass ) {
		tied(@var)->set_class($blessclass);
		bless \@var, $blessclass;
	}
	\@var;
}
# tie @array, 'Pogo::SNArray' [,$size_or_obj];
sub TIEARRAY { 
	my($class, $size_or_obj) = @_;
	my $self;
	unless( $size_or_obj ) {
		$self = $class->new;
	} elsif( $size_or_obj =~ /^\d+$/ ) {
		$self = $class->new($size_or_obj);
	} elsif( ref($size_or_obj) eq $class ) {
		$self = $size_or_obj;
	} else {
		croak "size or $class object required";
	}
	$self;
}
sub FETCH  {  $_[0]->get($_[1]); }
sub STORE  {  $_[0]->set($_[2]); } # index $_[1] not used
sub FETCHSIZE {  $_[0]->get_size; }
sub STORESIZE {  $_[0]->set_size($_[1]); }
sub EXTEND {  $_[0]->set_size($_[1]); }
sub CLEAR  {  $_[0]->clear; }
# raw utility subroutines
sub getvalues { @{$_[0]->call(\&_getvalues, \@_)}; }
sub _getvalues {
	my $self = shift;
	my @result = $self->get_size ? map {$self->get($_)} (0..$self->get_size-1) :
		();
	\@result;
}
sub exists { $_[0]->find($_[1]) >= 0; }
sub add { $_[0]->ins($_[1]); }
sub delete { $_[0]->del($_[1]); }

package Pogo;

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Pogo - Perl GOODS interface

=head1 SYNOPSIS

  use Pogo;

  $pogo = new Pogo 'sample.cfg';  # connect to a database
  $root = $pogo->root_tie;        # get a reference to root hash in the database
  
  $root->{key1} = "string";       # store a string into the database
  $value = $root->{key1};         # $value is "string"
  
  $root->{key2} = [1,2,3];        # store a array into the database
  $arrayref = $root->{key1};      # get a reference to the array in the database
  $value = $root->{key2}->[0];    # $value is 1
  
  $root->{key3} = {a=>1,b=>2};    # store a hash into the database
  $hashref = $root->{key3};       # get a reference to the hash in the database
  $value = $root->{key3}->{b};    # $value is 2
  
  $root->{key4} = new Pogo::Btree;# make a B-tree hash
  $hashref = $root->{key5};       # B-tree is accessed as hash
  
  $root->{key5} = new Pogo::Htree;# make a H-tree(see below) hash
  $hashref = $root->{key6};       # H-tree is accessed as hash
  
  $root->{key6} = new Aclass;     # store a object into the database
  $obj = $root->{key4};           # $obj is a Aclass object in the database


=head1 DESCRIPTION

=head2 Overview

Pogo is a Perl interface of GOODS (Generic Object Oriented Database System).
Pogo maps Perl's scalars, arrays, hashes and objects directly to the database 
objects. Pogo has the data types as follows.

  - scalar
  - array
  - hash
  - B-tree
  - H-tree (hash that hash entry table is placed as B-tree)
  - N-tree (same as B-tree but key is treated as number)

The value of a scalar data or an element of a collection type data is a 
string or a reference to another data. Pogo uses Perl's tieing mechanism and
provide transparent accessibility to persistent data in the database. Each 
data in the database can have class name string internally, so Perl objects
(i.e. reference which is blessed by a class name) can be stored in the 
database.

=head2 GOODS server

GOODS which is the base of Pogo is a client-server type database. A Pogo 
application needs a running GOODS server process in the same machine or 
another machine which is connected with TCP/IP network. The GOODS server
program is 'goodsrv' which is installed in /usr/local/goods/bin/.
The Pogo application and the corresponding goodsrv must use the same TCP
port to communicate with each other, so both use the same configuration file
which specifies goodsrv's hostname and TCP port number. The configuration 
file must have a filename extension '.cfg'. Typical configuration file for 
a local goodsrv as follows. 

  1
  0: localhost:6100

The '1' at the first line means that this database uses one goodsrv (two or 
more goodsrv's are available but Pogo uses always one). The '0: localhost:6100'
at the second line means that first goodsrv is at localhost and uses port
number 6100. 

If this configuration file is saved as 'test.cfg', goodsrv can be executed
as follows.

  goodsrv test

And the goodsrv creates a set of database files as follows. You must NOT 
delete or edit directly these database files.

  test.his
  test.idx
  test.log
  test.map
  test.odb

The running goodsrv waits commands from your console while providing database 
services through the specified TCP port. You can see the database statistics 
or backup the database by sending commands to the running goodsrv. See 
readme.htm of GOODS.

For practical use, goodsrv will be executed as a background process.
Pogo has two utility scripts for starting goodsrv at the background and 
sending commands to the goodsrv. To start goodsrv with test.cfg, type:

  startgoodsrv test &

This goodsrv's outputs are saved in test.goodsrv.log.
And to terminate the goodsrv, type:

  cmdgoodsrv test exit

=head2 Tie interface

=over 4

=item B<Connect>

First of all, connect to a running GOODS server.

  $pogo = new Pogo $cfgfilename;

The $cfgfilename is a configuration filename which specifies GOODS server. 
The gotten Pogo object will be used after.

=item B<Get root>

Then, get a hash reference to the root B-tree data in the database.

  $root = $pogo->root_tie;

NOTE: A persistent data in a GOODS database must be refered by another
persistent data. If a data is not refered by another persistent data, it will
be recovered by the GOODS garbage collection system. It means that at least 
one absolutely persistent data is necessary in each database. Such data is 
called 'root'. Pogo database's root is a B-tree data. The root_tie method
returns a hash reference to the root B-tree data in the database.

=item B<String and number>

To store a data into the database, simply assign a perl data through $root.
Note that $root is a hash reference.

  $root->{key} = "value";
  $root->{pi} = 3.14;

NOTE: Data value strings in the Pogo database can include null character 
("\x00"). But hash key strings in the Pogo database cannot include null 
character.

NOTE: The number 3.14 is stored as string "3.14" in the database. (This data
conversion is an overhead. In the future revision of Pogo, it will be stored
as number.)

Now, you can get the values of the data in the database.

  $value = $root->{key};  # $value is "value"
  $pi = $root->{pi};      # $pi is "3.14"

=item B<Array and hash>

To store an array or a hash, assign its reference.

  $root->{key1} = \@array;
  $root->{key2} = [1,2,3];
  $root->{key3} = \%hash;
  $root->{key4} = {a=>1,b=>2,c=>3};
  $root->{key5} = {a=>[1,2],b=>{c=>3,d=>4}};

Note that these assignments cause storing the contents of the array or hash 
into the database, not only the reference. Because a persistent data in a 
database cannot refer to a non persitent (i.e. only on memory) data. That is
to say, the array or hash is copied into the database and its reference is
assigned. In the above example, changing @array or %hash after assignment 
does not change the array of $root->{key1} or the hash of $root->{key3}.

To fetch the value, normally use ->,[],{}'s.

  $value = $root->{key5}->{a}->[1];  # $value is 2
  $value = $root->{key5}{a}[1];      # -> between {} or [] can be omitted

If the specfied value is a reference to another data in the database, an 
appropriate type reference is returned. You can use such references to store
into and fetch from the database.

  $hashref = $root->{key4};     # get a hash reference in the database
  $hashref->{d} = 4;            # store a data
  $value = $hashref->{c};       # $value is 3

NOTE: A CODE or IO reference cannot be stored into the database.

=item B<Array size>

Pogo's array is automatically enlarged when needed. But the enlargement causes
reassignment of the data in the database. 
When an array reference is assigned, the array size in the database is set to
the size of the assigned array. If you can estimate the maximum array
size, setting the array size beforehand is recommended.
To make a specified size array, use Pogo::Array::new method.

  $root->{sqrt} = new Pogo::Array 1000;
  for(0..999) { $root->{sqrt}->[$_] = sqrt $_; }

=item B<Hash size>

Pogo's hash has a static size hash entry table and cannot resize it. 
Note that the hash entry table size does not limit numbers of stored keys.
But if too many keys against the hash entry table size are stored into a Pogo's 
hash, it will slow down. So choose appropriate hash entry table size for your
purpose of using hash. (In the future revision of Pogo, automatic hash 
resizing will be supported.)
When a hash reference is assigned, the hash entry table size in the database
is set to it of the assigned hash.
To make a hash of specified hash entry table size, use Pogo::Hash::new method.

  $root->{smallhash} = new Pogo::Hash 8;
  $root->{largehash} = new Pogo::Hash 1024;

If the size defaults, 256 is used.

=item B<H-tree>

A hash entry table of Pogo's hash is a static size of array, so too large 
table size is not useful. If you want to use very large hash, use H-tree. 
A hash entry table of H-tree is placed as B-tree, so huge size table is 
available.
To make a H-tree hash of specified hash entry table size, use Pogo::Htree::new 
method.

  $root->{hugehash} = new Pogo::Htree 131072;

If the size defaults, 65536 is used.

=item B<B-tree>

Another way to make huge hash is to use B-tree. In B-tree, a hash key itself
is used as B-tree key. So hash keys are sorted automatically. And B-tree has 
no hash entry table size problem. On the other hand, the key indexes of Pogo's 
B-tree is made by the first 8 bytes of the hash key string. So if many keys have 
same first 8 bytes, searching such keys slows down.
To make a B-tree hash, use Pogo::Btree::new method.

  $root->{btree} = new Pogo::Btree;

Note that no size is required.

By the tie interface of Pogo, you cannot search key that partially matches the
specified string. You can do it by Pogo::tied_object function and 
Pogo::Btree::find_key method.

  $foundkey = Pogo::tied_object($root->{btree})->find_key($string);

Pogo::tied_object returns the behind object which is tied to the specified 
data's referent. If $root->{btree} is a B-tree, Pogo::tied_object($root->{btree})
returns a Pogo::Btree object. And Pogo::Btree::find_key method returns a key
string that matches front-partially to the specified string.

=item B<N-tree>

By B-tree, key string is sorted as character string. So '10' is smaller than '2'. By N-tree, key string is sorted as long integer. So '2' is smaller than '10'. Except this feature, N-tree is same as B-tree.

  $root->{ntree} = new Pogo::Ntree;

=item B<Object>

A Perl object which uses only SCALAR/ARRAY/HASH references can be stored into
the database.

  sub Foo::new { bless {name => $_[1]}, $_[0]; }
  sub Foo::name { $_[0]->{name}; }
  $root->{obj} = new Foo "bar";
  $obj = $root->{obj};            # $obj is a Foo object
  $name = $obj->name;             # $name is "bar"

If you want to set hash entry table size or use H-tree or B-tree for a object, 
use Pogo::Hash::new_tie, Pogo::Htree::new_tie or Pogo::Btree::new_tie method.

  sub Bar::new {
      my($class, $name) = @_;
      my $self = new_tie Pogo::Htree 10000;
      $self->{name} = $name;
      bless $self, $class;
  }

Note that a class using Pogo::*::new_tie is only for using with Pogo database.

=item B<Transaction>

Pogo has a transaction mechanism. If there is a sequence of operations with a 
database and you want to make it atomic, use transaction mechanism.
The term 'atomic' means that the sequence of operations are all done 
successfully or nothing is done. It means also that another database client
cannot interrupt the sequence.

To make a per database transaction, use Pogo::begin_transaction, 
Pogo::abort_transaction and Pogo::end_transaction methods.

  $root->{key} = 1;
  
  $pogo->begin_transaction;
  $root->{key} = 2;
  $pogo->abort_transaction;    # abort: cancel above assignment
  $value = $root->{key};       # $value is 1
  
  $pogo->begin_transaction;
  $root->{key} = 3;
  $pogo->end_transaction;      # end: above assignment is valid
  $value = $root->{key};       # $value is 3

Note that these methods must be called through a concrete Pogo object. Calling
as class method is not available.

This transaction locks a whole database. So a long time transaction lowers 
concurrent database access performance. 

To make a per data transaction, use Pogo::atomic_call method.

  $root->{key} = \@array;
  Pogo::atomic_call(\&sortarray, $root->{key});
  sub sortarray { my $aref = shift; @$aref = sort @$aref; }

While calling sortarray, $root->{key} is locked. So another databse 
client cannot disturb the sorting. And the sorting is done without halfway 
fail.

An abortion by the user is not supported for a per data transaction.

=item B<Passive action>

If you need a script which watches a data in the database and does some jobs 
when the data is modified by another database client, use Pogo::wait_modification
function.

  $result = Pogo::wait_modification($root->{key}, 5);

When this sentence is executed, execution stops until the data $root->{key} is 
modified by another database client or 5 seconds passes. $result is 1 by data
modification, 0 by timeout.

If the timeout seconds defaults, it waits forever.

=back

=head2 Database browser

Pogo has a database browsing script 'browse'. To browse the database of 
test.cfg, type:

  browse test

Then browse displays as follows and wait for your command.

  test.cfg opened
  root=(HASH(Btree)(10000))>

Type 'ls' to list the root B-tree hash contents. It displays as follows for 
example. For a reference to another data, it displays class name, data type and 
object id.

  {aobj} = Aclass(HASH(Hash)(1012d))
  {index} = (HASH(Btree)(10282))
  {list} = (ARRAY(10036))
  {name} = "test"

Type 'cd index' to change current data to $root->{index}. Then the prompt is
changed as follows for example.

  root{index}=(HASH(Btree))>

Type 'cd' to return root. Type 'cd ..' to change to parent. And type 'exit' to
terminate browse.

=head2 Methods

All but indicated as 'class method' are object methods. The symbol [] means 
optional argument.

=over 4

=item $pogo = Pogo->new [config_filename]

Class method. This makes and returns a Pogo object. If specified 
config_filename, connect to the running GOODS server which is specified 
by config_filename. The corresponding GOODS server must be already running.

=item $pogo->open config_filename

If a Pogo object does not connect to the GOODS server yet, this method does it.

=item $pogo->close

This disconnects to the GOODS server. You may not use this method, because it is 
called when the Pogo object is destroyed automatically.

=item $pogo->opened

Returns 1 for already opened $pogo or 0 for not opened.

=item $pogo->root

This makes and returns a Pogo::Btree object corresponding to the root B-tree.

=item $pogo->root_tie

This makes and returns a reference to a hash which is tied to a Pogo::Btree 
object corresponding to the root B-tree.

=item $pogo->begin_transaction

This starts a database global transacion.

=item $pogo->abort_transaction

This aborts the transacion which was started by Pogo::begin_transaction.

=item $pogo->end_transaction

This ends the transacion which was started by Pogo::begin_transaction.

=item $obj = Pogo::Scalar->new [pogoobj]

Class method. Makes and returns a Pogo::Scalar object. 
If Pogo::* object pogoobj is specified and it is already attached to a database,
the created object is attached to the same database.

=item $scalarref = Pogo::Scalar->new_tie [pogovar ,class]

Class method. Makes a Pogo::Scalar object and ties a scalar to it and returns 
a reference to the tied scalar. 
If reference variable pogovar is specified and it is already attached to a 
database, the created object is attached to the same database.
If class name class is specified, the reference is blessed by the class.

=item $obj = Pogo::Array->new [size ,pogoobj]

Class method. Makes and returns a Pogo::Array object of specified size. 
If size defaults, 0 is used. 
If Pogo::* object pogoobj is specified and it is already attached to a database,
the created object is attached to the same database.

=item $arrayref = Pogo::Array->new_tie [size ,pogovar ,class]

Class method. Makes a Pogo::Array object of specified size and ties a array to 
it and returns a reference to the tied array.
If size defaults, 0 is used.
If reference variable pogovar is specified and it is already attached to a 
database, the created object is attached to the same database.
If class name class is specified, the reference is blessed by the class.

=item $obj = Pogo::Hash->new [size ,pogoobj]

Class method. Makes and returns a Pogo::Hash object of specified hash 
entry table size. 
If size defaults, 256 is used.
If Pogo::* object pogoobj is specified and it is already attached to a database,
the created object is attached to the same database.

=item $hashref = Pogo::Hash->new_tie [size ,pogovar ,class]

Class method. Makes a Pogo::Hash object of specified hash 
entry table size and ties a hash to it and returns a reference to the tied
hash. If size defaults, 256 is used.
If reference variable pogovar is specified and it is already attached to a 
database, the created object is attached to the same database.
If class name class is specified, the reference is blessed by the class.

=item $obj = Pogo::Htree->new [size ,pogoobj]

Class method. Makes and returns a Pogo::Htree object of specified hash 
entry table size. 
If size defaults, 65536 is used.
If Pogo::* object pogoobj is specified and it is already attached to a database,
the created object is attached to the same database.

=item $hashref = Pogo::Htree->new_tie [size ,pogovar ,class]

Class method. Makes a Pogo::Htree object of specified hash 
entry table size and ties a hash to it and returns a reference to the tied
hash. If size defaults, 65536 is used.
If reference variable pogovar is specified and it is already attached to a 
database, the created object is attached to the same database.
If class name class is specified, the reference is blessed by the class.

=item $obj = Pogo::Btree->new [pogoobj]

Class method. Makes and returns a Pogo::Btree object. 
If Pogo::* object pogoobj is specified and it is already attached to a database,
the created object is attached to the same database.

=item $hashref = Pogo::Btree->new_tie [pogovar ,class]

Class method. Makes a Pogo::Btree object and ties a hash to it and returns a 
reference to the tied hash.
If reference variable pogovar is specified and it is already attached to a 
database, the created object is attached to the same database.
If class name class is specified, the reference is blessed by the class.

=item $obj = Pogo::Ntree->new [pogoobj]

Class method. Makes and returns a Pogo::Ntree object. 
If Pogo::* object pogoobj is specified and it is already attached to a database,
the created object is attached to the same database.

=item $hashref = Pogo::Ntree->new_tie [pogovar ,class]

Class method. Makes a Pogo::Ntree object and ties a hash to it and returns a 
reference to the tied hash.
If reference variable pogovar is specified and it is already attached to a 
database, the created object is attached to the same database.
If class name class is specified, the reference is blessed by the class.

NOTE: An object created by these Pogo::*::new and Pogo::*::new_tie is on the 
memory, not yet persistent. When it is refered by a existing persistent 
data in a database, it becomes persistent. When Pogo object is specified as 
an argument, the gotten object is attached to the database, but it is not yet 
persistent too. 

=back

=head2 Utility functions

=over 4

=item Pogo::type_of

This returns an array of reference type, class name, tied class name of the 
specfied data.

  ($reftype, $class, $tiedclass) = Pogo::type_of($root->{key});

Typical return values are:

  () : not a reference
  ('ARRAY', '', 'Pogo::Array') : an array
  ('HASH', '', 'Pogo::Btree') : a B-tree hash
  ('HASH', 'Aclass', 'Pogo::Hash') : an Aclass object

=item Pogo::tied_object

This returns a Pogo::* object which is tied to the referent of the specified 
Pogo data.

=item Pogo::equal

This requires two arguments of Pogo data and returns 1 if its datatabase objects are same, 0 if different.

=item Pogo::object_id

This returns a database object id of the specified Pogo data.

=item Pogo::atomic_call

This calls the specified function atomicly and returns its return value.

  $result = Pogo::atomic_call(\&func, $data, @args);

The first argument \&func is a reference to a subroutine. The second argument 
$data is a Pogo data. This data is locked between calling. This is same as 
below exept the locking.

  $result = func($data, @args);

The func is called in a scalar context, and returned value is convert to a 
integer number.

=item Pogo::wait_modification

This waits the modification of the specified data by another database client 
until the specified seconds passes. And returns 1 by data modification, 0 by
timeout.

  $result = Pogo::wait_modification($data, $sec);

If the timeout seconds defaults, it waits forever.

=item Pogo::get_root_tie

This function takes one reference argument which refer to a database data and 
returns the hash reference to the root B-tree in the database.

  $root = Pogo::get_root_tie($pogovar);

=back

=head2 Low level (non-tie) interface

The tie interface of Pogo is very convenient. But it causes much overheads. If 
you want to construct large and complex database application by Pogo, using 
low level (non-tie) interface is recommended.

For exmple, as follows by tie interface:

  $root = $pogo->root_tie;    # $root is a hash reference
  $root->{key} = "value";
  $value = $root->{key};      # $value is "value"

It is same as follows by low level interface:

  $root = $pogo->root;        # $root is a Pogo::Btree object
  $root->set(key => "value");
  $value = $root->get('key'); # $value is "value"

=head2 Low level classes and methods

These low level classes and methods below are used by tie interaface 
internally and you can use its directly.

=over 4

=item Pogo::Var

Pogo::Var is a abstract base class of all Pogo::* classes below. No Pogo::Var 
object is available.

  Pogo::Var::get_class
  Pogo::Var::set_class
  Pogo::Var::begin_transaction
  Pogo::Var::abort_transaction
  Pogo::Var::end_transaction
  Pogo::Var::root
  Pogo::Var::root_tie
  Pogo::Var::call
  Pogo::Var::equal
  Pogo::Var::wait_modification
  Pogo::Var::object_id

=item Pogo::Scalar

  Pogo::Scalar::get
  Pogo::Scalar::set

=item Pogo::Array

  Pogo::Array::get
  Pogo::Array::set
  Pogo::Array::get_size
  Pogo::Array::set_size
  Pogo::Array::clear
  Pogo::Array::push
  Pogo::Array::pop
  Pogo::Array::insert
  Pogo::Array::remove

=item Pogo::Hash

  Pogo::Hash::get
  Pogo::Hash::set
  Pogo::Hash::exists
  Pogo::Hash::remove
  Pogo::Hash::clear
  Pogo::Hash::first_key
  Pogo::Hash::next_key

=item Pogo::Htree

  Pogo::Htree::get
  Pogo::Htree::set
  Pogo::Htree::exists
  Pogo::Htree::remove
  Pogo::Htree::clear
  Pogo::Htree::first_key
  Pogo::Htree::next_key

=item Pogo::Btree, Pogo::Ntree

These methods below are same in Pogo::Ntree.

  Pogo::Btree::get
  Pogo::Btree::set
  Pogo::Btree::exists
  Pogo::Btree::remove
  Pogo::Btree::clear
  Pogo::Btree::first_key
  Pogo::Btree::last_key
  Pogo::Btree::next_key
  Pogo::Btree::prev_key
  Pogo::Btree::find_key

=back

=head2 Deriving low level classes and hooking methods 

You can derive low level classes and override some methods. Instead of entire 
overriding, Pogo provides a hook mechanism for low level methods.

For example if you want to hook Pogo::Array::set method, do:

  # MyArray.pm
  package MyArray;
  @ISA = qw(Pogo::Array);
  %HOOK = (set => \&set_hook);  # hook set() method by set_hook()
  sub set_hook {
    my($self, $idx, $value) = @_;
    do_something($self, $idx, $value);
    1;     # if returns false, original method not called
  }
  ...
  1;

Then do:

  use MyArray;
  $obj = new MyArray;
  $obj->set(0, "value"); # set_hook($obj, 0, "value") and Pogo::Array::set($obj, 0, "value")


=head1 AUTHOR

Sey Nakajima <nakajima@netstock.co.jp>

=head1 SEE ALSO

readme.htm of GOODS

=cut
