package Test::BDD::Cucumber::Definitions::Zip;

use strict;
use warnings;

use Archive::Zip;
use DDP ( show_unicode => 1 );
use Exporter qw(import);
use IO::String;
use Test::BDD::Cucumber::Definitions qw(S);
use Test::BDD::Cucumber::Definitions::Validator qw(:all);
use Test::More;
use Try::Tiny;

our $VERSION = '0.29';

our @EXPORT_OK = qw(
    http_response_content_read_zip
);
our %EXPORT_TAGS = (
    util => [
        qw(
            http_response_content_read_zip
            )
    ]
);

## no critic [Subroutines::RequireArgUnpacking]

sub http_response_content_read_zip {

    # Clean archive
    S->{zip}->{archive} = undef;

    my $error;

    my $decoded_content = S->{http}->{response_object}->decoded_content();

    S->{zip}->{archive} = try {
        my $fh = IO::String->new( \$decoded_content );

        # The default error handler is the Carp::carp function (warning, not an exception)
        Archive::Zip::setErrorHandler( sub { die @_ } );    ## no critic [ErrorHandling::RequireCarping]

        my $zip = Archive::Zip->new();
        $zip->readFromFileHandle($fh);

        return $zip;
    }
    catch {
        $error = "Could not read http response content as Zip: $_[0]";

        return;
    };

    if ($error) {
        fail(qq{Http response content was read as Zip});
        diag($error);
    }
    else {
        pass(qq{Http response content was read as Zip});
    }

    diag( 'Http response content = ' . np $decoded_content );

    return;
}

1;
