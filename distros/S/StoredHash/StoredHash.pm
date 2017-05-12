=head1 NAME

StoredHash - Minimalistic, yet fairly complete DBI Persister with a definite NoSQL feel to it

=head1 SYNOPSIS

   use StoredHash;
   use DBI;
   use Data::Dumper;
   
   my $dbh = DBI->connect("dbi:SQLite:dbname=/tmp/zoo.db");
   # Lightweight demonstration of StoredHash in action (with SQLite)
   $dbh->do("CREATE TABLE animals (speciesid INTEGER NOT NULL PRIMARY KEY, name CHAR(16), limbcnt INTEGER, family CHAR(16))");
   my $shp = StoredHash->new('table' => 'animals', 'pkey' => ['speciesid'],
      'autoid' => 1, 'dbh' => $dbh, 'debug' => 0);
   # Hash object to be stored
   my $monkey = {'name' => 'Common Monkey', 'limbcnt' => 5, 'family' => 'mammal',};
   
   # Happens to return numeric id (because of auto-increment pkey / autoid)
   my $spid = $shp->insert($monkey);
   print("Created by: id=$spid\n");
   # Load entry
   my $ent = $shp->load([$spid]);
   print("Fetched (by $spid): ".Dumper($ent)."\n");
   # Get: {'name' => 'Common Monkey', 'speciesid' => 469, 'limbcnt' => 5,'family' => 'mammal',}
   # Fix error in entry (don't count tail to be limb)
   $ent->{'limbcnt'} = 4;
   # Update (with some redundant attributes that do not change)
   print("Update $ent->{'speciesid'}\n");
   $shp->update($ent, [$ent->{'speciesid'}]);
   # Could reduce / optimize change to bare minimum:
   my %change = ('limbcnt' => 4);
   print("Reduce property value on $spid\n");
   $shp->update(\%change, [$spid]);
   # Later ... (species dies extinct ?)
   #$shp->delete([$spid]);
   
   # Test if we need to insert / update (based on presence in DB)
   my $id = 5987;
   my $invals = {'name' => 'Crow', 'limbcnt' => 4, 'family' => 'birds'};
   print("Test Presence of Animal '$id'\n");
   if ($shp->exists([$id])) {$shp->update($invals, [$id]);}
   else {$shp->insert($invals);}
   
   ##### Easy loading of sets / collections
   # Load all the animals
   my $animarr = $shp->loadset();
   print("All Animals: ".Dumper($animarr)."\n");
   # Load only mammals (by filter)
   my $mammarr = $shp->loadset({'family' => 'mammal'});
   print("Mammals: ".Dumper($mammarr)."\n");

=head1 DESCRIPTION

Allow DB Persistence operations (insert(), load(), update(), delete(),
exists()) on a plain old hash (unblessed or blessed) without writing
classes, persistence code or SQL.

Optionally StoredHash allows your classes to inherit peristence capability from StoredHash allowing your objects
to call StoredHash persistence methoda via object directly.


=head1 GENERAL INFO ON StoredHash PERSISTENCE

=over 4

=item * Connection is stored in persister. Thus there is no need to pass it as parameter to persister methods.

=item * Composite keys are supported by StoredHash. Because of this id values are passed in array. Id values must
be ordered the same as their attribute names suring construction (as passed in 'pkey' construction parameter).

=item * Some persistence methods support 'attrs' parameter. This means "partial attributes" or "only these attributes" whatever the direction is
persistence operation is. Examples: load(): load only these attributes, update(): update only these attributes, etc.

=item * StoredHash is not validating the hash keys / attribute (or 'attrs' parameter above) against these attributes
actually existing in DB schema. Caller of persistence methods is responsible validating the "fit" of hash to a schema.

=back

Above principles are consistent across persistence methods. These details will be not repeated in method documentation.

=cut

# Maintain a good NoSQL feel with your SQL database.
# ... a good nonrelation relationship

# Author: olli.hollmen@gmail.com
# License: Perl License

# StoredHash needs an OO instance of persister to function.

# TODO: Because insert, update (the vals we want to pers.) are instance specific
# Possibly return an object or bare hash from preparation of ins/upd/del
# With 
# - query
# - vals (to pass to exec)
# - attr (needed ?)
# - Assigned ID ?
#  Make this object w. meth execute() ???? getid()
# http://www.nntp.perl.org/group/perl.dbi.dev/2010/03/msg5887.html
# ANSI X3.135 and ISO/IEC 9075
# ftp://sqlstandards.org/SC32/SQL_Registry/ 

# TODO: Change/Add pkey => idattr @pkv => @idv
# Support Mappings (before storage as separate op ?)
package StoredHash;
use Scalar::Util ('reftype'); # 
use Data::Dumper;
our $hardval = 0; # 1= Call $dbh->do() 2=Return query
use strict;
use warnings;
our $VERSION = '0.031';
# Module extraction config
#our $mecfg = {};
# Instance attributes (create accessors ?)
# Allow 'attr' to act as attr filter
my @opta = ('dbh', 'table','pkey','autoid','autoprobe','simu','errstr',
   'seqname','debug',); # 
# TODO: Support sequence for Oracle / Postgres
# seq_emp.NEXTVAL
my $bkmeta = {
   #'mysql'  => {'iq' => "SELECT LAST_INSERT_ID()",},
   #'Sybase' => {'iq' => "SELECT \@\@identity",},
   'Oracle' => {
      #'iq' => "SELECT \@\@identity",
      'sv' => '%s.NEXTVAL',}, # AS adid SET NOCOUNT OFF
   # Postgres ???
};
# Tentative class-level / static structures:
# persister cache: $shpcache = {}; # Keyed by 'table'
# query cached: $qcache = {}; # Allow prepared and params ? plain K-V or HoH ?
# 
=head1 METHODS

