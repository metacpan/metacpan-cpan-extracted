
use 5.010;
use Test::More 0.88;

use Perl::PrereqScanner;

my @TESTS = (
    {
        perl_code => <<'PERL',

package Cat;
use Mojo::Base -base;
 
has name => 'Nyan';
has ['age', 'weight'] => 4;

package Tiger;
use Mojo::Base 'Cat';
 
has friend  => sub { Cat->new };
has stripes => 42;
 
package main;
use Mojo::Base -strict;
 
my $mew = Cat->new(name => 'Longcat');
say $mew->age;
say $mew->age(3)->weight(5)->age;
 
my $rawr = Tiger->new(stripes => 38, weight => 250);
say $rawr->tap(sub { $_->friend->name('Tacgnol') })->weight;

PERL
        expected => { 'Cat' => '0', 'Mojo::Base' => '0' },
        what     => 'Mojo::Base synopsis',
    },
    {
        perl_code => <<'PERL',

package Kevin::Command::kevin;
use Mojo::Base 'Mojolicious::Commands';

package Kevin::Command::kevin::jobs;
use Mojo::Base 'Mojolicious::Command';
use Kevin::Commands::Util ();
use Mojo::Util qw(getopt);

package Mojolicious::Plugin::Kevin::Commands;
use Mojo::Base 'Mojolicious::Plugin';

package Kevin::Commands::Util;
use Mojo::Base -strict;

PERL
        expected => {
            'Mojolicious::Command'  => '0',
            'Mojolicious::Commands' => '0',
            'Mojolicious::Plugin'   => '0',
            'Mojo::Base'            => '0',
            'Kevin::Commands::Util' => '0',
            'Mojo::Util'            => '0',
        },
        what => 'Kevin::Commands sample',
    },
    {
        perl_code => 'use Mojo::Base ()',
        expected  => { 'Mojo::Base' => '0' },
        what      => 'use Mojo::Base ()',
    },
    {
        perl_code => q{use Mojo::Base 'SomeBaseClass'},
        expected  => { 'Mojo::Base' => '0', 'SomeBaseClass' => '0' },
        what      => q{use Mojo::Base 'SomeBaseClass'},
    },
    {
        perl_code => q{use Mojo::Base "SomeBaseClass"},
        expected  => { 'Mojo::Base' => '0', 'SomeBaseClass' => '0' },
        what      => q{use Mojo::Base "SomeBaseClass"},
    },

    # TODO use Mojo::Base ('SomeBaseClass')
);

for my $t (@TESTS) {
    my $perl_code = $t->{perl_code};
    my $expected  = $t->{expected};
    my $name      = $t->{what} . " - right prereqs";

    my $scanner = Perl::PrereqScanner->new( { extra_scanners => ['Mojo'] } );
    my $prereqs = $scanner->scan_string($perl_code)->as_string_hash;
    is_deeply( $prereqs, $expected, $name );
}

done_testing;
