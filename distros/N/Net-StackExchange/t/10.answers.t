use strict;
use warnings;

use Test::More tests => 13;
use Test::Differences;

use Net::StackExchange;

my $se = Net::StackExchange->new( {
    'network' => 'stackoverflow.com',
    'version' => '1.0',
} );

my $answers_route = $se->route('answers');
isa_ok( $answers_route, 'Net::StackExchange::Route' );

my $answers_request = $answers_route->prepare_request( { 'id' => '1036353' } );
isa_ok( $answers_request, 'Net::StackExchange::Answers::Request' );

$answers_request->body    ('true');
$answers_request->comments('true');

my $answers_response = $answers_request->execute();
isa_ok( $answers_response, 'Net::StackExchange::Answers::Response' );

is( $answers_response->total   (), 1,  'matched total'    );
is( $answers_response->page    (), 1,  'matched page'     );
is( $answers_response->pagesize(), 30, 'matched pagesize' );

my $answer = $answers_response->answers(0);

is( $answer->answer_id(), 1036353, 'matched answer_id' );
is( $answer->answer_comments_url(),
    '/answers/1036353/comments', 'matched answer_comments_url' );
is( $answer->question_id(), 1036347, 'matched question_id' );

subtest 'Net::StackExchange::Owner' => sub {
    plan tests => 5;

    my $owner = $answer->owner();
    isa_ok( $owner, 'Net::StackExchange::Owner' );

    is( $owner->user_id     (), 66353,               'matched user_id'      );
    is( $owner->user_type   (), 'registered',        'matched user_type'    );
    is( $owner->display_name(), 'Alan Haggai Alavi', 'matched display_name' );
    is( $owner->email_hash(),
        'b56a740041997df881354ef8c97496d7', 'matched email_hash' );
};

is( $answer->creation_date(), 1245816616, 'matched creation_date' );

eq_or_diff( $answer->title(),
    'How do I use boolean variables in Perl?', 'matched title' );
eq_or_diff( $answer->body(),
    q{<p>In Perl, the following evaluate to false in conditionals:</p>

<pre><code>0
'0'
undef
''  # Empty scalar
()  # Empty list
('')
</code></pre>

<p>The rest are true. There are no barewords for <code>true</code> or <code>false</code>.</p>
}, 'matched body' );