=head2 $shp = StoredHash->new(%opts);

Create new instance of StoredHash Persister.

Keyword parameters in %opts:

=over 4

=item * 'pkey' - array (ref) to reflect the identifying attrtibute(s) of
entry (e.g. single attr for numeric sequential ids, multiple for composite key)

=item * 'dbh' - DBI connection to database (optional). Not passing 'dbh' makes
methods insert/update/load/delete return the SQL query only (as a string)

=back

=cut
sub new {
   my ($class, %opt) = @_;
   my $self = {};
   
   # Generate where by pkey OR use where
   #if ($opt{'where'}) {}
   # Moved for early bless
   bless($self, $class);
   # For Child loading / temp use
   if ($opt{'loose'}) {goto PASSPKEY;}
   if ($opt{'pkey'}) {
      $self->{'pkey'} = $opt{'pkey'};
      # TODO: Do NOT cache WHERE id ...
      $self->{'where'} = whereid($self); # \%opt # join('AND', map({" $_ = ?";} pkeys(\%opt));
   }
   else {die("Need pkey info");}
   PASSPKEY:
   # Validate seq. (Need additional params to note call for seq?)
   #if ($opt{'autoid'} eq 'seq') {
   #   #$c{'seqcall'};
   #}
   # Filter options to self
   @$self{@opta} = @opt{@opta};
   
   return($self);
}

=head2 $shp->errstr($v)

Access error string that method may leave to object.
Notice that many methods throw exception (by die()) with
error message rather than leave it within object.

=cut
sub errstr {
   my ($p, $v) = @_;
   if ($v) {$p->{'errstr'} = $v;}
   $p->{'errstr'};
}

# Internal method for executing query $q by filling placeholders with
# values passed in @$vals.
# Optional $rett (usually not passed) can force a special return type
# Some supported return force tags:
#=item * 'count' - number of entries counted with count(*) query
#=item * 'sth' - return statement handle ($sth), which will be used outside.
#=item * 'hash' - return a hash entry (first entry of resultset)
#=item * 'aoh'  - return array of hashes reflecting result set.
# By default (no $rett) returns the ($ok)value from $sth->execute().
# Also by default statement statement handle gets properly closed
# (If requested return type was $sth, the caller should take care of
# calling $sth->finish()
sub qexecute {
   my ($p, $q, $vals, $rett) = @_;
   my $dbh = $p->{'dbh'};
   my $sth; # Keep here to have avail in callbacks below
   if (!$dbh || $p->{'simu'}) { # 
      local $Data::Dumper::Terse = 1;
      local $Data::Dumper::Indent = 0;
      print(STDERR "SQL($p->{'table'}): $q\nPlaceholder Vals:".Dumper($vals)."\n");
      return(0);
   }
   # Special Return value generators
   # These should also close the statement (if that is not returned)
   my $rets = {
      'count' => sub {my @a = $sth->fetchrow_array();$sth->finish();$a[0];},
      'sth'   => sub {return($sth);},
      'hash'  => sub {my $h = $sth->fetchrow_hashref();$sth->finish();$h;},
      'aoh'   => sub {my $arr = $sth->fetchall_arrayref({});$sth->finish();$arr;},
   };
   # $p->{'errstr'} =return(0);
   if (!$dbh) {die("SHP: No Connection !");}
   if ($p->{'debug'} && $vals) {print("Full Q: $q w. ".scalar(@$vals)." values\n");}
   # Prepare cached ?
   $sth = $dbh->prepare_cached($q); # print("CACHED\n");
   if (!$sth) {die("Query ($q) Not prepared (".$dbh->errstr().")\n");}
   my $ok = $sth->execute(@$vals);
   if (!$ok) {die("Failed to execute\n - Query: $q\n - Vals: ".Dumper($vals)."\n - Message:\n".$sth->errstr()."");}
   # Special return processing.
   # TODO: Suppress Use of uninitialized value $rett in hash element
   if (!$rett) {$rett = '';}
   if (my $rcb = $rets->{$rett}) {
      #print("Special return by $rett ($rcb)\n");
      return($rcb->());
   }
   # Done with statement
   DWS:
   $sth->finish();
   return($ok);
}

###################################################
# Make this the "best-possible" fallback quote when quote() method from driver (via connection)
# is not available. The surrounding quotes are included in the quoted string.
# This aims to be SQL compliant as much as possible
# Need looks like number (will fail sometimes) ?
sub quote {
  my ($s) = @_;
  $s =~ s/\'/\'\'/g;
  $s =~ s/\n/\\n/g;
  "'".$s."'";
}

=head2 $shp->insert($e)

Store entry %$e (hash) inserting it as a new entry to a database.

Returns an array of ID values for the entry that got stored (array
of one element for numeric primary key, multiple for composite key).

