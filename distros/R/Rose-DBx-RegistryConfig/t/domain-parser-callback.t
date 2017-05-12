
# Demonstrate and test the capability of Rose::DBx::RegistryConfig to
# recognize novel "data source namespace" designs using a callback...

use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More tests => 3;

use constant DOMAIN_CONFIG_PATH => 't/config/domain_config_sqlite.yaml';
use constant DOMAIN             => 'dev-local-sqlite';
use constant TAXONOMY_DBNAME    => 't/db/taxonomy.sqlite';

use_ok( 'Rose::DBx::RegistryConfig' );

ok( my $independently_built_registry = Rose::DBx::RegistryConfig->conf2registry(
        domain_config               => DOMAIN_CONFIG_PATH,
        parse_domain_hash_callback  => \&parse_sqlite_domain,
    ),
    'build registry from file '
);
is( $independently_built_registry->entry(
        domain => 'dev-local-sqlite',
        type => 'taxonomy'
    )->database( ),
    TAXONOMY_DBNAME,
    'properly assumed database name default according to example SQLite rules'
);

#-------

=for Example
    / This alternative domain parser implements some special rules for
    / interpreting a DOMAIN_CONFIG containing SQLite databases:
    /
    / The 'defaults' section is structured as with the
    / Rose::DBx::RegistryConfig default, except 'db_prefix' and 'db_suffix'
    / are new indicators that describe how to convert a type name to a
    / database name for any arbitrary type that may be added.
    / 1) prepend the 'db_prefix' to the type name
    / 2) append the 'db_suffix'

=cut

sub parse_sqlite_domain {
    my (%param) = @_;

    my $registry        = $param{registry};
    my $domain_name     = $param{domain_name}       or die "param 'domain_name' required";
    my $domain_hashref  = $param{domain_hashref}    or die "param 'domain_hashref' required";

    $registry->isa( 'Rose::DB::Registry' ) or die "param 'registry' must be a Rose::DB::Registry object";

    # First get defaults...
    my $defaults = $domain_hashref->{defaults} && delete $domain_hashref->{defaults};

    # Recognize special abbreviations for sqlite...
    my $prefix = $defaults->{database}->{db_prefix};
    my $suffix = $defaults->{database}->{db_suffix};
    exists $defaults->{database} && delete $defaults->{database};

    # Process remaining entries...
    for my $type_name ( keys %$domain_hashref ) {
        my $this_type_hash = $domain_hashref->{$type_name};

        # Override any unspecified entries from provided type with defaults...
        for my $default (keys %$defaults) {
            $this_type_hash->{$default} ||= $defaults->{$default};
        }
        # If database name not provided, assume it is a sqlite file based on
        # the type name, with optional prefix/suffix...
        my $database_name = $type_name;
        $database_name = $prefix . $database_name if $prefix;
        $database_name .= $suffix if $suffix;
        $this_type_hash->{database} ||= $database_name;

        $registry->add_entry(
            domain  => $domain_name,
            type    => $type_name,
            %$this_type_hash
        );
    }
    return $registry;
}

