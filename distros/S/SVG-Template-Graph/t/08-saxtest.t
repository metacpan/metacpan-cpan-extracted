#!/usr/bin/perl
use Test;
BEGIN { plan tests => 1 }
use XML::SAX::PurePerl;
use XML::SAX::PurePerl::DebugHandler;
use XML::SAX qw(Namespaces);

my $handler = XML::SAX::PurePerl::DebugHandler->new();
my $parser = XML::SAX::PurePerl->new(Handler => $handler);

foreach my $f (qw(template1.svg)) {
     my $file = sprintf("t/%s", $f);
     eval {
         $parser->parse_uri($file);
     };
     if ($@) {
         ok(0, 1, $@);
         warn($@) if $ENV{DEBUG_XML};
     }
     else {
         ok(1);
     }
}

