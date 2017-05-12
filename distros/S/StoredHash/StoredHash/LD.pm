#=head1 NAME
# StoredHash::LD - LDAP storage backend for StoredHash
#=SYNOPSIS
#   use StoredHash::LD;
#   my $ld = Net::LDAP->new('ldap.myshop.com');
#   my $shp = StoredHash::LD->new('table' => 'ou=people,o=myshop', 'dbh' => $ld);
#
#=head1 DESCRIPTION
# General notes:
#=over 4
#=item * LDAP Does not support composite keys. Because of this passing id as
#scalar value (i.e. not as an arrayref) is allowed.
#=item * LDAP Update is an inherently complex operation as it is broken down to:
#=over 4
#=item * attribute additions
#=item * attribute deletions
#=item * attribute value modifications
#back
#=item * Update complexity is further aplified by the multiple values (per attribute)
#that every LDAP entry supports
#=item * As such LDAP update may be costly operation, especially in large bulk
#modifications.
#=item * Because of multivalue holding capability of all All entries
#=back

# 

#=cut
package StoredHash::LD;

use Net::LDAP;
use Net::LDAP::Constant qw(LDAP_SUCCESS LDAP_COMPARE_TRUE LDAP_COMPARE_FALSE);

use strict;
use warnings;
use Data::Dumper;
use StoredHash;
# Inherit all
#our @ISA = ('StoredHash');
use base ('StoredHash');
#use base ('StoredHash::NoSQL');
our $VERSION = '0.30';
# LDAP Helpers
sub success {
   my ($mesg) = @_;
   
   if ($mesg->code() eq Net::LDAP::LDAP_SUCCESS()) {return(1);}
   return(0);
}

#=head2 StoredHash->new(%opts)
#
#Notes on keyword parameters (in %opts).
#
#=over 4
#
#=item * 'table' needs to be a LDAP base suffix for the directory path
# where entries will reside and where they are searched from (with scope=one).
#
#=item * 'dbh' must be a valid Net::LDAP connection.
#
#=cut
sub new {
   my ($class, %opt) = @_;
   my $shp = StoredHash->new(%opt);
   bless($shp, $class);
}

#sub errstr {
#   my ($p, $v) = @_;
#   $ars_errstr
#}
#sub qexecute {
#   my ($p, $q, $vals, $rett) = @_;

# Class utility method to extract and validate the id from either array (ref)
# or scalar id paramater. simpleid considers composite keys as an error and
# throws exceptions on them.
sub simpleid {
   my ($eid) = @_;
   my $isarr = ref($eid) eq 'ARRAY' ? 1 : 0;
   if ($isarr && (scalar(@$eid) == 1)) {$eid = $eid->[0];}
   elsif ($isarr) {die("Entry ID must be passed as array of single id or non-empty scalar id");}
   # Check other refs ?
   # Check non-empty
   if (!$eid) {die("ID should not be empty value !");} # Allow '0' / 0 ?
   return($eid);
}

# Hash %$e may contain attributes with single (scalar) value or array
# of multiple values
sub insert {
   my ($p, $e) = @_;
   my ($ldap, $sc) = @$p{'dbh', 'table'};
   my $ida = $p->{'pkey'}->[0];
   my $idv;
   if (!($idv = $e->{$ida})) {die("LDAP Entry Must have ID (In hash) on insert");}
   my $dn = "$ida=$idv,$sc";
   # Serialize to array as perl Net::LDAP API. values (odd index
   # elems) may be arrays
   my @kvs = map({($_, $e->{$_});} keys(%$e));
   my $mesg = $ldap->add($dn, 'attrs' => [@kvs]);
   if (!success($mesg)) {die("Failed to create entry (".$mesg->error().")\n");}
   return([$idv]);
}
# 
sub update {
   my ($p, $e, $eid) = @_;
   my ($ldap, $sc) = @$p{'dbh', 'table'};
   my $ida = $p->{'pkey'}->[0];
   if ((ref($eid) eq 'ARRAY') && (scalar(@$eid) == 1)) {$eid = $eid->[0];}
   #my @kvs = map({($_, $e->{$_});} keys(%$e));
   my $eo = $p->load($eid);
   if (!$eo) {die("No Entry to update ('$eid')");}
   if (ref($eo) ne 'HASH') {die("No Entry as HASH to update ('$eid')");}
   # Do some diffing on $eo, $e
   # Change organized as add,delete,replace
   my @ch = ld_delta($eo, $e, $ida);
   print(Dumper(\@ch));
   return(0);
   # Separate round for ID ?
   my $rdn;
   # Check that NOT multival ?
   #if ($rep{$ida}) {$rdn = "$ida=$rep{$ida}";}
   # Can be done in single step
   my $dn = "$ida=$eid,$sc";
   my $mesg = $ldap->modify($dn, 'add' => {} );
   if (!success($mesg)) {die("Failed to modify entry (".$mesg->error().")\n");
      return(0);
   }
   #if ($rdn) {$mesg = $ldap->moddn( $dn, 'newrdn' => $rdn );}
   return(1);
}

   # How to (distinguish): add,delete,replace
   # Need to get existing ? Perform a diff to see add/del/replace
   # By default no attr deletions ? Or delete on existing attr = undef
