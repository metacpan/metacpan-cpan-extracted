#!/usr/bin/perl

use strict;

sub {
   my $env = shift;

   my $input = "";
   while( $env->{"psgi.input"}->read( my $buffer, 8192 ) ) {
      $input .= $buffer;
   }

   return [
      '200',
      [ 'Content-Type' => 'text/plain' ],
      [ "The method was $env->{REQUEST_METHOD}\n",
        "The path was $env->{PATH_INFO}\n",
        "The query string was $env->{QUERY_STRING}\n",
        "The body was ".length($input)." bytes\n\n" . 
        join("", map { "  \$ENV{$_} = $env->{$_}\n" } sort keys %$env) ],
   ];
}
