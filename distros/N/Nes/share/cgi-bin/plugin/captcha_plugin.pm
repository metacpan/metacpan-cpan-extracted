
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
#  captcha_plugin.pm
#
# -----------------------------------------------------------------------------

# despues de tanto parche, esto hay que volver a escribirlo.
package captcha_plugin;

use strict;

my $captcha;

sub replace_captcha {
  my ( $out, @param ) = @_;
  my ( $name, $type, $digits, $noise, $size, $sig, $spc, $expire, $attempts ) = @param;

  $type = 'ascii' if !$type;
  $captcha = nes_captcha->new( $name, $type, $digits, $noise, $size, $sig, $spc, $expire, $attempts );
  $captcha->create;

  return $out;
}

sub replace_captcha_code {
  my ( $out, @param ) = @_;

  return $captcha->out();   
}

sub verify {
  my ( $name, $type, $expire, $attempts ) = @_;

  $captcha = nes_captcha->new( $name,$type,'','','','','', $expire, $attempts );
  $captcha->verify();
  $captcha->{'tmp'}->clear() if $captcha->{'is_ok'};
     
}


{

  package nes_captcha_plugin;
  use vars qw(@ISA);
  @ISA = qw( nes_interpret );

  sub new {
    my $class = shift;
    my ($out) = @_;
    my $self  = $class->SUPER::new($out);
    
    foreach my $tag ( keys %{ $self->{'container'}->{'content_obj'}->{'tags'} } ) {
      $self->{'tags'}{$tag} = $self->{'container'}->{'content_obj'}->{'tags'}{$tag};
    }        

    $self->{'plugin'} = nes_plugin->new( 'captcha_plugin', 'captcha_plugin', $self );

    $self->{'tag_captcha'}     = 'captcha';
    $self->{'tag_captcha_out'} = 'captcha_code';
    $self->{'clear_out'}       = 0;

    return $self;
  }

  sub replace_block {
    my $self = shift;
    my ( $block, $space1, $space2 ) = @_;
    my ( $tag, $params, $code ) = $block =~ /$self->{'block_plugin'}/;
    my $out;

    if ( $tag && $tag =~ /^$self->{'tag_captcha'}$/ ) {

      $out = $self->replace_captcha( $code, $self->param_block($params) );

    } else {

      $block =~ s/(^\s*)($self->{'pre_start'})/$1$self->{'tag_start'}/g;
      $block =~ s/($self->{'pre_end'})(\s*$)/$self->{'tag_end'}$2/g;

      return $block;
    }

    $out .= $space1;
    return $out;
  }

  sub replace_captcha {
    my $self = shift;
    my ( $out, @param ) = @_;
    my ( $name, $type, $digits, $noise, $size, $sig, $spc, $expire, $attempts ) = @param;

    return '' if $self->{'clear_out'};

    $type = 'ascii' if !$type;
    $self->{'captcha'}{$name} = nes_captcha->new( $name, $type, $digits, $noise, $size, $sig, $spc, $expire, $attempts );
    $self->{'captcha'}{$name}->create;

    my $captcha_code = $self->{'captcha'}{$name}->out();
    $out =~ s/$self->{'pre_start'}\s*$self->{'tag_plugin'}\s*$self->{'tag_captcha_out'}\s*(.+?)\s*$self->{'pre_end'}/$captcha_code/gi;

    return $out;
  }

}

