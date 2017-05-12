use strictures 1;
package Mojito::Role::DB::OID;
{
  $Mojito::Role::DB::OID::VERSION = '0.24';
} 
use Moo::Role;

sub generate_mongo_like_oid {
  my $oid;
  for(my $i=0; $i<12; $i++) {
    my $n = int (rand(239) + 17.1);
    $oid .= sprintf "%x", $n;
  }
  if (length $oid != 24) {
    die "length of generated mongo like id is not 24 characters.  
    It's ", length $oid, ' instead';
  }
  return $oid;
}

1;