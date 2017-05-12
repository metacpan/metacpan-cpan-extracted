#!/usr/bin/perl

# -----------------------------------------------------------------------------
#
#  Nes by Skriptke
#  Copyright 2009 - 2010 Enrique F. Castañón
#  Licensed under the GNU GPL.
#
#  Sample:
#  http://nes.sourceforge.net/
#
#  Repository:
#  http://github.com/Skriptke/nes
#
#  CPAN:
#  http://search.cpan.org/perldoc?Nes
# 
#  Version 1.00
#
#  lib.cgi
#
# ------------------------------------------------------------------------------

use Nes;
my $nes = Nes::Singleton->new();
my $config = $nes->{'CFG'};

# obtiene el último artículo publicado
sub last_article {

  my @articles = latest(1);

  return $articles[0]->{'name'};
}

# obtiene $num últimos artículos publicados, ordenados por fecha
sub latest {
  my ( $num, $dirname ) = @_;
  $dirname = $config->{'miniblog_item_dir'} || './items' if !$dirname;
  $num     = 1000      if $num <= 0;    # nunca está de más poner límites
  my @articles;

  opendir( DIR, $dirname );
  my @files = sort { -M "$dirname/$a" <=> -M "$dirname/$b" } readdir(DIR);
  closedir(DIR);

  my $count = 0;
  foreach my $filename (@files) {
    my %this;
    $filename =~ s/(.*)\.nhtml$/$1/ || next;
    last if $count++ >= $num;
    $this{'name'} = $filename;
    push( @articles, \%this );
  }

  return @articles;
}

sub check_user_login {
  my $user = shift;
  my $pass = shift;
  
  return 0 if !$user || !$pass;
  
  my $query = qq~SELECT name  
                 FROM  `users`
                 WHERE ( name = \'$user\') AND (password = PASSWORD(\'$pass\'))
                 LIMIT 0,1;~;  
  
  use Nes::DB;
  my $config    = $nes->{'CFG'};
  my $db_name   = $config->{'DB_base'};
  my $db_user   = $config->{'DB_user'};
  my $db_pass   = $config->{'DB_pass'};
  my $db_driver = $config->{'DB_driver'};
  my $db_host   = $config->{'DB_host'};
  my $db_port   = $config->{'DB_port'};
  my $base      = Nes::DB->new( $db_name, $db_user, $db_pass, $db_driver, $db_host, $db_port );
  my @result = $base->sen_select($query);
  
  my $user_id = $result[0]->{'name'};
     $user_id = 0 if $user_id !~ /^$user$/;
  
  return $user_id;
}

sub fecha {

  my $ampm = "AM";
  my ( $minuto, $hora, $dia, $mes, $anio ) = ( localtime(time) )[ 1, 2, 3, 4, 5 ];
  $mes++;
  $ampm   = "PM"          if ( $hora > 11 );
  $hora   = $hora - 12    if ( $hora > 12 );
  $minuto = "0" . $minuto if ( length($minuto) == 1 );
  $anio += 1900;

  return ("$mes/$dia/$anio $hora:$minuto $ampm");
}

# importante que devuelvan 1 para evitar un error "couldn't run"
1;
