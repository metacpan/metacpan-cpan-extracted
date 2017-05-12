#!/usr/bin/env perl
use strict;
use warnings;

BEGIN { $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 }

use Test::More tests => 11;

# testing code starts here
use Mojolicious::Lite;
use Test::Mojo;
use Data::Dumper;

plugin 'CountryDropDown', { language => 'de' };

app->log->level('debug');

my $test1 = { language => 'de', html_attr => { name => 'country' }, codeset => 'LOCALE_CODE_ALPHA_2', };

my $test2 = { language  => 'de',
              html_attr => { name => 'country', class => 'shiny', 'data-xyz' => 'abc' },
              codeset   => 'LOCALE_CODE_ALPHA_2',
};

my $test3
    = { html_attr => { name => 'country', class => 'shiny', 'data-xyz' => 'abc' }, codeset => 'LOCALE_CODE_ALPHA_2', };

my $test4 = { html_attr => { name => 'country', class => 'shiny', 'data-xyz' => 'abc' },
              codeset   => 'LOCALE_CODE_ALPHA_2',
              prefer    => [qw/ GB US /],
};

my $test5 = { html_attr => { name => 'country', class => 'shiny', 'data-xyz' => 'abc' },
              codeset   => 'LOCALE_CODE_ALPHA_2',
              prefer    => [qw/ GB US /],
              exclude   => [qw/ DE AT CH /],
};

my $test6 = {
    html_attr => { name => 'country', class => 'shiny', 'data-xyz' => 'abc' },
    codeset   => 'LOCALE_CODE_ALPHA_3',
    names => { DEU => 'Krauts', FRA => 'Frogs' },
};

my $test7 = { html_attr => { name => 'country' }, codeset => 'LOCALE_CODE_ALPHA_2', };

my $test10 = { language => 'de', html_attr => { name => 'country' }, codeset => 'LOCALE_CODE_ALPHA_2', select => 'FOOBAR' };

get '/conf' => sub {
    my $self = shift;

    my $conf1 = $self->csf_conf();
    is_deeply( $conf1, $test1, "Default configuration plus init" );

    my $conf2 = $self->csf_conf( { html_attr => { class => 'shiny', 'data-xyz' => 'abc' }, } );
    is_deeply( $conf2, $test2, "Modified only html attr" );

    my $conf3 = $self->csf_conf( { language => undef } );
    is_deeply( $conf3, $test3, "Removed language" );

    my $conf4 = $self->csf_conf( { prefer => [ "Gb", "us", ] } );
    is_deeply( $conf4, $test4, "Added preferred countries" );

    my $conf5 = $self->csf_conf( { exclude => [ 'de', 'AT', 'cH' ] } );
    is_deeply( $conf5, $test5, "Excluded some countries" );

    my $conf6 = $self->csf_conf(
            { prefer => undef, exclude => undef, names => { DEU => 'Krauts', FRA => 'Frogs' }, codeset => 'ALPHA_3' } );
    is_deeply( $conf6, $test6, "Remove, change, added names" );

    my $conf7 = $self->csf_conf( {} );
    is_deeply( $conf7, $test7, "Reset configuration to default" );

	my $conf8 = $self->csf_conf( { html_attr => { name => 'country' }, codeset => 'LOCALE_CODE_FOOBAR', } );
	is_deeply( $conf8, $test7, "Unknown codeset is ignored" );

	my $conf9 = $self->csf_conf( { language  => 'FOOBAR', } );
	is_deeply( $conf9, $test7, "Unknown language is ignored" );

	my $conf10 = $self->csf_conf( { language  => 'de', select => 'fooBar', } );
	is_deeply( $conf10, $test10, "Unknown pre-selected country is accepted" );

    $self->render( text => 'test' );
};

my $t = Test::Mojo->new;

$t->get_ok('/conf');