=cut
# (ref to)
#Connection has been passed previously in construction of persister.
#The table / schema to store to is either the one passed at
#construction or derived from perl "blessing" of entry ($e).
sub insert {
   my ($p, $e, %c) = @_;
   local $Data::Dumper::Terse = 1;local $Data::Dumper::Indent = 0;
   # No enforced internal validation
   eval {$p->validate();};
   if ($@) {die("Persister validation error: $@");} # $p->{'errstr'} = $@;return(1);
   if (reftype($e) ne 'HASH') {die("Entry needs to be HASH");} # return(2);
   # Explicit attributes. Do not check for ref-valued attributes here.
   # (with an idea that caller must know what it is passing).
   if (my $ats = $c{'attrs'}) {
      if (ref($ats) ne 'ARRAY') {die("Passed 'attrs' must be an array");}
      %$e = map({($_, $e->{$_});} @$ats); # Reconfig $e content.
   }
   # Possibly also test for references (ds branching ?) eliminating them too
   # In case some ARE found, make a copy, eliminate refs and mark copy as $e
   if (grep({ref($e->{$_});} keys(%$e))) {
     # Consider array serialization policy here or as a step before ? 
     my %ec = map({ref($e->{$_}) ? () : ($_, $e->{$_});} keys(%$e));
     $e = \%ec;
   }
   # Extract attrs and values (for non-ref attrs)
   my @ea = sort (keys(%$e));
   my @ev = @$e{@ea}; # map()
   # To Support sequence we MUST precalc placeholders here.
   # In case of Sequence should place sequence call ...
   my @pha = map({'?';} @ea);
   # Sequence - Add sequenced ID allocation ???
   # $p->{'seqname'}
   if ($p->{'autoid'} && ($p->{'autoid'} eq 'seq')) {
      my $bkt = 'Oracle';
      my @pka = pkeys($p);
      if (@pka > 1) {die("Error: Multiple (composite) pkeys for sequenced ID");}
      # Add Sequence id attibute AND sequence call (unshift to front ?)
      push(@ea, @pka); #  $p->{'pkey'}->[0]
      # Lookup Sequence Syntax (as printf format)for paticular DB Backend
      # Fixed INSERT Below to NOT have placeholder for sequence (placeholders calc'd above)
      # I case of sequence the counts of VALS vs @pha will be unbalanced (off by 1)
      push(@pha, sprintf("$bkmeta->{$bkt}->{'sv'}", $p->{'seqname'}) ); # 
      #DEBUG:print("FMT: $bkmeta->{$bkt}->{'sv'} / $p->{'seqname'}\n");
   }
   if ($StoredHash::hardval) {

     #my $quote = $p->{'dbh'} ? ref($p->{'dbh'}).'::quote' : \&quote;
     #DEBUG:print("QUOTE =  $quote\n\n\n\n");
     #OLD:my $quote = $p->{'dbh'}->can('quote') ? \&$p->{'dbh'}->quote : \&sqlvalesc;
     my $quoter = $p->{'dbh'}->can('quote') ? sub {$p->{'dbh'}->quote($_[0]);} : \&quote;
     @pha = map({
       #$p->{'dbh'}->quote($e->{$_});
       $quoter->($e->{$_}); # OLD: Embed $dbh as $_[0]
     } @ea);
   }
   my $qp = "INSERT INTO $p->{'table'} (".join(',',@ea).") VALUES (".join(',', @pha).")";
   # For now $StoredHash::hardval will always return query for the very efficient $dbh->do()
   # to execute the query.
   if (my $hv = $StoredHash::hardval) {
      if ($hv == 2) {return($qp);} # Return INSERT ... as-is
      elsif ($hv == 1) {
         my $ok = $p->{'dbh'}->do($qp);
         if (!$ok) {die("Failed do on hard query: $qp");}
         # Proceed to autoid
      }
   }
   #DEBUG:print(Dumper($p));
   if ($p->{'debug'}) {print(STDERR "Ins.vals: ".Dumper(\@ev)."\n");}
   if (!$p->{'dbh'}) {return($qp);} # No conn. - return SQL
   
   my $okid;
   if (!$StoredHash::hardval) {$okid = $p->qexecute($qp, \@ev);}
   
   # Auto-id - either AUTO_INC style or Sequence (works for seq. too ?)
   if ($p->{'autoid'}) {
      my @pka = pkeys($p);
      if (@pka != 1) {die(scalar(@pka)." Keys for Autoid");}
      my $id = $p->fetchautoid();
      #$e->{$pka[0]} = $id;
      return(($id));
   }
   # Seq ?
   #elsif () {}
   # $p->pkeyvals($e); # wantarray ?
   else {
      my @pka = pkeys($p);
      return(@$e{@pka}); # wantarray ? @$e{@pka} : [@$e{@pka}];
   }
}

=head2 $shp->update($e, $ids, %opts);

Update an existing entry by ID(s) ($ids) in the database with values in hash %$e.

Return  true for success, false for failure (direct $ok values from underlying
$sth->execute() for 'autoid' => 1 ),  

=cut
# Provide protection for AUTO-ID (to not be changed) ?
#For flexibility the $idvals may be hash or array (reference) with
#hash containing (all) id keys and id values or alternatively array
#containing id values IN THE SAME ORDER as keys were passed during
#construction (with idattr/pkey parameter).

