use Test::More tests => [% modules.size %];

BEGIN {
[% FOREACH module = modules -%]
    use_ok('[%module%]');
[% END -%]
}

diag( "Testing [%modules.0%] $[%modules.0%]::VERSION" );
