use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::MockModule;


throws_ok {
    package MyService;
    use Any::Moose;
    use Net::Google::DataAPI;
    with 'Net::Google::DataAPI::Role::Service' => {
        service => 'wise',
        source => __PACKAGE__
    };

    feedurl 'myentry' => (

    );
} qr{entry_class not specified};

{
    {
        package MyEntry;
        use Any::Moose;
        with 'Net::Google::DataAPI::Role::Entry';
    }
    {
        package MyService;
        use Any::Moose;
        use Net::Google::DataAPI;
        with 'Net::Google::DataAPI::Role::Service' => {
            service => 'wise',
            source => __PACKAGE__
        };

        feedurl 'myentry' => (
            entry_class => 'MyEntry',
            # should have default or something
        );
    }
    my $s = MyService->new(
        username => 'example@gmail.com',
        password => 'foobar',
    );
    throws_ok {$s->add_myentry} qr{myentry_feedurl is not set};
    throws_ok {$s->myentry} qr{myentry_feedurl is not set};
} 

#throws_ok {
#    {
#        package Foo;
#        use Moose;
#        use Net::Google::DataAPI;
#
#        feedurl 'bar' => (
#            entry_class => 'Bar',
#        );
#    }
#} qr{Net::Google::DataAPI::Role::\(Service|Entry\) required to use feedurl};

# {
#     {
#         package Bar;
#         use Any::Moose;
#     }
#     throws_ok {
#         {
#             package MyService;
#             use Any::Moose;
#             use Net::Google::DataAPI;
# #            with 'Net::Google::DataAPI::Role::Service' => {
# #                service => 'wise',
# #                source => __PACKAGE__
# #            };
# 
#             feedurl 'foo' => (
#                 entry_class => 'Bar',
#                 default => 'http://example.com/bar',
#             );
#         }
#     } qr{Bar should do Net::Google::DataAPI::Role::Entry role};
# }

done_testing;
