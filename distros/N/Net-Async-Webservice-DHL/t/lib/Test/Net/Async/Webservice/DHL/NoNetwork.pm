package Test::Net::Async::Webservice::DHL::NoNetwork;
use Moo;
use 5.010;
use Future;
use XML::Simple;
use HTTP::Response;
use Test::More;
use Test::Deep;
use Data::Printer;
use Data::Visitor::Callback;

our @requests;our @testing_requests;our @responses;

sub make_ignore_dates {
    my ($struct) = @_;

    state $v = Data::Visitor::Callback->new(
        value => sub {
            return ignore() if /\A\d{4}-\d{2}-\d{2}($|T| )/;
            return ignore() if /\APT\d{2}H\d{1,2}M\z/;
            return $_;
        },
        hash => sub {
            if ($_->{MessageReference}) {
                $_->{MessageReference} = ignore();
            }
            return $_;
        },
    );

    return $v->visit($struct);
}

sub do_request {
    my ($self,%args) = @_;

    my $request = $args{request};

    my $url = $request->uri;
    my $content = $request->content;

    my $parsed_content = XMLin(
        $content,
        KeepRoot=>1,
        NoAttr=>1, KeyAttr=>[],
    );

    push @requests,[$url,$parsed_content];
    if (@testing_requests) {
        my ($url,$request_comp,$comment) = @{shift @testing_requests};
        $request_comp = make_ignore_dates($request_comp);

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

sub prepare_test_from_file {
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
