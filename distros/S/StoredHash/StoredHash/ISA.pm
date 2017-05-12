=head1 NAME

StoredHash::ISA - Allow Object to be-a StoredHash by automatically inheriting persistence abilities.

=head1 DESCRIPTION

StoredHash::ISA allows to create an IS-A (ISA in Perl lingo) relationship between any object class
and StoredHash persister. This allows you to call StoredHash methods directly via instance
(or as Class methods where appropriate).

Because StoredHash::ISA bases persistence operations on class introspection, the persisted
objects must belong to a class package and not be "plain" HASHes (You'd use StoredHash).
Even when some methods are overloaded to work as Instance or class methods, the Objects
must be blessed.

Using StoredHash::ISA as a base class allows you to use following persistence methods

=over 4

=item * insert()  - as instance method

=item * update()  - as instance method

=item * load()    - as class method

=item * loadset() - as class method

=item * delete() - as instance method - or class method

=item * exists() - as class method

=item * reload() - StoredHash::ISA custom instance method to reload instance from db

=back

=cut
# Stripped
# insert  (or class method)
# update   (or class method)
# load (or instance method to "reload")
# exists  (or instance method)
=pod

The ways of using methods (class vs. instance) above.
Perl generally allows class methods (i.e. non-instance methods) to be called with two syntaxes
(with major underlying differences):

   ThePack::a_method()
   # And
   ThePack-> a_method()

All StoredHash::ISA class methods (as listed above) need to be called using ThePack-> a_method() (this is related to
giving framework a hint about objects type).

=head1 SYNOPSIS

Package wanting to be-a persister:

   {
     package Justanother::Object;
     # Inherit persister methods
     # our @ISA = ('StoredHash::ISA'); # Or more by more modern style ...
     use base ('StoredHash::ISA');
     # Must declare 
     our $shp = {'table' => 'another', 'pkey' => ['id'], 'autoid' => 1,}
     # Custom functionality ... methods as usual
     
   }

using the class ...

   my $o = Justanother::Object->new('prop' => 'The Value',);
   my $id = $o->insert();
   
   # Load object
   my $o = Justanother::Object->load([46]);
   # Load related children (blessed automatically)
   my $o->{'items'} = Justanother::Object::Children->loadset({'parent' => 46});
   
   # Setting up Your inheriting class-package for persistence
   {
     package Justanother::Object;
   
     our $shp = {'table' => 'anotherobj', ...};
     use base 'StoredHash::ISA'; # Same as our @ISA = ('StoredHash::ISA');
   }

=cut

# package Justanother::Object;
# At import Tweak (bless) our $shp of requesting class  
# use Storedhash;
# use Storedhash::ISA;
# our @ISA = ('StoredHash::ISA');

# This only puts one more burden on the application - hashes must always be blessed hashes -
# not plain
# unblessed ones. On the other hasn when they are retrieved from DB with autoconnected methods:
# - 
# -
# They will always be automatically blessed.
# The scenario that you have to watch for is when getting a raw hash from Desktop app or Web form in
# unblessed, form - it must be blessed to class before calling methods via it. 


# DEV:
# Whatever way the persistence is implemented The StoredHash or StoredHash::ISA Must somehow get to
# know what persister to use

# Using original StoredHash methods (Benefit-no new classes):
# sub insert {
# my ($p, $h) = @_;
# if (($c = ref($p)) ne 'StoredHash') {
#	$h = $p; # Make Calling abject THE hash
#	# Lookup persister from "Class Table"
#   $p = $StoredHash::clt->{$c};
#   # OR Class itself !!!
#   $p = ${"$c"}::shp;
#}
# ...
#}

# Implement _relevant_methods of

#our @ISA
package StoredHash::ISA;
use StoredHash;
# blessed gets the ...
use Scalar::Util('reftype','blessed');
use strict;
use warnings;

use Data::Dumper;
our $debug = 0;
our $VERSION = '0.30';
$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 1;
# Cache Mapping from classes to persister (to avoid lookup to the class itself)
# The internal import-time boot() -method registers classes in here.
my $clt = {};
our @methods  = ('insert','update','delete','load','loadset','exists',);
# Safe methods (no 'delete' and 'exists') 
our @safemethods  = ('insert','update','load','loadset',);

# Perl standard import method for StoredHash::ISA.
# This is auto-triggered when class loads StoredHash::ISA by "use StoredHash::ISA;".
# This calls boot() to carry out some of the setup.
sub import {
   my ($cl) = @_;
   my @ci = caller(0);
   if ($debug) {print(STDERR Dumper(\@ci));}
   no strict 'refs';
   # Grab $shp from callers package
   # TODO: Convert to symbol table lookup
   my $ssym = "$ci[0]\:\:shp";
   my $shp = ${$ssym}; # eval('$'.$ci[0].'::shp'); # 
   #DEBUG:print("#$ssym#\n");print(Dumper($shp));
   #if (!$shp) {$shp = '';} # undef does not work for strict/warnings
   # TODO: Use reftype()
   if (!$shp) {die("No persister info for package '$ci[0]'");}
   if (reftype($shp) ne 'HASH') {die("Persister info for package '$ci[0]' NOT in a HASH ($shp)");}
   #StoredHash::validate($shp); # Throws errors
   boot($shp,  $ci[0]); # 'class' =>
   if ($debug) {print(Dumper($shp));}
   if ($debug) {print("CLT ".Dumper($clt));}
}

#=head2 boot($shp, $class)

# Bootstrap StoredHash configuration embedded into the class loading the StoredHash::ISA.
#
#=item * Make sure the StoredHash config-declaration (with 'table', 'pkey' ...) is blessed to StoredHash
#=item * Attach / import methods to original class
#=item * Register class to class-to-persister mapping table maintained here.
#=cut
sub boot {
   my ($shp, $c) = @_; # %c
   if (!blessed($shp)) {bless($shp, 'StoredHash');}
   $shp->{'class'} = $c; # Force class = $class
   # Methods OR safemethods
   # NOTE: This should be optional as @ISA method dispatching takes care of this.
   map({eval("*${c}::$_ =  \\&StoredHash::ISA::$_");} @methods); # $c{'class'}
   $clt->{$c} = $shp; # $c{'class'}
   
}

=head1 METHODS

Implementations as distinct instance methods

=head2 my ($id) = $e->insert(%opts)

Insert an instance of a class to database.
Return id(s) as a array / list (real array that is).

=cut
sub insert {
   my ($h, %c) = @_;
   my $c;
   # Called as class method. Allow this somewhat ugly overloading ?
   if (reftype($h) ne 'HASH') {
     ($c, $h, %c) = @_;
     #die("StoredHash::ISA: Only works with hash Objects");
   }
   else {$c = blessed($h);}
   my $p = $clt->{$c};
   # Ensure this is a StoredHash $p->isa('StoredHash');
   if (!$p) {die("Persister not resolved for '$c'");}
   return $p->insert($h, %c);
}
# OLD:
# Probe caller() to to insert / update 
# Swap the roles of $p and $h
# TODO: Allow Class / Inst

=head2 $entry->update($ids)

Update entry in database. Allows using explicit 'attrs' to minimize attributes to be updated.
Return true value on success. Throw exception on failure.

=cut
sub update {
   my ($h, $ids, %c) = @_;
   if (reftype($h) ne 'HASH') {die("StoredHash::ISA: Only works with hash Objects");}
   # Allow entry to contain IDs ? See reload() for example.
   if (!$ids) {}
   if (reftype($ids) ne 'ARRAY') {die("ID not in an ARRAY");}
   my $c = blessed($h);
   my $p = $clt->{$c};
   $p->update($h, $ids, %c);
}

=head2 $entry->delete($ids)

Delete an instance of an entry from DB.
Note that as the persisted version ceases to exist, probably the runtime instance should as well.

   $entry->delete($ids)
   undef($entry);

=cut
# TODO: Allow to work as Class or instance method: MyType->delete();
# TODO: 
sub delete {
   my ($h, $ids, %c) = @_;
   my $c;
   my $isinst = reftype($h) eq 'HASH';
   # Support instance BUT w/o $ids: $e->delete()
   #TODO:if ($isinst && !$ids) {$ids = embedded_ids($p, $e);}
   # Support Class method call: MyType->delete($ids). Re-shuffle stack params slightly.
   # param $_[0] (class) must be found in the class table.
   #TODO:if (!$isinst && $clt->{$_[0]}) {$c = $h;goto ANYDELETE;}
   if (!$isinst) {die("No (hash based) instance (and not a class call)");}
   
   $c = blessed($h); # Declared above to allow stack
   ANYDELETE:
   # Do this validation late (mainly for case Class call)
   if (reftype($ids) ne 'ARRAY') {die("ID(s) not in an ARRAY");}
   my $p = $clt->{$c};
   ##TODO: if (!$ids) {$ids = embedded_ids($p, $e);}
   $p->delete($h, $ids, %c);
   # Ok as Enforced ?
   if ($isinst) {$_[0] = undef;}
}

=head2 $e = MyType->load($ids)

Class Method to load an entry of particular type from DB.
Return (blessed) entry.
 
=cut
# TODO: Consider the usage instance method to "reload") 
sub load {
   my ($c, $ids, %c) = @_;
   #if (reftype($c) eq 'HASH') {}
   my $p = $clt->{$c};
   my $e = $p->load($ids, %c);
   # Is this redundant - entry already blessed ?
   return bless($e, $c);
}
=head2 $e->reload($ids)

Reload entry instance from database.
$ids is optional as long as entry contains the id attribute values.
Return (blessed) entry.

=cut
# TODO: Define the behaviour for setting $_[0] in callstack
sub reload {
   my ($e, $ids, %c) = @_;
   my $c = blessed($e);
   if (!$c) {die("Not a blessed object");}
   my $p = $clt->{$c};
   # No explicit ID, must be in the entry. Discover them.
   if (!$ids) {
      my @pkv = $p->pkeyvals($e);
      my @pka = $p->pkeys();
      if (@pkv ne @pka) {die("ID attrs / vals - not matching");}
      $ids = \@pkv; # Use "discovered" IDs
      #TODO: $ids = embedded_ids($p, $e);
   }
   # This would not overwrite callers instance (assigning to $_[0] will)
   $e = $p->load($ids, %c);
   bless($e, $c);
   $_[0] = $e; # Optional "replace in stack" ?
   return($e);
}

=head2 MyType->loadset($filter, $sortattrs, %opts)

Class method to load a set of entries for a class from the database.

=cut
sub loadset {
   my ($c, $wf, $o) = @_;
   my $p = $clt->{$c};
   if (!$p) {die("No persister for class '$c'");}
   my $arr = $p->loadset($wf, $o);
   # Test autobless config (for class)
   my $abv = "$c\:\:noautobless";
   no strict ('refs');
   # no auto bless - return unblessed
   if (${$abv}) {return($arr);}
   return [map({  bless($_, $c);  } @$arr)];
}

=head2 MyType->exists($ids)

Class method to test if an instance exists in database.
Return true for "does exist", false for "not".

=cut
sub exists {
   my ($c, $ids, %c) = @_;
   my $p = $clt->{$c};
   $p->exists($ids, %c);
}

#=head2 $ids = embedded_ids($shp, $e)
#Try to discover (DB) id(s) for methods that allow leaving out $ids from parameters.
#The discovery must be prefect to be valid.
#Return $ids (as arrayref), throw exception on any failures.
#=cut
sub embedded_ids {
   my ($p, $e) = @_;
   my @pkv = $p->pkeyvals($e);
   my @pka = $p->pkeys();
   if (grep({!$_;} @pkv)) {die("ID:s cannot be empty or have a non-true value.");}
   if (@pkv ne @pka) {die("ID attrs / vals - not matching");}
   return \@pkv; # Use "discovered" IDs
}

1;
