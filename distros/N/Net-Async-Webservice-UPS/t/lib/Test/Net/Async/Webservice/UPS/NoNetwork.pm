package Test::Net::Async::Webservice::UPS::NoNetwork;
use Moo;
use Future;
use XML::Simple;
use HTTP::Response;
use Test::Deep;

our @requests;our @testing_requests;our @responses;

sub do_request {
    my ($self,%args) = @_;

    my $request = $args{request};

    my $url = $request->uri;
    my $content = $request->content;

    # remove the access request prefixed document
    $content =~ s{\A <\?xml .*? (?= <\?xml)}{}xms;

    my $parsed_content = XMLin(
        $content,
        KeepRoot=>1,
        NoAttr=>1, KeyAttr=>[],
    );

    push @requests,[$url,$parsed_content];
    if (@testing_requests) {
        my ($url,$request_comp,$comment) = @{shift @testing_requests};
        my ($root) = keys %$request_comp;
        if ($request_comp->{$root}{Request}{TransactionReference}) {
            $request_comp->{$root}{Request}{TransactionReference}{XpciVersion} =
                $Net::Async::Webservice::UPS::VERSION||'0';
        }
        cmp_deeply([$url,$parsed_content],
                   [$url,$request_comp],
                   $comment || 'expected request');
    }

    if (@responses) {
        my $data = shift @responses;
        return Future->wrap(HTTP::Response->new(
            200,'OK',[],
            (ref($data) ? ( XMLout(
                $data,
                KeepRoot => 1,
                NoAttr => 1,
                KeyAttr => [],
                XMLDecl => 1,
            ) ) : $data),
        ));
    }
    else {
        my $res = HTTP::Response->new(
            500,'no test response prepared',
            [],'',
        );
        return Future->new->fail(
            $res->status_line,
            'http',
            $res,
            $request,
        );
    }
}

sub file_for_next_test {
    my ($self,$file,$comment) = @_;

    my ($req_line,$request,$response) = do {
        open my $fh,'<',$file;
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

sub POST {}
sub GET {}

1;
