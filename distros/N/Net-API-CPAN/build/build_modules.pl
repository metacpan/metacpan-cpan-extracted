#!/usr/local/bin/perl
use v5.36;
use strict;
use warnings;
use vars qw( $VERSION );
# use Data::Dump ();
use Data::Pretty ();
use Data::Dumper::Concise ();
use DateTime;
use Module::Generic v0.31.1;
use Module::Generic::Array;
use Module::Generic::File qw( file );
our $VERSION = 'v0.1.0';

my $base_dir = file( __FILE__ )->parent;
# Built with ./build/fields2api_def.pl
my $api_specs = $base_dir->child( 'api.json' );
my $specs = $api_specs->load_json || die( $api_specs->error );
my $mod_dir = $base_dir->child( 'modules' );
$mod_dir->mkdir(0755) if( !$mod_dir->exists );
my $test_dir = $base_dir->child( 't' );
$test_dir->mkdir(0755) if( !$test_dir->exists );
$specs = $specs->{cpan_v1_01} || die( "Cannot find specs for cpan_v1_01\n" );
my $today = eval
{
    DateTime->now( time_zone => 'local' )->strftime( '%Y/%m/%d' );
};
$today = DateTime->now->strftime( '%Y/%m/%d' ) if( $@ );

my $year = DateTime->now->year;
# Starting from 006, because 001 is the load test and 002 is for filter, 003 is for list, 004 is for scroll and 005 is for activity. The value is set to 5, because it will be increased before each iteration
my $test_num = 5;
my $modules_version = 'v0.1.0';
my $modules_created = DateTime->new( year => 2023, month => 7, day => 25 )->strftime( '%Y/%m/%d' );

my $core_methods =
{
    object =>
    {
        code => "sub object { return( shift->_set_get_scalar_as_object( 'object', \@_ ) ); }\n",
        pod => <<EOT,
=head2 object

Returns the object type for this class, which is C<{object}>
EOT
    },
};

my $other_methods =
{
    author =>
    {
        dir =>
        {
            code => "sub dir { return( shift->links->cpan_directory( \@_ ) ); }\n",
            pod => <<EOT,
=head2 dir

Sets or gets the C<cpan_directory> link property.

This is actually a shortcut to accessing the property C<cpan_directory> in L</links>

It returns an L<URI> object, or C<undef> if no value is set.
EOT
            type => 'string',
        },
        metacpan_url => 
        {
            code => <<EOT,
sub metacpan_url
{
    my \$self = shift( \@_ );
    my \$pauseid = \$self->pauseid || 
        return( \$self->error( "No pause ID is set to return a Meta CPAN URL for this author." ) );
    my \$api_uri = \$self->api->api_uri->clone;
    \$api_uri->path( "/author/\$pauseid" );
    return( \$api_uri );
}
EOT
            pod => <<EOT,
=head2 metacpan_url

Returns a link, as an L<URI> object, to the author's page on MetaCPAN, or C<undef> if no C<pauseid> is currently set.
EOT
            type => 'uri',
            class => 'URI',
        },
        releases =>
        {
            code => <<EOT,
# Taken from MetaCPAN::Client::Author for compatibility
sub releases
{
    my \$self = shift( \@_ );
    my \$id   = \$self->pauseid;
    return( \$self->api->release({
        all => [
            { author => \$id },
            { status => 'latest' },
        ]
    }) );
}
EOT
            pod => <<EOT,
=head2 releases

Returns an L<Net::API::CPAN::ResultSet> oject containing all the author latest releases as L<release objects|Net::API::CPAN::Release>.
EOT
            type => 'object',
            class => 'Net::API::CPAN::List',
        },
    },
    distribution =>
    {
        metacpan_url => 
        {
            code => <<EOT,
sub metacpan_url
{
    my \$self = shift( \@_ );
    my \$name = \$self->name || 
        return( \$self->error( "No distribution name is set to return a Meta CPAN URL for this distribution." ) );
    my \$api_uri = \$self->api->api_uri->clone;
    \$api_uri->path( "/release/\$name" );
    return( \$api_uri );
}
EOT
            pod => <<EOT,
=head2 metacpan_url

Returns a link, as an L<URI> object, to the distribution's page on MetaCPAN, or C<undef> if no distribution C<name> is currently set.
EOT
            type => 'uri',
            class => 'URI',
        },
        github =>
        {
            code => "sub github { return( shift->bugs->github ); }\n",
            pod => <<EOT,
=head2 github

Returns the object for the dynamic class C<Net::API::CPAN::Bugs::Github>, which provides access to a few methods.

See L</bugs> for more information.

It returns C<undef> if no value is set.
EOT
            type => 'object',
        },
        rt =>
        {
            code => "sub rt { return( shift->bugs->rt ); }\n",
            pod => <<EOT,
=head2 rt

Returns the object for the dynamic class C<Net::API::CPAN::Bugs::Rt>, which provides access to a few methods.

See L</bugs> for more information.

It returns C<undef> if no value is set.
EOT
            type => 'object',
        },
    },
    module =>
    {
        metacpan_url => 
        {
            code => <<EOT,
sub metacpan_url
{
    my \$self = shift( \@_ );
    my \$author = \$self->author || 
        return( \$self->error( "No module author is set to return a Meta CPAN URL for this module." ) );
    my \$release = \$self->release ||
        return( \$self->error( "No module release is set to return a Meta CPAN URL for this module." ) );
    my \$path = \$self->path ||
        return( \$self->error( "No module path is set to return a Meta CPAN URL for this module." ) );
    my \$api_uri = \$self->api->api_uri->clone;
    \$api_uri->path( "/pod/\$author/\$release/\$path" );
    return( \$api_uri );
}
EOT
            pod => <<EOT,
=head2 metacpan_url

Returns a link, as an L<URI> object, to the module's page on MetaCPAN, or C<undef> if no module L<author|/author>, L<release|/release>. or L<path|/path> is currently set.
EOT
            type => 'uri',
            class => 'URI',
        },
        package =>
        {
            code => <<EOT,
sub package
{
    my \$self = shift( \@_ );
    my \$doc = \$self->documentation || 
        return( \$self->error( "No documentation module class is set to call Net::API::CPAN->package" ) );
    my \$result = \$self->api->package( \$doc ) || return( \$self->pass_error );
    return( \$result );
}
EOT
            pod => <<EOT,
=head2 package

Returns an L<Net::API::CPAN::Package> object for this module, or upon error, sets an L<error object|Net::API::CPAN::Exception> and returns C<undef> in scalar context or an empty list in list context.

An error is returned if the L<documentation property|/documentation> is not set.
EOT
            type => 'object',
        },
        permission =>
        {
            code => <<EOT,
sub permission
{
    my \$self = shift( \@_ );
    my \$doc = \$self->documentation || 
        return( \$self->error( "No documentation module class is set to call Net::API::CPAN->package" ) );
    my \$result = \$self->api->permission( \$doc ) || return( \$self->pass_error );
    return( \$result );
}
EOT
            pod => <<EOT,
=head2 permission

Returns an L<Net::API::CPAN::Permission> object for this module, or upon error, sets an L<error object|Net::API::CPAN::Exception> and returns C<undef> in scalar context or an empty list in list context.

An error is returned if the L<documentation property|/documentation> is not set.
EOT
            type => 'object',
        },
    },
};

