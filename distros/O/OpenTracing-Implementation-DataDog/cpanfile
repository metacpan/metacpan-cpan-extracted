requires        "OpenTracing::Role", '>= 0.06, < 0.80.0'; # moving more to roles
requires        "OpenTracing::Implementation", '0.03';

requires        "Carp";
requires        "Exporter";
requires        "HTTP::Request";
requires        "JSON::MaybeXS";
requires        "LWP::UserAgent";
requires        "Moo";
requires        "Moo::Role";
requires        "MooX::Attribute::ENV";
requires        "MooX::HandlesVia";
requires        "PerlX::Maybe";
requires        "Ref::Util";
requires        "Sub::Trigger::Lock";
requires        "Syntax::Feature::Maybe";
requires        "Time::HiRes";
requires        "Try::Tiny";
requires        "Types::Common::String";
requires        "Types::Interface";
requires        "Types::Standard";
requires        "Type::Tiny::XS";
requires        "aliased";
requires        "syntax";

on 'develop' => sub {
    requires    "ExtUtils::MakeMaker::CPANfile";
};

on 'test' => sub {
    requires    "Test::Most";
    requires    "Test::OpenTracing::Interface";
};