sub update {
   my ($p, $e, $idvals, %c) = @_;
   local $Data::Dumper::Terse = 1;local $Data::Dumper::Indent = 0;
   my @pka; # To be visible to closure
   # Extract ID Values from hash OR array
   # TODO: Loosen requirement for hash to describe pk-attributes ?
   my $idvgens = {
      'HASH'  => sub {@$idvals{@pka};},
      'ARRAY' => sub {return(@$idvals);},
      #'' => sub {[$idvals];}
   };
   # No mandatory (internal) validation ?
   #eval {$p->validate();};if ($@) {$p->{'errstr'} = $@;return(1);}
   @pka = pkeys($p); # PKs from Persister
   if (reftype($e) ne 'HASH') {die("Entry not passed as hash");} # {$p->{'errstr'} = "Entry needs to be hash";return(2);}
   # Probe the type of $idvals
   my $idrt = reftype($idvals);
   if ($p->{'debug'}) {print("Got IDs:".Dumper($idvals)." as '$idrt'\n");}
   #my @idv;
   my @pkv; # PK Values
   # Handle kw params for bulk updates ? Example: 'w' => {...} if (!$idrt {$widstr = wherefilter();}  
   if (my $idg = $idvgens->{$idrt}) {@pkv = $idg->();}
   #VERYOLD:if ($idrt ne 'HASH') {$p->{'errstr'} = "ID needs to be hash";return(3);}
   else {die("Need IDs as HASH or ARRAY (reference, got '$idrt')");}
   #my ($cnt_a, $cnt_v) = (scalar(@pka), scalar(@pkv));
   if (@pkv != @pka) {die("Number of ID keys and ID values (".scalar(@pka).'/'.scalar(@pkv).") not matching for update ($p->{'table'})");}
   #OLDSIMPLE: my @ea = sort(keys(%$e));
   my @ea;
   # Leave to caller to check: Verify that we DO NOT HAVE pkeys in set (?)
   #my $drive = 0;
   # Comply to explicit attributes passed as 'attrs'
   if (ref($c{'attrs'}) eq 'ARRAY') {
     #print("DRIVE ATTRIBUTES: ");
     @ea = @{$c{'attrs'}};
     #$drive = 1;
   }
   # Use natural attributes from entry.
   else {@ea = sort(keys(%$e));}
   #print("DRIVE ATTRIBUTES = $drive: @ea\n");exit(1);
   #my @pkv = @$idh{@pka}; # $idvals, Does not work for hash
   # Check for undef/empty ID comps
   if (my @badid = $p->invalidids(@pkv)) {
     $p->{'errstr'} = "Bad ID Values found (@badid)";return(4);
   }
   my $widstr = whereid($p, $StoredHash::hardval ? (\@pkv) : () );
   # Persistent object type
   my $pot = $p->{'table'};
   if (!$pot) {die("No table for update");}
   # 
   my $qp = "UPDATE $pot SET ".join(',', map({" $_ = ?";} @ea)).
      " WHERE $widstr";
   my $dbh = $p->{'dbh'};
   
   if (my $hv = $StoredHash::hardval) {
     #my $quote = $p->{'dbh'} ? ref($p->{'dbh'}).'::quote' : \&quote;
     #TODO:
     my $quoter = $p->{'dbh'}->can('quote') ? sub {$p->{'dbh'}->quote($_[0]);} : \&quote;
     my $set = join(',', map({
        #" $_ = ".$dbh->quote($e->{$_});
        " $_ = ".$quoter->($e->{$_});
     } @ea) );
     $qp = "UPDATE $pot SET $set WHERE $widstr"; # hard values embedded by whereid()
     if (!@pkv) {die("No ID:s for hardval=$StoredHash::hardval");}
     if ($hv == 2) {return($qp);}
     #elsif ($hv == 1) {return $dbh->do($qp);}
     elsif ($hv == 1) {
        my $ok = eval {$dbh->do($qp);};
        if (!$ok) {die("Error DO(SQL: $qp): ".$@);}
        return($ok);
     }
   }
   # Combine Entry attr values and primary key values
   my $allv = [@$e{@ea}, @pkv];
   if ($p->{'debug'}) {print("Update allvals: ".Dumper($allv)."\n");}
   if (!$p->{'dbh'}) {return($qp);}
   my $ok;
   eval {
   $ok = $p->qexecute($qp, $allv);
   };
   if ($@) {die("Error Executing: ".$p->{'dbh'}->errstr()."\n");}
   # Check all natural IDs (separate case for composite ?)
   #if (!$p->{'autoid'}) {
   #   
   #}
   return($ok);
}

=head2 $shp->delete($ids) OR $shp->delete($filter)

Delete an entry from database by passing one of the following:

=over 4

=item * $ids - array with ID(s) for entry to be deleted (the usual use-case)

=item * $filter - a hash with a where filter condition to delete by.

=back

Note that passing $filter haphazardly can cause massive destruction. Try to stick with passing $ids.

=cut

# (filter) ... containing (all) primary key(s) and their values)
#=item * array @$e - One or many primary key values for entry to be deleted
#The recommended use is case "array" as it is most versatile and most
#consistent with other API methods.

sub delete {
   my ($p, $e) = @_;
   #if (!ref($p->{'pkey'})) {die("PKA Not Known");}
   #eval {$p->validate();};if ($@) {$p->{'errstr'} = $@;return(1);}
   #my @pka = @{$p->{'pkey'}}; 
   my @pka = pkeys($p);
   if (!$e) {die("Must have ID or filter for delete()\n");}
   
   my $rt = reftype($e); # Allows blessed
   my $pkc = $p->pkeycnt();
   my @pkv;my $wstr;
   # $e Scalar, must have 1 pkey. Allow this forgiving behaviour for now.
   if (!$rt && ($pkc == 1)) {$e = [$e];$rt = 'ARRAY';} # OLD: {@pkv = $e;}
   # Hash - OLD: extract primary keys @pkv = @$e{@pka};
   # NEW: treat as filter
   if ($rt eq 'HASH') {
      if (!%$e) {die("Will not delete by empty filter (HASH) !");}
      # TODO: Share filter-case with load(), count()
      #my @ks = sort(keys(%$e));
      my @ks = grep({!ref($e->{$_})} keys(%$e));
      @pkv = @$e{@ks}; # In this context @vs => @pkv - Not really vals for primary keys, but filter
      #NOT:$wstr = wherefilter($e);
      $wstr = join(' AND ', map({"$_ = ?";} @ks));
   } # 
   # Array (of pk values) - check count matches
   elsif (($rt eq 'ARRAY') && ($pkc == scalar(@$e))) {
      @pkv = @$e;
      $wstr = whereid($p);
   }
   else {die("No way to delete (without  ARRAY for IDs or HASH for filter)\n");}
   #NOTNEEDED:#my %pkh;@pkh{@pka} = @pkv;
   #my $wstr = join(' AND ', map({"$_ = ?";} @pka));
   if (!$wstr) {die("Not proceding to delete with empty filter !");}
   my $qp = "DELETE FROM $p->{'table'} WHERE $wstr";
   if (!$p->{'dbh'}) {return($qp);}
   $p->qexecute($qp, \@pkv);
}
#my $dbh = $p->{'dbh'};
#my $sth = $dbh->prepare($qp);
#if (!$sth) {print("Not prepared\n");}
#$sth->execute(@pkv);

