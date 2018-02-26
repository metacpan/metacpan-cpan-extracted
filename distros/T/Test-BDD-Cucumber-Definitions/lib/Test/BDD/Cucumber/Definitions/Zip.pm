package Test::BDD::Cucumber::Definitions::Zip;

use strict;
use warnings;

use Archive::Zip;
use Carp;
use DDP ( show_unicode => 1 );
use Exporter qw(import);
use IO::String;
use Params::ValidationCompiler qw(validation_for);
use Test::BDD::Cucumber::Definitions qw(S);
use Test::More;
use Try::Tiny;

our $VERSION = '0.19';

our @EXPORT_OK = qw(
    read_content
);
our %EXPORT_TAGS = (
    util => [
        qw(
            read_content
            )
    ]
);

## no critic [Subroutines::RequireArgUnpacking]

sub read_content {

    # Clean object
    S->{zip}->{object} = undef;

    my $error;

    my $decoded_content = S->{http}->{response_object}->decoded_content();

    S->{zip}->{object} = try {
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
