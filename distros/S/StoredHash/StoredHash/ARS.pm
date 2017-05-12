=head1 NAME

StoredHash::ARS - Remedy/ARS adapter for StoredHash

=head1 DESCRIPTION

StoredHash::ARS allows the normal persistence methods of StoredHash to be used with
Remedy ARS database backend (with few exceptions where certain method would not make sense).

ARS is much more constrained about DB side conventions than traditional relational databases.
ID numbering is always automatic and primary key is always field called (actually numbered as
ARS uses numbers for attribute names) '1'.

To learn to use StoredHash::ARS, read "perldoc StoredHash". The documentation here
focuses only on ARS / Remedy specific quirks.

NOTE: This module is still experimental.

=head2 SYNOPSIS

   use StoredHash::ARS;
   use ARS;
   
   # ARS Connection
   my $ctrl = ars_Login($ENV{'ARS_SERVER'}, $ENV{'ARS_USER'}, $ENV{'ARS_PASS'});
   # StoredHash persister configuration ('pkey' intentionally missing for ARS)
   my $shpc = {'table' => 'HPD::Helpdesk',  'dbh' => $ctrl, 'debug' => 0};
   my $shp = StoredHash::ARS->new(%$shpc);
   # Load
   my hdent = $shp->load(['HD...']);
   # Insert, Update, Delete ... as usual
   
   
=head1 METHODS

Method documentation focuses only on ASR specific differences.
Be sure to read StoredHash documentation for an overview.

General notes:

=over 4

=item * The hash to store must be keyed by Remedy field numbers (not descriptibve names ...)

=item * On update, delete ... ops that require entry id to be passed, use the
value assigned to Remedy field '1' (reserved for id of an entry by Remedy conventions).

=item * StoredHash basic / DBI backend will tolerate calling methods via persister
that does not have the connection ('dbh') set. StoredHash::ARS will not.

=item * Because of no composite keys in ARS, the StoredHash::ARS persistnce
methods will tolarate a loose / forging way of passing id:s as plain scalars,
with "wrapping" array being optional. However using array(ref) is still the
recommended, future-proof way of passing the id.

=item * Remedy schemas usually host a huge amount of attributes. For this reason you should focus
on using parameter 'attrs' in your persistence operations for optimal performance.

=back

=cut

package StoredHash::ARS;

use ARS;

use strict;
use warnings;

use Data::Dumper;
# Inherit all
our @ISA = ('StoredHash');
our $VERSION = '0.30';
our $ars_errstr; # Auto exported from ARS

=head2 StoredHash::ARS->new(%opts)

StoredHash::ARS constructor. Notes on keyword parameters (in %opts).

=over 4

=item * 'dbh' - The connection passed should be ARS Connection (use ARS API idiomatic handle $ctrl as value).

=item * 'table' - use ARS Schema name (e.g. 'table' => 'HPD:HelpDesk')

=back

Because Remedy always uses the same numeric name for primary key and auto-allocates id, the parameters
'pkeys' and 'autoid' are not relevant for Remedy.

=cut
sub new {
   my ($class, %opt) = @_;
   # TODO: Lazy load ARS for easier testability.
   # eval("use ARS;");
   my %overr = ('pkey' => ['1'], 'autoid' => 1,);
   my $shp = StoredHash->new(%opt, %overr);
   return bless($shp, $class);
}

#sub errstr {
#   my ($p, $v) = @_;
#   $ars_errstr
#}
#sub qexecute {
#   my ($p, $q, $vals, $rett) = @_;

=head2 $shp->insert($e);

Insert an entry into ARS database.
Pass ARS Entry instance ($e) with NUMERIC Field IDs (i.e. not descriptive field names).

    $e = {'240000005' => 'mrjohnsmith', '260000002' => 'mrjohnsmith@corp.com'};
    my $eid = $sp->insert($e);

Return Remedy entry ID for the new entry (usable in further persistence ops).

