
# Demonstrate and test usage of ROSEDBRC and auto_load_fixups() with
# Rose::DBx::RegistryConfig...

use strict;
use warnings;

use lib 'lib';
use Test::More tests => 3;

use constant DOMAIN_CONFIG_PATH => 't/config/domain_config_2bfixedup.yaml';

#~~~~ ((( begin test initialization ))) ~~~~

# Path to ROSEDBRC must be in env var or it defaults to /etc/rosedbrc...
$ENV{ROSEDBRC} = $ENV{PWD} . '/t/config/rosedbrc';

#~~~~ ((( end test initialization ))) ~~~~

# Prepare a registry from DOMAIN_CONFIG data and set Rose::DBx::RegistryConfig
# to use it...  (Imagine that we're actually in a production environment.  The
# ROSEDBRC file could be a local, protected file that is not committed into
# revision control.  It could be used to override placeholder settings in
# DOMAIN_CONFIG.)
use Rose::DBx::RegistryConfig
    domain_config   => DOMAIN_CONFIG_PATH,
    target_domains  => [ 'production' ];

Rose::DBx::RegistryConfig->auto_load_fixups();

my $domain = 'production';
for my $type ( qw/ db1 db2 db3 / ) {
    my $entry = Rose::DBx::RegistryConfig->registry()->entry(
        domain  => $domain,
        type    => $type,
    );
    ok( (   $entry->host()      eq 'localhost'  &&
            $entry->username()  eq 'me'         &&
            $entry->password    eq 'foo'        ),
        "auto_load_fixups() updated data for domain '$domain' and type '$type' from template DOMAIN_CONFIG file"
    );
}
