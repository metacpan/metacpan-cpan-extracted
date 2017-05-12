#!/usr/bin/env perl
#
# $Id: Template-Provider-Unicode-Japanese.t,v 1.2 2007/05/04 07:58:53 hironori.yoshida Exp $
#
use strict;
use warnings;
use version; our $VERSION = qv('1.2.1');

use blib;
use Encode::Guess qw(iso-2022-jp shiftjis euc-jp);
use FindBin qw($Bin);
use Template;
use Template::Provider::Unicode::Japanese;
use Test::More tests => 11;

my $provider = Template::Provider::Unicode::Japanese->new(
    { INCLUDE_PATH => "$Bin/data/" } );
isa_ok( $provider, $Template::Config::PROVIDER );

my $template = Template->new( { LOAD_TEMPLATES => [$provider] } );

foreach my $filename (qw(ascii jis sjis ujis utf8)) {
  TODO: {
        local $TODO;    ## no critic
        if ( $filename eq 'ascii' ) {
            $TODO = 'The output is not utf8 though _load returns utf8';
        }
        $template->process( $filename, {}, \my $output );
        is( eval { Encode::Guess->guess($output)->name },
            'utf8', "$filename: utf8 encoding" );
        ok( utf8::is_utf8($output), "$filename: utf8 flag" );
    }
}
