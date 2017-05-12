
requires "parent";
requires "Carp";
requires "Plack::Component";
requires "Plack::Response";
requires "AnyEvent";
requires "AnyEvent::WebSocket::Server" => "0.06";
requires "Try::Tiny";
requires "Scalar::Util";
requires "Devel::GlobalDestruction";

on "test" => sub {
    requires "Test::More";
    requires "Test::Requires";
    requires "AnyEvent";
    requires "Net::EmptyPort";
    requires "AnyEvent::WebSocket::Client" => "0.20";
    requires "Scalar::Util";
    requires "Plack::Util";
    requires "Protocol::WebSocket";
};

on 'configure' => sub {
    requires 'Module::Build', '0.42';
    requires 'Module::Build::Prereqs::FromCPANfile', "0.02";
};