sub ld_delta {
   my ($eo, $e, $ida) = @_;
   my (%add, %del, %rep);
   
   my $ismv  = sub {ref($_[0]) eq 'ARRAY' ? 1 : 0;};
   my $mvcnt = sub {
      if (ref($_[0]) eq 'ARRAY') {return(scalar(@{$_[0]}));}
      return(1);
   };
   my @ksnew = keys(%$e);
   # Consider keys of mod
   for my $k (@ksnew) {
      # Skip RDN / ID Attribute
      if ($k eq $ida) {next;}
      my $vnew = $e->{$k};
      my $vold = $eo->{$k}; # #$eo->get_value($_);
      # New undef (but exists), delete
      if (!defined($vnew)) {
   	 if ($vold) {$del{$k} = 1;}
   	 else {}
   	 next;
      }
      # Not in old, add new
      elsif (!$vold) {
         if ($vnew) {$add{$k}= $vnew;}
	 else {}
      }
      # In both, replace
      # Check if same, also consider multival
      # Use Value counts ?
      else {
         my $vcold = $mvcnt->($vold);
	 my $vcnew = $mvcnt->($vnew);
	 # TODO: test single here to elim most simple case ?????
	 #if    (!$ismv->($vold) && !$ismv->($vnew)) {$rep{$k} = $vnew;}
	 # Different type: multival/ singleval
   	 if    (!$ismv->($vold) && $ismv->($vnew)) {$rep{$k} = $vnew;}
	 elsif ($ismv->($vold) && !$ismv->($vnew)) {$rep{$k} = $vnew;}
	 # Same type: single or multival
	 # Else Need more thorough comp
	 else {
	    if (($vcold == 1) && ($vcnew == 1)) {
	       # Count 1, value Same, do nothing
	       if ($vold eq $vnew) {}
	       # Replace with new
	       else {$rep{$k} = $vnew;}
	    }
	    # Both multival
	    else {
	       # Counts differ, use new
	       if ($vcold != $vcnew) {$rep{$k} = $vnew;}
	       # Same count
	       # Trick: Sort vals, join and compare
	       else {
	          my $cnt = $vcold;
		  my $o = join('', sort($vold));
		  my $n = join('', sort($vnew));
		  # Same effective content
		  # TODO: Allow re-order (by temp delete)
		  if ($o eq $n) {}
		  # Different content
		  else {$rep{$k} = $vnew;}
	       }
	    }
	 }
	 
      }
   }
   return(\%add, \%del, \%rep);
   #return('add' => \%add, 'delete' => \%del, 'replace' => \%rep);
}

