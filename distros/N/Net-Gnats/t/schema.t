use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats qw(verbose verbose_level);
use Net::Gnats::Schema;
use Net::Gnats::Session;

Net::Gnats->verbose(1);
Net::Gnats->verbose_level(1);

use File::Basename;
use lib dirname(__FILE__);
use Net::Gnats::TestData::Gtdata qw(connect_standard conn user schema1);

my $module = Test::MockObject::Extends->new('IO::Socket::INET');
$module->fake_new( 'IO::Socket::INET' );
$module->set_true( 'print' );
$module->set_series( 'getline',
                     @{ conn() },
                     @{ user() },
                     "210-Now accessing GNATS database 'default'\r\n",
                     "210 User access level set to 'admin'\r\n",
                     @{ schema1() }
                   );

my $g = Net::Gnats->new();
print "Connecting\n";
$g->gnatsd_connect;
$g->login('default', 'madmin', 'madmin');

# initialize new schema
print "init schema\n";
isa_ok my $s = $g->session->schema, 'Net::Gnats::Schema';

print "lookup field\n";
is $s->field('Synopsis')->name, 'Synopsis';
is $s->field('Synopsis')->description, 'One-line summary of the PR';
is $s->field('Synopsis')->type, 'Text';
is $s->field('Synopsis')->default, '';
is $s->field('Synopsis')->flags, 'textsearch ';

is $s->field('Number')->name, 'Number';
is $s->field('Number')->description, 'PR Number';
is $s->field('Number')->type, 'Integer';
is $s->field('Number')->default, '-1';
is $s->field('Number')->flags, 'readonly ';

done_testing();
