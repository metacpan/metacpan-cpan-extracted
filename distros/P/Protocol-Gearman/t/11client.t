#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;
use Protocol::Gearman::Client;

{
   package TestClient;
   use base qw( Protocol::Gearman::Client );

   sub new { bless {}, shift }

   sub new_future { return Future->new }
}

my $client = TestClient->new;

# option_request exceptions
{
   no warnings 'once';
   local *TestClient::send_packet = sub {
      my $self = shift;
      my ( $type, @args ) = @_;

      is( $type,    "OPTION_REQ", '$type for sent packet by ->option_request' );
      is( $args[0], "exceptions", '$args[0] for sent packet by ->option_request' );

      $self->on_OPTION_RES( $args[0] );
   };

   my $f = $client->option_request( "exceptions" );

   is( scalar $f->get, undef, '->option_request->get yields undef' );
}

# submit job
{
   no warnings 'once';
   local *TestClient::send_packet = sub {
      my $self = shift;
      my ( $type, @args ) = @_;

      is( $type,    "SUBMIT_JOB", '$type for sent packet by ->submit_job' );
      is( $args[0], "function",   '$args[0] for sent packet by ->submit_job' );
      is( $args[2], "arg",        '$args[2] for sent packet by ->submit_job' );

      $self->on_JOB_CREATED( "the-handle" );

      $self->on_WORK_STATUS( "the-handle", 0, 1 );
      $self->on_WORK_DATA( "the-handle", "moredata" );
      $self->on_WORK_WARNING( "the-handle", "Ooops?" );
      $self->on_WORK_STATUS( "the-handle", 1, 1 );
      $self->on_WORK_COMPLETE( "the-handle", "result" );
   };

   my $data;
   my @warnings;
   my $status;

   my $result = $client->submit_job(
      func => "function",
      arg  => "arg",
      on_data    => sub { $data .= $_[0] },
      on_warning => sub { push @warnings, $_[0] },
      on_status  => sub { $status = "$_[0]/$_[1]" },
   )->get;

   is( $result, "result", '$result from ->submit_job->get' );
   is( $data, "moredata", 'on_data received data for ->submit_job' );
   is_deeply( \@warnings, [ "Ooops?" ], 'on_warning received warnings for ->submit_job' );
   is( $status, "1/1", 'on_status received status updates for ->submit_job' );
}

# submit job bg
{
   no warnings 'once';
   local *TestClient::send_packet = sub {
      my $self = shift;
      my ( $type, @args ) = @_;

      is( $type, "SUBMIT_JOB_BG", '$type for sent packet by ->submit_job bg' );

      $self->on_JOB_CREATED( "bg-handle" );
   };

   my $f = $client->submit_job(
      func => "function",
      arg  => "arg",
      background => 1,
   );

   is( scalar $f->get, undef, '->submit_job->get returns nothing' );
}

# submit job prio=high
{
   no warnings 'once';
   local *TestClient::send_packet = sub {
      my $self = shift;
      my ( $type, @args ) = @_;

      is( $type, "SUBMIT_JOB_HIGH", '$type for sent packet by ->submit_job prio=high' );

      $self->on_JOB_CREATED( "high-handle" );
      $self->on_WORK_COMPLETE( "high-handle", "fast result" );
   };

   my $result = $client->submit_job(
      func => "function",
      arg  => "arg",
      priority => "high",
   )->get;

   is( $result, "fast result", '$result from ->submit_job(prio=high)->get' );
}

# work failure exception
{
   no warnings 'once';
   local *TestClient::send_packet = sub {
      my $self = shift;

      $self->on_JOB_CREATED( "f-handle" );
      $self->on_WORK_EXCEPTION( "f-handle", "The failure here" );
      $self->on_WORK_FAIL( "f-handle" );
   };

   my $f = $client->submit_job(
      func => "fail",
      arg  => "arg",
   );

   is_deeply( [ $f->failure ],
              [ "Work failed", gearman => "The failure here" ],
              '->failure from ->submit_job on failing job' );
}

done_testing;