# NOTE: special methods definition
my $special_methods =
{
    distribution =>
    {
        _init_preprocess => <<'EOT',
sub
    {
        my $this = shift( @_ );
        if( $self->_is_array( $this ) )
        {
            for( my $i = 0; $i < scalar( @$this ); $i += 2 )
            {
                if( $this->[$i] eq 'bugs' )
                {
                    my $ref = $this->[$i + 1];
                    if( ref( $ref ) eq 'HASH' &&
                        exists( $ref->{rt} ) &&
                        ref( $ref->{rt} ) eq 'HASH' &&
                        exists( $ref->{rt}->{new} ) )
                    {
                        $ref->{rt}->{recent} = CORE::delete( $ref->{rt}->{new} );
                        $this->[$i + 1] = $ref;
                    }
                }
            }
        }
        elsif( $self->_is_hash( $this ) )
        {
            if( exists( $this->{bugs} ) &&
                ref( $this->{bugs} ) eq 'HASH' &&
                exists( $this->{bugs}->{rt} ) &&
                ref( $this->{bugs}->{rt} ) eq 'HASH' &&
                exists( $this->{bugs}->{rt}->{new} ) )
            {
                $this->{bugs}->{rt}->{recent} = CORE::delete( $this->{bugs}->{rt}->{new} );
            }
        }
        return( $this );
    };
EOT
    },
    author =>
    {
        # There is an inconsistency for the property perlmongers whereby the endpoint /author/by_user will return an hash but others will return an array of hash reference.
        _init_preprocess => <<'EOT',
sub
    {
        my $this = shift( @_ );
        if( $self->_is_hash( $this ) )
        {
            if( exists( $this->{perlmongers} ) &&
                ref( $this->{perlmongers} ) eq 'HASH' )
            {
                $this->{perlmongers} = [$this->{perlmongers}];
            }
        }
        return( $this );
    };
EOT
    }
};

# Which class is extended by which other class
my $extends =
{
    changes => 'file',
    module => 'file',
};

my $pod_more =
{
    package =>
    {
        version => <<EOT,
Please note that this represents the numified version of the module version number. In other object classes, the property C<version_numified> is used instead. For the L<version object|Changes::Version> of the module, see L</dist_version>
EOT
    },
    release_recent => 
    {
        __description => <<EOT,
This class serve to retrieve and manipulate recent releases.
EOT
    }
};

# To explicitly set the module name, but only its trailing part, since it will be appended to the top module name (Net::API::CPAN)
my $module_names =
{
    changes_release => 'Changes::Release',
    release_recent => 'Release::Recent',
    suggest => 'Release::Suggest',
};

# For the properties that simply cannot be used as-is as word, we use a dictionary map
# Example:
# "Sets or gets an array of providess" -> "Sets or gets an array of module class name"
my $property_to_word =
{
    provides => 'module class name',
};

my $default_value =
{
    version => "''",
};