=head2 $shp->exists($ids)

Test if an entry exists in the DB table with ID values passed in @$ids (array).
Returns 1 (entry exists) or 0 (does not exist) under normal conditions.

=cut
sub exists {
   my ($p, $ids) = @_;
   my $whereid = $p->{'where'} ? $p->{'where'} : whereid($p);
   my $qp = "SELECT COUNT(*) FROM $p->{'table'} WHERE $whereid";
   if (!$p->{'dbh'}) {return($qp);}
   $p->qexecute($qp, $ids, 'count');
}

=head2 $shp->load($ids)

Load entry from DB table by its IDs passed in @$ids (array, 
single id typical sequece autoid pkey, multiple for composite primary key).

Entry will be loaded from single table passed at construction
(never as result of join from multiple tables).
Return entry as a hash (ref).

=cut
sub load {
   my ($p, $ids) = @_;
   my $whereid = $p->{'where'} ? $p->{'where'} : whereid($p);
   # Allow loading unique entry generic filter
   if (reftype($ids) eq 'HASH') {
     #$whereid = wherefilter($ids);
     my @ks = grep({!ref($ids->{$_})} keys(%$ids));
     my @vs = @$ids{@ks};
     $whereid = join(' AND ', map({"$_ = ?";} @ks));
     $ids = \@vs;
     # Need hard (unique values) for Certain DBs
     # TODO: Move to neater abstraction for $StoredHash::hardval
     if (my $hv = $StoredHash::hardval && $p->{'dbh'}) {
        my $i = -1;
        my $dbh = $p->{'dbh'};
        $whereid = join(' AND ', map({$i++;"$_ = ".$dbh->quote($vs[$i]);} @ks));
        $ids = undef;
     }
   }
   my $qp = "SELECT * FROM $p->{'table'} WHERE $whereid";
   if (!$p->{'dbh'}) {return($qp);}
   $p->qexecute($qp, $ids, 'hash');
   #if (my $c = $p->{'class'}) {return(bless($h, $c));}
}

=head2 $shp->loadset($filter, $sort, %opts);

Load a set of Entries from persistent storage.
Optionally provide simple "where filter hash" ($filter), whose key-value criteria
is ANDed together to form the filter. Allow attibutes (in $sort, arrayref) to define sorting for entry set.
Allow %opts to contain 'attrs' (arrayref) to explicitly to define ettributes to load for each entry.
Return set / collection of entries as array of hashes (AoH).

=cut
sub loadset {
   my ($p, $h, $sort, %c) = @_; # filter, sortby
   my $w = '';
   my $s = '';
   # if (@_ = 2 && ref($_[1]) eq 'HASH') {}
   if ($h) {
     my $vals = []; # Parameteric values
     my $wf = wherefilter($h); # 'vals' => $vals
     if (!$wf) {die("Empty Filter !");}
     $w = " WHERE $wf";
   }
   # TODO: How to trigger DESC sorting (Something in %c OR first or last elem of $sort) ?
   if (ref($sort) && @$sort) {
     my $stype = ''; # Default in SQL: 
     #if ($sort->[0] eq '') {}
     $s = ' ORDER BY '.join(',', @$sort);
   }
   if ($p->{'debug'}) {print("Loading set by '$w'\n");}
   my $fldstr = '*';
   if (ref($c{'attrs'}) eq 'ARRAY') {
      $fldstr = join(',', @{$c{'attrs'}});
   }
   my $qp = "SELECT $fldstr FROM $p->{'table'} $w $s";
   # Clean up query by (?):
   $qp =~ s/\s+$//;
   $p->qexecute($qp, undef, 'aoh');
}
=head2 $shp->cols(%opts)

Sample Column names from (current) DB table.
Return (ref to) array with field names in it.

%opts may contain KW parameter 'full' to get full DBI column_info() structure (See DBI for details).

=cut
sub cols {
   my ($p, %c) = @_;
   
   # Alternative for full table schema info
   # TODO: 'fullinfo' => 1 or 'meta'
   if ($c{'full'}) {
     my $dbh = $p->{'dbh'};
     my $sth = $dbh->column_info(undef, undef, $p->{'table'}, '%');
     my $fullinfo = $sth->fetchall_arrayref({});
     $sth->finish();
     return($fullinfo);
   }
   # Likely Most portable way of quering cols
   my $qp = "SELECT * FROM $p->{'table'} WHERE 1 = 0";
   my $sth = $p->qexecute($qp, undef, 'sth');
   my $cols = $sth->{'NAME'};
   if (@_ == 1) {$sth->finish();return($cols);}
   #elsif (@_ == 2) {$rett = $_[1];};
   #if ($rett ne 'meta') {return(undef);}
   return(undef);
}

