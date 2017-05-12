package Net::Google::PicasaWeb::Test::Role::Offline;
use Test::Able::Role;

use Test::MockObject;
use Test::More;

our $NOT_A_TEST = 1;

BEGIN {
    my $obj = Test::MockObject->new;
    $obj->fake_module('LWP::UserAgent');
    $obj->fake_module('HTTP::Request');
    $obj->fake_module('HTTP::Response');
}

eval "use Net::Google::PicasaWeb";

has ua => (
    is        => 'rw',
    isa       => 'LWP::UserAgent',
);

has request => (
    is        => 'rw',
    isa       => 'HTTP::Request',
);

has headers => (
    is        => 'rw',
    isa       => 'HashRef',
);

has response => (
    is        => 'rw',
    isa       => 'HTTP::Response',
);

has service => (
    is        => 'rw',
    isa       => 'Net::Google::PicasaWeb',
);

setup order => -9, setup_mock_ua => sub {
    my $self = shift;

    my $ua = Test::MockObject->new;
    $ua->set_isa('LWP::UserAgent');

    {
        no warnings 'redefine';
        *LWP::UserAgent::new = sub { $ua };
    }

    $ua->set_always('simple_request', $self->response);
    $ua->set_always('request', $self->response);

    # Setup env_proxy()
    $ua->mock( env_proxy => sub { } );

    $self->ua($ua);
};

setup order => -10, setup_mock_request => sub {
    my $self = shift;

    my $request = Test::MockObject->new;
    $request->set_isa('HTTP::Request');

    {
        no warnings 'redefine';
        *HTTP::Request::new = sub { $request->{new_args} = [@_]; $request };
    }

    $request->set_always('authorization_basic', '');
    $request->set_always('header', '');
    $request->set_always('content', '');

    $request->mock(push_header => sub { });
    $request->mock('-new_args', sub { delete $request->{new_args} });

    $self->request($request);
};

setup order => -10, setup_mock_response => sub {
    my $self = shift;

    my $response = Test::MockObject->new;
    $response->set_isa('HTTP::Response');

    {
        no warnings 'redefine';
        *HTTP::Response::new = sub { $response };
    }

    my $headers = {};

    $response->mock('header', sub { return $headers->{$_[1]} });
    $response->set_always('code', 200);
    $response->set_always('content', '');
    $response->set_always('is_success', 1);
    $response->set_always( is_error => '' );

    $self->headers($headers);
    $self->response($response);
};

setup setup_service => sub {
    my $self = shift;
    $self->service( Net::Google::PicasaWeb->new );
};

sub set_response_content {
    my ($self, $file) = @_;
    my $path = "t/data/$file.xml";

    open my $fh, $path or die "failed to open test data file $path: $!";
    $self->response->set_always( content => do { local $/; <$fh> } );
}

1;
