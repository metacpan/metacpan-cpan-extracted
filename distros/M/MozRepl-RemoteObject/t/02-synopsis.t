#!perl -w
use strict;
use Test::More;

use MozRepl::RemoteObject;

# use $ENV{MOZREPL} or localhost:4242
my $repl;
my $ok = eval {
    $repl = MozRepl::RemoteObject->install_bridge();
    1;
};
if (! $ok) {
    my $err = $@;
    plan skip_all => "Couldn't connect to MozRepl: $@";
} else {
    plan tests => 2;
};

# get our root object:
my $tab = $repl->expr(<<JS);
    window.getBrowser().addTab()
JS

isa_ok $tab, 'MozRepl::RemoteObject::Instance', 'Our tab';

# Now use the object:
my $body = $tab->{linkedBrowser}
            ->{contentWindow}
            ->{document}
            ->{body}
            ;
$body->{innerHTML} = "<h1>Hello from MozRepl::RemoteObject</h1>";

like $body->{innerHTML}, '/Hello from/', "We stored the HTML";

# Don't connect to the outside:
#$tab->{linkedBrowser}->loadURI('http://corion.net/');

# close our tab again:
$tab->__release_action('window.getBrowser().removeTab(self)');
undef $tab;