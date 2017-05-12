#!/usr/bin/perl

# -----------------------------------------------------------------------------
#
#  Nes by Skriptke
#  Copyright 2009 - 2010 Enrique F. Castañón Barbero
#  Licensed under the GNU GPL.
#
#  CPAN:
#  http://search.cpan.org/dist/Nes/
#
#  Sample:
#  http://nes.sourceforge.net/
#
#  Repository:
#  http://github.com/Skriptke/nes
# 
#  Version 1.03
#
#  add_user.cgi
#
# -----------------------------------------------------------------------------

use strict;
use Nes;

my $nes      = Nes::Singleton->new();
my $q        = $nes->{'query'}->{'q'};
my $config   = $nes->{'CFG'};
my $action   = $q->{'action'};
my $item     = $q->{'item'};
my $nes_tags = {};

sub register_user {
  my $data = shift;
  my %error_fields;
  my $error = 0;
  
  use Nes::DB;
  my $config    = $nes->{'CFG'};
  my $db_name   = $config->{'DB_base'};
  my $db_user   = $config->{'DB_user'};
  my $db_pass   = $config->{'DB_pass'};
  my $db_driver = $config->{'DB_driver'};
  my $db_host   = $config->{'DB_host'};
  my $db_port   = $config->{'DB_port'};
  my $base      = Nes::DB->new( $db_name, $db_user, $db_pass, $db_driver, $db_host, $db_port );

  my $user_exist = qq~SELECT name  
                      FROM  `users`
                      WHERE ( name = \'$data->{'name'}\' )
                      LIMIT 0,1;~;  
                  
  my @result = $base->sen_select_no_close($user_exist);
  return $base->{'errstr'} if $base->{'errstr'};
  my $user_id = $result[0]->{'name'};

  if ( $data->{'name'} =~ /^$user_id$/i ) {
    $error_fields{'name'} = 'existing';
    $error = 1;
  }
  
  if ( $data->{'password'} =~ /^$data->{'name'}$/i ) {
    $error_fields{'password'} = 'error1';
    $error = 1;
  }
  
  if ( $data->{'password'} =~ /^pass/i      || 
       $data->{'password'} =~ /^1234/i      ||
       $data->{'password'} =~ /^contrase/i  ) {
         
    $error_fields{'password'} = 'error2';
    $error = 1;
  }  
  
  $base->close if $error;
  return \%error_fields if $error;

  my $values = qq~\'$data->{'name'}\',
                    PASSWORD(\'$data->{'password'}\'),
                  \'$data->{'email'}\',
                  \'$data->{'script'}\',
                  \'$data->{'message'}\'~;
                  
  my $sql = qq~INSERT INTO `users` 
                (
                  `name`,
                  `password`,
                  `email`,
                  `script`,
                  `message`
                )
                VALUES 
                (
                  $values
                );~;

  $base->sen_no_select($sql);
  
  return $base->{'errstr'} if $base->{'errstr'};

  return undef;
}



1;
