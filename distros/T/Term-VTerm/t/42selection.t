#!/usr/bin/perl

use v5.14;
use warnings;
use utf8;

use Test::More;

use Term::VTerm qw( :selections );

# Selection manipulation uses base64-encoded data
use constant {
   CONTENT_TEXT   => "text goes here\n",
   CONTENT_BASE64 => "dGV4dCBnb2VzIGhlcmUK",
};

my $vt = Term::VTerm->new( cols => 80, rows => 25 );

my $state = $vt->obtain_state;
$state->reset;

# set selection
{
   my @args;
   $state->set_selection_callbacks(
      on_set => sub { @args = @_; return 1; },
   );

   $vt->input_write( "\e]52;c;" . CONTENT_BASE64 . "\e\\" );

   is( $args[0], SELECTION_CLIPBOARD, 'Set mask is clipboard' );
   is( $args[1], CONTENT_TEXT, 'Set content' );
}

# query selection
{
   my $queried;
   $state->set_selection_callbacks(
      on_query => sub { ( $queried ) = @_; },
   );

   $vt->input_write( "\e]52;c;?\e\\" );

   ok( defined $queried, 'on_query callback invoked' );
   is( $queried, SELECTION_CLIPBOARD, 'Query mask is clipboard' );

   $state->send_selection( SELECTION_CLIPBOARD, CONTENT_TEXT );

   sub unqq { my ( $s ) = @_; $s =~ s/\e/\\e/g; $s }

   my $len = $vt->output_read( my $buf, 128 );

   is( unqq($buf), unqq("\e]52;c;" . CONTENT_BASE64 . "\e\\" ),
      '$buf from ->output_read after ->send_selection' );
}

done_testing;