#=head2 $shp->delete([$eid])
# Delete an Entry by id from LDAP directory.
#=cut
sub delete {
   my ($p, $eid) = @_;
   my ($ldap, $sc) = @$p{'dbh', 'table'};
   if ((ref($eid) eq 'ARRAY') && (scalar(@$eid) == 1)) {$eid = $eid->[0];}
   if (!$eid || ref($eid)) {die("Entry ID must be passed as array of single item or non-empty scalar");}
   my $pka = $p->{'pkey'}->[0];
   my $dn = "$pka=$eid,$sc";
   my $mesg = $ldap->delete($dn);
   if (!success($mesg)) {die("Failed to delete entry (".$mesg->error().")\n");}
}
sub exists {
   my ($p, $eid) = @_;
   my ($ldap, $sc) = @$p{'dbh', 'table'};
   if ((ref($eid) eq 'ARRAY') && (scalar(@$eid) == 1)) {$eid = $eid->[0];}
   # Implement as compare ?
   my $pka = $p->{'pkey'}->[0];
   my $dn = "$pka=$eid,$sc";
   my $base = $sc; # $dn
   my $mesg = $ldap->compare($dn, 'attr' => $pka, 'value' => $eid);
   #  How to analyze mesg for compare
   my $cm = $mesg->code();
   if ($cm eq LDAP_COMPARE_TRUE()) {return(1);} # 
   return(0);
}
# Load 
sub load {
   my ($p, $eid) = @_;
   my ($ldap, $sc) = @$p{'dbh', 'table'};
   if ((ref($eid) eq 'ARRAY') && (scalar(@$eid) == 1)) {$eid = $eid->[0];}
   my @ats = $p->{'attrs'} || (); # TODO: %o $o{'attrs'}
   my $pka = $p->{'pkey'}->[0];
   my $dn = "$pka=$eid,$sc";
   #attrs => [qw(cn)]
   my @atpara = ();
   if (@ats) {@atpara = ('attrs', \@ats);}
   my $qs = wherefilter({$pka => $eid, });
   # Use scope ?
   my $base = $sc;
   my $mesg = $ldap->search('base' => $base, 'filter' => $qs, @atpara);
   if (!success($mesg)) {die("Failed to load entry (".$mesg->error().")\n");}
   my $ent;
   my @es = $mesg->entries();
   if (!@es || (@es > 1)) {die("None or not unique");return(undef);}
   $ent = $es[0];
   if (!ref($ent)) {die("Not a reference");}
   #NOT:my %vals = %$ent;
   my $vals = entry2hash($ent);
   return($vals);
}
# Convert Net::LDAP::Entry To Plain Perl hash(ref)
# Add a pseudo-attribute 'dn' for distinguished name.
# Return hash(ref)
sub entry2hash {
   my ($ent) = @_;
   my @atvs = @{$ent->{'asn'}->{'attributes'}}; # $_[0]
   #if ($p->{'debug'}) {print(Dumper(\@atvs));}
   my %vals = map({
      if (!$_->{'vals'}) {();}
      else {
         my $v = (scalar(@{$_->{'vals'}})  == 1 )? $_->{'vals'}->[0] : $_->{'vals'};
         ($_->{'type'}, $v);
      }
   } @atvs);
   $vals{'dn'} = $ent->dn();
   return(\%vals);
}


sub loadset {
   my ($p, $h, $sort) = @_; # filter, sortby
   my ($ldap, $sc) = @$p{'dbh', 'table'};
   my $qs = wherefilter($h);
   my $mesg = $ldap->search('base'=> $sc, 'filter' => $qs);
   
   my @es;
   # Convert to plain perl hash
   @es = map({entry2hash($_);} $mesg->entries());
   #for my $e ($mesg->entries()) {push(@es, entry2hash($e));}
   
   return(\@es);
}
# Need to do entry stats or inspect schema
# Option: Sample objectclasses, query schema by them ?
sub cols {
   my ($p, %c) = @_;
   my ($ldap, $sc) = @$p{'dbh', 'table'};
   # Use scope ?
   my $mesg = $ldap->search('base'=> $sc, 'filter' => 'objectclass=*');
   my $ent;
   my @es = $mesg->entries();
   if (!($ent = $es[0])) {die("No entries");}
   # Sample all ?
   my @attrs = $ent->attributes();
   return(\@attrs);
}
#sub loadtree {
#   my ($p, %c) = @_;
#   
#}

# Load Children by DN attrs (to what attrs "_..." ?)
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

# Should not be used with LDAP
sub fetchautoid {
   my ($p) = @_;
   die("fetchautoid - Not Relevant with LDAP\n");
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

sub invalues {
   my ($vals, $attr) = @_;
   my @ivc = map({"($attr=$_)";} @$vals);
   #"(".
   return join('', @ivc);
   #.")";
}
sub rangefilter {
   my ($attr, $v) = @_;
}

# Internal method to generate LDAP search Filter.
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
   @qc = map({
      my $v = $e->{$_};
      #my $rv = ref($v);
      #if ($rnga->{$_} && ($rv eq 'ARRAY') && (@$v == 2)) {rangefilter($_, $v);}
      if (ref($v) eq 'ARRAY') {
         "(|".invalues($v, $_).")";
      }
      # SQL Wildcard
      elsif ($v =~ /%/) {"($_=$v)";}
      # Detect numeric (likely numeric, not perfect)
      elsif ($v =~ /^\d+$/) {"($_=$v)";}
      # Assume string
      else {"($_=".StoredHash::sqlvalesc($v).")";}
      
   } @keys);
   return(join($fop, @qc));
}
sub allentvals {
   my ($h) = @_;
}