=cut
sub insert {
   my ($p, $e) = @_;
   my ($ctrl, $sc) = @$p{'dbh', 'table'};
   if (ref($e) ne 'HASH') {die("Not a HASH for ARS Insert");}
   my $eid = ars_CreateEntry($ctrl, $sc, %$e);
   if (!$eid) {die("Failed to create entry ($ars_errstr)\n");}
   return($eid); # OLD: [$eid]
}
=head2 $shp->update($e, [$eid], %opts)

Update entry in ARS database schema. Keyword params in %opts:

=over 4

=item * 'attrs' - Allow only a subset of attributes from entry ($e) to be updated.

=back

=cut

#=item *  Allow ID to be extracted (param count problem) ?
sub update {
   my ($p, $e, $eid, %c) = @_;
   my ($ctrl, $sc) = @$p{'dbh', 'table'};
   # Allow ARRAY or plain scalar, coerce to scalar here
   my $isidarr = (ref($eid) eq 'ARRAY') ? 1 : 0;
   if ($isidarr && (scalar(@$eid) == 1)) {$eid = $eid->[0];}
   elsif ($isidarr) {die("Passing no values or multiple values for Remedy ID");}
   if (!$eid) {die("No ID (value of field '1') Specified for ARS update");}
   # Allow Blessed ? Use reftype()
   if (ref($e) ne 'HASH') {die("Not a HASH for ARS Update");}
   # Serialize entry values to ARRAY (additionally Allow mapping ?)
   my @kvs;
   if (my $ats = $c{'ats'}) {@kvs = map({($_, $e->{$_});} @$ats);}
   else {@kvs = map({($_, $e->{$_});} keys(%$e));} # %$e
   # getTime=0, Return undef on fail, 1 on success
   my $ok = ars_SetEntry($ctrl, $sc, $eid, 0, @kvs);
   return($ok);
}
=head2 $shp->delete([$eid])

Delete an Entry by id ($eid) permanently from ARS database.

Return true value for successesful deletion.

=cut
sub delete {
   my ($p, $eid) = @_;
   my ($ctrl, $sc) = @$p{'dbh', 'table'};
   my $isidarr = (ref($eid) eq 'ARRAY') ? 1 : 0;
   if ($isidarr && (scalar(@$eid) == 1)) {$eid = $eid->[0];}
   elsif ($isidarr) {die("Passing no values or multiple values for Remedy ID");}
   # || ref($eid)
   if (!$eid ) {die("Entry ID must be passed as array of single item or non-empty scalar");}
   my $ok = ars_DeleteEntry($ctrl, $sc, $eid);
   return($ok);
}
=head2 $shp->exists([$eid])

Test presence of entry by ID ($eid) in ARS database.
Return true for present in DB, false for not present.

=cut
sub exists {
   my ($p, $eid) = @_;
   # OLD:
   #my ($ctrl, $sc) = @$p{'dbh', 'table'};
   #if ((ref($eid) eq 'ARRAY') && (scalar(@$eid) == 1)) {$eid = $eid->[0];}
   #my %vals = ars_GetEntry($ctrl, $sc, $eid); #, @ats
   #if (%vals) {return(1);}
   #return(0);
   # NEW: Load entry with only ID - this should be extremely light search.
   my $e = $p->load($eid, 'attrs' => [1]);
   if ($p->{'debug'}) {print(STDERR Dumper($e));}
   if (!$e) {return(0);}
   if (ref($e) ne 'HASH') {return(0);}
   if (!%$e) {return(0);}
   return(1);
}
=head2 $shp->load([$eid], %opts)

Load an entry from Remedy database schema by its id ($eid). Keyword params in %opts:

=over 4

=item * 'attrs' - Load only attributes listed (arrayref, pass numeric field IDs)

=back

