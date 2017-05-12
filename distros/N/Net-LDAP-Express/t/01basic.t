use Test::More tests => 25 ;

# $Id: 01basic.t,v 1.3 2014/06/22 20:20:19 bronto Exp $

my $fulltest  = 25 ;
my $shorttest = 2 ;

BEGIN {
  use_ok('Net::LDAP::Express') ;
  use_ok('Net::LDAP::Entry') ;
}

SKIP: {
  skip "doing local tests only",$fulltest-$shorttest
    unless $ENV{TEST_HOST} ;
  my $server = $ENV{TEST_HOST}             || 'localhost' ;
  my $port   = $ENV{TEST_PORT}             || 389 ;
  my $base   = "ou=test,$ENV{TEST_BASE}"   || 'ou=simple,o=test' ;
  my $binddn = $ENV{TEST_BINDDN}           || 'cn=admin,o=test' ;
  my $bindpw = $ENV{TEST_BINDPW}           || 'secret' ;
  my @search = qw(uid mail cn objectclass) ;
  my @only   = qw(cn) ;
  my @sortby = qw(sn givenname) ;
  my $query  = 'marco' ;

  my @ent_data = qw(Marco Marongiu
		    Larry Wall
		    Tim Vroom) ;
  my %ent_common = (
		    objectclass => [qw(top person inetOrgPerson)],
		   ) ;
  my $ldap = Net::LDAP::Express->new(host => $server,
				    port => $port,
				    base => $base,
				    bindDN => $binddn,
				    bindpw => $bindpw,
				    searchattrs => \@search) ;

  isa_ok($ldap,'Net::LDAP::Express') ;

  # Add subtrees
  {
    my $r ;
    my $root = Net::LDAP::Entry->new ;
    $root->dn($base) ;
    $root->add(
	       objectclass => [qw(top organizationalUnit)],
	       ou => 'test',
	      ) ;
    $r = $ldap->add_many($root) ;
    ok(@$r == 1 or $ldap->errcode == 68) ; # Ok if already exists
  }

  # add_many
  {
    my @e ;
    while (my ($givenname,$sn) = splice @ent_data,0,2) {
      my $e = Net::LDAP::Entry->new ;
      my $cn = "$givenname $sn" ;
      my $uid = lc $givenname ;
      my $mail = "$uid@"."express.ldap.net" ;

      $e->dn("cn=$cn,$base") ;
      my %attrs = (
		   givenName => $givenname,
		   sn        => $sn,
		   cn        => $cn,
		   mail      => $mail,
		   uid       => $uid,
		   %ent_common,
		  ) ;
      $e->add(%attrs) ;
      push @e,$e ;
    }

    my $r = $ldap->add_many(@e) ;
    cmp_ok(@$r,'==',@e,'add') ;
    is($ldap->error,'','error code for add') ;
  }


  {
    # Search
    my $entries = $ldap->simplesearch('person') ;
    ok(defined($entries),"search") ;
    is($ldap->error,'','error code for search') ;

    # Modify and update
    foreach my $e (@$entries) {
      $e->delete('mail') ;
    }

    my $r = $ldap->update(@$entries) ;
    cmp_ok(@$r,'==',@$entries,'update') ;
    is($ldap->error,'','error code for update') ;
  }

  {
    my ($r,$e) ;

    # Search again, and rename
    my $entries = $ldap->simplesearch('person') ;
    ok(defined($entries),"search") ;
    is($ldap->error,'','error code for search') ;
    cmp_ok(@$entries,'>=',3) ;

    # Rename the first entry
    $e = shift @$entries ;
    $r = $ldap->rename($e,'cn=Graham Barr') ;
    is($ldap->error,'','rename') ;
  }

  # Search and return sorted
  {
    my $ldap = Net::LDAP::Express->new(host        => $server,
				       port        => $port,
				       base        => $base,
				       bindDN      => $binddn,
				       bindpw      => $bindpw,
				       onlyattrs   => \@only,
				       sort_by     => \@sortby,
				       searchattrs => \@search) ;
    my $entries = $ldap->simplesearch('person') ;
    ok(defined($entries),"sorted search returns entries") ;
    is($ldap->error,'','error code for sorted search') ;

    # Check for sortedness
    my @sorted_from_ldap ;
    foreach my $e (@$entries) {
      push @sorted_from_ldap,[$e->get_value('sn'),
			      $e->get_value('givenName')]
    }

    my @sorted_from_sort =
      sort
	{$a->[0] cmp $b->[0] or $a->[1] cmp $b->[1]}
	  @sorted_from_ldap ;

    # Test: make it fail
    # @sorted_from_ldap = reverse @sorted_from_ldap ;

    for (my $i = 0 ; $i <= $#sorted_from_ldap ; $i++) {
      my ($sn1,$fn1) = @{$sorted_from_ldap[$i]} ;
      my ($sn2,$fn2) = @{$sorted_from_sort[$i]} ;
      is($sn1,$sn2,"checking surname $i") ;
      is($fn1,$fn2,"checking first name $i") ;
    }
  }


  # Search again, and delete_many
  {
    my $entries = $ldap->simplesearch('person') ;
    ok(defined($entries),"search") ;

    my $r = $ldap->delete_many(@$entries) ;
    cmp_ok(@$r,'==',@$entries,'delete') ;
    is($ldap->error,'','error code for delete') ;
  }
}
