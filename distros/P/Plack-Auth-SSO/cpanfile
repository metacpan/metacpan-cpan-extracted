#perl dependencies
requires "perl","v5.10.1";

requires "Data::Util";
requires "Moo";
requires "Moo::Role";
requires "Authen::CAS::Client";
requires "Plack";
requires "Plack::Middleware::Session";
requires "URI";
requires "URI::QueryParam";
requires "LWP::UserAgent";
requires "WWW::ORCID","0.0401";
requires "Clone";
requires "LWP::Protocol::https";
requires "Data::UUID";

on "test" => sub {
    requires "Devel::Cover";
    requires "Test::More";
    requires "Test::Exception";
    requires "Plack::Test";
    requires "Plack::Test::Server";
    requires "Plack::Builder";
    requires "Plack::Session";
    requires "HTTP::Request::Common";
    requires "HTTP::Cookies";
    requires "Dancer::Middleware::Rebase";
    requires "URI::Escape";
    requires "LWP::UserAgent";
};
