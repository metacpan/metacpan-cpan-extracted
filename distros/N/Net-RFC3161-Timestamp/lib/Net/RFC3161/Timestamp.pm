package Net::RFC3161::Timestamp;
# ABSTRACT: Utility functions to request RFC3161 timestamps
$Net::RFC3161::Timestamp::VERSION = '0.010';
use strict;
use warnings;
use Exporter 'import';
use Carp;
use HTTP::Request;
use LWP::UserAgent;

our @EXPORT    = qw(list_tsas attest_file);
our @EXPORT_OK = qw(dump_ts make_request_for_file post_request write_response_to_file);



my %TSAs = (
    ## RFC 3161 compatible:
    "certum" => "http://time.certum.pl/",
    "comodo" => "http://timestamp.comodoca.com/",
    "digicert" => "http://timestamp.digicert.com/",
    "globalsign" => "http://timestamp.globalsign.com/scripts/timestamp.dll",
    "quovadis" => "http://tsa01.quovadisglobal.com/TSS/HttpTspServer",
    "startcom" => "http://tsa.startssl.com/rfc3161",
    "verisign" => "http://sha256timestamp.ws.symantec.com/sha256/timestamp",
    # national
    "dfn.de" => "http://zeitstempel.dfn.de",
    "ermis.gov.gr" => "http://timestamp.ermis.gov.gr/TSS/HttpTspServer",
    "e-guven.com" => "http://zd.e-guven.com/TSS/HttpTspServer",
    "ssc.lt" => "http://gdlqtsa.ssc.lt/TSS/HttpTspServer",
);

sub list_tsas() {
  return \%TSAs;
}


sub dump_ts {
    my ($kind, $buf) = @_;

    if (open(my $fh, "|-", "openssl", "ts", "-$kind",
                                            "-in" => "/dev/stdin",
                                            "-text"))
    {
        $fh->binmode;
        $fh->write($buf);
        $fh->close;
    } else {
        _warn("failed to spawn 'openssl ts'");
    }
}


sub make_request_for_file {
    my ($file, $hash_algo, $policy) = @_;
    $hash_algo //= "sha512";

    my @cmd = ("openssl", "ts", "-query",
                                "-data" => $file,
                                "-$hash_algo",
                                "-cert");
    if ($policy) {
        push @cmd, ("-policy" => $policy);
    }

    if (open(my $fh, "-|", @cmd)) {
        my $req_buf;
        $fh->binmode;
        $fh->read($req_buf, 4*1024);
        $fh->close;
        return $req_buf;
    } else {
        croak("failed to spawn 'openssl ts'");
    }
}


sub post_request {
    my ($req_buf, $tsa_url) = @_;
    
    croak "no timestamping request given" unless defined $req_buf;
    $tsa_url //= "dfn.de";

    if ($tsa_url !~ m!^https?://!) {
        if ($TSAs{$tsa_url}) {
            $tsa_url = $TSAs{$tsa_url};
        } else {
            croak("unknown timestamping authority '$tsa_url'");
        }
    }
    
    my $ua = LWP::UserAgent->new;

    my $req = HTTP::Request->new("POST", $tsa_url);
    $req->protocol("HTTP/1.0");
    $req->header("Content-Type" => "application/timestamp-query");
    $req->header("Accept" => "application/timestamp-reply,application/timestamp-response");
    $req->content($req_buf);

    my $res = $ua->request($req);
    if ($res->code == 200) {
        my $ct = $res->header("Content-Type");
        if ($ct eq "application/timestamp-reply"
            || $ct eq "application/timestamp-response")
        {
            return $res->content;
        } else {
            croak("server returned wrong content-type '$ct'");
        }
    } else {
        croak("server returned error '".$res->status_line."'");
    }
}


sub write_response_to_file {
    my ($res_buf, $file) = @_;

    if (open(my $fh, ">", $file)) {
        $fh->binmode;
        $fh->write($res_buf);
        $fh->close;
    } else {
        croak("could not open '$file': $!");
    }
}


sub attest_file {
    my $in_file = shift;
    my $out_file = shift;
    my $tsa = shift;
    my $hash_algo = shift;
    my $policy = shift;
    my $verbose = shift;

    my $req_buf = make_request_for_file($in_file, $hash_algo, $policy);
    if ($verbose) {
        say("generated timestamp query follows:");
        dump_ts("query", $req_buf);
    }

    my $res_buf = post_request($req_buf, $tsa);
    if ($verbose) {
        say("received timestamp reply follows:");
        dump_ts("reply", $res_buf);
    }

    write_response_to_file($res_buf, $out_file);
    if ($verbose) {
        say("wrote signed timestamp to '$out_file'");
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::RFC3161::Timestamp - Utility functions to request RFC3161 timestamps

=head1 VERSION

version 0.010

=head2 list_tsas

 my $l = list_tsas();

Returns a hash reference. The keys correspond to shortnames of timestamping
authorities ("dfn.de", "verisign"), the values to the access URLs.

=head2 make_request_for_file

 my $req_buf = make_request_for_file($in_file, $hash_algo, $policy);

Generate a timestamp request for a file and place it into $req_buf.

=head2 post_request

 my $res_buf = post_request_to_tsa($req_buf, $tsa);

Post a timestamp request to a timestamping authority and retrieve the result.

$tsa can either be the name of a timestamping authority from the above table
or directly a https URL.

=head2 write_response_to_file

 write_response_to_file($res_buf, $out_file);

Write the timestamp to a result file.

=head2 attest_file

 attest_file($in_file, $out_file, $tsa, $hash_algo, $policy, $verbose);

Obtain an attested timestamp for $in_file and place it into $out_file, using
the hash algorithm $hash_algo and the policy $policy.

=head1 AUTHOR

Andreas K. Huettel <dilfridge@gentoo.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Andreas K. Huettel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
