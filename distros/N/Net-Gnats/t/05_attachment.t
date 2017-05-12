use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats;
use Net::Gnats::PR;
use Net::Gnats::Field;
use Net::Gnats::FieldInstance;

use 5.10.00;

Net::Gnats->verbose(1);
Net::Gnats->verbose_level(1);

use File::Basename;
use lib dirname(__FILE__);
use Net::Gnats::TestData::Gtdata qw(connect_standard_wauth);

my $module = Test::MockObject::Extends->new('IO::Socket::INET');
$module->fake_new( 'IO::Socket::INET' );
$module->set_true( 'print' );
$module->set_series( 'getline',
                     @{ connect_standard_wauth() },
                     "212 Ok.",  # send text
                     "210 Ok.",  # accept text
                   );

my $g = Net::Gnats::Session->new(username => 'madmin', password => 'madmin');
$g->gconnect;

# EDIT requires a PR, so hydrate.
my $pr1 = Net::Gnats::PR->deserialize(data => pr1(), schema => $g->schema);
my $pr2 = Net::Gnats::PR->deserialize(data => pr2(), schema => $g->schema);
is scalar @{ $pr1->{attachments} }, 1, 'one attachment';
is scalar @{ $pr2->{attachments} }, 2, 'two attachments';

done_testing();
#say $pr1->get_field('Unformatted')->value;

sub pr1 {
 return ["To: bugs\r\n",
         "Cc: \r\n",
         "Subject: Your product sucks\r\n",
         "From: riche\@cpan.org\r\n",
         "Reply-To: riche\@cpan.org\r\n",
         "X-Send-Pr-Version: Net::Gnats-5\r\n",
         "\r\n",
         ">Number: 50\r\n",
         ">Synopsis: A great synopsis\r\n",
         ">Priority: high\r\n",
         ">Unformatted:\r\n",
         qq| ----gnatsweb-attachment----\r\n|,
         qq| Content-Type: application/x-gzip; name="foo.png"\r\n|,
         qq| Content-Transfer-Encoding: base64\r\n|,
         qq| Content-Disposition: attachment; filename="gnatsweb-4.00.tar.gz"\r\n|,
         qq| \r\n|,
         qq| H4sIAMdnJj8AA+RbW3MayZKe1+FX1LHlRZ4DCNBtLIXPGEttmzACHUD2KHY3Ohq6gB71zV3dwpzd\r\n|,
         qq| H79fZlVfQMjnZeZpNRGyqEtWVl6/zGKWoZOqtZw1T1rt9tFPf8lPu33SPj89/al90jltn+Hfdrtz\r\n|,
         qq| ftqmf/Ofn9rn553Oydnxefsc452Tbrf70+lfw872T6ZSJ8GRG9U5Pjv/tfPcurmPlYnzLB26xcnp\r\n|,
         qq| \r\n|,
         qq| \r\n|,
         ".\r\n"];
}
sub pr2 {
 return ["To: bugs\r\n",
         "Cc: \r\n",
         "Subject: Your product sucks\r\n",
         "From: riche\@cpan.org\r\n",
         "Reply-To: riche\@cpan.org\r\n",
         "X-Send-Pr-Version: Net::Gnats-5\r\n",
         "\r\n",
         ">Number: 50\r\n",
         ">Synopsis: A great synopsis\r\n",
         ">Priority: high\r\n",
         ">Unformatted:\r\n",
         qq| ----gnatsweb-attachment----\r\n|,
         qq| Content-Type: application/x-gzip; name="foo.png"\r\n|,
         qq| Content-Transfer-Encoding: base64\r\n|,
         qq| Content-Disposition: attachment; filename="foo.png"\r\n|,
         qq| \r\n|,
         qq| H4sIAMdnJj8AA+RbW3MayZKe1+FX1LHlRZ4DCNBtLIXPGEttmzACHUD2KHY3Ohq6gB71zV3dwpzd\r\n|,
         qq| H79fZlVfQMjnZeZpNRGyqEtWVl6/zGKWoZOqtZw1T1rt9tFPf8lPu33SPj89/al90jltn+Hfdrtz\r\n|,
         qq| ftqmf/Ofn9rn553Oydnxefsc452Tbrf70+lfw872T6ZSJ8GRG9U5Pjv/tfPcurmPlYnzLB26xcnp\r\n|,
         qq| \r\n|,
         qq| ----gnatsweb-attachment----\r\n|,
         qq| Content-Type: application/x-gzip; name="foo.png"\r\n|,
         qq| Content-Transfer-Encoding: base64\r\n|,
         qq| Content-Disposition: attachment; filename="foo.png"\r\n|,
         qq| \r\n|,
         qq| H4sIAMdnJj8AA+RbW3MayZKe1+FX1LHlRZ4DCNBtLIXPGEttmzACHUD2KHY3Ohq6gB71zV3dwpzd\r\n|,
         qq| H79fZlVfQMjnZeZpNRGyqEtWVl6/zGKWoZOqtZw1T1rt9tFPf8lPu33SPj89/al90jltn+Hfdrtz\r\n|,
         qq| ftqmf/Ofn9rn553Oydnxefsc452Tbrf70+lfw872T6ZSJ8GRG9U5Pjv/tfPcurmPlYnzLB26xcnp\r\n|,
         qq| \r\n|,
         qq| \r\n|,
         ".\r\n"];
}