=cut
sub load {
   my ($p, $eid, %o) = @_;
   my ($ctrl, $sc) = @$p{'dbh', 'table'};
   if (!ref($ctrl)) {die("No Connection\n");}
   if ((ref($eid) eq 'ARRAY') && (scalar(@$eid) == 1)) {$eid = $eid->[0];}
   if (ref($eid)) {die("EID is Still ref after dereferencing");}
   if (!$eid) {die("No entry id");}
   my @ats = ref($o{'attrs'}) eq 'ARRAY' ? @{$o{'attrs'}} : (); # TODO: %o
   if ($p->{'debug'}) {print(STDERR "Querying by attrs: ".Dumper(\@ats));}
   my %vals = ars_GetEntry($ctrl, $sc, $eid, @ats);# $diaryfield_fid
   return(\%vals);
}

=head2 $shp->loadset($filter, $sortby, %opts)

Keyword parameters (in %opts):

=over 4

=item * 'attrs' - if set to true scalar value, the entries are fetched
 brute force with all entry attributes (in Remedy this usually is a LOT of data).
 
=item * 

=back

=cut
sub loadset {
   my ($p, $h, $sort, %c) = @_; # filter, sortby
   my ($ctrl, $sc) = @$p{'dbh', 'table'};
   if (!ref($ctrl)) {die("No Connection\n");}
   my $qs = wherefilter($h);
   if ($p->{'debug'}) {print(STDERR "Filter: $qs\n");}
   my $qual = ars_LoadQualifier($ctrl, $sc, $qs);
   if ($ars_errstr || !$qual) {die("No Qualifier (for schema '$sc'): $ars_errstr");}   
   my $df = $c{'attrs'}; # || []; # $c{'attr'} || ...;
   my (@es, @es2); # Entry sets - @es2 is the final to return
   # TODO: Break into 3 cases for 'attrs':
   # 1) undefined, param not present - return default fields (this is the "safe", low bandwidth solution)
   # 2) explicit, valid list of more than 1 attributes, return exactly those
   # 3) empty array - return all fields (recommennded to be used only at development / testing / debugging)
   # Consider 1/3 behaviour
   # No $df - signal search returning small (server side configured) default fields
   if (!ref($df)) {$df = [];goto EXPLICIT;} # What does empty do ?
   # Has $df, but empty array
   # http://cpansearch.perl.org/src/JMURPHY/ARSperl-1.90/html/manual/ars_GetListEntry.html
   elsif (!@$df) {
      # Implied / schema default fields (i.e not all)
      if ($p->{'debug'}) {print(STDERR "fields passed as empty set, return set with ALL fields\n");}
      my %entries = ars_GetListEntry($ctrl, $sc, $qual, 0, 0);
      # if ($p->{'debug'} > 3) {print(STDERR Dumper(\%entries));}
      @es2 = map({my %e = ars_GetEntry($ctrl, $sc, $_);(\%e);} keys(%entries));
      # TODO: Try ars_GetListEntryWithFields($ctrl, $sc, $qual, 0, 0);
   }
   # Explicit fields (return those) or empty array (return ALL fields !)
   # http://cpansearch.perl.org/src/JMURPHY/ARSperl-1.90/html/manual/ars_GetListEntryWithFields.html
   else {
     EXPLICIT:
     #my $cnt = 
     my $desc = @$df ? "Explicit fields: @$df" : 'set with default fields';
     if ($p->{'debug'}) {print(STDERR "Fields passed internally (@$df), return $desc\n");}
     @es = ars_GetListEntryWithFields($ctrl, $sc, $qual, 0, 0, $df);
     # Map to Include keys (Already in entry)
     my $i = 0;
     my $re;
     #@es = map({($i % 2) ? () : ($_);} @es);
     #@es = values(@es); # Coerce early
     for ($i = 1;$re = $es[$i];$i += 2) {push(@es2, $re);}
   }
   return(\@es2);
}

=head2 $shp->cols()

Query columns for ARS Schema (given by persister internal field 'table'
passed at construction time). Return numeric fieldnames sorted alphabetically
(as ARS does not have deterministic order for fields).

