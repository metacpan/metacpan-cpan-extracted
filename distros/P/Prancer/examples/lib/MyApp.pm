package MyApp;

use strict;
use warnings FATAL => 'all';

use Prancer qw(config);

sub initialize {
    my $self = shift;

    # in here we get to initialize things!

    return;
}

sub handler {
    my ($self, $env, $request, $response, $session) = @_;

    # increment this counter every time the user requests a page
    my $counter = $session->get('counter');
    $counter ||= 0;
    ++$counter;
    $session->set('counter', $counter);

    sub (GET + /) {
        $response->header('Location' => '/hello');
        $response->finalize(301);
    }, sub (GET + /hello) {
        $response->header('Content-Type' => 'text/plain');
        $response->body(sub {
            my $writer = shift;

            $writer->write("hello, world\n");
            $writer->write("what is foo? foo is " . config->get('foo') . "\n");
            $writer->write("what are we counting to? let's count to " . $counter . "\n");

            $writer->close();
            return;
        });
        return $response->finalize(200);
    }, sub (GET + /goodbye) {
        $response->header('Content-Type' => 'text/plain');
        $response->body("Goodbye!");
        return $response->finalize(200);
    }
}

1;
