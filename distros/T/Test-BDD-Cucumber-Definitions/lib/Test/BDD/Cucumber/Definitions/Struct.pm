package Test::BDD::Cucumber::Definitions::Struct;

use strict;
use warnings;

use Carp;
use DDP ( show_unicode => 1 );
use Exporter qw(import);
use JSON::Path 'jpath1';
use JSON::XS;
use Params::ValidationCompiler qw(validation_for);
use Test::BDD::Cucumber::Definitions qw(S);
use Test::BDD::Cucumber::Definitions::Struct::Types qw(:all);
use Test::More;
use Try::Tiny;

our $VERSION = '0.21';

our @EXPORT_OK = qw(
    read_content
    jsonpath_eq jsonpath_re
);
our %EXPORT_TAGS = (
    util => [
        qw(
            read_content
            jsonpath_eq jsonpath_re
            )
    ]
);

# Enable JSONPath Embedded Perl Expressions
$JSON::Path::Safe = 0;    ## no critic (Variables::ProhibitPackageVars)

## no critic [Subroutines::RequireArgUnpacking]

sub read_content {

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

my $validator_jsonpath_eq = validation_for(
    params => [

        # data structure jsonpath
        { type => StructJsonpath },

        # data structure value
        { type => StructString },
    ]
);

sub jsonpath_eq {
    my ( $jsonpath, $value ) = $validator_jsonpath_eq->(@_);

    my $result = jpath1( S->{struct}->{data}, $jsonpath );

    is( $result, $value, qq{Data structure jsonpath "$jsonpath" eq "$value"} );

    diag( 'Data structure = ' . np S->{struct}->{data} );

    return;
}

my $validator_jsonpath_re = validation_for(
    params => [

        # data structure jsonpath
        { type => StructJsonpath },

        # data structure regexp
        { type => StructRegexp },
    ]
);

sub jsonpath_re {
    my ( $jsonpath, $regexp ) = $validator_jsonpath_re->(@_);

    my $result = jpath1( S->{struct}->{data}, $jsonpath );

    like(
        $result,
        qr/$regexp/,    ## no critic [RegularExpressions::RequireExtendedFormatting]
        qq{Data structure jsonpath "$jsonpath" re "$regexp"}
    );

    diag( 'Data structure = ' . np S->{struct}->{data} );

    return;
}

1;
