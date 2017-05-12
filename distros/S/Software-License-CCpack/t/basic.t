use strict;
use warnings;

use Test::More;
use File::Spec;

my $year = (localtime)[5]+1900;
my @modules = map { s/^lib\W|\.pm$//g; s/\W/::/g; $_; } grep { !/CCpack/ } glob File::Spec->catdir(qw/lib Software License *.pm/);
my %methods = (
   name       => qr/^Creative Commons Attribution[\w\-]* \d\.0(?: Unported| International)? License \(CC BY[\w\-]* \d\.0\)$/,
   url        => qr{^http://creativecommons\.org/licenses/by[a-z\-]*/\d\.0/$},
   meta_name  => qr/^(?:un)?restricted$/,
   meta2_name => qr/^(?:un)?restricted$/,
   year       => qr/^$year$/,
   holder     => qr/^\QJ. Phred Bloggs\E$/,
   notice     => qr/^\QThis work, created by J. Phred Bloggs, is licensed under a\E\nCreative Commons Attribution[\w\-]* \d\.0(?: Unported| International)? License.\n/m,
   license    => qr/^\s*Creative Commons Legal Code\n\n\s*Attribution[\w\-]* \d\.0(?: Unported| International)?/m,
   version    => qr/^\d\.0$/,
);

$methods{fulltext} = qr($methods{notice}.+$methods{license})s;

plan tests => @modules * (3 + scalar keys %methods);

for my $module (@modules) {
   require_ok($module);
   my $obj = new_ok($module, [{ holder => 'J. Phred Bloggs' }]);
   can_ok($obj, keys %methods);

   foreach my $method (keys %methods) {
      ($module =~ /Software::License::CC_PDM/ && $method =~ /name|url|notice|license|version|fulltext/) ?
         ok  ($obj->$method(),                    "$module->$method (lite)") :
         like($obj->$method(), $methods{$method}, "$module->$method");
   }
}

done_testing;
