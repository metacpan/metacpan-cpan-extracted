package Test::BDD::Cucumber::Definitions::Data;

use strict;
use warnings;

use Carp;
use DDP ( show_unicode => 1 );
use Exporter qw(import);
use JSON::Path 'jpath1';
use JSON::XS;
use Params::ValidationCompiler qw( validation_for );
use Test::BDD::Cucumber::Definitions::TypeConstraints qw(:all);
use Test::BDD::Cucumber::StepFile qw();
use Test::More;
use Try::Tiny;

our $VERSION = '0.11';

our @EXPORT_OK = qw(S C
    content_decode
    jsonpath_eq jsonpath_re
);
our %EXPORT_TAGS = (
    util => [
        qw(
            content_decode
            jsonpath_eq jsonpath_re
            )
    ]
);

# Enable JSONPath Embedded Perl Expressions
$JSON::Path::Safe = 0;    ## no critic (Variables::ProhibitPackageVars)

## no critic [Subroutines::RequireArgUnpacking]

sub S { return Test::BDD::Cucumber::StepFile::S }
sub C { return Test::BDD::Cucumber::StepFile::C }

my $validator_content_decode = validation_for(
    params => [

        # http response content format
        { type => ValueString }
    ]
);

sub content_decode {
    my ($format) = $validator_content_decode->(@_);

    # Clean data structure
    S->{data}->{structure} = undef;

    my $error;

    my $decoded_content = S->{http}->{response_object}->decoded_content();

    if ( $format eq 'JSON' ) {
        S->{data}->{structure} = try {
            decode_json($decoded_content);
        }
        catch {
            $error = "Could not decode http response content as JSON: $_[0]";

            return;
        };
    }

    if ($error) {
        fail(qq{Http response content was decoded as "$format"});
        diag($error);
    }
    else {
        pass(qq{Http response content was decoded as "$format"});
    }

    diag( 'Http response content = ' . np $decoded_content );

    return;
}

my $validator_jsonpath_eq = validation_for(
    params => [

        # data structure jsonpath
        { type => ValueJsonpath },

        # data structure value
        { type => ValueString },
    ]
);

sub jsonpath_eq {
    my ( $jsonpath, $value ) = $validator_jsonpath_eq->(@_);

    my $result = jpath1( S->{data}->{structure}, $jsonpath );

    is( $result, $value, qq{Data structure jsonpath "$jsonpath" eq "$value"} );

    diag( 'Jsonpath result = ' . np $result);
    diag( 'Data structure = ' . np S->{data}->{structure} );

    return;
}

my $validator_jsonpath_re = validation_for(
    params => [

        # data structure jsonpath
        { type => ValueJsonpath },

        # data structure regexp
        { type => ValueRegexp },
    ]
);

sub jsonpath_re {
    my ( $jsonpath, $regexp ) = $validator_jsonpath_re->(@_);

    my $result = jpath1( S->{data}->{structure}, $jsonpath );

    like(
        $result,
        qr/$regexp/,    ## no critic [RegularExpressions::RequireExtendedFormatting]
        qq{Data structure jsonpath "$jsonpath" re "$regexp"}
    );

    diag( 'Jsonpath result = ' . np $result);
    diag( 'Data structure = ' . np S->{data}->{structure} );

    return;
}

1;
