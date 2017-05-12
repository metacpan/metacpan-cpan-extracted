package MyService;
use Any::Moose;
use Net::Google::DataAPI;
with 'Net::Google::DataAPI::Role::Service';

has '+namespaces' => (
    default => sub { 
        +{
            hoge => 'http://example.com/schemas#hoge',
        }
    }
);

feedurl myentry => (
    entry_class => 'MyService::MyEntry',
    default => 'http://example.com/myentry',
);

feedurl fixed => (
    entry_class => 'MyService::MyEntry',
    default => 'http://example.com/fixed',
    can_add => 0,
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;
no Net::Google::DataAPI;

1;
