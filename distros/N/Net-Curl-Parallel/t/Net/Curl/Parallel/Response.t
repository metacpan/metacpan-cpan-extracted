use Test2::V0;
use Test2::API qw(context);
use Test2::Tools::Spec;
use Test2::Tools::Explain;
use Test2::Plugin::SpecDeclare;
use strictures 2;

use Net::Curl::Parallel::Response;

subtest basics => sub{
  ok my $r = Net::Curl::Parallel::Response->new, 'ctor';
  #ok !$r->complete,  'incomplete';
  ok !$r->completed, 'incompleted';

  is $r->as_http_response, undef, 'as_http_response returns undef before completion';

  print {$r->fh_head} "HTTP/1.1 200 OK\r\nContent-type: text/sarcasm\r\nDate: Tue, 12 Dec 2017 08:00:00 GMT\r\n\r\n";
  print {$r->fh_body} 'how now brown bureaucrat';

  $r->complete;

  ok $r->completed, 'completed';

  is $r->headers, {'content-type' => 'text/sarcasm', 'date' => 'Tue, 12 Dec 2017 08:00:00 GMT'}, 'headers';
  is $r->content, 'how now brown bureaucrat', 'content';

  subtest as_http_response => sub{
    isa_ok((my $h = $r->as_http_response), 'HTTP::Response');
    is $h->content, 'how now brown bureaucrat', 'content';
    is $h->header('Content-type'), 'text/sarcasm', 'header';
  };
};

subtest fail => sub{
  subtest 'random error' => sub {
    my $r = Net::Curl::Parallel::Response->new;
    $r->fail('fnord');
    ok $r->completed, 'complete';
    is $r->error, 'fnord', 'error';
    is $r->status, 400, 'status is 400';
    is $r->headers, hash{ end; }, 'headers';
  };

  subtest 'with timeout' => sub {
    my $r = Net::Curl::Parallel::Response->new;
    $r->fail('with timeout');
    ok $r->completed, 'complete';
    is $r->error, 'with timeout', 'error';
    is $r->status, 408, 'status is 408';
    is $r->headers, hash{ end; }, 'headers';
  };

  subtest 'complete without raw_head' => sub {
    my $r = Net::Curl::Parallel::Response->new;
    ok !$r->complete, 'complete returns failure without raw_head';
    ok $r->completed, 'marked completed';
    is $r->status, 400, 'status is 400';
    is $r->error, 'incomplete message', 'message is correct';
  };
};

done_testing;
