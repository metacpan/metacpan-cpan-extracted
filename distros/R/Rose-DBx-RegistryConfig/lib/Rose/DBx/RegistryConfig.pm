package Rose::DBx::RegistryConfig;
use base qw( Rose::DB );

use strict;
use warnings;
use Carp;

our $VERSION = 0.01;

#-------

sub import {
    my ($pkg, %args) = @_;

    # Optionally set class-wide defaults...
    $pkg->default_domain(   $args{default_domain} || 'default' );
    $pkg->default_type(     $args{default_type}   || 'default' );

    # A registry can be passed explicitly...
    my $registry            = $args{registry};

    # Optional auto-registration of data sources...
    my $domain_config       = $args{domain_config};  # DOMAIN_CONFIG file
    my $target_domains      = $args{target_domains};

    # Support alternative means of interpreting domain hash...
    my $parse_domain_hash   = $args{parse_domain_hash_callback};

    # Optional data source registration...
    $registry && do{ $pkg->registry( $registry ) };

    if( defined $domain_config ) {
        # Auto-registration from DOMAIN_CONFIG...
        (-f $domain_config)
            or croak "DOMAIN_CONFIG file '$domain_config' not found";
        # Parse DOMAIN_CONFIG and auto-register all types in the current domain...
        my $reg = $pkg->conf2registry( domain_config => $domain_config, target_domains => $target_domains, parse_domain_hash_callback => $parse_domain_hash );
        $pkg->registry( $reg );
    }
    return 1;
}

#-------

sub auto_load_fixups {
    my ($class) = @_;

    # Load fixups from YAML fixup file, supporting our compressed YAML
    # namespace representation...
    my $fixup_file = $ENV{'ROSEDBRC'};
    $fixup_file = '/etc/rosedbrc' unless defined $fixup_file && -e $fixup_file;

    if( -e $fixup_file ) {
        if(-r $fixup_file) {
            $class->load_yaml_fixups_from_file( $fixup_file );
        }
        else {
          warn "Cannot read Rose::DB fixup file '$fixup_file'";
        }
    }
    # Defer to Rose::DB for alternative ways to load fixups, suppressing
    # warning about unexpected 'defaults' type...
    local $SIG{__WARN__} = sub {
        $_[0] =~ /no $class data source found for .* type 'defaults'/i
            || warn( @_ )
    };
    $class->SUPER::auto_load_fixups( @_ );
}

#-------

sub load_yaml_fixups_from_file {
    my ($class, $file) = @_;

    my $registry = $class->registry();

    require YAML;
    my @domains = YAML::LoadFile( $file );

    for my $domain_hash (@domains) {
        # Domain hashes have only one key -- the domain name...
        my ($domain_name) = keys %$domain_hash;

        my $this_domain_hash = $domain_hash->{ $domain_name };

        # Get domain defaults...
        my $defaults = $this_domain_hash->{defaults} && delete $this_domain_hash->{defaults};

        for my $type_name (keys %$this_domain_hash) {
            my $this_type_hash = $this_domain_hash->{$type_name};

            # Override any unspecified entries from provided type with defaults...
            for my $default (keys %$defaults) {
                $this_type_hash->{$default} ||= $defaults->{$default};
            }
            my $entry = $registry->entry( domain => $domain_name, type => $type_name );
            unless( $entry ) {
                warn "No $class data source found for domain '$domain_name' and type '$type_name'";
                next;
            }
            # Apply updates...
            while( my ($method, $value) = each %{ $this_type_hash } ) {
                $entry->$method( $value );
            }
        }
    }
    return 1;
}

#-------

sub parse_domain { # Default domain parser implements alt namespace representation
    my ($class, %param) = @_;

    my $registry        = $param{registry};
    my $domain_name     = $param{domain_name}       or croak "param 'domain_name' required";
    my $domain_hashref  = $param{domain_hashref}    or croak "param 'domain_hashref' required";

    $registry->isa( 'Rose::DB::Registry' ) or croak "param 'registry' must be a Rose::DB::Registry object";

    # First get defaults...
    my $defaults = $domain_hashref->{defaults} && delete $domain_hashref->{defaults};

    # Process remaining entries...
    for my $type_name ( keys %$domain_hashref ) {
        my $this_type_hash = $domain_hashref->{$type_name};

        # Override any unspecified entries from provided type with defaults...
        for my $default (keys %$defaults) {
            $this_type_hash->{$default} ||= $defaults->{$default};
        }
        # If database name not provided, assume it is same as type name...
        $this_type_hash->{database} ||= $type_name;

        $registry->add_entry(
            domain  => $domain_name,
            type    => $type_name,
            %$this_type_hash
        );
    }
    return $registry;
}