foreach my $object ( sort( keys( %$specs ) ) )
{
    my $module_name = exists( $module_names->{ $object } )
        ? $module_names->{ $object } 
        : join( '', map( ucfirst( lc( $_ ) ), split( /_/, $object ) ) );
    ( my $module_path = $module_name ) =~ s,::,/,g;
    $module_path .= '.pm';
    my $mod_file = $mod_dir->child( "$module_name.pm" );
    my $parent = 'Net::API::CPAN::Generic';
    my $parent_specs;
    my $object_plural = ( substr( $object, -1, 1 ) eq 's' ? $object : $object . 's' );
    if( index( $module_name, '::' ) != -1 )
    {
        my @parts = split( /::/, $module_name );
        # Skip the last one that forms our module name and retain the rest that constitutes the parent directory(ie)
        my $this_name = pop( @parts );
        my $module_parent_dir = $mod_dir->child( join( '/', @parts ) );
        $module_parent_dir->mkpath if( !$module_parent_dir->exists );
        $mod_file = $module_parent_dir->child( "${this_name}.pm" );
    }
    
    if( exists( $extends->{ $object } ) )
    {
        $parent_specs = $specs->{ $extends->{ $object } } ||
            die( "There is no object '", $extends->{ $object }, "' to extends object '$object' in CPAN API specifications ($api_specs)." );
        $parent = 'Net::API::CPAN::' . join( '', map( ucfirst( lc( $_ ) ), split( /_/, $extends->{ $object } ) ) );
        say "\tClass $object inherits from ", $extends->{ $object };
    }
    my $methods = $specs->{ $object };
    my $all_methods = Module::Generic::Array->new( [keys( %$methods )] );
    if( exists( $other_methods->{ $object } ) )
    {
        $all_methods->push( keys( %{$other_methods->{ $object }} ) );
    }
    if( scalar( keys( %$core_methods ) ) )
    {
        $all_methods->push( keys( %$core_methods ) );
    }
    
    my $sample_file = $base_dir->child( "$object.json" );
    my $sample_data;
    $sample_data = $sample_file->load_json( boolean_values => [\0, \1] ) if( $sample_file->exists );
    my $synop = Module::Generic::Array->new;
    if( defined( $sample_data ) )
    {
        my $args_string = &dump_this( $sample_data );
        $synop->push( "my \$obj = Net::API::CPAN::${module_name}->new( $args_string ) || die( Net::API::CPAN::${module_name}->error );\n" );
    }
    
    my $lines = Module::Generic::Array->new;
    my $pod = Module::Generic::Array->new;
    my $code = <<EOT;
##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN/${module_path}
## Version ${modules_version}
## Copyright(c) ${year} DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack\@deguest.jp>
## Created $modules_created
## Modified $today
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
# This module file has been automatically generated. Any change made here will be lost.
# Edit the script in ./build/build_modules.pl instead
package Net::API::CPAN::${module_name};
BEGIN
{
    use strict;
    use warnings;
    use parent qw( ${parent} );
    use vars qw( \$VERSION );
    our \$VERSION = '${modules_version}';
};

use strict;
use warnings;

sub init
{
    my \$self = shift( \@_ );
EOT

    my $test_file = $test_dir->child( sprintf( '%03d_%s.t', ++$test_num, $object ) );
    my $test_content = <<EOT;
#!perl
# This test file has been automatically generated. Any change made here will be lost.
# Edit the script in ./build/build_modules.pl instead
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( \$DEBUG );
    use Test::More qw( no_plan );
    use Module::Generic;
    use Scalar::Util ();
    our \$DEBUG = exists( \$ENV{AUTHOR_TESTING} ) ? \$ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Net::API::CPAN::${module_name}' );
};

use strict;
use warnings;

my \$test_data = Module::Generic->new->new_json->decode( join( '', <DATA> ) );
\$test_data->{debug} = \$DEBUG;
my \$this;
my \$obj = Net::API::CPAN::${module_name}->new( \$test_data );
isa_ok( \$obj => 'Net::API::CPAN::${module_name}' );
if( !defined( \$obj ) )
{
    BAIL_OUT( Net::API::CPAN::${module_name}->error );
}

# To generate this list:
# egrep -E '^sub ' ./lib/Net/API/CPAN/${module_name}.pm | perl -lnE 'my \$m = [split(/\\s+/, \$_)]->[1]; say "can_ok( \\\$obj, ''\$m'' );"'
EOT
    
    
    my $max = 0;
    # foreach my $meth ( keys( %$methods ) )
    foreach my $meth ( sort( @$all_methods ) )
    {
        $max = length( $meth ) if( length( $meth ) > $max );
        $test_content .= <<EOT;
can_ok( \$obj, '${meth}' );
EOT
    }
    $test_content .= "\n";
    # + 2 (1 for each curly bracket surrounding the property name
    $max += 2;
    my $methods_list = [];
    
    # foreach my $meth ( sort( keys( %$methods ) ) )
    foreach my $meth ( sort( @$all_methods ) )
    {
        say "Building $object -> $meth";
        # The term to use in the POD for this method (a.k.a. property)
        my $prop_term = exists( $property_to_word->{ $meth } ) ? $property_to_word->{ $meth } : $meth;
        my $prop_term_plural = ( substr( $prop_term, -1, 1 ) eq 's' ? $prop_term : $prop_term . 's' );
        my $default = exists( $default_value->{ $meth } ) ? $default_value->{ $meth } : 'undef';
        
        if( exists( $other_methods->{ $object }->{ $meth } ) )
        {
            die( "No pod documentation for extra method $meth in object $object" ) if( !exists( $other_methods->{ $object }->{ $meth }->{pod} ) );
            my $other_def = $other_methods->{ $object }->{ $meth };
            # say "# Adding pod for method $meth in object $object -> $other_methods->{ $object }->{ $meth }->{pod}";
            $lines->push( $other_def->{code} );
            $pod->push( $other_def->{pod} );
            my $other_type = $other_def->{type};
            if( $other_type eq 'object' )
            {
                $synop->push( "my \$this = \$obj->${meth};" );
            }
            else
            {
                $synop->push( "my \$${other_type} = \$obj->${meth};" );
            }
            next;
        }
        elsif( exists( $core_methods->{ $meth } ) )
        {
            if( $meth eq 'object' )
            {
                $code .= sprintf( "    \$self->%-*s = '$object';\n", $max, "\{${meth}\}" );
            }
            else
            {
                $code .= sprintf( "    \$self->%-*s = ${default} unless( CORE::exists( \$self->\{${meth}\} ) );\n", $max, "\{${meth}\}" );
            }
            $synop->push( "my \$str = \$obj->${meth};" );
            $lines->push( $core_methods->{ $meth }->{code} );
            my $pod_text = $core_methods->{ $meth }->{pod};
            $pod_text =~ s/\{object\}/$object/gs;
            $pod->push( $pod_text );
            next;
        }
        
        push( @$methods_list, $meth );
        
        my $def = $methods->{ $meth };
        my $type = $def->{type} || die( "No type is defined for method $meth in object $object\n" );
        my $example = '';
        my $sample_data_string;
        if( exists( $sample_data->{ $meth } ) )
        {
            # Even if this is a simple string, Data::Dumper::Concise will set the surrounding quotes appropriately
            $sample_data_string = &dump_this( $sample_data->{ $meth } );
#             $sample_data_string = Data::Dumper::Concise::Dumper( $sample_data->{ $meth } );
#             $sample_data_string =~ s/\n$//gs;
            if( index( $sample_data_string, "\n" ) != -1 )
            {
                my @sample_lines = split( /\n/, $sample_data_string );
                # We start from 1 on purpose
                for( my $i = 1; $i < scalar( @sample_lines ); $i++ )
                {
                    substr( $sample_lines[$i], 0, 0, '    ' );
                }
                $sample_data_string = join( "\n", @sample_lines );
            }
        }
        
        # NOTE: string
        if( $type eq 'string' || $type eq 'scalar' )
        {
            $code .= sprintf( "    \$self->%-*s = ${default} unless( CORE::exists( \$self->\{${meth}\} ) );\n", $max, "\{${meth}\}" );
            # If this is an inheriting object class and this method exists in our parent class, no need to produce it, but we do create the POD documentation for clarity and simplicity of browsing for the end user.
            if( defined( $parent_specs ) && exists( $parent_specs->{ $meth } ) )
            {
                $lines->push( "# NOTE: sub $meth is inherited from ${parent}\n" );
            }
            else
            {
                $lines->push( "sub $meth { return( shift->_set_get_scalar_as_object( '$meth', \@_ ) ); }\n" );
            }
            
            if( exists( $sample_data->{ $meth } ) )
            {
                $example = <<EOT;
    \$obj->${meth}\( $sample_data_string \);
    my \$string = \$obj->${meth};

EOT
            }
            $pod->push( <<EOT );
=head2 $meth

${example}Sets or gets a string and returns a L<scalar object|Module::Generic::Scalar>, even if there is no value.
EOT
            $synop->push( "my \$string = \$obj->${meth};" );
            $test_content .= <<EOT;
is( \$obj->${meth}, \$test_data->{$meth}, '${meth}' );
EOT
        }
        # NOTE: array or array_as_object
        elsif( $type eq 'array' || $type eq 'array_as_object' )
        {
            $code .= sprintf( "    \$self->%-*s = [] unless( CORE::exists( \$self->\{${meth}\} ) );\n", $max, "\{${meth}\}" );
            if( defined( $parent_specs ) && exists( $parent_specs->{ $meth } ) )
            {
                $lines->push( "# NOTE: sub $meth is inherited from ${parent}\n" );
            }
            else
            {
                $lines->push( "sub $meth { return( shift->_set_get_array_as_object( '$meth', \@_ ) ); }\n" );
            }
            
            if( exists( $sample_data->{ $meth } ) )
            {
                $example = <<EOT;
    \$obj->${meth}\( $sample_data_string \);
    my \$array = \$obj->${meth};

EOT
            }
            $pod->push( <<EOT );
=head2 $meth

${example}Sets or gets an array of ${prop_term_plural} and returns an L<array object|Module::Generic::Array>, even if there is no value.
EOT
            $synop->push( "my \$array = \$obj->${meth};" );
            $test_content .= <<EOT;
\$this = \$obj->${meth};
ok( ( Scalar::Util::reftype( \$this ) eq 'ARRAY' && Scalar::Util::blessed( \$this ) ), '${meth} returns an array object' );
if( defined( \$test_data->\{${meth}\} ) )
{
    ok( scalar( \@\$this ) == scalar( \@{\$test_data->\{${meth}\}} ), '${meth} -> array size matches' );
    for( my \$i = 0; \$i < \@\$this; \$i++ )
    {
        is( \$this->\[\$i\], \$test_data->\{${meth}\}->\[\$i\], '${meth} -> value offset \$i' );
    }
}
else
{
    ok( !scalar( \@\$this ), '${meth} -> array is empty' );
}
EOT
        }
        # NOTE: hash
        elsif( $type eq 'hash' )
        {
            $code .= sprintf( "    \$self->%-*s = ${default} unless( CORE::exists( \$self->\{${meth}\} ) );\n", $max, "\{${meth}\}" );
            if( defined( $parent_specs ) && exists( $parent_specs->{ $meth } ) )
            {
                $lines->push( "# NOTE: sub $meth is inherited from ${parent}\n" );
            }
            else
            {
                $lines->push( "sub $meth { return( shift->_set_get_hash_as_mix_object( '$meth', \@_ ) ); }\n" );
            }
            
            if( exists( $sample_data->{ $meth } ) )
            {
                $example = <<EOT;
    \$obj->${meth}\( $sample_data_string \);
    my \$hash_obj = \$obj->${meth};

EOT
            }
            $pod->push( <<EOT );
=head2 $meth

${example}Sets or gets an hash reference of ${prop_term_plural} and returns an L<hash object|Module::Generic::Hash>. If no value is set, it will return an empty L<hash object|Module::Generic::Hash> in L<object context|Want/"Reference context:">, or C<undef> in scalar context, or an empty list in list context.
EOT
            $synop->push( "my \$hash_obj = \$obj->${meth};" );
            $test_content .= <<EOT;
\$this = \$obj->${meth};
if( defined( \$test_data->\{${meth}\} ) )
{
    isa_ok( \$this => 'Module::Generic::Hash', '${meth}' );
}
else
{
    is( \$this => \$test_data->\{${meth}\}, '${meth}' );
}
EOT
        }
        # NOTE: version
        elsif( $type eq 'version' )
        {
            $code .= sprintf( "    \$self->%-*s = ${default} unless( CORE::exists( \$self->\{${meth}\} ) );\n", $max, "\{${meth}\}" );
            if( exists( $sample_data->{ $meth } ) )
            {
                $example = <<EOT;
    \$obj->${meth}\( $sample_data_string \);
    my \$version = \$obj->${meth};

EOT
            }
            
            if( exists( $def->{def} ) && ref( $def->{def} ) eq 'HASH' )
            {
                my $dict_as_string = Data::Pretty::dump( $def->{def} );
                if( defined( $parent_specs ) && exists( $parent_specs->{ $meth } ) )
                {
                    $lines->push( "# NOTE: sub $meth is inherited from ${parent}\n" );
                }
                else
                {
                    $lines->push( "sub $meth { return( shift->_set_get_version( $dict_as_string, \@_ ) ); }\n" );
                }
                
                my $version_class = ( $def->{def}->{class} // $def->{def}->{package} ) || die( "No class or package set for version in method $meth for object $object -> ${dict_as_string}\n" );
                $pod->push( <<EOT );
=head2 $meth

${example}Sets or gets a version value and returns a version object using L<${version_class}>.
EOT
            }
            else
            {
                if( defined( $parent_specs ) && exists( $parent_specs->{ $meth } ) )
                {
                    $lines->push( "# NOTE: sub $meth is inherited from ${parent}\n" );
                }
                else
                {
                    $lines->push( "sub $meth { return( shift->_set_get_version( '$meth', \@_ ) ); }\n" );
                }
                
                $pod->push( <<EOT );
=head2 $meth

Sets or gets a version value and returns a version object using L<version>.
EOT
            }
            $synop->push( "my \$vers = \$obj->${meth};" );
            $test_content .= <<EOT;
\$this = \$obj->${meth};
is( \$this, \$test_data->\{${meth}\}, '${meth}' );
EOT
        }
        # NOTE: class_array_object or class
        elsif( $type eq 'class_array_object' || $type eq 'class' )
        {
            my $sample = $sample_data->{ $meth };
            foreach my $k ( keys( %{$def->{def}} ) )
            {
                if( $def->{def}->{ $k } eq 'string' ||
                    $def->{def}->{ $k } eq 'scalar' )
                {
                    $def->{def}->{ $k } = 'scalar_as_object';
                }
                elsif( $def->{def}->{ $k } eq 'array' )
                {
                    $def->{def}->{ $k } = 'array_as_object';
                }
                elsif( $def->{def}->{ $k } eq 'hash' )
                {
                    $def->{def}->{ $k } = 'hash_as_object';
                }
            }

            if( $type eq 'class_array_object' )
            {
                $code .= sprintf( "    \$self->%-*s = \[\] unless( CORE::exists( \$self->\{${meth}\} ) );\n", $max, "\{${meth}\}" );
                $synop->push( "my \$array = \$obj->${meth};" );
                $synop->push( "foreach my \$this ( \@\$array )" );
                $synop->push( "{" );
                foreach my $k ( sort( keys( %{$def->{def}} ) ) )
                {
                    my $type = [split( /_/, $def->{def}->{ $k } )]->[0];
                    $synop->push( "    my \$${type} = \$this->${k};" );
                }
                $synop->push( "}" );
                
                if( exists( $sample_data->{ $meth } ) )
                {
                    $example = <<EOT;
    \$obj->${meth}\( $sample_data_string \);
    my \$array = \$obj->${meth};
    foreach my \$this ( \@\$array )
    {
EOT
                    foreach my $k ( sort( keys( %{$def->{def}} ) ) )
                    {
                        my $type = [split( /_/, $def->{def}->{ $k } )]->[0];
                        if( defined( $sample->[0]->{ $k } ) && length( $sample->[0]->{ $k } ) )
                        {
                            my $sample_str = Data::Dump::dump( $sample->[0]->{ $k } );
                            $example .= "        \$this->${k}( ${sample_str} );\n";
                        }
                        $example .= "        my \$${type} = \$this->${k};\n";
                    }
                    $example .= <<EOT;
    }

EOT
                }
            }
            # $type eq 'class'
            else
            {
                $code .= sprintf( "    \$self->%-*s = ${default} unless( CORE::exists( \$self->\{${meth}\} ) );\n", $max, "\{${meth}\}" );
                $synop->push( "my \$this = \$obj->${meth};" );
                foreach my $k ( sort( keys( %{$def->{def}} ) ) )
                {
                    my $type;
                    if( ref( $def->{def}->{ $k } ) eq 'HASH' )
                    {
                        $type = "${k}_obj";
                    }
                    else
                    {
                        $type = [split( /_/, $def->{def}->{ $k } )]->[0];
                    }
                    $synop->push( "my \$${type} = \$obj->${meth}->${k};" );
                }
                if( exists( $sample_data->{ $meth } ) )
                {
                    $example = <<EOT;
    \$obj->${meth}\( $sample_data_string \);
    my \$this = \$obj->${meth};
EOT
                    foreach my $k ( sort( keys( %{$def->{def}} ) ) )
                    {
                        my $type;
                        if( ref( $def->{def}->{ $k } ) eq 'HASH' )
                        {
                            $type = "${k}_obj";
                        }
                        else
                        {
                            $type = [split( /_/, $def->{def}->{ $k } )]->[0];
                        }
                        if( defined( $sample->{ $k } ) && length( $sample->{ $k } ) )
                        {
                            # my $sample_str = Data::Dump::dump( $sample->{ $k } );
                            my $sample_str = &dump_this( $sample->{ $k } );
                #             $sample_data_string = Data::Dumper::Concise::Dumper( $sample_data->{ $meth } );
                #             $sample_data_string =~ s/\n$//gs;
                            if( index( $sample_str, "\n" ) != -1 )
                            {
                                my @sample_lines = split( /\n/, $sample_str );
                                # We start from 1 on purpose
                                for( my $i = 1; $i < scalar( @sample_lines ); $i++ )
                                {
                                    substr( $sample_lines[$i], 0, 0, '    ' );
                                }
                                $sample_str = join( "\n", @sample_lines );
                            }
                            $example .= "    \$obj->${meth}->${k}( ${sample_str} );\n";
                        }
                        $example .= "    my \$${type} = \$obj->${meth}->${k};\n";
                    }
                    $example .= <<EOT;

EOT
                }
            }
            die( "No method definition is provided for method $meth in object $object\n" ) if( !exists( $def->{def} ) || ref( $def->{def} ) ne 'HASH' );
            my $method_class = $meth;
            $method_class =~ tr/-/_/;
            $method_class =~ s/\_{2,}/_/g;
            $method_class = join( '', map( ucfirst( lc( $_ ) ), split( /\_/, $method_class ) ) );

            my $dict_as_string = Data::Pretty::dump( $def->{def} );
            if( defined( $parent_specs ) && exists( $parent_specs->{ $meth } ) )
            {
                $lines->push( "# NOTE: sub $meth is inherited from ${parent}\n" );
            }
            else
            {
                $lines->push( "sub $meth { return( shift->_set_get_${type}( '$meth', $dict_as_string, \@_ ) ); }\n" );
            }
            
            my $props_definition = &definition_to_pod( $def->{def} );
            my $this_prop_pod;
            if( $type eq 'class_array_object' )
            {
                $this_prop_pod = <<EOT;
=head2 $meth

${example}Sets or gets an array of dynamic class objects with class name C<Net::API::CPAN::${module_name}::${method_class}> and having the folowing properties also accessible as methods, and returns an L<array object|Module::Generic::Array> even if there is no value.

A C<Net::API::CPAN::${module_name}::${method_class}> object will be instantiated with each value from the array provided and replace said value.

${props_definition}
EOT
                $test_content .= <<EOT;
\$this = \$obj->${meth};
isa_ok( \$this => 'Module::Generic::Array', '${meth} returns an array object' );
EOT
            }
            # $type eq 'class'
            else
            {
                $this_prop_pod = <<EOT;
=head2 $meth

${example}Sets or gets a dynamic class object with class name C<Net::API::CPAN::${module_name}::${method_class}> and having the folowing properties also accessible as methods, and returns an object from such class, or C<undef> if no value was provided.

${props_definition}
EOT
                $test_content .= <<EOT;
\$this = \$obj->${meth};
ok( Scalar::Util::blessed( \$this ), '${meth} returns a dynamic class' );
EOT
            }
            $this_prop_pod =~ s/\n$//gs;
            $pod->push( "$this_prop_pod\n" );
        }
        # NOTE: scalar_or_object
        elsif( $type eq 'scalar_or_object' )
        {
            $code .= sprintf( "    \$self->%-*s = \[\] unless( CORE::exists( \$self->\{${meth}\} ) );\n", $max, "\{${meth}\}" );
            my $class = $def->{class} || $def->{package} || die( "No ckass or package was specified for the method $meth in object $object\n" );
            if( defined( $parent_specs ) && 
                exists( $parent_specs->{ $meth } ) )
            {
                $lines->push( "# NOTE: sub $meth is inherited from ${parent}\n" );
            }
            else
            {
                $lines->push( "sub $meth { return( shift->_set_get_scalar_or_object( '$meth', '$class', \@_ ) ); }\n" );
            }

            if( exists( $sample_data->{ $meth } ) )
            {
                $example = <<EOT;
    \$obj->${meth}\( $sample_data_string \);
    # Returns a scalar object when this is a string, or an ${class} object
    my \$${meth} = \$obj->${meth};

EOT
            }
            $pod->push( <<EOT );
=head2 $meth

${example}Sets or gets either a string or an L<${class}> object, and returns either a L<scalar object|Module::Generic::Array> or an L<${class} object|${class}>, or C<undef> if nothing was set.
EOT
            $synop->push( "# Returns a scalar object when this is a string, or an ${class} object" );
            $synop->push( "my \$${meth} = \$obj->${meth};" );
            $test_content .= <<EOT;
\$this = \$obj->${meth};
if( defined( \$this ) )
{
    if( ref( \$this ) )
    {
        isa_ok( \$this => '$class', '${meth} returns a ${class} object' );
    }
    else
    {
        is( \$this => \$test_data->\{${meth}\}, '${meth} returns a string' );
    }
}
EOT
        }
        # NOTE: object_array_object
        elsif( $type eq 'object_array_object' )
        {
            $code .= sprintf( "    \$self->%-*s = \[\] unless( CORE::exists( \$self->\{${meth}\} ) );\n", $max, "\{${meth}\}" );
            my $class = $def->{class} || $def->{package} || die( "No ckass or package was specified for the method $meth in object $object\n" );
            if( defined( $parent_specs ) && exists( $parent_specs->{ $meth } ) )
            {
                $lines->push( "# NOTE: sub $meth is inherited from ${parent}\n" );
            }
            elsif( exists( $def->{callback} ) )
            {
                my $callback = $def->{callback};
                $callback =~ s/\n$//gs;
                $lines->push( "sub $meth { return( shift->_set_get_object_array_object( {
    field => '$meth',
    callback => sub
    {
${callback}
    }
}, '$class', \@_ ) ); }\n" );
            }
            else
            {
                $lines->push( "sub $meth { return( shift->_set_get_object_array_object( '$meth', '$class', \@_ ) ); }\n" );
            }
            
            if( exists( $sample_data->{ $meth } ) )
            {
                $example = <<EOT;
    \$obj->${meth}\( $sample_data_string \);
    my \$array = \$obj->${meth};

EOT
            }
            $pod->push( <<EOT );
=head2 $meth

${example}Sets or gets an array of L<${class}> objects, or creates an L<${class}> instance for each ${meth} provided in the array, and returns an L<array object|Module::Generic::Array>, even if no value was provided.
EOT
            $synop->push( "my \$array = \$obj->${meth};" );
            $test_content .= <<EOT;
\$this = \$obj->${meth};
isa_ok( \$this => 'Module::Generic::Array', '${meth} returns an array object' );
EOT
        }
        # NOTE: uri
        elsif( $type eq 'uri' )
        {
            $code .= sprintf( "    \$self->%-*s = ${default} unless( CORE::exists( \$self->\{${meth}\} ) );\n", $max, "\{${meth}\}" );
            if( defined( $parent_specs ) && exists( $parent_specs->{ $meth } ) )
            {
                $lines->push( "# NOTE: sub $meth is inherited from ${parent}\n" );
            }
            else
            {
                $lines->push( "sub $meth { return( shift->_set_get_uri( '$meth', \@_ ) ); }\n" );
            }
            
            if( exists( $sample_data->{ $meth } ) )
            {
                $example = <<EOT;
    \$obj->${meth}\( $sample_data_string \);
    my \$uri = \$obj->${meth};

EOT
            }
            $pod->push( <<EOT );
=head2 $meth

${example}Sets or gets an L<URI>, and returns an L<URI object|URI> or C<undef> if no value is set.
EOT
            $synop->push( "my \$uri = \$obj->${meth};" );
            $test_content .= <<EOT;
\$this = \$obj->${meth};
is( \$this => \$test_data->\{${meth}\}, '${meth}' );
if( defined( \$test_data->\{${meth}\} ) )
{
    isa_ok( \$this => 'URI', '${meth} returns an URI object' );
}
EOT
        }
        # NOTE: boolean
        elsif( $type eq 'boolean' )
        {
            $code .= sprintf( "    \$self->%-*s = ${default} unless( CORE::exists( \$self->\{${meth}\} ) );\n", $max, "\{${meth}\}" );
            if( defined( $parent_specs ) && exists( $parent_specs->{ $meth } ) )
            {
                $lines->push( "# NOTE: sub $meth is inherited from ${parent}\n" );
            }
            else
            {
                $lines->push( "sub $meth { return( shift->_set_get_boolean( '$meth', \@_ ) ); }\n" );
            }
            
            if( exists( $sample_data->{ $meth } ) )
            {
                $sample_data_string = ( $sample_data->{ $meth } ? 1 : 0 );
                $example = <<EOT;
    \$obj->${meth}\(${sample_data_string}\);
    my \$bool = \$obj->${meth};

EOT
            }
            $pod->push( <<EOT );
=head2 $meth

${example}Sets or gets a boolean value, and returns a L<boolean object|Module::Generic::Boolean> or C<undef> if no value is set.
EOT
            $synop->push( "my \$bool = \$obj->${meth};" );
            $test_content .= <<EOT;
\$this = \$obj->${meth};
if( defined( \$test_data->\{${meth}\} ) )
{
    is( \$this => \$test_data->\{${meth}\}, '${meth} returns a boolean value' );
}
else
{
    ok( !\$this, '${meth} returns a boolean value' );
}
EOT
        }
        # NOTE: date or datetime
        elsif( $type eq 'date' || $type eq 'datetime' )
        {
            $code .= sprintf( "    \$self->%-*s = ${default} unless( CORE::exists( \$self->\{${meth}\} ) );\n", $max, "\{${meth}\}" );
            if( defined( $parent_specs ) && exists( $parent_specs->{ $meth } ) )
            {
                $lines->push( "# NOTE: sub $meth is inherited from ${parent}\n" );
            }
            else
            {
                $lines->push( "sub $meth { return( shift->_set_get_datetime( '$meth', \@_ ) ); }\n" );
            }
            
            if( exists( $sample_data->{ $meth } ) )
            {
                $example = <<EOT;
    \$obj->${meth}\( $sample_data_string \);
    my \$datetime_obj = \$obj->${meth};

EOT
            }
            $pod->push( <<EOT );
=head2 $meth

${example}Sets or gets a datetime value, and returns a L<DateTime object|DateTime> that stringifies to the format that was provided with the string set (usally an ISO 8601 datetime format) or C<undef> if no value is set.
EOT
            $synop->push( "my \$date = \$obj->${meth};" );
            $test_content .= <<EOT;
\$this = \$obj->${meth};
is( \$this => \$test_data->\{${meth}\}, '${meth}' );
if( defined( \$test_data->\{${meth}\} ) )
{
    isa_ok( \$this => 'DateTime', '${meth} returns a DateTime object' );
}
EOT
        }
        # NOTE: integer or number or float or decimal
        elsif( $type eq 'integer' || $type eq 'number' || $type eq 'float' || $type eq 'decimal' )
        {
            $code .= sprintf( "    \$self->%-*s = ${default} unless( CORE::exists( \$self->\{${meth}\} ) );\n", $max, "\{${meth}\}" );
            if( defined( $parent_specs ) && exists( $parent_specs->{ $meth } ) )
            {
                $lines->push( "# NOTE: sub $meth is inherited from ${parent}\n" );
            }
            elsif( exists( $def->{def} ) && ref( $def->{def} ) eq 'HASH' )
            {
                my $field_def = { %{$def->{def}} };
                $field_def->{field} = $meth;
                my $field_def_str = Data::Pretty::dump( $field_def );
                $lines->push( "sub $meth { return( shift->_set_get_number( $field_def_str, \@_ ) ); }\n" );
            }
            else
            {
                $lines->push( "sub $meth { return( shift->_set_get_number( '$meth', \@_ ) ); }\n" );
            }
            
            if( exists( $sample_data->{ $meth } ) )
            {
                $example = <<EOT;
    \$obj->${meth}\($sample_data_string\);
    my \$number = \$obj->${meth};

EOT
            }
            my $pronoun = ( $type =~ /^(a|e|i|u|o)/ ? 'an' : 'a' );
            $pod->push( <<EOT );
=head2 $meth

${example}Sets or gets ${pronoun} $type value, and returns a L<number object|Module::Generic::Number> or C<undef> if no value is set.
EOT
            $synop->push( "my \$num = \$obj->${meth};" );
            $test_content .= <<EOT;
\$this = \$obj->${meth};
is( \$this => \$test_data->\{${meth}\}, '${meth}' );
if( defined( \$test_data->\{${meth}\} ) )
{
    isa_ok( \$this => 'Module::Generic::Number', '${meth} returns a number object' );
}
EOT
        }
        else
        {
            die( "Unknown type '$type' for method '$meth' in object '$object'\n" );
        }
        
        # Do we have POD addendum ?
        if( exists( $pod_more->{ $object }->{ $meth } ) &&
            defined( $pod_more->{ $object }->{ $meth } ) &&
            length( $pod_more->{ $object }->{ $meth } ) )
        {
            $pod->push( $pod_more->{ $object }->{ $meth } );
        }
    }
    
    # NOTE: special methods treatment
    if( exists( $special_methods->{ $object }->{_init_preprocess} ) )
    {
        $code .= "    \$self->{_init_preprocess} = " . $special_methods->{ $object }->{_init_preprocess};
    }
    
    $code .= <<EOT;
    \$self->{_init_strict_use_sub} = 1;
    \$self->{_exception_class} = 'Net::API::CPAN::Exception';
    \$self->SUPER::init( \@_ ) || return( \$self->pass_error );