# TODO: Load "tree" of entries rooted at an entry / entries (?)
# Returns a set (array) of entries or single (root entry if
# option $c{'fsingle'} - force single - is set.
sub loadtree {
   my ($p, %c) = @_;
   my $chts = $c{'ctypes'};
   my $w = $c{'w'};
   my $fsingle = $c{'fsingle'}; # singleroot, uniroot
   my $arr = loadset($p, $w);
   for my $e (@$arr) {my $err = loadchildern($p, $e, %c);}
   # Choose return type
   if ($fsingle) {return($arr->[0]);}
   return($arr);
}

# TODO: Load Instances of child object types for entry.
# Child types are defined in 'ctypes' array(ref) in options.
# Array 'ctypes' may be one of the following
#=item * Plain child type names (array of scalars), the rest is guessed
#=item * Array of child type definition hashes with hashes defining following:
#  =item * table   - The table / objectspace of child type
#  =item * parkey  - Parent id field in child ("foreign key" field in rel DBs)
#  =item * memname - Mamber name to place the child collection into in parent entry
#=item * Array of arrays with inner arrays containing 'table','parkey','memname' in
#   that order(!), (see above for meanings)
# Return 0 for no errors

# TODO: Maintain persister cache with rudimentary relational info.
sub loadchildren {
  my ($p, $e, %c) = @_;
  my $chts = $c{'ctypes'};
  if (!$chts) {die("No Child types indicated");}
  if (ref($chts) ne 'ARRAY') {die("Child types not ARRAY");}
  my @ids = pkeyvals($p, $e);
  if (@ids > 1) {die("Loading not supported for composite keys");}
  my $dbh = $p->{'dbh'};
  my $debug = $p->{'debug'};
  for (@$chts) {
     #my $ct = $_;
     my $cfilter;
     # Use or create a complete hash ?
     my $cinfo = makecinfo($p, $_);
     if ($debug) {print(Dumper($cinfo));}
     # Load type by created filter
     my ($ct, $park, $memn) = @$cinfo{'table','parkey','memname',};
     if (!$park) {}
     # Create where by parkey info
     #$cfilter = {$park => $ids[0]}; # What is par key - assume same as parent
     if (@$park != @ids) {die("Par and child key counts mismatch");}
     @$cfilter{@$park} = @ids;
     #my $cfilter = 
     # Take a shortcut by not providing pkey
     my $shc = StoredHash->new('table' => $ct, 'pkey' => [],
        'dbh' => $dbh, 'loose' => 1, 'debug' => $debug);
     my $carr = $shc->loadset($cfilter);
     if (!$carr || !@$carr) {next;}
     #if ($debug) {print("Got Children".Dumper($arr));}
     $e->{$memn} = $carr;
     # Blessing
     if (my $bto = $cinfo->{'blessto'}) {map({bless($_, $bto);} @$carr);}
     # Circular Ref from child to parent ?
     #if (my $pla = $cinfo->{'parlinkattr'}) {map({$_->{$pla} = $e;} @$carr);}
  }
  # Autobless Children ?
  return(0);
}


# Internal method for using or making up Child relationship information
# for loading related entities.
sub makecinfo {
   my ($p, $cv) = @_;
   # Support array with: 'table','parkey','memname'
   if (ref($cv) eq 'ARRAY') {
      my $cinfo;
      if (@$cv != 3) {die("Need table, parkey, memname in array");}
      @$cinfo{'table','parkey','memname'} = @$cv;
      return($cinfo);
   }
   # Assume all is there (could validate and provide missing)
   elsif (ref($cv) eq 'HASH') {
      my @a = ('table','parkey','memname');
      # Try guess parkey ?
      if (!$cv->{'parkey'}) {$cv->{'parkey'} = [pkeys($p)];}
      for (@a) {if (!$cv->{$_}) {die("Missing '$_' in cinfo");}}
      return($cv);
   }
   elsif (ref($cv) ne '') {die("child type Not scalar (or hash)");}
   ################## Make up
   my $ctab = $cv;
   my $memname = $ctab; # Default memname to child type name (Plus 's') ?
   # Guess by parent
   my $parkey = [pkeys($p)];
   my $cinfo = {'table' => $ctab, 'parkey' => $parkey, 'memname' => $ctab,};
   return($cinfo);
}

###################################################################

# Internal Persister validator for the absolutely mandatory properties of
# persister object itself.
# Doesn't not validate entry
sub validate {
   my ($p) = @_;
   if (ref($p->{'pkey'}) ne 'ARRAY') {die("PK Attributes Not Known\n");}
   # Allow table to come from blessing (so NOT required)
   #if (!$p->{'table'}) {die("No Table\n");}
   if ($p->{'simu'}) {return;}
   # Do NOT Require conenction
   #if (!ref($p->{'dbh'})) {die("NO dbh to act on\n");} # ne 'DBI'
   
}

#=head2 @pka = $shp->pkeys()
#
# Internal method for returning  array of id keys (Real array, not ref).
#
#=cut
sub pkeys {
   my ($p) = @_;
   my $prt = reftype($p);
   if ($prt ne 'HASH') {
      $|=1;
      print(STDERR Dumper([caller(1)]));
      die("StoredHash Not a HASH (is '$p'/'$prt')");
   }
   # Excessive validation ?
   if (ref($p->{'pkey'}) ne 'ARRAY') {die("Primary keys not in an array");}
   #return($p->{'pkey'});
   return(@{$p->{'pkey'}});
}

=head2 $shp->count($filter)

