#!/usr/bin/perl

use strict;
use warnings;

use base qw( Parser::MGC );

my %unescape = (
   q(') => q('),
   q(") => q("),
   "\\" => "\\",
   n    => "\n",
   r    => "\r",
);
my $escapes = join "|", map quotemeta, keys %unescape;
$escapes = qr/$escapes/;

sub parse
{
   my $self = shift;

   $self->any_of(
      # qq() strings
      sub { $self->scope_of( q("), sub { $self->parse_qq_body( q(") ) }, q(") ) },
      sub { $self->expect( 'qq' );
            my $start = $self->expect( qr/./ );
            $self->commit;
            if( ( my $stop = $start ) =~ tr/([<{/)]>}/ ) {
               $self->scope_of( undef, sub { $self->parse_qq_body( $start, $stop ) }, $stop )
            }
            else {
               $self->scope_of( undef, sub { $self->parse_qq_body( $start ) }, $stop )
            }
      },

      # q() strings
      sub { $self->scope_of( q('), sub { $self->parse_q_body( q(') ) },  q(') ) },
      sub { $self->expect( 'q' );
            my $start = $self->expect( qr/./ );
            $self->commit;
            if( ( my $stop = $start ) =~ tr/([<{/)]>}/ ) {
               $self->scope_of( undef, sub { $self->parse_q_body( $start, $stop ) }, $stop )
            }
            else {
               $self->scope_of( undef, sub { $self->parse_q_body( $start ) }, $stop )
            }
      },
   );
}

sub parse_q_body
{
   my $self = shift;
   my ( $start, $stop ) = @_;

   my @bodies = (
      sub { $self->expect( "\\" );
            $self->commit;
            $self->expect( qr/['"\\]/ ) },
      sub { $self->substring_before( qr/[\\\Q$start\E]/ ) },
   );

   $stop and unshift @bodies,
      sub { $self->expect( $start );
            $self->commit;
            my $inner;
            $self->scope_of( undef, sub { $inner = $self->parse_q_body( $start, $stop ) }, $stop );
            "$start$inner$stop" };

   my $parts = $self->sequence_of( sub { $self->any_of( @bodies ) } );
   return join "", @$parts;
}

sub parse_qq_body
{
   my $self = shift;
   my ( $start, $stop ) = @_;

   my @parts;

   my @bodies = (
      sub { $self->expect( "\\" );
            $self->commit;
            push @parts, $self->one_of(
               sub { $unescape{ $self->expect( $escapes ) } },
               sub { $self->expect( "x" ); chr oct( "0x" . $self->expect( qr/[0-9A-Fa-f]+/ ) ) },
               sub { chr oct "0" . $self->expect( qr/[0-7]+/ ) },
            ); },
      sub { $self->expect( '$' );
            push @parts, [ interpolate => $self->token_ident ] }, # TODO: This isn't very accurate
      sub { $self->substring_before( qr/[\\\$\Q$start\E]/ ) },
   );

   $stop and unshift @bodies,
      sub { $self->expect( $start );
            $self->commit;
            my $inner;
            $self->scope_of( undef, sub { $inner = $self->parse_qq_body( $start, $stop ) }, $stop );
            push @parts, $start, @$inner, $stop; };

   $self->sequence_of( sub { $self->any_of( @bodies ) } );

   # Coaless plain strings
   for( my $i = 1; $i < @parts; $i++ ) {
      last; # debug
      next if ref $parts[$i-1] or ref $parts[$i];

      $parts[$i-1] .= splice @parts, $i, 1;
      redo;
   }

   return \@parts;
}

use Data::Dumper;

if( !caller ) {
   my $parser = __PACKAGE__->new;

   while( defined( my $line = <STDIN> ) ) {
      my $ret = eval { $parser->from_string( $line ) };
      print $@ and next if $@;

      print Dumper( $ret );
   }
}

1;
