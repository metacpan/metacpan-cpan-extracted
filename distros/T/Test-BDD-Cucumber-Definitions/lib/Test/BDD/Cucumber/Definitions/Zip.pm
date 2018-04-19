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

our $VERSION = '0.35';

our @EXPORT_OK = qw(Zip);

## no critic [Subroutines::RequireArgUnpacking]

sub Zip {
    return __PACKAGE__;
}

sub read_http_response_content_as_zip {
    my $self = shift;

    S->{Zip} = __PACKAGE__;

    # Clean archive
    S->{_Zip}->{archive} = undef;

    my $error;

    S->{_Zip}->{archive} = try {
        my $fh = IO::String->new( \S->{HTTP}->content() );

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

    if ( !ok( !$error, qq{Http response content was read as Zip} ) ) {
        diag($error);
        diag( 'Http response content = ' . np S->{HTTP}->content );

        return;
    }

    return 1;
}

sub member_names {
    my $self = shift;

    return S->{_Zip}->{archive}->memberNames();
}

1;
