
# $Id: rt47481.t,v 1.2 2010-04-20 23:42:15 Martin Exp $

# This is a test for RT#47481: Simple triple croaks

use strict;
use warnings;

use blib;
use Data::Dumper;
use Test::More 'no_plan';
use Test::Deep;

my $sMod;

BEGIN
  {
  $sMod = 'RDF::Simple::Serialiser::N3';
  use_ok($sMod);
  } # end of BEGIN block


# diag "Version: $RDF::Simple::Serialiser::N3::VERSION\n";
my ($sSubj, $sPred, $sObj) = qw( urn:x-my:object urn:x-my:property string );
my @triples = ( [ $sSubj, $sPred, \$sObj ] );
my $expected = join(qq{\n},
                    q{@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .}, # },
                    q{},
                    qq{$sSubj a rdf:Description .},
                    qq{$sSubj $sPred "$sObj" .},
                   );

my $oRSSN = new $sMod;
isa_ok($oRSSN, $sMod);
# $oRSSN->addns(urn => 'somewhere');
my $n3 = $oRSSN->serialise( @triples );
# Strip whitespace:
$n3 =~ s/\s+\z//;
is($n3, $expected);

__END__