Get Count of all or a filtered set of entries (by optional $filter) in table.
Return (scalar) count of entries.

=cut
sub count {
   my ($p, $fh) = @_; # $fh - Filter Hash
   my $qc = "SELECT COUNT(*) FROM $p->{'table'}";
   # TODO: See filter case for load(), delete()
   # Use it and replace 2nd param of qexecute w. params
   if (ref($fh) eq 'HASH' && keys(%$fh)) {
      my $w = wherefilter($fh); # my ($w, $vals) = wherefilter_para($fh);
      $qc .= " WHERE $w";
   }
   if ($p->{'debug'}) {print("Count Query:$qc\n");}
   if (!$p->{'dbh'}) {return($qc);}
   $p->qexecute($qc, undef, 'count'); # $vals
}

=head1 INTERNAL METHODS

These methods you should not need working on the high level. However for the curious they are outlined here.

=head2 @pkv = $shp->pkeyvals($e)

Return Primary key values (as "real" array, not ref to one) from hash %$e.
undef values are produced for non-existing keys.
Mostly used for internal operations (and possibly debugging).

=cut
sub pkeyvals {
   my ($p, $e) = @_;
   my @pkeys = pkeys($p);
   @$e{@pkeys};
}

# TODO: Implement pulling last id from sequence
sub fetchautoid {
   my ($p) = @_;
   my $dbh;
   #$dbh->{'Driver'}; # Need to test ?
   #DEV:print("AUTOID FETCH TO BE IMPLEMENTED\n");return(69);
   my $pot = $p->{'table'};
   if (!$pot) {die("No table for fetching auto-ID");}
   if (!($dbh = $p->{'dbh'})) {die("No Connection for fetching ID");}
   $dbh->last_insert_id(undef, undef, $pot, undef);
}

sub pkeycnt {
   my ($p) = @_;
   #if (ref($p->{'pkey'}) ne 'ARRAY') {die("Primary keys not in an array");}
   #scalar(@{$p->{'pkey'}});
   my @pkeys = pkeys($p);
   scalar(@pkeys);
}

# Internal method for checking for empty or undefined ID values.
# In all reasonable databases and apps these are not valid values.
sub invalidids {
   my ($p, @idv) = @_;
   my @badid = grep({!defined($_) || $_ eq '';} @idv);
   return(@badid);
}

=head2 $shp->whereid($pkvals);

Generate SQL WHERE Clause for update() (or delete() or load() or exists()) based on primary keys of current (table) type.
Return WHERE clause with id-attribute(s) and placeholder(s) (idkey = ?, ...), without the WHERE keyword.
Mostly called for internal operations. You should not need this.

=cut
sub whereid {
   my ($p, $pkval) = @_;
   # # Allow IDs to be hash OR array ?? Not because hash would req. to store order
   my @pka = pkeys($p);
   if (@pka < 1) {die("No Pkeys to create where ID clause");}
   # my $wstr = 
   if ($pkval && (ref($pkval) eq 'ARRAY') && (@$pkval == @pka) ) {
     # TODO: Mock DBI
     my $dbh = $p->{'dbh'};
     # Can't use string ("DBI::db::quote") as a subroutine ref while "strict refs" in use
     my $quote = $p->{'dbh'} ?
        #ref($p->{'dbh'}).'::quote'
        sub {$p->{'dbh'}->quote($_[0]);}
        : \&quote;
     my $i = -1;
     #no strict 'refs';
     my $wif = join(' AND ', map({
        $i++;"$_ = ".$quote->($pkval->[$i]);
     } @pka));
     return $wif; # OLD (nostrict) $wid
   }
   return join(' AND ', map({"$_ = ?";} @pka));
}

# Internal fallback method to escape (string) value. Prefer using $dbh->quote() if $dbh is
# handle available and the associated DBD Driver supports it.
# The first parameter to this is an unused dummy parameter to match call of $dbh->quote($str).
# This does not place surrounding quotes on the value returned.
# Return value properly escaped.
# TODO: Cover all scenarios
sub sqlvalesc {
   my ($foo, $v) = @_;
   #$v =~ s/'/\\'/g; # $str =~ s/'/''/g;
   $v =~ s/\'/\'\'/g;
   $v =~ s/\n/\\n/g;
   $v;
}

# TODO: Create list for WHERE IN Clause based on some assumptions
sub invalues {
   my ($vals) = @_;
   # Assume array ref validated outside
   if (ref($vals) ne 'ARRAY') {die("Not an array for invals");}
   # Escape within Quotes ?
   join(',', map({
      if (/^\d+$/) {$_;}
      else {
        my $v = sqlvalesc(undef, $_);
        "'$v'";
      }
   } @$vals));
}

sub rangefilter {
   my ($attr, $v) = @_;
   if (ref($v) ne 'ARRAY') {die("Need value range as ARRAY of 2 elems");}
   # Or just even and sort, grab 2 at the time ?
   if (@$v != 2) {die("Range cannot be formed - need exactly 2 elements");}
   if (!defined($v->[0]) || !defined($v->[1]) ) {die("Missing either of the values ($v->[0], $v->[0])");}
   # Auto-arrange ??? Test for both being numbers
   my @nums = map({Scalar::Util::looks_like_number($_) ? (1) : ();} @$v);
   if (@nums == 2) {
      if ($v->[1] < $v->[0]) {$v = [$v->[1],$v->[0]];}
   }
   # Detect need to escape (time vs. number)
   return "($attr >= $v->[0]) AND ($attr <= $v->[1])";
   #return " $attr BETWEEN $v->[0] AND $v->[1]";
}

