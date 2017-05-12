package Net::Flotum::API::ExceptionHandler;
use strict;
use warnings;
use utf8;
use JSON::MaybeXS;

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw/request_with_retries/;

sub request_with_retries {
    my (%opts)    = @_;
    my $logger    = $opts{logger};
    my $requester = $opts{requester};
    my $tries = $opts{tries} || 3;
    my $sleep = $opts{sleep} || 1;
    my $name  = $opts{name};

    my ( $obj, $req, $res );
    while ( $tries-- ) {

        my $func = $opts{method};
        $obj = eval {
            $requester->stash->$func(
                @{ $opts{params} },
                process_response => sub {
                    $res = $_[0]->{res};
                    $req = $_[0]->{req};
                },
            );
        };
        last unless $@;

        die "Response not defined: $@" unless defined $res;
        if ( $res->code == 404 && $res->content !~ /Endpoint not found/ ) {
            die "Resource does not exists\n";
        }
        if ( $res->code == 400 && ref $obj eq 'HASH' && ref $obj->{error} eq 'form_error' ) {
            my $msg = "Invalid data:\n";
            $msg .= "$_ = " . $obj->{form_error}{$_} . "\n" for keys %{ $obj->{form_error} };
            $logger->error( &log_error_txt( $@, $req, $res ) );
            $logger->error($msg);
            die "$msg\n";
        }
        elsif ( $res->code == 400 && ref $obj eq 'ARRAY' ) {
            my $msg = "Invalid data:\n";
            $msg .= encode_json($_) . "\n" for @{$obj};
            $logger->error( &log_error_txt( $@, $req, $res ) );
            $logger->error($msg);
            die $obj;
        }

        $logger->error( &log_error_txt( $@, $req, $res ) );

        # erros nao 500 desiste na hora.
        if ( $tries == 0 || $res->code != 500 ) {
            $logger->error( "Giving up $name. Reponse code " . $res->code );
            die "Can't $name right now, response code ${\$res->code}.\n";
        }
        $logger->info("trying $tries more times...");
        sleep $sleep;
    }

    return ( obj => $obj, res => $res );
}

sub log_error_txt {
    my ( $err, $req, $res ) = @_;

    return "Error! $err\nREQUEST: \n" . eval { $req->as_string } . "\nRESPONSE\n" . eval { $res->as_string };
}

1;
