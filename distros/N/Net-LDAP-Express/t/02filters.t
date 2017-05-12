use Test::More tests => 20 ;

# $Id: 02filters.t,v 1.2 2004/12/04 18:10:34 bronto Exp $

my $fulltest  = 20 ;
my $shorttest = 1 ;

BEGIN {
  use_ok('Net::LDAP::Express') ;
}

SKIP: {
  skip "doing local tests only",$fulltest-$shorttest
    unless $ENV{TEST_HOST} ;

  my $server = $ENV{TEST_HOST}             || 'localhost' ;
  my $port   = $ENV{TEST_PORT}             || 389 ;
  my $base   = "ou=test,$ENV{TEST_BASE}"   || 'ou=simple,o=test' ;
  my %parms  = (host => $server, port => $port, base => $base) ;

  my $word  = 'test' ;
  my @attrs = qw(cn sn uid mail) ;
  my @bools = qw(| &) ;
  my @match = qw(a s) ;
  my %matchname = (a => 'approx', s => 'substr') ;

  my %tests ;

  {
    # If you are thinking that this piece of code is ugly, well, I
    # agree with you.  I know I could "compress" a couple of cycle
    # into one, but I don't need the tests to be fast, I just need
    # them to be debuggable in case I did something wrong.
    my %testparms ;
    my %filters   ;
    my @subattrs ;

    # Initialize @subattrs ;
    for (my $i = 0 ; $i <= $#attrs ; $i++) {
      push @subattrs,[@attrs[0..$i]] ;
    }

    # Initialize %testparms by $bool and $match
    foreach my $b (@bools) {
      foreach my $m (@match) {
	$testparms{$b}{$m} = makeparms($b,$m) ;
      }
    }

    # Initialize %filters
    foreach my $b (@bools) {
      foreach my $m (@match) {
	my $w  = $m eq 'a'? $word : "*$word*" ;
	my $op = $m eq 'a'? '~='  : '=' ;
	my @filters = "($attrs[0]$op$w)" ;
	my $chain   = $filters[0] ;
	for (my $i = 1 ; $i <= $#attrs ; $i++) {
	  $chain .= "($attrs[$i]$op$w)" ;
	  push @filters,"($b$chain)" ;
	}

	$filters{$b}{$m} = \@filters ;
      }
    }

    # Initialize %tests using @subattrs, %testparms and %filters
    foreach my $b (@bools) {
      foreach my $m (@match) {
	my @f = @{$filters{$b}{$m}} ;
	for (my $i = 0 ; $i <= $#f ; $i++) {
	  my %p = %{$testparms{$b}{$m}} ;
	  $p{searchattrs} = $subattrs[$i] ;
	  $tests{$b}{$m}{$f[$i]} = \%p ;
	}
      }
    }
  }

  # Different objects create different filters
  {
    my ($sim1,$sim2) ;
    ok($sim1 = Net::LDAP::Express->new(%parms,
				      searchattrs => [qw(uid mail cn)])) ;


    ok($sim2 = Net::LDAP::Express->new(%parms,
				      searchattrs => [qw(fn sn cn)])) ;

    my $filt1 = $sim1->_makefilter($word) ;
    my $filt2 = $sim2->_makefilter($word) ;

    isnt($filt1,$filt2,'filters') ;
  }

  ########################################################################
  # Filters are what they should
  #diag('Filters are printed before they undergo the test') ;
  foreach my $b (@bools) {
    foreach my $m (@match) {
      while (my ($f,$p) = each %{$tests{$b}{$m}}) {
	my $r = Net::LDAP::Express
	  ->new(%parms,%$p)
	    ->_makefilter($word) ;
	#diag($f) ;
	is($r,$f,
	   "bool: $b, attrs: ".scalar(@{$p->{searchattrs}}).
	   ", match: $matchname{$m}") ;
      }
    }
  }

  # This subroutine is here just to let it see %matchname. I didn't
  # want %matchname the only test variable to live outside the SKIP
  # block.
  sub makeparms {
    my ($b,$m) = @_ ;
    my %parms ;

    $parms{searchbool}  = $b             if $b eq '&' ;
    $parms{searchmatch} = $matchname{$m} if $m eq 's' ;

    return \%parms ;
  }
}

