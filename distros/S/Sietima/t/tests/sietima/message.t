#!perl
use lib 't/lib';
use Test::Sietima;
use Email::Stuffer;
use Sietima::Message;

my $mail = Email::Stuffer
    ->from('one@example.com')
    ->to('two@example, three@example.com')
    ->text_body('test message')->email;

my $message = Sietima::Message->new({
    mail => $mail,
    from => 'one@envelope.example.com',
    to => [
        'two@envelope.example.com',
        'three@envelope.example.com',
    ],
});

is(
    $message->envelope,
    {
        from => 'one@envelope.example.com',
        to => bag {
            item 'two@envelope.example.com';
            item 'three@envelope.example.com';
        },
    },
    'the envelope should be built from the attributes',
);

# I'm not sure I'll need 'clone', so I won't test it for the moment

done_testing;