EOT
    my $prefix = '    $self->{fields} = ';
    my $fields_string = $prefix . '[qw( ' . join( ' ', @$methods_list ) . ' )];';
    if( length( $fields_string ) > 80 )
    {
        $code .= "${prefix}\[qw\(\n";
        my $fields_list = '';
        my $tmpstr = ' ' x 8;
        foreach my $f ( @$methods_list )
        {
            if( length( $tmpstr . " $f" ) > 90 )
            {
                $fields_list .= $tmpstr . "\n";
                $tmpstr = ( ' ' x 8 ) . $f;
            }
            else
            {
                $tmpstr .= ( $tmpstr =~ /^[[:blank:]]*$/ ? $f : " ${f}" );
            }
        }
        $fields_list .= $tmpstr if( length( $tmpstr ) );
        $code .= $fields_list;
        # $code .= "\n" . ( ' ' x length( $fields_string ) ) . ")];\n";
        $code .= "\n" . ( ' ' x 4 ) . ")];\n";
        
    }
    else
    {
        $code .= $fields_string . "\n";
    }
    $code .= <<EOT;
    return( \$self );
}

EOT
    $code .= $lines->join( "\n" )->scalar;
    my $pod_lines = $pod->join( "\n" )->scalar;
    $synop = $synop->join( "\n" )->split( qr/\n/ );
    foreach( @$synop )
    {
        substr( $_, 0, 0, '    ' );
    }
    my $synop_lines = $synop->join( "\n" )->scalar;
    my $module_short_description = exists( $pod_more->{ $object }->{__description} )
        ? $pod_more->{ $object }->{__description}
        : "This class serves to retrieve and manipulate ${object_plural}.";
    $module_short_description =~ s/\n$//gs;
    $code .= <<EOT;

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::CPAN::${module_name} - Meta CPAN API ${module_name} Class

