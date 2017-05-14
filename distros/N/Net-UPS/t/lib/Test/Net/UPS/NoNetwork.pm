package Test::Net::UPS::NoNetwork;
use strict;
use warnings;
use Net::UPS;
use XML::Simple;
use HTTP::Response;
use Test::Deep;

our @ISA=('Net::UPS');

our @requests;our @testing_requests;our @responses;

# we don't need this in tests, and it makes parsing the requsets
# harder
sub access_as_xml { '' }

sub post {
    my ($self,$url,$content) = @_;

    my $parsed_content = XMLin(
        $content,
        KeepRoot=>1,
        NoAttr=>1, KeyAttr=>[],
    );

    push @requests,[$url,$parsed_content];
    if (@testing_requests) {
        my ($url,$request,$comment) = @{shift @testing_requests};
        cmp_deeply([$url,$parsed_content],
                   [$url,$request],
                   $comment || 'expected request');
    }

    if (@responses) {
        my $data = shift @responses;
        return (ref($data) ? ( XMLout(
            $data,
            KeepRoot => 1,
            NoAttr => 1,
            KeyAttr => [],
            XMLDecl => 1,
        ) ) : $data);
    }
    else {
        die 'no test response prepared';
    }
}

sub prepare_test_from_file {
    my ($self,$file,$comment) = @_;

    my ($req_line,$request,$response) = do {
        open my $fh,'<:utf8',$file;
        local $/="";
        <$fh>;
    };
    $req_line =~ s{^POST }{}; # remove HTTP verb, we know it's a POST
    $request = XMLin(
        $request,
        KeepRoot=>1,
        NoAttr=>1, KeyAttr=>[],
    );
    push @testing_requests,[$req_line,$request];
    push @responses,$response;
    return;
}

sub pop_last_request {
    return @{pop @requests};
}

sub push_test_responses {
    shift;
    push @responses,@_;
}

1;
