# Bulk insert / update
# INITIALLY: On Update Assume NO ID changes
# (Allow passing via update() call parameters '' => '' - too late ?
# Scenario: rename of children when par. id changes (composite key)
# TODO: Support AoA (not only AoH) as input ?
package StoredHash::Bulk;


use strict;
use warnings;
use Scalar::Util ('reftype');
use Data::Dumper;
# Inherit ???
#NOT: our @ISA = ('StoredHash');
our $VERSION = '0.30';
# Factory method to return bulk-op (insert / update) ready object.
# Keyword params:
# - dbh - Data Connection (Default: use connection in $shp)
# TODO: Allow attribute mapping ?
# TODO: Pass 2 persisters ?
sub StoredHash::Bulk {
   my ($p, %c) = @_;
   my $bulk = {'shp' => $p, 'idcache' => undef };
   if (ref($_[1]) eq 'StoredHash') {
      # Assume destination SHP
   }
   # Allow overrides in destination
   my $dbh = $c{'dbh'} || $p->{'dbh'};
   my $table = $c{'table'} || $p->{'table'};
   # Explicit attrs allow partial updates
   my $attrs = $c{'attrs'};
   # 
   if (ref($attrs) ne 'ARRAY') {$attrs = $p->cols();}
   my @pks = $p->pkeys();
   my @ats;
   if (ref($attrs) ne 'ARRAY') {die("No attributes for replication !!!");}
   # Clone (or contain HAS-A style) and add a few members ????
   $bulk->{'attrs'} = $attrs;
   # Generate INSERT/UPDATE and Prepare for bulk-op
   # Plain SQL (attrs sorted or not ?)
   local $p->{'dbh'} = undef;
   local $p->{'table'} = $table; # Table may be different
   
   # TODO: Avoid this by allowing passing explicit attr to insert / update
   # TODO: Eliminate workaround by sort()
   # TODO: Any exceptions to attrs ???
   # TODO: Pass whole %c to insert / update here (or only 'attrs','table')
   my %dummy = map({$_ => 1;} @$attrs);
   @ats = sort(@$attrs); # Workaround
   ###### Insert:
   # Need braches to describe attribute params for particular OP (ins/upd) ?
   # Ensure that 'attrs' drives the order OR that order is stored.
   $bulk->{'ins'} = $p->insert(\%dummy, 'attrs' => \@ats);
   $bulk->{'insattrs'} = [@ats];
   
   ###### Update: ALWAYS Strip ID fields
   #sub attrs_noids {
   my %ids = map({$_ => 1;} @pks);
   @ats = grep({!$ids{$_};} @$attrs);
   #}
   if ($c{'debug'}) {print("Attrs for up: ".Dumper(\@ats));}
   # Generate SQL
   $bulk->{'upd'} = $p->update(\%dummy, [@pks], 'attrs' => \@ats);
   # Rely on attributes in order
   $bulk->{'updattrs'} = [@ats];
   
   ##### Prepare Exists sth 
   my $whereid = StoredHash::whereid($p);
   my $qe = "SELECT COUNT(*) FROM $table WHERE $whereid";
   #my $sth = $dbh->prepare($qe); # Delay prep ?
   $bulk->{'exs'} = $qe;
   $bulk->{'exsattrs'} = [@pks];
   ############### DEBUG #########
   if ($c{'debug'}) {print(Dumper($bulk));}
   # Supported as plain query w/o $dbh ?
   #$bulk->{'exi'} = $p->exists(undef, 'attrs' => $attrs);
   
   
   
   bless($bulk, 'StoredHash::Bulk'); # __PACKAGE__
   # TOO EARLY (need tgt conn)
   #NOT:if ($c{'cacheid'}) {$bulk->makeidcache();}
   return($bulk);
}
# 
#sub new {
#   my ($class, %opt) = @_;
#   my $shp = StoredHash->new(%opt);
#   bless($shp, $class);
#}

# Create a cache of target system IDs to avoid probing presence of each entry
# individually during replication.
# TODO: Rely on StoredHash to load IDs
sub makeidcache {
   my ($bulk, $dbh, $table, $id) = @_;
   my $idcnt = scalar(@$id);
   # Simple ID Maker
   my $idmk = sub {($_[0]->[0], 1);};
   my $q = "SELECT ".join(',', @$id)." FROM $table";
   my $aoa = $dbh->selectall_arrayref($q);
   my %idc = map({
      # Create ':' -delimited composite keys
      my $ck = join(":", splice(@$_, 0, 2));
      ($ck, 1);
      
   } @$aoa);
   # ID:s for target system
   $bulk->{'idcache'} = \%idc;
}

# TODO: Keep insert/update as wrappers, label actual op to keyword
# parameter "stack" to be passed downstream