{

  package nes_captcha;
  use vars qw(@ISA);
  @ISA = qw( Nes );

  sub new {
    my $class = shift;
    my ( $name, $type, $digits, $noise, $size, $sig, $spc, $expire, $attempts ) = @_;
    my $self = $class->SUPER::new();

    foreach my $tag ( keys %{ $self->{'container'}->{'content_obj'}->{'tags'} } ) {
      $self->{'tags'}{$tag} = $self->{'container'}->{'content_obj'}->{'tags'}{$tag};
    }    
    
    $self->{'cookie_name'} = 'cp_'.$name;

    $self->{'plugin'} = nes_plugin->get_obj('captcha_plugin');

    if ($self->{'plugin'} =~ /nes_plugin/) {
      # antiguo método, obsoleto
      $self->{'plugin'}->add_obj( $name, $self );
    }
    # nevo método
    $self->{'plugin'} = $self->{'register'}->add_obj('captcha_plugin', $name, $self);

    $attempts = $self->{'CFG'}{'captcha_plugin_max_attempts'} if !$attempts;
    ($self->{'max_attempts'}, $self->{'max_time'})  = split ('/',$attempts);

    $self->{'expire_tmp'}    = utl::expires_time( $self->{'CFG'}{'captcha_plugin_expire_attempts'} );
    $self->{'expire'}        = $expire || $self->{'CFG'}{'captcha_plugin_expire'};
    $self->{'captcha_start'} = $self->{'query'}->get( $self->{'CFG'}{'captcha_plugin_start'} . '_' . $name ) || '';
    $self->{'class'}         = 'nes_captcha_' . $type;
    $self->{'captcha'}       = $self->{'class'}->new( $name, $digits, $noise, $size, $sig, $spc );
    $self->{'captcha_name'}  = $name || '';
    $self->{'tmp'}           = nes_tmp->new($self->{'CFG'}{'captcha_plugin_suffix'},$self->{'captcha_name'});

    $self->{'is_ok'} = 0;
    $self->load_captcha();  

    $self->get_attempts;

    return $self;
  }
  
  sub create {
    my $self = shift;

    $self->{'captcha'}->create();
    $self->{'key_ok'} = $self->{'captcha'}->{'key_ok'};
    $self->save_captcha();    
    $self->{'tmp'}->save(time.':') if $self->{'captcha_start'} eq $self->{'captcha_name'};
    $self->get_attempts;
    
  }  
  
  sub get_attempts {
    my $self = shift;

    my @data = $self->{'tmp'}->load();
    my ( $first_attempt, $used_key ) = split( ':', $data[0] );
    my $attempts = $#data;
    $first_attempt =~ s/:.*//;
    $self->{'used_key'} = $used_key;

    if ( $first_attempt ) {
      if ( time - $first_attempt > $self->{'expire_tmp'} ) {
        $self->{'tmp'}->clear();
        $attempts = -1;
        $first_attempt = time;
        $self->{'used_key'} = '';
      }
    }
 
    if ( $attempts > $self->{'max_attempts'} ) {
      $self->{'tmp'}->clear() if time - $first_attempt > ( $self->{'max_time'} * 60 );
    }
    
    $self->{'attempts'} = $attempts + 1;
    $self->{'attempts'} = 0 if $attempts < 0;
    $self->{'plugin'}->add_env( 'captcha_plugin', $self->{'captcha_name'}, 'attempts', $self->{'attempts'} );   

    return;
  }  

  sub verify {
    my $self = shift;

    $self->{'fatal_error'} = 0;

    # no se ha terminado de llenar el formulario
    $self->{'last_error'} = 'no captcha start';
    $self->{'plugin'}->add_fatal_error( 'captcha_plugin', $self->{'captcha_name'}, 0 );
    $self->{'plugin'}->add_last_error( 'captcha_plugin', $self->{'captcha_name'}, 'no captcha start' );
    return 0 if $self->{'captcha_start'} ne $self->{'captcha_name'};

    return $self->is_ok( $self->{'query'}->get( $self->{'captcha_name'} ) );
  }

  sub is_ok {
    my $self = shift;
    my ($key_ok) = @_;
    
    $self->{'is_ok'} = 0;
    
    $self->{'last_error'}  = 3;
    $self->{'fatal_error'} = 3;
    $self->{'plugin'}->add_last_error( 'captcha_plugin', $self->{'captcha_name'}, "max attempts, wait $self->{'max_time'} minutes" );
    $self->{'plugin'}->add_fatal_error( 'captcha_plugin', $self->{'captcha_name'}, 3 );
    return 0 if $self->{'attempts'} > $self->{'max_attempts'};    
    
    my $expire = $self->{'expire'};
    $self->{'last_error'}  = 1;
    $self->{'fatal_error'} = 1;
    $self->{'plugin'}->add_last_error( 'captcha_plugin', $self->{'captcha_name'}, 'expire' );
    $self->{'plugin'}->add_fatal_error( 'captcha_plugin', $self->{'captcha_name'}, 1 );
    return (0) if ( $self->{'time'} + utl::expires_time($expire) ) < time;

    $self->{'last_error'}  = 2;
    $self->{'fatal_error'} = 2;
    $self->{'plugin'}->add_last_error( 'captcha_plugin', $self->{'captcha_name'}, 'no key' );
    $self->{'plugin'}->add_fatal_error( 'captcha_plugin', $self->{'captcha_name'}, 2 );
    return (0) if !$key_ok;
    
    # impide que guarden una cookie válida para volver a usarla      
    $self->{'last_error'}  = 4;
    $self->{'fatal_error'} = 4;
    $self->{'plugin'}->add_last_error( 'captcha_plugin', $self->{'captcha_name'}, 'already been used' );
    $self->{'plugin'}->add_fatal_error( 'captcha_plugin', $self->{'captcha_name'}, 4 );
    return (0) if $self->{'used_key'} eq $key_ok;    

    if ( $key_ok eq $self->{'load_key_ok'} ) {
      $self->{'last_error'}  = 0;
      $self->{'fatal_error'} = 0;
      $self->{'plugin'}->add_last_error( 'captcha_plugin', $self->{'captcha_name'}, '' );
      $self->{'plugin'}->add_fatal_error( 'captcha_plugin', $self->{'captcha_name'}, 0 );
      $self->{'plugin'}->add_env( 'captcha_plugin', $self->{'captcha_name'}, 'is_ok', 1 );
      $self->{'is_ok'} = 1;
      my $data = time.':'.$key_ok;
      $self->{'tmp'}->clear($data);
      $self->get_attempts;
      return (1);
    }

    $self->{'last_error'}  = 5;
    $self->{'fatal_error'} = 5;
    $self->{'plugin'}->add_last_error( 'captcha_plugin', $self->{'captcha_name'}, 'incorrect key' );
    $self->{'plugin'}->add_fatal_error( 'captcha_plugin', $self->{'captcha_name'}, 5 );
    $self->{'is_ok'} = 0;
    return (0);
  }

  sub save_captcha {
    my $self = shift;

    my $key_ok  = $self->{'key_ok'};
    my $refuse1 = $self->get_key( 20 + int rand 10 );
    $refuse1 =~ s/\://g;
    my $refuse2 = $self->get_key( 20 + int rand 10 );
    $refuse2 =~ s/\://g;
    my $value = $refuse1 . ':' . $key_ok . ':' . time . ':' . $refuse2;

    my $expire = $self->{'expire'};

    $self->{'cookies'}->create( $self->{'cookie_name'}, $value, $expire );
    
    return;
  }

  sub load_captcha {
    my $self = shift;

    $self->{'cookie'} = $self->{'cookies'}->get( $self->{'cookie_name'} );

    my $refuse;
    ( $refuse, $self->{'load_key_ok'}, $self->{'time'}, $refuse ) = split( ':', $self->{'cookie'} );

    return;
  }

  sub out {
    my $self = shift;

    return $self->{'captcha'}->out;
  }
  
}

