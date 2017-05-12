use Test::More;

use warnings;
use POE;

# this quiets the warning "POE::Kernel's run() method was never called."
POE::Kernel->run();

my $CONF = do "config.cache";

if( 0 and $CONF->{skip_all_tests} ) {
    plan skip_all => 'No SNMP data specified.';
}
else {
    plan tests => 6;
}

eval { require POE::Component::SNMP };
ok(!$@, "you just saved a kitten");

ok $POE::Component::SNMP::Dispatcher::INSTANCE, 'loaded';
ok $POE::Component::SNMP::Dispatcher::INSTANCE->isa('POE::Component::SNMP::Dispatcher'), 'correct class';

# THERE IS A TYPO IN '-hosntame'! this should generate an error!
eval { POE::Component::SNMP->create(
                                    -alias     => 'snmp',
                                    -hosntame  => $CONF->{hostname} || 'localhost',
                                    -community => $CONF->{community}|| 'public',
                                    -debug     => $CONF->{debug},
                                    -timeout   => 5,
                                   )
};

# ok $@, $@;

ok $@ =~ /hostname parameter required/, 'catches parameter typo';

# THIS ONE HAS THE TYPO ON 'debug';
eval { POE::Component::SNMP->create(
                                    -alias     => 'snmp2',
                                    -hostname  => $CONF->{hostname} || 'localhost',
                                    -community => $CONF->{community}|| 'public',
                                    -debgu     => $CONF->{debug},
                                    -timeout   => 5,
                                   )
};

# warn $@;
# ok $@, $@;

ok $@ =~ /^Invalid argument|The argument .* is unknown/, 'catches parameter typo';

eval { POE::Component::SNMP->create() };

# dies, no params supplied. actually dies on missing hostname parameter.
ok $@ =~ /hostname parameter required at/, 'catches missing required param';