#-------

sub conf2registry {
    my ($class, %param) = @_;
    
    my $domain_config       = $param{domain_config};
    my $target_domains      = $param{target_domains};   # to register specific domains only
    my $parse_domain_hash   = $param{parse_domain_hash_callback};

    (-f $domain_config) or croak "DOMAIN_CONFIG file '$domain_config' not found";
    require YAML;
    my @domains = YAML::LoadFile( $domain_config );

    # Parse data structure derived from DOMAIN_CONFIG, creating a Registry...
    my $registry = Rose::DB::Registry->new();
    for my $domain_hash ( @domains ) {
        # Domain hashes have only one key -- the domain name...
        my ($domain_name) = keys %$domain_hash;

        if( $target_domains ) {
            # Ignore non-target domains...
            next unless grep { $_ eq $domain_name } @$target_domains;
        }
        my $this_domain_hash = $domain_hash->{ $domain_name };

        # Interpret this domain hash, updating registry accordingly...
        if( $parse_domain_hash ) {
            $parse_domain_hash->( domain_name => $domain_name, domain_hashref => $this_domain_hash, registry => $registry );
        }
        else {
            $class->parse_domain( domain_name => $domain_name, domain_hashref => $this_domain_hash, registry => $registry );
        }
    }
    return $registry;
}

#-------
1;

__END__

=pod

=head1 NAME

Rose::DBx::RegistryConfig - Rose::DB with auto-registration of data sources from YAML configuration file

=head1 DESCRIPTION

Rose::DBx::RegistryConfig helps you work with data source definitions in
YAML-based configuration files, supporting multiple "namespace representations."  It
allows you to register Rose data sources without hard-coding anything directly in
source code.

=head1 MOTIVATION

Using configuration files to store data source definitions instead of
putting this information (which amounts to configuration details) directly in
source code (as is typically done when using Rose::DB) is a valuable convenience in
general.  It becomes especially valuable as the number of data sources increases.

The end goal is to cleanly organize configuration data.  This is not just a
matter of aesthetics.  Small, self-contained configuration files reduce error
and save time.  They are naturally easy to maintain.

=head1 SYNOPSIS & IMPORT ARGUMENTS

    #------- First create a local subclass (recommended):
    package My::DB;
    use base qw( Rose::DBx::RegistryConfig );
    ...
    1;
    __END__

    #------- Then use it in your client code:

    # Use with a DOMAIN_CONFIG file to auto-register all domains:
    use My::DB
        default_domain  => 'devel',
        default_type    => 'mydb',
        domain_config   => '/path/to/DOMAIN_CONFIG';

    # ...or register only a subset of the domains in DOMAIN_CONFIG:
    use My::DB
        domain_config   => '/path/to/DOMAIN_CONFIG',
        target_domains  => [ qw( domain1 domain2 ) ];

    # ...or just use an existing registry:
    use My::DB
        registry        => $registry;   # ($registry defined at compile-time)

    # ...a custom namespace representation can also be supported instead of the default:
    use My::DB
        domain_config   => '/path/to/DOMAIN_CONFIG',
        parse_domain_hash_callback  => \&my_domain_parser;

    # (after 'use()'ing, proceed as you would with Rose::DB...)

Rose::DBx::RegistryConfig is a specialization of Rose::DB.  Understanding the
basic usage of Rose::DB is essential.

Rose::DBx::RegistryConfig provides some alternative ways for working with the
Rose::DB Registry.  Beyond that sphere of responsibility, it behaves like
Rose::DB.  As with Rose::DB, Rose::DBx::RegistryConfig is intended to be
subclassed.

Most interaction with the interface usually takes place via C<import> arguments
(arguments to C<use>).  However, all C<import> arguments are optional.