{

  package nes_captcha_ascii;
  use vars qw(@ISA);
  @ISA = qw( Nes );

  sub new {
    my $class = shift;
    my ( $name, $digits, $noise_level, $size, $sig_char, $space_char ) = @_;
    my $self = $class->SUPER::new();

    $self->{'captcha_name'} = $name;

    my @sigs = ( '0', 'X', '9', '@', '&#9617;', '&#9619;', '&#9689;' );
    my @spaces = ( ' ', '·', '.', ',', ' ', '&#732;', '&#39;', '&nbsp;', '&#8249;', '&nbsp;' );

    $noise_level = 9 if $noise_level > 9;
    $self->{'noise_level'} = $self->{'CFG'}{'captcha_plugin_noise'} || 1;

    # $noise_level puede ser 0
    $self->{'noise_level'} = $noise_level if defined $noise_level;

    $self->{'digits'}     = $digits     || $self->{'CFG'}{'captcha_plugin_digits'} || ( 5 + int rand 3 );
    $self->{'size'}       = $size       || $self->{'CFG'}{'captcha_plugin_size'}   || 2;
    $self->{'sig_char'}   = $sig_char   || $self->{'CFG'}{'captcha_plugin_sig'}    || ( $sigs[ int rand $#sigs + 1 ] );
    $self->{'space_char'} = $space_char || $self->{'CFG'}{'captcha_plugin_spc'}    || ( $spaces[ int rand $#spaces + 1 ] );

    return ($self);
  }

  sub create {
    my $self = shift;

    my $fonts = nes_captcha_fonts->new();
    my @type  = @{ $fonts->{'ceros'}{'font'} };
    my $sig   = $fonts->{'ceros'}{'sig'};

    my $nums;
    for ( 1 .. $self->{'digits'} ) {
      $nums .= int rand 10;
    }

    $self->{'key_ok'} = $nums;

    my @lines;
    my $noise;
    foreach my $num ( split( '', $nums ) ) {
      my @char  = @{ $type[$num] };
      my $n1    = int rand 9;
      my $space = ' ' x 1;
      $space = ' ' x ( int rand 4 ) if $self->{'noise_level'};
      unshift( @char, pop(@char) ) if int rand 2;
      for ( my $i = 0 ; $i < @char ; $i++ ) {
        $lines[$i] .= $space . $char[$i] . $space;
      }
    }

    # add noise
    if ( $self->{'noise_level'} ) {

      # corta una columna, dificulta que se detecte el comienzo de cada número
      my $colums = ',';
      for ( my $c = 0 ; $c < length( $lines[0] ) ; $c++ ) {
        if ( !int rand 9 - $self->{'noise_level'} ) {
          $colums .= $c . ',';
          $c = $c + 4;
        }
      }
      foreach my $line (@lines) {
        my $colum = int rand length($line);
        for ( my $c = 0 ; $c < length($line) ; $c++ ) {
          for ( my $level = 0 ; $level < $self->{'noise_level'} && $level < 10 ; $level++ ) {
            substr( $line, $c, 1, ' ' ) if $colums =~ /,$c,/;
            substr( $line, $c, 1, $sig ) if $colums =~ /,$c,/ && !int rand 5;
            substr( $line, $c, 1, $sig ) if !int rand 50;
            substr( $line, $c, 1, ' ' )  if !int rand 50;
          }
        }
      }
    }

    my $line_out;
    foreach my $line (@lines) {
      $line =~ s/ /$self->{'space_char'}/gi;
      $line =~ s/$sig/$self->{'sig_char'}/gi;
      $line .= "\n";
      $line_out .= $line;
    }

    my $captcha_form_fstart = '<input type="hidden" name=":-:name:-:"  value=":-:value:-:" />';
    $captcha_form_fstart =~ s/:-:name:-:/$self->{'CFG'}{'captcha_plugin_start'}_$self->{'captcha_name'}/;
    $captcha_form_fstart =~ s/:-:value:-:/$self->{'captcha_name'}/;
    $line_out .= "\n" . $captcha_form_fstart;
    if ( $self->{'size'} ne 'none' ) {
      $line_out = '<pre style="font-size:' . $self->{'size'} . 'px; line-height:1.0;">' . $line_out . '<br></pre>';
    }

    $self->{'out'} = $line_out;

    return;
  }

  sub out {
    my $self = shift;

    return $self->{'out'};
  }

}

{

  package nes_captcha_fonts;
  use vars qw(@ISA);
  @ISA = qw( nes );

  sub new {
    my $class = shift;
    my $self = bless {}, $class;

    # con el caracter que esta escrita la fuente
    $self->{'ceros'}{'sig'} = '0';
    @{ $self->{'ceros'}{'font'} } = (
      [
        '               ',
        ' 0000000000000 ',
        '000000000000000',
        '0000       0000',
        '0000       0000',
        '0000       0000',
        '0000       0000',
        '0000       0000',
        '0000       0000',
        '0000       0000',
        '0000       0000',
        '000000000000000',
        ' 0000000000000 ',
        '               ',
        '               ',
      ],
      [
        '               ',
        '    000000     ',
        '   0000000     ',
        '      0000     ',
        '      0000     ',
        '      0000     ',
        '      0000     ',
        '      0000     ',
        '      0000     ',
        '      0000     ',
        '      0000     ',
        '000000000000000',
        ' 0000000000000 ',
        ,
        '               ',
        '               ',
      ],
      [
        '               ',
        ' 0000000000000 ',
        '000000000000000',
        '           0000',
        '           0000',
        '           0000',
        ' 00000000000000',
        '00000000000000 ',
        '0000           ',
        '0000           ',
        '0000           ',
        '000000000000000',
        ' 0000000000000 ',
        '               ',
        '               ',
      ],
      [
        '               ',
        ' 0000000000000 ',
        '000000000000000',
        '           0000',
        '           0000',
        '           0000',
        ' 00000000000000',
        ' 00000000000000',
        '           0000',
        '           0000',
        '           0000',
        '000000000000000',
        ' 0000000000000 ',
        '               ',
        '               ',
      ],
      [
        '               ',
        ' 000       000 ',
        '0000       0000',
        '0000       0000',
        '0000       0000',
        '0000       0000',
        '000000000000000',
        ' 00000000000000',
        '           0000',
        '           0000',
        '           0000',
        '           0000',
        '           000 ',
        '               ',
        '               ',
      ],
      [
        '               ',
        ' 0000000000000 ',
        '000000000000000',
        '0000           ',
        '0000           ',
        '0000           ',
        '00000000000000 ',
        ' 00000000000000',
        '           0000',
        '           0000',
        '           0000',
        '000000000000000',
        ' 0000000000000 ',
        '               ',
        '               ',
      ],
      [
        '               ',
        ' 0000000000000 ',
        '000000000000000',
        '0000           ',
        '0000           ',
        '0000           ',
        '00000000000000 ',
        '000000000000000',
        '0000       0000',
        '0000       0000',
        '0000       0000',
        '000000000000000',
        ' 0000000000000 ',
        '               ',
        '               ',
      ],
      [
        '               ',
        ' 0000000000000 ',
        '000000000000000',
        '           0000',
        '           0000',
        '           0000',
        '           0000',
        '           0000',
        '           0000',
        '           0000',
        '           0000',
        '           0000',
        '           000 ',
        '               ',
        '               ',
      ],
      [
        '               ',
        ' 0000000000000 ',
        '000000000000000',
        '0000       0000',
        '0000       0000',
        '0000       0000',
        '000000000000000',
        '000000000000000',
        '0000       0000',
        '0000       0000',
        '0000       0000',
        '000000000000000',
        ' 0000000000000 ',
        '               ',
        '               ',
      ],
      [
        '               ',
        ' 0000000000000 ',
        '000000000000000',
        '0000       0000',
        '0000       0000',
        '0000       0000',
        '000000000000000',
        ' 00000000000000',
        '           0000',
        '           0000',
        '           0000',
        '           0000',
        '           000 ',
        '               ',
        '               ',
      ]
    );

    return $self;
  }

}

1;
