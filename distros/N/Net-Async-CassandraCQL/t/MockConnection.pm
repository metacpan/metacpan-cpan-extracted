package t::MockConnection;

use strict;
use warnings;
use base qw( Net::Async::CassandraCQL::Connection );

use Socket qw( inet_aton );

sub new
{
   my $class = shift;
   my ( $nodeid ) = @_;
   my $self = $class->SUPER::new;

   $self->{nodeid} = $nodeid;
   $self->{pending_queries} = [];
   $self->{pending_prepares} = [];

   return $self;
}

# Mocking API
sub next_query
{
   my $self = shift;
   return shift @{$self->{pending_queries}};
}

sub next_prepare
{
   my $self = shift;
   return shift @{$self->{pending_prepares}};
}

sub is_registered
{
   my $self = shift;
   return $self->{is_registered};
}

sub send_nodelist
{
   my $self = shift;
   my %args = @_;

   my $local = $args{local};
   my $peers = $args{peers};

   while( my $q = $self->next_query ) {
      if( $q->[1] eq "SELECT data_center, rack FROM system.local" ) {
         $q->[2]->done( rows =>
            Protocol::CassandraCQL::Result->new(
               columns => [
                  [ system => local => data_center => "VARCHAR" ],
                  [ system => local => rack        => "VARCHAR" ],
               ],
               rows => [
                  [ $local->{dc}, $local->{rack} ],
               ],
            )
         );
      }
      elsif( $q->[1] eq "SELECT peer, data_center, rack FROM system.peers" ) {
         $q->[2]->done( rows =>
            Protocol::CassandraCQL::Result->new(
               columns => [
                  [ system => peers => peer        => "VARCHAR" ],
                  [ system => peers => data_center => "VARCHAR" ],
                  [ system => peers => rack        => "VARCHAR" ],
               ],
               rows => [ map { my $peer = $peers->{$_};
                               [ inet_aton( $_ ), $peer->{dc}, $peer->{rack} ] } sort keys %$peers
                       ],
            ),
         );
      }
      else {
         die "Unexpected initial query $q->[1]";
      }
   }
}

# Connection API
sub query
{
   my $self = shift;
   my ( $cql ) = @_;
   push @{$self->{pending_queries}}, [ $self->nodeid, $cql, my $f = Future->new ];
   return $f;
}

sub prepare
{
   my $self = shift;
   my ( $cql ) = @_;
   push @{$self->{pending_prepares}}, [ $self->nodeid, $cql, my $f = Future->new ];
   return $f;
}

sub register
{
   my $self = shift;
   $self->{is_registered} = 1;
   return Future->new->done;
}

0x55AA;