Import arguments for basic class-wide settings...

=over

=item C<default_domain>

Define the class-wide default domain.

=item C<default_type>

Define the class-wide default type.

=back

Arguments for initializing the data source registry from the
L<DOMAIN_CONFIG|/"DOMAIN_CONFIG"> file are also accepted.  See the arguments by
the following names in L<conf2registry|/"conf2registry">:

=over

=item C<domain_config>


=item C<target_domains>


=item C<parse_domain_hash_callback>


=back

...or, mutually-exclusive to arguments dealing with L<DOMAIN_CONFIG|/"DOMAIN_CONFIG">:

=over

=item C<registry>

A pre-made data source registry object.  This allows you to explicitly cause an
existing registry to be used (NOTE that setting this argument with C<use>
constitutes the use of variable data at compile time, so the registry must be
available then, e.g. by creating it in a BEGIN block).

=back

=head2 Tip: dynamically setting C<import> arguments

When you need to dynamically set arguments to use(), make sure that they are
defined at compile time:

    # Importing with dynamic arguments...
    my $domain_config;
    BEGIN {
        $domain_config = get_rose_dbx_domains_from_somewhere();
    }
    use Rose::DBx::RegistryConfig
        default_domain  => $default_domain,
        default_type    => $default_type,
        domain_config   => $domain_config;

=head1 DOMAIN_CONFIG

F<DOMAIN_CONFIG> is a YAML file containing data source definitions.
Rose::DBx::RegistryConfig interprets the following namespace representation by default:

    # an example domain specifically for a collection of similar databases:
    dev-private:
        defaults:
            driver:     mysql
            host:       dbhost
            username:   me
            password:   foo
        DATASET_A:
        DATASET_B:
        DATASET_C:
        DATASET_D:
        DATASET_E:
    ---
    # another domain:
    otherdomain:
        defaults:
            somemethod:     somevalue
        sometype:
            othermethod:    othervalue
        

This namespace representation is used as the Rose::DBx::RegistryConfig default because the
Rose::DB default representation leads to a large amount of redundant information for
configurations that involve many similar databases.

Note especially the following about this namespace representation:

=over

=item *

The standard namespace representation used by Rose for F<ROSEDBRC> and
C<auto_load_fixups> is the same as this one except it does not have a
'defaults' pseudo-type and is more explicit.  This means that either
representation can be used with Rose::DBx::RegistryConfig.

=item *

DOMAIN_CONFIG must consist of a sequence of Rose domains, which each contain Rose
types and their definitions.

=item *

In addition to the normal types of Rose::DB, the 'defaults' pseudo-type is
recognized.  The L<domain parser|/"_parse_domain"> assumes the default value for
each attribute that is not defined for a type.  Thus, in the above example,
all DATASET data sources will have the value 'mysql' for the driver attribute,
'dbhost' for the host, etc.

=item *

The DATASET_X type names have no 'database' method/value even though the
defaults do not provide a database attribute.  Where does the database name come
from?  The default L<domain parser|/"_parse_domain"> knows to use the type name (DATASET_X) as the
database name if the attribute is omitted.

=item *

This representation is also supported in the "fix-ups" file used for the
F<ROSEDBRC>/C<auto_load_fixups> feature.

=back

Alternative representations may be handled using L<a domain parser|/"parse_domain">,
but NOTE the following restriction: B<DOMAIN_CONFIG should consist of a set of
domain names (the top-level keys)>.  The values can define types in any way
desired, as long as it's YAML.  If this is too restrictive then set the registry explicitly.

=head1 CLASS METHODS

=head2 conf2registry

    my $reg = Rose::DBx::RegistryConfig->conf2registry(
        domain_config   => $domain_config,
        target_domains  => [ 'd1', 'd2', 'd3' ],
        parse_domain_hash_callback  => \&my_domain_parser,
    );

Parse L<DOMAIN_CONFIG|/"DOMAIN_CONFIG> and use its contents to create a data
source registry.  This allows data source definitions to be kept in a file
instead of in source code, which is encouraged because data source definitions
are, conceptually, configuation data.

=over

=item C<domain_config>

(Required)

