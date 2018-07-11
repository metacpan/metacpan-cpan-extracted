package Test::BDD::Cucumber::Definitions::Struct;

use strict;
use warnings;

use DDP ( show_unicode => 1 );
use Exporter qw(import);
use JSON::Path qw(jpath jpath1);
use JSON::XS;
use List::Util qw(any all);
use Test::BDD::Cucumber::Definitions qw(S :validator);
use Test::More;
use Try::Tiny;

our $VERSION = '0.41';

our @EXPORT_OK = qw(Struct);

# Enable JSONPath Embedded Perl Expressions
$JSON::Path::Safe = 0;    ## no critic (Variables::ProhibitPackageVars)

## no critic [Subroutines::RequireArgUnpacking]

sub Struct {
    return __PACKAGE__;
}

sub read_http_response_content_as_json {
    my $self = shift;

    S->{Struct} = __PACKAGE__;

    # Clean data
    S->{_Struct}->{data} = undef;

    my $error;

    S->{_Struct}->{data} = try {
        decode_json( S->{HTTP}->content() );
    }
    catch {
        $error = "Could not read http response content as JSON: $_[0]";

        return;
    };

    if ( !ok( !$error, qq{Http response content was read as JSON} ) ) {
        diag($error);
        diag( 'Http response content = ' . np S->{HTTP}->content );

        return;
    }

    return 1;
}

sub read_file_content_as_json {
    my $self = shift;

    S->{Struct} = __PACKAGE__;

    # Clean data
    S->{_Struct}->{data} = undef;

    my $error;

    S->{_Struct}->{data} = try {
        decode_json( S->{File}->content );
    }
    catch {
        $error = "Could not read file content as JSON: $_[0]";

        return;
    };

    if ( !ok( !$error, qq{File content was read as JSON} ) ) {
        diag($error);
        diag( 'File content = ' . np S->{File}->content );

        return;
    }

    return 1;
}

sub read_zip_archive_members_as_list {
    my $self = shift;

    S->{Struct} = __PACKAGE__;

    # Clean data
    S->{_Struct}->{data} = undef;

    my @members = S->{Zip}->member_names();

    S->{_Struct}->{data} = \@members;

    pass('Zip archive members was read as list');

    return 1;
}

sub read_base_response_as_struct {
    my $self = shift;

    S->{Struct} = __PACKAGE__;

    # Clean data
    S->{_Struct}->{data} = S->{Base}->response();

    pass('Base response was read as struct');

    return 1;
}

sub data_element_eq {
    my $self = shift;
    my ( $jsonpath, $value ) = validator_ns->(@_);

    my $result = jpath1( S->{_Struct}->{data}, $jsonpath );

    is( $result, $value, qq{Struct data element "$jsonpath" eq "$value"} );

    diag( 'Data = ' . np S->{_Struct}->{data} );

    return;
}

sub data_list_any_eq {
    my $self = shift;
    my ( $jsonpath, $value ) = validator_ns->(@_);

    my @result = jpath( S->{_Struct}->{data}, $jsonpath );

    my $ok = any { $_ eq $value } @result;

    ok( $ok, qq{Struct data list "$jsonpath" any eq "$value"} );

    diag( 'List = ' . np @result );
    diag( 'Data = ' . np S->{_Struct}->{data} );

    return;
}

sub data_element_re {
    my $self = shift;
    my ( $jsonpath, $regexp ) = validator_nr->(@_);

    my $result = jpath1( S->{_Struct}->{data}, $jsonpath );

    like(
        $result,
        qr/$regexp/,    ## no critic [RegularExpressions::RequireExtendedFormatting]
        qq{Struct data element "$jsonpath" re "$regexp"}
    );

    diag( 'Data = ' . np S->{_Struct}->{data} );

    return;
}

sub data_list_any_re {
    my $self = shift;
    my ( $jsonpath, $regexp ) = validator_nr->(@_);

    my @result = jpath( S->{_Struct}->{data}, $jsonpath );

    my $ok = any {/$regexp/x} @result;

    ok( $ok, qq{Struct data list "$jsonpath" any re "$regexp"} );

    diag( 'List = ' . np @result );
    diag( 'Data = ' . np S->{_Struct}->{data} );

    return;
}

sub data_list_count {
    my $self = shift;
    my ( $jsonpath, $count ) = validator_ni->(@_);

    my @result = jpath( S->{_Struct}->{data}, $jsonpath );

    is( scalar @result, $count, qq{Struct data list "$jsonpath" count "$count"} );

    diag( 'List = ' . np @result );
    diag( 'Data = ' . np S->{_Struct}->{data} );

    return;
}

sub data_element_key {
    my $self = shift;
    my ( $jsonpath, $value ) = validator_ns->(@_);

    my $result = jpath1( S->{_Struct}->{data}, $jsonpath );

    if (   ok( $result, qq{Struct data element "$jsonpath" exists} )
        && is( ref $result, 'HASH', qq{Struct data element "$jsonpath" is a hash} )
        && ok( exists $result->{$value}, qq{Struct data element "$jsonpath" contains key "$value"} ) )
    {
        return 1;
    }

    diag( "Element = " . np $result );
    diag( 'Data = ' . np S->{_Struct}->{data} );

    return;
}

sub data_list_all_key {
    my $self = shift;
    my ( $jsonpath, $value ) = validator_ns->(@_);

    my @result = jpath( S->{_Struct}->{data}, $jsonpath );

    if (   ok( @result, qq{Struct data list "$jsonpath" is not empty} )
        && ok( ( all { ref $_ eq 'HASH' } @result ),    qq{Struct data list "$jsonpath" is a list of hashes} )
        && ok( ( all { exists $_->{$value} } @result ), qq{Struct data list "$jsonpath" all contains key "$value"} ) )
    {
        return 1;
    }

    diag( "List = " . np @result );
    diag( 'Data = ' . np S->{_Struct}->{data} );

    return;
}

sub data_element {
    my $self = shift;
    my ($jsonpath) = validator_n->(@_);

    return jpath1( S->{_Struct}->{data}, $jsonpath );
}

1;
