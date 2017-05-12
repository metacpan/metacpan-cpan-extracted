# Dropdown test with scalar iterator

use strict;
use warnings;

use Test::More tests => 2;
use Template::Flute;

use Data::Dumper;
use Data::Transpose::Iterator::Scalar;

my $html = q{
<select class="input-small quantity">
  <option>8</option>
</select>
};

my $spec = q{
<specification>
<value name="quantity" iterator="quantity"/>
</specification>
};

my $scalar = Data::Transpose::Iterator::Scalar->new([1,2]);

my ($flute, $out);

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
			      auto_iterators => 1,
                              values => {quantity => $scalar},
                             );

$out = $flute->process;

ok ($out =~ m%<select class="(.*?)">(.*?)</select>%, 'Check on select');

my $options = $2;

ok ($options eq '<option>1</option><option>2</option>', 'Check options')
  || diag "Output: $out.";

