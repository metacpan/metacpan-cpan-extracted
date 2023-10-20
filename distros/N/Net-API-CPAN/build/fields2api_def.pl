#!/usr/local/bin/perl
use v5.36;
use strict;
use warnings;
use vars qw( $VERSION );
use Module::Generic v0.31.1;
use Module::Generic::File qw( file );
our $VERSION = 'v0.1.0';

# This scripts takes in the fields.json file, which is an aggregation of all the fields definition found, and can be edited manually.
# It then makes some adjustments, and produces the api.json file used by the modules builder.
# Also check out the cpan-openapi-spec-3.0.0.pl reference file

# Reference:
# <https://github.com/metacpan/metacpan-api>
# <https://github.com/metacpan/metacpan-api/tree/master/lib/MetaCPAN/DocumentE>
# <https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md>
# ./dev/fields.json

my $base_dir = file( __FILE__ )->parent;

my $field2type =
{
'file::author' =>
    {
        type => 'scalar_or_object',
        package => 'Net::API::CPAN::Author',
    },
blog    => 
    {
        type => 'class_array_object',
        def =>
        {
            feed => 'scalar',
            url => 'uri',
        }
    },
bugs =>
    {
        type => 'class',
        # MetaCPAN::API defines a type, but this is not a class, so also it would have
        # been nice to mirror the name if it had been a class, since it is not one, no need
        # class => 'Net::API::CPAN::BugSummary',
        def =>
        {
            github => 
            {
                type => 'class',
                def =>
                {
                    active => 'integer',
                    closed => 'integer',
                    open => 'integer',
                    source => 'uri',
                },
            },
            rt =>
            {
                type => 'class',
                def =>
                {
                    # /usr/local/src/perl/Net-API-CPAN/dev/metacpan-api/lib/MetaCPAN/Types/TypeTiny.pm
                    # contradicts this, and this field <html> looks more like a bug
                    # '<html>' => 'decimal',
                    active => 'integer',
                    closed => 'integer',
                    # new => 'integer',
                    open => 'integer',
                    patched => 'integer',
                    recent => 'integer',
                    rejected => 'integer',
                    resolved => 'integer',
                    source => 'uri',
                    stalled => 'integer',
                }
            },
        },
    },
'changes_release::changes' =>
    {
        type => 'class_array_object',
        def =>
        {
            author => 'string',
            changes_file => 'string',
            changes_text => 'string',
            release => 'string',
        },
    },
co_maintainers =>
    {
        type => 'array_as_object',
    },
'mirror::contact' =>
    {
        type => 'class_array_object',
        def =>
        {
            contact_site => 'string',
            contact_user => 'string',
        },
    },
# NOTE: for cover (coverage)
criteria =>
    {
        type => 'class',
        def =>
        {
            branch => 'float',
            condition => 'float',
            statement => 'float',
            subroutine => 'float',
            total => 'float',
        },
    },
date =>
    {
        type => 'date'
    },
dependency =>
    {
        type => 'class_array_object',
        def =>
        {
            module => 'scalar',
            phase => 'scalar',
            relationship => 'scalar',
            version => =>
            {
                type => 'version',
                class => 'Changes::Version',
            },
        }
    },
# NOTE: MetaCPAN::Client::Rating has got it wrong thinking this is a scalar when it is actually a dictionary with one element 'description'
'rating::details' =>
    {
        type => 'class',
        def =>
        {
            description => 
            {
                type => 'scalar',
            }
        }
    },
# In object package, 'version' as it is used elsewhere is named 'dist_version', and 'version_numified' is named 'version'
'package::dist_version' => 
    {
        type => 'version',
        def =>
        {
            field => 'dist_version',
            class => 'Changes::Version',
        },
    },
donation =>
    {
        type => 'class_array_object',
        def =>
        {
            id => 'scalar',
            name => 'scalar',
        }
    },
download_url =>
    {
        type => 'uri',
    },
# Correction -> The MetaCPAN API specs indicates this is a string, but it is an array
email =>
    {
        type => 'object_array_object',
        class => 'Email::Address::XS',
        # The parameters to pass to object_array_object in lieu of the object property name
        callback => <<'EOT',
        my( $class, $args ) = @_;
        return( $class->parse_bare_address( $args->[0] ) );
EOT
    },
external_package =>
    {
        type => 'class',
        def =>
        {
            cygwin => 'scalar',
            debian => 'scalar',
            fedora => 'scalar',
        },
    },
# mirror
ftp =>
    {
        type => 'uri',
    },
gravatar_url =>
    {
        type => 'uri',
    },
'rating::helpful' =>
    {
        type => 'class_array_object',
        def =>
        {
            user => 'scalar',
            value => 'boolean',
        },
    },
# mirror
http =>
    {
        type => 'uri',
    },
# mirror
inceptdate =>
    {
        type => 'date',
    },
license =>
    {
        type => 'array_as_object',
    },
links =>
    {
        type => 'class',
        def =>
        {
            backpan_directory => 'uri',
            cpan_directory => 'uri',
            cpantesters_matrix => 'uri',
            cpantesters_reports => 'uri',
            cpants => 'uri',
            metacpan_explorer => 'uri',
            repology => 'uri',
        },
    },
# This is a 2-elements array (latitude, longitude)
location => 
    {
        type => 'array_as_object',
    },
metadata =>
    {
        def => 
        {
            abstract => 'string',
            author => 'array_as_object',
            dynamic_config => 'boolean',
            generated_by => 'string',
            license => 'array_as_object',
            meta_spec =>
            {
                def =>
                {
                    url => 'uri',
                    version => 
                    {
                        type => 'version',
                        class => 'Changes::Version',
                    },
                },
                type => 'class',
            },
            name => 'string',
            no_index =>
            {
                def => 
                {
                    directory => 'array_as_object',
                    package => 'array_as_object',
                },
                type => 'class',
            },
            prereqs =>
            {
                type => 'class',
                def =>
                {
                    build =>
                    {
                        type => 'class',
                        def =>
                        {
                            recommends => 'hash_as_object',
                            requires => 'hash_as_object',
                            suggests => 'hash_as_object',
                        },
                    },
                    configure =>
                    {
                        type => 'class',
                        def =>
                        {
                            recommends => 'hash_as_object',
                            requires => 'hash_as_object',
                            suggests => 'hash_as_object',
                        },
                    },
                    develop =>
                    {
                        type => 'class',
                        def =>
                        {
                            recommends => 'hash_as_object',
                            requires => 'hash_as_object',
                            suggests => 'hash_as_object',
                        },
                    },
                    runtime =>
                    {
                        type => 'class',
                        def =>
                        {
                            recommends => 'hash_as_object',
                            requires => 'hash_as_object',
                            suggests => 'hash_as_object',
                        },
                    },
                    test =>
                    {
                        type => 'class',
                        def =>
                        {
                            recommends => 'hash_as_object',
                            requires => 'hash_as_object',
                            suggests => 'hash_as_object',
                        },
                    },
                },
            },
            release_status => 'string',
            resources =>
            {
                type => 'class',
                def =>
                {
                    bugtracker =>
                    {
                        type => 'class',
                        def =>
                        {
                            mailto => 'uri',
                            type => 'string',
                            web => 'uri',
                        },
                    },
                    homepage =>
                    {
                        type => 'class',
                        def =>
                        {
                            web => 'uri',
                        },
                    },
                    license =>
                    {
                        type => 'string',
                    },
                    repository =>
                    {
                        type => 'class',
                        def =>
                        {
                            type => 'string',
                            url => 'uri',
                            web => 'uri',
                        },
                    },
                    x_IRC =>
                    {
                        type => 'string',
                    },
                    x_MailingList =>
                    {
                        type => 'string',
                    },
                },
            },
            # resources aliased to /resources to avoid uselessly duplicate it here
            version => 
            {
                type => 'version',
                class => 'Changes::Version',
            },
            version_numified => 'float',
            x_contributors =>
            {
                type => 'array',
            },
            x_generated_by_perl =>
            {
                type => 'string',
            },
            x_serialization_backend =>
            {
                type => 'string',
            },
            x_spdx_expression =>
            {
                type => 'string',
            },
            x_static_install =>
            {
                type => 'string',
            },
        },
        type => 'class',
    },
mirrors =>
    {
        type => 'object_array_object',
        class => 'Net::API::CPAN::Mirror',
    },
# module =>
#     {
#         type => 'object_array_object',
#         package => 'Net::API::CPAN::Module',
#     },
module =>
    {
        type => 'class_array_object',
        def =>
        {
            associated_pod => 'string',
            authorized => 'boolean',
            indexed => 'boolean',
            name => 'string',
            version => 'string',
            version_numified => 'number',
        },
    },
perlmongers =>
    {
        type => 'class_array_object',
        def =>
        {
            name => 'scalar',
            url => 'uri',
        },
    },
profile =>
    {
        type => 'class_array_object',
        def =>
        {
            id => 'scalar',
            name => 'scalar',
        }
    },
provides =>
    {
        type => 'array_as_object',
    },
# mirror
reitredate =>
    {
        type => 'date',
    },
'file::release' =>
    {
        type => 'scalar_or_object',
        package => 'Net::API::CPAN::Release',
    },
release_count =>
    {
        type => 'class',
        def =>
        {
            # THe property name is actually 'backpan-only', but Module::Generic::init will check for the method backpan_only too
            backpan_only => 'integer',
            cpan => 'integer',
            latest => 'integer',
        },
    },
'release_recent::releases' =>
    {
        type => 'class_array_object',
        def =>
        {
            abstract => 'string',
            author => 'string',
            date => 'datetime',
            distribution => 'string',
            name => 'string',
            status => 'string',
        },
    },
# Used also in 'metadata'
resources =>
    {
        type => 'class',
        def =>
        {
            bugtracker => 
            {
                type => 'class',
                def => 
                {
                    mailto => 'uri',
                    type => 'string',
                    web => 'uri',
                },
            },
            # homepage => 'uri',
            homepage => 
            {
                type => 'class',
                def =>
                {
                    web => 'uri',
                },
            },
            # Yes, the web mapping definition states it is a string, but the code at
            # <https://github.com/metacpan/metacpan-api/blob/master/lib/MetaCPAN/Document/Release.pm>
            # <https://github.com/metacpan/metacpan-api/blob/97b4791bf274bfb4e25f3a122e7115a2e9315404/lib/MetaCPAN/Types/TypeTiny.pm#L74>
            # says this is an array reference of strings
            license => 'array_as_object',
            repository =>
            {
                type => 'class',
                def => 
                {
                    url => 'uri',
                    type => 'scalar',
                    web => 'uri',
                },
            }
        },
    },
river =>
    {
        type => 'class',
        def =>
        {
            bucket => 'integer',
            bus_factor => 'integer',
            immediate => 'integer',
            total => 'integer',
        },
    },
'mirror::rsync' =>
    {
        type => 'uri',
    },
'mirror::src' =>
    {
        type => 'uri',
    },
stat =>
    {
        type => 'class',
        def =>
        {
            gid => 'integer',
            mode => 'integer',
            mtime => 'datetime',
            size => 'integer',
            uid => 'integer',
        },
    },
'diff::statistics' =>
    {
        type => 'class_array_object',
        def =>
        {
            deletions => 'integer',
            diff => 'string',
            insertions => 'integer',
            source => 'string',
            target => 'string',
        },
    },
suggest =>
    {
        type => 'class',
        def =>
        {
            input => 'array',
            payload => 'hash',
            weight => 'integer',
        },
    },
'release::tests' =>
    {
        type => 'class',
        def =>
        {
            fail => 'integer',
            na => 'integer',
            pass => 'integer',
            unknown => 'integer',
        },
    },
'mirrors::took' =>
    {
        type => 'integer',
    },
total =>
    {
        type => 'integer',
    },
url =>
    {
        type => 'uri',
    },
# e.g.: 2014-02-14T11:13:32
updated =>
    {
        type => 'datetime',
    },
# 'version' in object package should have been 'version_numified'
'package::version' => 
    {
        type => 'float',
        def =>
        {
            undef_ok => 1,
        },
    },
version => 
    {
        type => 'version',
        def =>
        {
            field => 'version',
            class => 'Changes::Version',
        },
    },
# Correction -> The MetaCPAN API specs indicates this is a string, but it is an array
website =>
    {
        type => 'object_array_object',
        class => 'URI',
    },
};
$field2type->{metadata}->{def}->{resources} = $field2type->{resources};