=head1 SYNOPSIS

    use Net::API::CPAN::${module_name};
${synop_lines}

=head1 VERSION

    ${modules_version}

=head1 DESCRIPTION

${module_short_description}

It inherits from L<Net::API::CPAN::Generic>

=head1 CONSTRUCTOR

=head2 new

Provided with an hash or hash reference of parameters, and this instantiates a new C<Net::API::CPAN::${module_name}> object.

The parameters that can be provided bear the same name and supports the same values as the methods below.

=head1 METHODS

${pod_lines}
EOT
    
    my $test_object_data;
    if( $sample_file->exists )
    {
        # Add 4 spaces to show it as code in POD
        my $sample_lines = $sample_file->load_utf8->split( qr/\n/ );
        # Make a copy before modifications
        $test_object_data = [@$sample_lines];
        # my $sample_lines = $sample_file->content( binmode => 'utf8' );
        for( @$sample_lines )
        {
            substr( $_, 0, 0, '    ' );
        }
        local $" = "\n";
        $code .= <<EOT;
=head1 API SAMPLE

@$sample_lines

EOT
    }
    else
    {
        $test_object_data = ["{}"];
    }
    
    $code .= <<EOT;
=head1 AUTHOR

Jacques Deguest E<lt>F<jack\@deguest.jp>E<gt>

