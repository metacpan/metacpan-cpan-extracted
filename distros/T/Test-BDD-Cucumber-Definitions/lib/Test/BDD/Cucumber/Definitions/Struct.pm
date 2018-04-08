package Test::BDD::Cucumber::Definitions::Struct;

use strict;
use warnings;

use DDP ( show_unicode => 1 );
use Exporter qw(import);
use JSON::Path qw(jpath jpath1);
use JSON::XS;
use List::Util qw(any all);
use Test::BDD::Cucumber::Definitions qw(S);
use Test::BDD::Cucumber::Definitions::Validator qw(:all);
use Test::More;
use Try::Tiny;

our $VERSION = '0.31';

our @EXPORT_OK = qw(
    http_response_content_read_json
    file_content_read_json
    zip_archive_members_read_list
    struct_data_element_eq struct_data_array_any_eq
    struct_data_element_re struct_data_array_any_re
    struct_data_element_key struct_data_list_all_key
    struct_data_element
    struct_data_array_count
);
our %EXPORT_TAGS = (
    util => [
        qw(
            http_response_content_read_json
            file_content_read_json
            zip_archive_members_read_list
            struct_data_element_eq struct_data_array_any_eq
            struct_data_element_re struct_data_array_any_re
            struct_data_element_key struct_data_list_all_key
            struct_data_element
            struct_data_array_count
            )
    ]
);

# Enable JSONPath Embedded Perl Expressions
$JSON::Path::Safe = 0;    ## no critic (Variables::ProhibitPackageVars)

## no critic [Subroutines::RequireArgUnpacking]

sub http_response_content_read_json {

    # Clean data
    S->{struct}->{data} = undef;

    my $error;

    my $decoded_content = S->{http}->{response_object}->decoded_content();

    S->{struct}->{data} = try {
        decode_json($decoded_content);
    }
    catch {
        $error = "Could not read http response content as JSON: $_[0]";

        return;
    };

    if ($error) {
        fail(qq{Http response content was read as JSON});
        diag($error);
    }
    else {
        pass(qq{Http response content was read as JSON});
    }

    diag( 'Http response content = ' . np $decoded_content );

    return;
}

sub file_content_read_json {

    # Clean data
    S->{struct}->{data} = undef;

    my $error;

    S->{struct}->{data} = try {
        decode_json( S->{file}->content );
    }
    catch {
        $error = "Could not read file content as JSON: $_[0]";

        return;
    };

    if ( !ok( !$error, qq{File content was read as JSON} ) ) {
        diag($error);

        return;
    }

    diag( 'File content = ' . np S->{file}->{content} );

    return 1;
}

sub zip_archive_members_read_list {

    # Clean data
    S->{struct}->{data} = undef;

    my @members = S->{zip}->{archive}->memberNames();

    S->{struct}->{data} = \@members;

    pass('Zip archive members was read as list');

    return;
}

sub struct_data_element_eq {
    my ( $jsonpath, $value ) = validator_ns->(@_);

    my $result = jpath1( S->{struct}->{data}, $jsonpath );

    is( $result, $value, qq{Struct data element "$jsonpath" eq "$value"} );

    diag( 'Data = ' . np S->{struct}->{data} );

    return;
}

sub struct_data_array_any_eq {
    my ( $jsonpath, $value ) = validator_ns->(@_);

    my @result = jpath( S->{struct}->{data}, $jsonpath );

    my $ok = any { $_ eq $value } @result;

    ok( $ok, qq{Struct data array "$jsonpath" any eq "$value"} );

    diag( 'Find = ' . np @result );
    diag( 'Data = ' . np S->{struct}->{data} );

    return;
}

sub struct_data_element_re {
    my ( $jsonpath, $regexp ) = validator_nr->(@_);

    my $result = jpath1( S->{struct}->{data}, $jsonpath );

    like(
        $result,
        qr/$regexp/,    ## no critic [RegularExpressions::RequireExtendedFormatting]
        qq{Struct data element "$jsonpath" re "$regexp"}
    );

    diag( 'Data = ' . np S->{struct}->{data} );

    return;
}

sub struct_data_array_any_re {
    my ( $jsonpath, $regexp ) = validator_nr->(@_);

    my @result = jpath( S->{struct}->{data}, $jsonpath );

    my $ok = any {/$regexp/x} @result;

    ok( $ok, qq{Struct data array "$jsonpath" any re "$regexp"} );

    diag( 'Find = ' . np @result );
    diag( 'Data = ' . np S->{struct}->{data} );

    return;
}

sub struct_data_array_count {
    my ( $jsonpath, $count ) = validator_ni->(@_);

    my @result = jpath( S->{struct}->{data}, $jsonpath );

    is( scalar @result, $count, qq{Struct data array "$jsonpath" count "$count"} );

    diag( 'Find = ' . np @result );
    diag( 'Data = ' . np S->{struct}->{data} );

    return;
}

sub struct_data_element_key {
    my ( $jsonpath, $value ) = validator_ns->(@_);

    my $result = jpath1( S->{struct}->{data}, $jsonpath );

    if (   ok( $result, qq{Struct data element "$jsonpath" exists} )
        && is( ref $result, 'HASH', qq{Struct data element "$jsonpath" is a hash} )
        && ok( exists $result->{$value}, qq{Struct data element "$jsonpath" contains key "$value"} ) )
    {
        return 1;
    }

    diag( "Element = " . np $result );
    diag( 'Data = ' . np S->{struct}->{data} );

    return;
}

sub struct_data_list_all_key {
    my ( $jsonpath, $value ) = validator_ns->(@_);

    my @result = jpath( S->{struct}->{data}, $jsonpath );

    if (   ok( @result, qq{Struct data list "$jsonpath" is not empty} )
        && ok( ( all { ref $_ eq 'HASH' } @result ),    qq{Struct data list "$jsonpath" is a list of hashes} )
        && ok( ( all { exists $_->{$value} } @result ), qq{Struct data list "$jsonpath" all contains key "$value"} ) )
    {
        return 1;
    }

    diag( "List = " . np @result );
    diag( 'Data = ' . np S->{struct}->{data} );

    return;
}

sub struct_data_element {
    my ($jsonpath) = validator_n->(@_);

    return jpath1( S->{struct}->{data}, $jsonpath );
}

1;
