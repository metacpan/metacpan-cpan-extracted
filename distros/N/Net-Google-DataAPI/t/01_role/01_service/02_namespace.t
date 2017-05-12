use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockModule;
use Test::Exception;

BEGIN {
    use_ok 'Net::Google::DataAPI::Role::Service';
}

{
    package MyService;
    use Any::Moose;
    with 'Net::Google::DataAPI::Role::Service';
    has '+source' => (default => __PACKAGE__);
    has '+namespaces' => (
        default => sub {
            +{
                gs => 'http://schemas.google.com/spreadsheets/2006',
            }
        }
    );

    has password => (is => 'ro', isa => 'Str');
    has username => (is => 'ro', isa => 'Str');

    sub _build_auth {
        my ($self) = @_;
        my $auth = Net::Google::DataAPI::Auth::ClientLogin->new(
            username => $self->username,
            password => $self->password,
            service => 'wise',
            source => $self->source,
        );
        $auth;
    }
}

{
    my $res = Test::MockObject->new;
    $res->mock(is_success => sub {1});
    $res->mock(auth => sub {'foobar'});

    my $auth = Test::MockModule->new('Net::Google::AuthSub');
    $auth->mock(login => sub {return $res});

    my $service = MyService->new(
        username => 'example@gmail.com',
        password => 'foobar',
    );
    {
        ok my $gs = $service->ns('gd');
        isa_ok $gs, 'XML::Atom::Namespace';
        is $gs->{prefix}, 'gd';
        is $gs->{uri}, 'http://schemas.google.com/g/2005';
    }
    {
        ok my $gs = $service->ns('gs');
        isa_ok $gs, 'XML::Atom::Namespace';
        is $gs->{prefix}, 'gs';
        is $gs->{uri}, 'http://schemas.google.com/spreadsheets/2006';
    }
    {
        throws_ok { $service->ns('foobar') } qr{Namespace 'foobar' is not defined!};
    }
}

done_testing;
