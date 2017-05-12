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
#  Setting.pm
#
# -----------------------------------------------------------------------------

{

  package Nes::Setting;

  my $instance;

  sub new {
    my $class = shift;
    
    utl::cleanup(\$instance) if $ENV{'MOD_PERL'};
    return $instance if $instance;

    my $level       = utl::get_file_dir();
    my $file_name   = '.nes.cfg';
    my $nes_dir     = $ENV{'SCRIPT_NAME'} || '/cgi-bin/nes';  # default: /cgi-bin/nes
    my $nes_top_dir = $ENV{'SCRIPT_FILENAME'} || ''; 
    $nes_dir        =~ s/\/[^\/]*\.cgi|pl$//;
    $nes_top_dir    =~ s/\/[^\/]*\.cgi|pl$//;

    # en entornos no cgi da el directorio en el que se ejecuta el script
    my $top_dir = utl::get_root_dir();

    my $self = {
      tmp_dir        => '/tmp/nes',
      tmp_suffix     => '.nes_file_temp',
      tmp_clear      => 0, # borrar los archivos temporales de más del tiempo indicado, si es 0 no borra
      top_dir        => $top_dir,              # document root
      nes_top_dir    => $nes_top_dir,          # nes dir install
      nes_dir        => $nes_dir,              # default: /cgi-bin/nes
      plugin_dir     => $nes_dir . '/plugin',
      obj_dir        => $nes_dir . '/obj',
      plugin_top_dir => $nes_top_dir . '/plugin',
      obj_top_dir    => $nes_top_dir . '/obj',     
      obj_form       => $nes_top_dir . '/obj/Nes/form',
      img_dir        => $nes_dir . '/images',
      time_zone      => 'Europe/Madrid',       # * sin implementar *
      locale         => '',                    # es_ES.utf8
      session_prefix => 'NESSESSION',
      private_key    => 'ChangeIt',            # Change private key 
      DB_base        => '',                    # Change in you .nes.cfg             
      DB_user        => '',                    # Change in you .nes.cfg 
      DB_pass        => '',                    # Change in you .nes.cfg 
      DB_driver      => 'mysql',               # Change in you .nes.cfg 
      DB_host        => 'localhost',           # Change in you .nes.cfg 
      DB_port        => '3306',                # Change in you .nes.cfg 
      php_cline      => '/usr/bin/php',
      php_cgi_cline  => '/usr/bin/php-cgi',
      perl_cline     => '/usr/bin/perl',
      python_cline   => '/usr/bin/python',
      shell_cline    => '/bin/bash',            
      max_post       => 512,                   # max kB. for POST
      max_upload     => 2048,                  # max kB. for upload, 0 none
      tmp_upload     => 512,                   # a partir de que kB. se usa un archivo temporal en los upload
      auto_load_plugin_top_first => [ ], # Cargar Plugins al inicio, sólo para la URL
      auto_load_plugin_all_first => [ ], # Cargar Plugins al inicio, para todos los archivos incluidos
      auto_load_plugin_top_last  => [ ], # Cargar Plugins al final, sólo para la URL
      auto_load_plugin_all_last  => [ ], # Cargar Plugins al final, para todos los archivos incluidos
      kletters => [ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z' ],
      knumbers => [ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' ],
      kletnum  => [ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' ],      
    };
    bless $self, $class;
    $instance = $self;
    
    while (1) {
      my $file = $level . '/' . $file_name;
       
      $self->load_cfg($file);
      $level =~ s/[\/\\][^\/\\]*$//;
      last if $level !~ /$self->{'top_dir'}/;
    }

    warn "Change the private_key in $file_name" if $self->{'private_key'} =~ /ChangeIt/i;

    return $self;
  }

  sub load_cfg {
    my $class      = shift;
    my $self       = Nes::Setting::get_obj();
    my ($file) = @_;
    
    if ( -e $file ) {
      open( my $fh, "$file" ) || warn "couldn't open $file";
      while (<$fh>) {
        chomp;
        my $line = $_;
        next if $line =~ /^#/;
        next if $line =~ /^$/;
        my ( $key, $value ) = split( /=\s*/, $line, 2 );
        $key =~ s/\s*(\@|\%|\$)?$//;
        my $eval = $1 || 0;
        $value =~ s/\s*$//;

        # impide que se reescriba 'set';
        next if $key eq 'set';

        # sólo sobreescribe los valores que cambian, los valores de éste
        # directorio priman sobre el nivel superior, se empieza a leer en el
        # nivel del script ya que por ejemplo $self->{'top_dir'} tiene que
        # estar fijado para conocer cual es el nivel superior.
        unless ( $self->{'set'}{$key} ) {
          if ( $eval ) {
            $eval = '@' if ref( $self->{$key} ) eq 'ARRAY';
            $eval = '%' if ref( $self->{$key} ) eq 'HASH';
            $eval = '$' if ref( $self->{$key} ) eq 'SCALAR';
            @{ $self->{$key} } = eval { $value } if $eval eq '@';
            %{ $self->{$key} } = eval { $value } if $eval eq '%';
            $self->{$key}      = eval  "$value"  if $eval eq '$';
          } elsif ( ref( $self->{$key} ) eq 'ARRAY' ) {
            @{ $self->{$key} } = split( /,/, $value );
          } else {
            $self->{$key} = $value;
          }
          $self->{'set'}{$key} = 1;
        }
      }
      close $fh;
    }    
    
    # si por error se deja la ultima barra del directorio
    $self->{'top_dir'}        =~ s/[\/\\]$//;
    $self->{'tmp_dir'}        =~ s/[\/\\]$//;
    $self->{'nes_dir'}        =~ s/[\/\\]$//;
    $self->{'plugin_dir'}     =~ s/[\/\\]$//;
    $self->{'obj_dir'}        =~ s/[\/\\]$//;
    $self->{'plugin_top_dir'} =~ s/[\/\\]$//;
    $self->{'obj_top_dir'}    =~ s/[\/\\]$//;
    $self->{'obj_form'}       =~ s/[\/\\]$//;

    push( @INC, ( $self->{'plugin_top_dir'}, $self->{'obj_top_dir'}, $self->{'obj_form'} )  );
    
    return;
  }

  sub get_obj {
    my $self = $instance || Nes::Setting->new();

    return $self;
  }

}

1;

