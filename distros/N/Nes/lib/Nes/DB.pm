#!/bin/perl

# -----------------------------------------------------------------------------
#
#  Nes by Skriptke
#  Copyright 2009 - 2010 Enrique Castañón 
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
#  DB.pm
#
# -----------------------------------------------------------------------------

{
  package Nes::DB;

  use DBI;
  
  sub new {
    my $class = shift;
    my ($name, $user, $pass, $drv, $host, $port) = @_;
    $self = bless {}, $class;
    
    $self->{'name'} = $name;
    $self->{'user'} = $user;
    $self->{'pass'} = $pass;
    $self->{'drv'}  = $drv;
    $self->{'host'} = $host;
    $self->{'port'} = $port;
    $self->{'data_source'} = "DBI:$self->{'drv'}:database=$self->{'name'};host=$self->{'host'};port=$self->{'port'}";

    $self->{'dbh'}     = 0;
    $self->{'rows'}    = 0;
    $self->{'errstr'}  = '';
    $self->{'error'}   = '';
    $self->{'filas'}   = 0;
    
    $self->open();
  
    return $self;
  }
  
  sub open {
    my $self = shift;
  
    if($self->{'dbh'}) { # la base ya esta abierta, salir
      return 1;
    }    
    
    eval {
      $self->{'dbh'} = DBI->connect($self->{'data_source'},$self->{'user'},$self->{'pass'});
      $self->{'errstr'} = $DBI::errstr;
      $self->{'error'}  = $DBI::errstr;
    };
  
    return $self->{'dbh'};
    
  }
  
  sub close {
    my $self = shift;
  
    if(!$self->{'dbh'}) { # la base ya esta cerrada, salir.
      return 0;
    } 

    eval {
      $self->{'dbh'}->disconnect;
#      $self->{'errstr'} = $DBI::errstr;
      $self->{'error'}  .= $DBI::errstr;
    };  

    $self->{'dbh'} = 0;
    
    return 1;
  }
  
  sub isopen {
    my $self = shift;
  
    return $self->{'dbh'};
  }
  
  sub create {
    my $self = shift;
    local ($tabla,$campos) = @_;
    my $resultado;
    
    if($self->{existe}) { # la tabla existe.
      return $self->{'error'} = "No se puede crear la tabla, ya existe"; 
    }
    
    $resultado = $self->{'dbh'}->do("create table $tabla ($campos);") || return $self->{'error'} = $DBI::errstr;
    $self->{'rows'} = $self->{'dbh'}->rows;
    $self->{'errstr'} = $self->{'dbh'}->errstr;
  
    return $resultado;
  }
  
  sub sen_select {
    my $self = shift;
    my ($SQL_sentencia) = @_;
    my $resultado   = '';
    my @encontrados = ();
  
    $self->open();
  
    my $sth = '';
    eval {
      $sth = $self->{'dbh'}->prepare( $SQL_sentencia );
      $self->{'filas'} = $sth->execute();
      $self->{'rows'} = $self->{'dbh'}->rows;
      $self->{'errstr'} = $self->{'dbh'}->errstr;
    };   
    
    return if $DBI::errstr;
    while( $resultado = $sth->fetchrow_hashref ) {
      push(@encontrados, $resultado);
    }
    $sth->finish(); 
    $self->close();    
    
    return @encontrados;
  }
  
  sub sen_select_no_close {
    my $self = shift;
    my ($SQL_sentencia) = @_;
    my $resultado   = '';
    my @encontrados = ();
  
    $self->open();
  
    my $sth = '';
    eval {
      $sth = $self->{'dbh'}->prepare( $SQL_sentencia );
      $self->{'filas'} = $sth->execute();
      $self->{'rows'} = $self->{'dbh'}->rows;
      $self->{'errstr'} = $self->{'dbh'}->errstr;
    };

    return if $DBI::errstr;

    while( $resultado = $sth->fetchrow_hashref ) {
      push(@encontrados, $resultado);
    }
    $sth->finish();

    return @encontrados;
  }
  
  sub sen_no_select {
    my $self = shift;
    my ($SQL_sentencia) = @_;
    my $resultado;
    
    $self->open();
    
    eval {
      $resultado = $self->{'dbh'}->do( $SQL_sentencia );
      $self->{'rows'} = $self->{'dbh'}->rows;
      $self->{'errstr'} = $self->{'dbh'}->errstr;
      $self->{'error'} = $DBI::errstr;
    };      
    
    $self->close();
  
    return $resultado;
  }

  sub sen_no_select_no_close {
    my $self = shift;
    my ($SQL_sentencia) = @_;
    my $resultado;
    
    $self->open();
    
    eval {
      $resultado = $self->{'dbh'}->do( $SQL_sentencia );
      $self->{'rows'} = $self->{'dbh'}->rows;
      $self->{'errstr'} = $self->{'dbh'}->errstr;
      $self->{'error'} = $DBI::errstr;
    };     
      
    return $resultado;
  }

}

1;