=head1 SEE ALSO

L<Net::API::CPAN>, L<Net::API::CPAN::Activity>, L<Net::API::CPAN::Author>, L<Net::API::CPAN::Changes>, L<Net::API::CPAN::Changes::Release>, L<Net::API::CPAN::Contributor>, L<Net::API::CPAN::Cover>, L<Net::API::CPAN::Diff>, L<Net::API::CPAN::Distribution>, L<Net::API::CPAN::DownloadUrl>, L<Net::API::CPAN::Favorite>, L<Net::API::CPAN::File>, L<Net::API::CPAN::Module>, L<Net::API::CPAN::Package>, L<Net::API::CPAN::Permission>, L<Net::API::CPAN::Rating>, L<Net::API::CPAN::Release>

L<MetaCPAN::API>, L<MetaCPAN::Client>

L<https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md>

=head1 COPYRIGHT & LICENSE

Copyright(c) ${year} DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

EOT
    $mod_file->unload_utf8( $code ) || die( $mod_file->error );
    say "Saved object ${object} methods to $mod_file";
    
    {
        local $" = "\n";
        $test_content .= <<EOT;

done_testing();

__END__
@$test_object_data
EOT
    }
    $test_file->unload_utf8( $test_content ) || die( $test_file->error );
    say "Saved object ${object} unit tests to $test_file";
}

