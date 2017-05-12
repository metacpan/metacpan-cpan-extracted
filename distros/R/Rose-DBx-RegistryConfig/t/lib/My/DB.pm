package My::DB;
use base qw( Rose::DBx::RegistryConfig );

use strict;
use warnings;
use Carp;

# Use data source registry that is specific to this class...
__PACKAGE__->use_private_registry();

# Set default DBI options...
__PACKAGE__->default_connect_options(
    PrintError          => 0,
    ShowErrorStatement  => 1,
);

#-------

# Recognize special keys 'db_prefix' and 'db_suffix' in the domain defaults
# hash.  If the database name is unspecified, it is assumed to be the type
# name with prefix prepended and suffix appended.  This simplifies
# representation of e.g. SQLite databases, which should be path names with
# the '.sqlite' suffix.
sub parse_domain {
    my ($class, %param) = @_;

    my $registry        = $param{registry};
    my $domain_name     = $param{domain_name}       or carp "param 'domain_name' required";
    my $domain_hashref  = $param{domain_hashref}    or carp "param 'domain_hashref' required";

    $registry->isa( 'Rose::DB::Registry' ) or carp "param 'registry' must be a Rose::DB::Registry object";

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

#-------
1;

__END__

=for Purpose
    / This module exists as a demonstration and test of inheritance from
    / Rose::DBx::RegistryConfig.
    /
    / It overrides the Rose::DBx::RegistryConfig default domain parser to
    / recognize an alternative class-wide default DOMAIN_CONFIG representation.
    / 
    / (there is no need to override _load_yaml_fixups_from_file() because
    / fix-up files for this representation would be handled by the superclass
    / method by default.

=cut

