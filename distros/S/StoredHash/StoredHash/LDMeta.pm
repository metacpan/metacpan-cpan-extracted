# LD Meta Fetch

# Sample ObjectClasses from a set of ents (use loadset with few attrs)
#
#use Net::LDAP::Schema;
package StoredHash::LDMeta;
use Data::Dumper;

sub meta {
   my ($p) = @_;
   my ($ldap, $sc) = @$p{'dbh','table'};
   my $schema = $ldap->schema();
   # get objectClasses
   my @ocs = $schema->all_objectclasses();
   
   my @atts = $schema->all_attributes;
   my %attsidx = map({$_->{'name'}, $_;} @atts);
   # Attrs: 'max_length' 'single-value'
   my $mka = sub {
      my ($ats, $man, $ocn) = @_;
      map({
         #my $an = mkals($_);
	 
         {'tabname' => $ocn, 'attrname' => $_, 'notnull' => $man, };
      } @$ats);
   };
   # Refine
   for my $oc (@ocs) {
      my $ocn = $oc->{'name'};
      my ($am, $ao) = @$oc{'must', 'may'};
      my $as = $oc->{'attrs'} = [$mka->($am, 1, $ocn), $mka->($ao, 0, $ocn)];
      delete(@$oc{'must', 'may'});
      map({
         my $an = $_->{'attrname'};
         my $ldm = $attsidx{$an};
	 if (my $v = $ldm->{'max_length'}) {$_->{'dlen'} = $v;}
	 if (my $v = $ldm->{'desc'}) {$_->{'longdesc'} = $v;}
	 # Prefer slightly longer alias if present
	 #if (length($ldm->{'name'} < 6) && ref($ldm->{'aliases'})) {
	 #   $_->{'attrname'} = $ldm->{'aliases'}->[0];
	 #}
	 if ($ldm->{'single-value'}) {$_->{'multiplicity'} = 1;}
	 # Desive type from 'equality' 'substr'
	 my $eq = $ldm->{'equality'};
	 my ($dtype);
	 # distinguishedNameMatch
	 if    ($eq =~ /caseIgnore/) {$dtype = 'char';}
	 elsif ($eq =~ /^integer/) {$dtype = 'int';}
	 elsif ($eq =~ /^numericString/) {$dtype = 'float';} # numeric
	 elsif ($eq =~ /^boolean/) {$dtype = 'bool';}
	 elsif ($eq =~ /^generalizedTime/) {$dtype = 'datetime';}
	 elsif ($eq =~ /^telephoneNumber/) {$dtype = 'char';}
	 elsif ($eq =~ /^octetString/) {$dtype = 'blob';}
	 elsif ($eq =~ /^caseExact/) {$dtype = 'char';}
	 #elsif ($eq =~ /bitStringMatch/) {$dtype = 'char';} # Mask ?
	 elsif ($eq =~ /^distinguishedName/) {$dtype = 'char';$optsrc = 'ldap';}
	 #elsif ($eq =~ /caseIgnore/) {$dtype = 'char';}
	 if ($ldm->{'desc'} =~ /binary$/) {$dtype = 'blob';}
	 $_->{'dtype'} = $dtype;
      } @$as);
      
   }
   # Get the attributes
   #my @atts = $schema->all_attributes;
   print(Dumper(\@ocs));
   #print(Dumper(\@atts));
}
1;
