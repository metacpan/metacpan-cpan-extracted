# -*- cperl -*-


use strict;
use lib 't/springfield';
use Springfield;
use Data::Lazy;
use Scalar::Util qw(refaddr);

BEGIN {
    eval "use Scalar::Util";
    eval "use WeakRef" if $@;
    if ($@) {
	eval 'use Test::More skip_all => "No WeakRef / Scalar::Util"';
	exit;
    } else {
	eval 'use Test::More tests => 4;';
    }
}

my $VERBOSE;
if ( @ARGV and $ARGV[0] eq "-v" ) {
    $VERBOSE = 1;
    $SpringfieldObject::VERBOSE = 1;
}

# $Tangram::TRACE = \*STDOUT;

my $tests = 3;

{
  my $storage = Springfield::connect_empty;

  $storage->insert( NaturalPerson->new( firstName => 'Homer' ));

  is(leaked, 0, "WeakRef works");

  $storage->disconnect();
}

{
  my $storage = Springfield::connect;

  {
    my ($homer) = $storage->select('Person');
    is($SpringfieldObject::pop, 1,
       "Objects not lost until they fall out of scope");
  }

  is(leaked, 0, "WeakRef still works");

  $storage->disconnect();
}

sub sameid {
    my $obj;
    for (1..2) {
	$obj = {};
	diag("got ".sprintf("0x%.8x",refaddr($obj))
	     .", looking for ".sprintf("0x%.8x",$_[0]||0)) if $VERBOSE;
	last if refaddr($obj) == ($_[0] ||= refaddr($obj));
	$obj = undef;
    }
    $obj;
}

sub homer {
    my ($homer) = $_[0]->select('Person');
    return $homer;
}

SKIP:
{
  my $storage = Springfield::connect;

  my ($sameid,$refaddr, $test) = (undef, 0, undef);
  {
      homer($storage);
  }

  $storage->{schema}{make_object} = sub { my $x = $sameid;
					  bless $x, (shift);
					  $SpringfieldObject::pop++;
					  return $sameid;
				      };
  diag("leaked is: ".leaked) if $VERBOSE;

  # note - this loop is fragile, but worksforme on perl 5.8.4, Ubuntu
  # hoary on amd64.  Reports of other successes welcome.
 LOOP:
  for my $x ( 1..5 ) {
      {
	  $refaddr = 0 unless $x > 2;
	  diag("undef(\$sameid = $sameid)") if $VERBOSE;
	  undef($sameid);
	  undef($test);
	  diag("done undef") if $VERBOSE;
	  $test = sameid($refaddr) or next;
	  tie $sameid, 'Data::Lazy' => sub { $test };
	  diag("test is: ".$test) if $VERBOSE;
	  diag("sameid is: ".$sameid) if $VERBOSE;
	  if ( $x <= 2 ) {
	      homer($storage);
	  } else {
	      diag("wohoo! I got ".sprintf("0x%.8x",refaddr($sameid)
					  )) if $VERBOSE;
	      diag ("calling last") if $VERBOSE;
	      last LOOP;
	  }
      }
      diag("leaked is: ".leaked) if $VERBOSE;
  }

  skip "failed to get an object with the same refid", 1
      unless $sameid;

  is($storage->id($sameid), undef, "hmm!");

  $storage->disconnect();
}