sub definition_to_pod
{
    my $this = shift( @_ );
    
    my $equi =
    {
        array => q{array (L<array object|Module::Generic::Array>)},
        array_as_object => q{array (L<array object|Module::Generic::Array>)},
        boolean => q{boolean (L<boolean object|Module::Generic::Boolean>)},
        decimal => q{integer (L<number object|Module::Generic::Number>)},
        float => q{integer (L<number object|Module::Generic::Number>)},
        integer => q{integer (L<number object|Module::Generic::Number>)},
        scalar => q{string (L<scalar object|Module::Generic::Scalar>)},
        uri => q{URI (L<uri object|URI>)},
        date => q{datetime (L<datetime object|DateTime>)},
    };
    
    my $process;
    $process = sub
    {
        my( $ref, $level ) = @_;
        $level //= 1;
        my $rows = Module::Generic::Array->new;
        $rows->push( "=over " . ( 4 * $level ) . "\n" );
        foreach my $prop ( sort( keys( %$ref ) ) )
        {
            my $prop_def = $ref->{ $prop };
            if( ref( $prop_def ) eq 'HASH' && $prop_def->{type} =~ /^class/ )
            {
                $rows->push( "=item * C<${prop}> dynamic subclass (hash reference)\n" );
                my $prop_dict = ( $prop_def->{def} || $prop_def->{definition} );
                my $subrows = $process->( $prop_dict, $level + 1 );
                $rows->push( $subrows->list );
            }
            elsif( ref( $prop_def ) eq 'HASH' && ( $prop_def->{class} || $prop_def->{package} ) )
            {
                my $prop_type = ( $equi->{ $prop_def->{type} } // $prop_def->{type} );
                my $prop_class = ( $prop_def->{class} || $prop_def->{package} );
                $rows->push( "=item * C<${prop}> L<${prop_type} object|${prop_class}>\n" );
            }
            else
            {
                my $prop_type = ref( $prop_def ) eq 'HASH' ? $prop_def->{type} : $prop_def;
                $prop_type = $equi->{ $prop_type } if( exists( $equi->{ $prop_type } ) );
                $rows->push( "=item * C<${prop}> ${prop_type}\n" );
            }
        }
        $rows->push( "=back\n" );
    };
    my $lines = $process->( $this );
    return( $lines->join( "\n" )->scalar );
}

sub dump_this
{
    my $ref = shift( @_ );
    my $str = Data::Dumper::Concise::Dumper( $ref );
    $str =~ s/\n$//gs;
    $str =~ s{
        \$VAR1\->\{(\w[\w\-]+)\}
    }
    {
        my $ref_str = $ref->{ $1 };
        Data::Dumper::Concise::Dumper( $ref_str );
    }gexs;
    return( $str );
}

exit(0);

__END__
