#!perl -w

# mock up an entire delivery pipeline then include the actual tequila
# and see if it runs
use strict;
use Test::More tests => 1;
use lib qw(t/lib);
use Siesta::Test;
use Siesta;

{
    # create a list with everything
    my $list = Siesta::List->create({
        name         => 'all_plugins',
        owner        => Siesta::Member->create({ email => 'test' }),
        post_address => 'all_plugins@siesta.unixbeard.net',
    });
    for (Siesta->available_plugins) {
        print "# adding $_\n";
        $list->add_plugin( post => $_ );
    }
}

$ENV{SIESTA_NON_STOP} = 1;
Siesta->process( action => 'post',
                 list   => 'all_plugins',
                 mail   =>  <<'MAIL');
To: dealers@front-of.quick-stop
From: Bob <bob@front-of.quick-stop>
Mailer: hack to stop Mail::DeliveryStatus::BounceParser spewing
X-Mailer: hack to stop Mail::DeliveryStatus::BounceParser spewing
Subject: .

--
<bob@front-of.quick-stop>
MAIL

ok(1, "it all ran");
