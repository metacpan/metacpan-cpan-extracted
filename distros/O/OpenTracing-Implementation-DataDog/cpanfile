requires        "OpenTracing::Role", '>= v0.86.0';
requires        "OpenTracing::Implementation", '0.03';

requires        "Carp";
requires        "Data::Validate::URI";
requires        "Exporter";
requires        "Hash::Merge";
requires        "HTTP::Request";
requires        "HTTP::Response::Maker";
requires        "JSON::MaybeXS";
requires        "LWP::UserAgent";
requires        "Moo";
requires        "Moo::Role";
requires        "MooX::Attribute::ENV", '>= 0.04';
requires        "MooX::Enumeration";
requires        "MooX::ProtectedAttributes";
requires        "MooX::Should", '>=v0.1.4';
requires        "PerlX::Maybe";
requires        "Ref::Util";
requires        "Sub::HandlesVia";
requires        "Sub::Trigger::Lock";
requires        "Syntax::Feature::Maybe";
requires        "Try::Tiny";
requires        "Types::Common::Numeric";
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
    requires    "Ref::Util";
    requires    "Test::JSON";
    requires    "Test::Most";
    requires    "Test::MockModule";
    requires    "Test::OpenTracing::Interface";
    requires    "Test::URI";
};
