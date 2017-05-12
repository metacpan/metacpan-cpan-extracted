package
    # hide from PAUSE
    Test::Net::BaruwaAPI;

use utf8;
use strict;
use warnings;
use Exporter qw/import/;
use Net::BaruwaAPI;
use Carp qw/confess/;
use HTTP::Response;
use FindBin '$Bin';
use JSON::MaybeXS qw(decode_json);

my ($Current_Object, $Expected_Response, $Last_Request_method, $Last_Request_path);

our @EXPORT = qw/get_last_request_method get_last_request_path set_expected_response/;

{
    no warnings 'redefine', 'once';
    no strict 'refs';

    *Net::BaruwaAPI::_call = \&_mocked_send_request;
}

sub new {
    my $class = shift;

    $Current_Object = Net::BaruwaAPI->new(@_);

    return $Current_Object;
}

sub get_last_request_method {
    return $Last_Request_method;
}

sub get_last_request_path {
    return $Last_Request_path;
}

sub set_expected_response {
    my ($filename) = @_;

    if (defined($filename) and -f "$Bin/responses/$filename") {
        my $slurped = _slurp("$Bin/responses/$filename");
        $Expected_Response = decode_json($slurped);
    } else {
        $Expected_Response = "";
    }
    return;
}

sub _mocked_send_request {
    my ( $self, $request_method, $request_path ) = @_;

    $Last_Request_method = $request_method;
    $Last_Request_path = $request_path;

    if ( !defined $Expected_Response ) {
        confess "Test implemented with errors: "
              . "please define the response before making request";
    }

    return $Expected_Response;
}

sub _slurp {
    my ($path) = @_;

    open my $fh, '<', $path or die $!;
    my $slurped = do { local $/; <$fh> };
    close $fh or die $!;

    return $slurped;
}

1;