# Internal sub to implement EITHER insert or update (with very similar pattern)
# TODO: Support AoA ?
# - check for exist (prepared earlier at bulk constructor)
sub ins_or_upd {
  my ($bulk, $arr, %c) = @_;
  my $dbh = $c{'dbh'} || $bulk->{'shp'}->{'dbh'};
  my $ok = 0;
  my $debug = $c{'debug'};
  my $p = $bulk->{'shp'} || die("No StoredHash for Bulk-op");
  my $idc = $bulk->{'idcache'} || 0;
  local $Data::Dumper::Terse = 1;
  # Need more granular / custom attrs than bulk universal attrs ?
  my (@attrs, @attrsupd, @pks);
  my ($sth, $sthi, $sthu, $sthe);
  my ($inscnt, $updcnt) = (0,0);
  # Exec Ops for hash
  my $ops = {
    'ins' => sub {
       my ($e) = @_;
       $sth->execute(@$e{@attrs});
    },
    'upd' => sub {
       my ($e) = @_;
       $sth->execute(@$e{@attrs},); #  @$e{@pks},
    },
    'insorup' => sub {
       my ($e) = @_;
       my $ok = 0;
       # Exists => Update
       my @pkv = @$e{@pks};
       my $is = 0;
       if ($idc) {
          if ($idc->{join(':', @pkv)}) {$is = 1;}
       }
       elsif (_exists($sthe, \@pkv)) {$is = 1;}
       ############################
       if ($is) {
          # ID attrs already included at end
          $ok = $sthu->execute(@$e{@attrsupd},);$updcnt++;
       }
       # insert as new
       else {$ok = $sthi->execute(@$e{@attrs},);$inscnt++;}
       return($ok);
    },
  };
  my $op = $c{'op'} || 'insorup';
  if (!$ops->{$op}) {die("$op - No such operartion supported");}
  # Allow blessed too !
  if (!$arr || (reftype($arr) ne 'ARRAY')) {die("No Bulk Array to operate on !");}
  @pks = $p->pkeys();
  
  DEBUG:my $qe = $bulk->{'exs'};
  # This does not show lack of knowledge about datastructures, we merely
  # want to extract max perf from lexicals statement handles
  if ($op eq 'insorup') {
     $sthe = $bulk->prepare($dbh, 'op' => 'exs', 'debug' => 1);
     $sthi = $bulk->prepare($dbh, 'op' => 'ins', 'debug' => 1);
     $sthu = $bulk->prepare($dbh, 'op' => 'upd', 'debug' => 1);
     # Setup separate: @attrs / 
     @attrs = @{$bulk->{'insattrs'}};
     @attrsupd = @{$bulk->{'updattrs'}};
     # Add ID (In order)
     push(@attrsupd, @pks);
     local $Data::Dumper::Indent=0;
     print("Final INS: ".Dumper(\@attrs)."\n\n");
     print("Final UPD: ".Dumper(\@attrsupd)."\n\n");
  }
  # Need only single handle (in the callbacks)
  else {
     $sth = $bulk->prepare($dbh, 'op' => $op);
     @attrs = @{$bulk->{$op.'attrs'}};
  }
  # Pick callback to execute
  my $opcb = $ops->{$op};
  # In case of update append the earlier stripped ID (for where clause)
  if ($op eq 'upd') {push(@attrs, @pks);}
  my $i = 0;
  local $Data::Dumper::Terse = 1;local $Data::Dumper::Indent = 0;
  #my $qiu = $bulk->{$op}; # These's no sigle op
  for my $e (@$arr) {
     if (reftype($e) ne 'HASH') {die("Not a hash to insert");}
     if ($c{'dry'}) {
        my @v = @$e{@attrs};
	my @vu = @$e{@attrsupd};
	print("QUERY:\n");
	# OP:$bulk->{$op}
	print("(\@v(ins)=)".Dumper(\@v)."\n");
	print("(\@vu(upd)=)".Dumper(\@vu)."\n");
     }
     else {
        my $ok = $opcb->($e);
	# Could re-enable !!!!$DBI::errstr
        #OLD:my $ok = $sth->execute(@$e{@attrs});
        if (!$ok) {die("Failed to ins/upd: \n");} # $qiu
	#print("NOP\n");
     }
     if ($debug) {print("Proc: $i\n");}
     $i++;
  }
  if ($debug) {print("tot: $i, ins=$inscnt, upd=$updcnt\n");}
  return($i);
}

sub insert {
   my ($bulk, $arr, %c) = @_;
   $c{'op'} = 'ins';
   $bulk->ins_or_upd($arr, %c);
}

# Try to keep as a stub containing call to shared implementation
sub update {
   my ($bulk, $arr, %c) = @_;
   $c{'op'} = 'upd';
   $bulk->ins_or_upd($arr, %c);
}

# Insert or update
sub store {
   my ($bulk, $arr, %c) = @_;
   #my $dbh = $c{'dbh'} || $bulk->{'shp'}->{'dbh'};
   #my $ok = 0;
   $c{'op'} = 'insorup';
   # OPTION 1
   $bulk->ins_or_upd($arr, %c);
   #my ($sth, $sthi, $sthu, $sthe);
}

# Internal method to Prepare any of the ops bulk-op queries
sub prepare {
   my ($bulk, $dbh, %c) = @_;
   my $op = $c{'op'};
   my $qi = $bulk->{$op};
   if (!$qi) {die("No query for bulk-op");}
   my $sth = $dbh->prepare($qi);
   if (!$sth) {die("No statement for $op : ".$dbh->errstr()."");}
   if ($c{'debug'}) {print("PREP($op): $qi\n\n");}
   return($sth);
}

# Keep not stepping on perl built-in
sub _exists {
   my ($sthe, $idvals) = @_;
   my $ok = $sthe->execute(@$idvals);
   if (!$ok) {die("Failed to execute exist query by @$idvals");}
   my $es = $sthe->fetchall_arrayref();
   # Check multiple (likely a false ID field)
   my $cnt = $es->[0]->[0];
   if ($cnt > 1) {die("More than one entry for unique ID !");}
   return($cnt);
   
}
1;