This allows you to specify the path to
L<DOMAIN_CONFIG|/"DOMAIN_CONFIG">.  With this import argument, a data source registry
is automatically created for this class based on the data sources
defined in your L<DOMAIN_CONFIG|/"DOMAIN_CONFIG"> file.

=item C<target_domains>

An array of domain names for auto_registration.
This defines the set of domains which will be auto-registered.  All other domains
will be excluded.  This lets you ensure that only a subset of the data source
definitions in DOMAIN_CONFIG will be registered, which might be useful
if DOMAIN_CONFIG is being used for multiple tasks or multiple apps.

=item C<parse_domain_hash_callback>

A subroutine reference to a caller-defined
alternative to the default L<domain parser|/"parse_domain">.  It is called with
the same arguments as the default L<domain parser|/"parse_domain"> and is
responsible for the same task.  It differs only in that it is used to
implement an alternative namespace representation.

=back

=head2 parse_domain

This method is the class-wide default domain parser, responsible for creating
a set of registry entries from a data structure that represents a domain.  It
recognizes the class-wide default data source namespace representation.

The domain parser is called automatically for each domain in
L<DOMAIN_CONFIG|/"DOMAIN_CONFIG">.  It must interpret a given domain data
structure, which should represent a single domain in the data source registry,
as a set of registry entries.  These entries are added to the provided registry
object, which is finally returned.

=over

=item C<registry>

(Required.  Must be a descendant of Rose::DB::Registry.)

A Rose::DB::Registry object to operate on.

=item C<domain_name>

(Required)

The name of the domain to be registered.

=item C<domain_hashref>

(Required)

Data structure containing the definition of the domain to be interpreted.

=back

=head1 SUBCLASSING

See the notes about derived classes in the Rose::DB documentation.

Additionally, subclasses may implement a class-wide default data source
namespace representation by overriding the default L<domain parser|/"parse_domain">.

Note also that if your subclass is to support your new namespace
representation for the F<ROSEDBRC>/C<auto_load_fixups> feature (doing this where
applicable is a good idea for consistency -- it would be best to use the same
representation for F<ROSEDBRC> and DOMAIN_CONFIG), you also need to override
L<load_yaml_fixups_from_file|/"load_yaml_fixups_from_file">.

=head2 auto_load_fixups

This method overrides C<auto_load_fixups> in Rose::DB.  This is done so that
alternative namespace representations can be used within F<ROSEDBRC>.  Aside
from supporting alternative representations, this method functions in the same
way.  See L<load_yaml_fixups_from_file|/"load_yaml_fixups_from_file">.

=head2 load_yaml_fixups_from_file

This method is called by L<auto_load_fixups|/"auto_load_fixups"> when a file
is being used to indicate "fix-up" information.  Subclasses should override it
if an alternative namespace representation is being used.

It is called as a class method with one (additional) argument: the name of the
F<ROSEDBRC> file containing fix-up data.

=head1 DIAGNOSTICS

=over

=item C<< DOMAIN_CONFIG file '...' not found >>

The supplied path for L<DOMAIN_CONFIG|/"DOMAIN_CONFIG"> was not found.

=item C<< param '...' required >>

Missing a required subroutine parameter.

=item C<< param '...' must be a <class> object >>

A given subroutine parameter is not an object of the required type (<class>).

=back

=head1 CONFIGURATION AND ENVIRONMENT

See Rose::DB.  Rose::DBx::RegistryConfig adds the following features that impact
configuration/environment:

L<DOMAIN_CONFIG|/"DOMAIN_CONFIG">

=head1 DEPENDENCIES

Carp

YAML

Rose::DB

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Karl Erisman (karl.erisman@icainformatics.com), ICA
Informatics. All rights reserved.

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself. See perlartistic.

=head1 ACKNOWLEDGEMENTS

Thanks to ICA Informatics for providing the opportunity for me to develop
and to release this software.  Thanks also to John Ingram for ideas about the simplified
representation of the default L<DOMAIN_CONFIG|/"DOMAIN_CONFIG>, which is helping us reduce the complexity
of our configurations significantly.

Thanks also to John Siracusa for the Rose family of modules and for providing
guidance in the form of answers to questions about development of this
module.

=head1 AUTHOR

Karl Erisman (karl.erisman@icainformatics.com)

=cut