=cut
sub cols {
   my ($p) = @_;
   my ($ctrl, $sc) = @$p{'dbh', 'table'};
   my %fld = ars_GetFieldTable($ctrl, $sc);
   # TODO ADVANCED:
   # - Col ID Numbers to names mapping (hash)
   # - Full ARS column_info / Meta info
   #if (0) {} 
   return([sort keys(%fld)]);
}
#sub loadtree {
#   my ($p, %c) = @_;
#   
#}

#sub loadchildren {
#  my ($p, $e, %c) = @_;
#     # Load type by created filter
#     my ($ct, $park, $memn) = @$cinfo{'table','parkey','memname',};
#}

#sub makecinfo {
#   my ($p, $cv) = @_;
#sub validate {
#   my ($p) = @_;
#}

#sub pkeys {
#   my ($p) = @_;
#   
#}
#sub pkeyvals {
#   my ($p, $e) = @_;

# Should not be used with ARS
sub fetchautoid {
   my ($p) = @_;
   die("fetchautoid - Not Relevant with ARS\n");
}
# Should always produce 1 for Remedy
#sub pkeycnt {
#   my ($p) = @_;
#
#sub invalidids {
#   my ($p, @idv) = @_;
#}
# Irrelevant with Remedy API
#sub whereid {
#   my ($p) = @_;
#}

#sub sqlvalesc {
#   my ($v) = @_;
#   $v =~ s/'/\'/g;
#   return($v);
#}

# WHERE IN Clause
sub invalues {
   my ($vals) = @_;
   my @uvals = map({
      #if (/^\d+$/) {"";}
      "\"$_\"";
   } @$vals);
   join(',', @uvals);
}
sub rangefilter {
   my ($attr, $v) = @_;
}
# Internal method to create ARS/Remedy where filter.
sub wherefilter {
   my ($e, %c) = @_;
   my $w = '';
   my $fop = ' AND ';
   #my $rnga = $c{'rnga'}; # Range attributes
   if (ref($e) ne 'HASH') {die("No hash for filter generation");}
   my @keys = sort keys(%$e);
   my @qc;
   # Assume hard values, treat everything as string (?)
   # TODO: forcestr ?
   no strict ('refs');
   @qc = map({
      my $v = $e->{$_};
      #my $rv = ref($v);
      #if ($rnga->{$_} && ($rv eq 'ARRAY') && (@$v == 2)) {rangefilter($_, $v);}
      if (ref($v) eq 'ARRAY') {" '$_' IN (".invalues($v).") ";}
      # SQL Wildcard
      elsif ($v =~ /%/) {"'$_' LIKE \"$v\"";}
      # Detect numeric (likely numeric, not perfect)
      elsif ($v =~ /^\d+$/) {"'$_' = $v";}
      # Assume string
      else {"'$_' = \"".StoredHash::sqlvalesc(undef, $v)."\"";}
      
   } @keys);
   return(join($fop, @qc));
}
sub allentvals {
   my ($h) = @_;
   die("allentvals: Not implemented");
}
#=head2 $shp->count($filter)
#
# Exists ONLY for interface completeness, NOT Implemented (yet).
# Return -1 (till completed)
#
#=cut
sub count {
   my ($p, $h) = @_;
   # How do we counts ents easily / most efficiently ?
   # my $arr = $shp->loadset(undef,undef,'attrs' => [1]);return(scalar(@$arr));
   my ($ctrl, $sc) = @$p{'dbh', 'table'};
   my $qs = ($h && %$h) ? wherefilter($h) : "1 = 1";
   my $qual = ars_LoadQualifier($ctrl, $sc, $qs);
   #my %entries = ars_GetListEntry($ctrl, $sc, $qual, 0, 0);
   # Get entries with ONLY ID field to minimize "DB traffic".
   my %entries = ars_GetListEntryWithFields($ctrl, $sc, $qual, 0, 0, [1]);
   if ($p->{'debug'}) {print(Dumper(\%entries));}
   my $cnt = keys(%entries);
   return(-1);
}
1;
