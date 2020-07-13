use strict;
use warnings;

use Test::More;

BEGIN { $ENV{EMAIL_SENDER_TRANSPORT} = 'Test' }

use Email::Simple;
use Email::Simple::Creator;
use Email::Sender::Simple qw(sendmail);

use Log::Any::Adapter qw(TAP);

use OpenTracing::Any qw($tracer);
use OpenTracing::Integration qw(Email::Sender);

my $email = Email::Simple->create(
    my %msg = (
        header => [
          To      => '"System user" <system@example.com>',
          From    => '"Target user" <target@example.com>',
          Subject => 'Example subject content',
        ],
        body => "Message content here",
    )
);

sendmail($email);
my @spans = $tracer->span_list;
is(@spans, 1, 'have a single span');
my $span = shift @spans;
is($span->operation_name, 'email: Example subject content', 'have correct operation');
my %tags = $span->tags->%*;
is_deeply(\%tags, {
    'component'       => 'Email::Sender::Simple',
    'email.to'        => 'system@example.com',
    'email.from'      => 'target@example.com',,
    'email.subject'   => 'Example subject content',
    'email.body_size' => length($msg{body}) + 2, # CRLF
    'span.kind'       => 'client',
}, 'have expected tags');

done_testing;


