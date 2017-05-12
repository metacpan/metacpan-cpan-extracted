package Test::Net::Async::Webservice::DHL::Tracing;
use Moo;
use Future;
use Time::HiRes 'gettimeofday';
use File::Temp 'tempfile';

has loop => ( is => 'ro', required => 1 );
has user_agent => (
    is => 'lazy',
    handles => [qw(do_request GET POST)],
);
sub _build_user_agent {
    my ($self) = @_;
    require Net::Async::HTTP;
    my $ua = Net::Async::HTTP->new();
    $self->loop->add($ua);
    return $ua;
}

around do_request => sub {
    my ($orig,$self,%args) = @_;
    my $request = $args{request};

    my ($sec,$usec) = gettimeofday;

    my ($fh,$filename) = tempfile("net-dhl-$sec-$usec-XXXX");

    printf $fh "POST %s\n\n%s\n",
        $request->uri,
        $request->content;

    my $response_f = $self->$orig(%args);
    $response_f->on_done(
        sub {
            my ($response) = @_;
            print $fh $response->content;
        }
    );

    return $response_f;
};

1;