# NOTE: fields.json is an adjusted aggregation of the fields mapping as documented by the MetaCPAN API documentation
# However, some fields are missing, and/or do not have the right definition, such as in author, 'links' and 'release_count' are missing. 'email' and 'website' are marked as being strings, when they are arrays
# This script needs to be run to cleanse those inaccuracies and build a clean 'api.json' reference file, which is then used by build_modules.ok
# Also check out the cpan-openapi-spec-3.0.0.pl reference file
my $f = $base_dir->child( 'fields.json' );
my $ref = $f->load_json || die( $f->error );
my $cpan_api_version = [keys( %$ref )]->[0];
my $def = { $cpan_api_version => {} };
foreach my $t ( sort( keys( %{$ref->{ $cpan_api_version }->{mappings}} ) ) )
{
    say "Checking type $t";
    $def->{ $cpan_api_version }->{ $t } = {};
    my $props = $ref->{ $cpan_api_version }->{mappings}->{ $t }->{properties};
    foreach my $prop ( sort( keys( %$props ) ) )
    {
        say "\tProcessing property $prop";
        my $this = $props->{ $prop };
        my $mirror = {};
        if( exists( $field2type->{ "${t}::${prop}" } ) )
        {
            $mirror = $field2type->{ "${t}::${prop}" };
        }
        elsif( exists( $field2type->{ $prop } ) )
        {
            $mirror = $field2type->{ $prop };
        }
        elsif( $this->{type} )
        {
            if( $this->{type} eq 'nested' )
            {
                say "\t\ttype is nested. Look into it.";
            }
            $mirror->{type} = $this->{type};
        }
        else
        {
            say "\t\tMissing a type definition.";
        }
        $def->{ $cpan_api_version }->{ $t }->{ $prop } = $mirror;
    }
}
my $api_def_file = $base_dir->child( 'api.json' );
$api_def_file->unload_json( $def => { pretty => 1, sorted => 1 } ) ||
    die( $api_def_file->error );
# We should not modify this file by hand directly
$api_def_file->chmod(0400);
say "Done.";
say "Results in file $api_def_file";

exit(0);

__END__