#=head2  StoredHash::wherefilter($e,%c);
#
# Generate simple WHERE filter by hash %$e. The keys are assumed to be attributes
# of DB and values are embedded as values into SQL (as opposed to using placeholers).
# To be perfect in escaping per attribute type info would be needed.
# For now we do best effort heuristics (attr val \d+ is assumed
# to be a numeric field in SQL, however 000002345 could actually 
# be content of a char/text/varchar field).
# Return WHERE filter clause without WHERE keyword.
sub wherefilter {
   my ($e, %c) = @_;
   my $w = '';
   my $fop = ' AND ';
   #my $rnga = $c{'rnga'}; # Range attributes
   if (ref($e) ne 'HASH') {die("No hash for filter generation");}
   # Ensure deterministic order
   my @keys = sort keys(%$e);
   my @qc; # Query Components
   # Assume hard values, treat everything as string (?)
   # TODO: forcestr ?
   @qc = map({
      my $v = $e->{$_};
      #my $rv = ref($v);
      #if ($rnga->{$_} && ($rv eq 'ARRAY') && (@$v == 2)) {rangefilter($_, $v);}
      # For now, assume IN - clause
      if (ref($v) eq 'ARRAY') {" $_ IN (".invalues($v).") ";}
      # SQL Wildcard
      elsif ($v =~ /%/) {"$_ LIKE '$v'";}
      # Detect numeric (likely numeric, not perfect)
      # TODO: Explicit param to 
      elsif ($v =~ /^\d+$/) {"$_ = $v";}
      # Assume string
      else {"$_ = '".sqlvalesc(undef, $v)."'";}
      
   } @keys);
   # Create PARAMETRIC query
   if (ref $c{'vals'} eq 'ARRAY') {
     my @vals = ();
     map({
       my $v = $e->{$_};
       if (ref($v) eq 'ARRAY') {push(@vals, @$v);" $_ IN (".join(',', map({"?";} @$v)).") ";}
       elsif ($v =~ /%/) {push(@vals, $v);"$_ LIKE ?";}
       else {push(@vals, $v);"$_ = ?";}
     } @keys);
     push(@{$c{'vals'}}, @vals);
   }
   return(join($fop, @qc)); # join by AND
}

#=head2 my ($where, $para) = wherefilter_para($e);
# Where filter for parametric query (for load(), delete() count())
# Return WHERE clause (without 'WHERE') and parametric values.
# Throw exception on empty %$e or ... (empty filter)
# Caller should not simply check the count of keys in hash as ref
# valued key-pairs are skipped here.
sub wherefilter_para {
   my ($e) = @_;
   if (!$e || !%$e) {die("Will not generate filter by no HASH / empty HASH !");}
   my @ks = grep({!ref($e->{$_})} keys(%$e));
   my @vs = @$e{@ks}; # In this context @vs => @pkv - Not really vals for primary keys, but filter
   my $wstr = join(' AND ', map({"$_ = ?";} @ks));
   #if (!$wstr || $wstr =~ /^\s*$/) {die("Will not generate empty filter clause");}
   return($wstr, \@vs);
}

# Internal: Serialize all values (singles,multi) from a hash to an array
# based on sorted key order. Multi-valued keys (with value being array reference)
# add multiple items. 
sub allentvals {
   my ($h) = @_;
   map({
     if (ref($h->{$_}) eq 'HASH') {();}
     elsif (ref($h->{$_}) eq 'ARRAY') {@{$h->{$_}};}
     else {($h->{$_});}
   } sort(keys(%$h)));
}


# TODO: Move to util ?
#=head2 $p->dbtabinfo(%opts) OR StoredHash::dbtabinfo($dbh, %opts);
# Covenience method for $dbh->table_info()
# Options:
#=item * tabonly - Filter out all DB Objects where TABLE_TYPE is not 'TABLE'
# 
# Return AoH where each of inner hashes are info for single table. Property names are in
# standard DBI table_info() format (see perldoc DBI).
sub dbtabinfo {
   my (%c) = @_;
   my ($p, $pdbh);
   my $rt = reftype($_[0]);
   if ($rt eq 'StoredHash') {$p = shift();%c = @_;}
   # elsif ($rt eq '')
   else {$pdbh = shift();%c = @_;}
   my $dbh = $pdbh || $p->{'dbh'} || $c{'dbh'};
   if (!$dbh) {die("No Connection for table info");}
   my $sth = $dbh->table_info();
   my $tabinfo = $sth->fetchall_arrayref({}); # AoH
   $sth->finish();
   # Replace with $c{'all'} - Get all database objects (like views, indices ...)
   if ($c{'tabonly'}) {
      @$tabinfo = grep({$_->{'TABLE_TYPE'} eq 'TABLE';} @$tabinfo);
   }
   
   return($tabinfo);
}
# Experimental wrapper to query attributes
# TODO: dbattrinfo($dbh, $tn);
sub dbattrinfo {
   my ($dbh, $tn) = @_;
   #my ($p, $pdbh);
   #my $rt = reftype($_[0]);
   #if ($rt eq 'StoredHash') {$p = shift();%c = @_;}
   #elsif ($rt eq '') {$pdbh = shift();%c = @_;}
   #my $dbh = $pdbh || $p->{'dbh'} || $c{'dbh'};
   if (!$dbh) {die("No Connection for attribute info");}
   if (!$tn) {die("No table name for attribute info");}
   my $sth = $dbh->column_info(undef, undef, $tn, '%');
   my $arr = $sth->fetchall_arrayref({}); # AoH
   $sth->finish();
   return($arr);
}
1;
