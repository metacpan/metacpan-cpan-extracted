#!perl
use Template::Test;
$Template::Test::DEBUG = 1;

test_expect( \*DATA );

__DATA__
-- test --
[% USE Gravatar -%]
loaded

-- expect --
loaded

-- test --
[% USE Gravatar -%]
[% TRY %][% Gravatar %][% CATCH %][% error.info.replace('\s+at\s.+','') %][% END %]

-- expect --
Cannot generate a Gravatar URI without an email address

-- test --
[% USE Gravatar -%]
[% TRY %][% Gravatar(email => 'x', rating => 'NC-17') %][% CATCH %][% error.info.replace('\s+at\s.+','') %][% END %]

-- expect --
Gravatar rating can only be G, PG, R, or X

-- test --
[% USE Gravatar( size => 2049 ) -%]
[% TRY %][% Gravatar(email => 'x') %][% CATCH %][% error.info.replace('\s+at\s.+','') %][% END %]

-- expect --
Gravatar size must be 1 .. 2048
