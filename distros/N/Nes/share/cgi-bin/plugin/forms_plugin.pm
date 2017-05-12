
# -----------------------------------------------------------------------------
#
#  Nes by Skriptke
#  Copyright 2009 - 2010 Enrique F. Castañón
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
#  forms_plugin.pm
#
# -----------------------------------------------------------------------------


package forms_plugin;

use strict;

{

  package nes_forms_plugin;
  use vars qw(@ISA);
  @ISA = qw( nes_interpret );

  sub new {
    my $class = shift;
    my ($out) = @_;
    my $self  = $class->SUPER::new($out);

    $self->{'plugin'} = nes_plugin->new( 'forms_plugin', 'forms_plugin', $self );
    $self->{'captcha_name'} = '';

    $self->{'tag_form'} = 'form';
    
    foreach my $tag ( keys %{ $self->{'container'}->{'content_obj'}->{'tags'} } ) {
      $self->{'tags'}{$tag} = $self->{'container'}->{'content_obj'}->{'tags'}{$tag};
    }    

    return $self;
  }

  sub replace_block {
    my $self = shift;
    my ( $block, $space1, $space2 ) = @_;
    my ( $tag, $params, $code ) = $block =~ /$self->{'block_plugin'}/;
    my $out;

    if ( $tag && $tag =~ /^$self->{'tag_form'}$/ ) {

      $out = $self->replace_form( $code, $self->param_block($params) );

    } else {

      $block =~ s/(^\s*)($self->{'pre_start'})/$1$self->{'tag_start'}/g;
      $block =~ s/($self->{'pre_end'})(\s*$)/$self->{'tag_end'}$2/g;

      return $block;
    }

    $out .= $space1;
    return $out;
  }

  sub replace_form {
    my $self = shift;
    my ( $code, @param ) = @_;

    $self->{'name'} = shift @param;
    $self->{'auto_submit'} = 1 if $self->{'auto_submit'} ne '0';

    $self->{'form'}{ $self->{'name'} } = nes_forms->new( $code, $self->{'name'}, @param );

    return $self->{'form'}{ $self->{'name'} }->out();
  }
  
}

{

  package nes_forms;
  use vars qw(@ISA);
  @ISA = qw( nes_interpret );

  sub new {
    my $class = shift;
    my ( $out, $name, $auto_submit, $captcha_name, $captcha_last, $expire, $expire_last, $location, $attempts, $attempts_for_captcha ) = @_;
    my $self = $class->SUPER::new();

    foreach my $tag ( keys %{ $self->{'container'}->{'content_obj'}->{'tags'} } ) {
      $self->{'tags'}{$tag} = $self->{'container'}->{'content_obj'}->{'tags'}{$tag};
    }    

    $self->{'plugin'} = nes_plugin->get_obj('forms_plugin');
    $self->{'plugin'}->add_obj( $name, $self );
    
    $self->{'attempts_for_captcha'} = $attempts_for_captcha;

    $self->{'tag_obfuscated'} = 'obfuscated';
    $self->{'tag_form_check'} = 'check';

    $self->{'out'}          = $out;
    $self->{'name'}         = $name;
    $self->{'auto_submit'}  = 0;
    $self->{'auto_submit'}  = 1 if $auto_submit ne '0';
    $self->{'captcha_name'} = $captcha_name;
    $self->{'captcha_last'} = $captcha_last;
    $self->{'location'}     = $location;
    
    $attempts = $self->{'CFG'}{'forms_plugin_max_attempts'} if !$attempts;
    ( $self->{'max_attempts'}, $self->{'max_time'} ) = split( '/', $attempts );

    $self->{'expire_tmp'}        = utl::expires_time( $self->{'CFG'}{'forms_plugin_expire_attempts'} );
    $self->{'form_start_name'}   = $self->{'CFG'}{'forms_plugin_start'} . '_' . $self->{'name'};
    $self->{'form_finish_name'}  = $self->{'CFG'}{'forms_plugin_finish'} . '_' . $self->{'name'};
    $self->{'form_start'}        = $self->{'query'}->get( $self->{'form_start_name'} );
    $self->{'form_finish'}       = $self->{'query'}->get( $self->{'form_finish_name'} );
    $self->{'form_start_field'}  = '<input type="hidden" name="' . $self->{'form_start_name'} . '"  value="' . $self->{'name'} . '" />';
    $self->{'form_finish_field'} = '<input type="hidden" name="' . $self->{'form_finish_name'} . '"  value="' . $self->{'name'} . '" />';
    $self->{'auto_submit_field'} = '';
    $self->{'auto_submit_field'} = 'document.' . $self->{'name'} . '.submit();';

    $self->{'tmp'} = nes_tmp->new( $self->{'CFG'}{'forms_plugin_suffix'}, $self->{'name'} );

    $self->{'form_is_start'}  = 0;
    $self->{'form_is_start'}  = 1 if $self->{'form_start'} eq $self->{'name'};
    $self->{'form_is_finish'} = 0;
    $self->{'form_is_finish'} = 1 if $self->{'form_finish'} eq $self->{'name'};

    $self->{'expire'}      = $expire || $self->{'CFG'}{'forms_plugin_expire'};
    $self->{'expire_last'} = $expire_last || $self->{'CFG'}{'forms_plugin_expire_last'};
    
    if ( $self->{'form_is_start'} && !$self->{'form_finish'} ) {
      $self->{'expire'} = $self->{'expire_last'};
    }

    $self->{'is_ok'} = 0;

    $self->replace_form();

    return $self;
  }

  sub replace_form {
    my $self = shift;

    if ( $self->{'form_is_start'} ) {
      $self->load();
      $self->{'tmp'}->save( time . ':' ) if !$self->{'form_is_finish'};
    }
    
    $self->get_attempts;

    if ( $self->{'attempts'} < $self->{'attempts_for_captcha'}+1 && $self->{'attempts_for_captcha'} ) {
      $self->{'auto_submit'}  = 1;
      $self->{'captcha_name'} = '';
      $self->{'captcha_last'} = '';
    }    

    $self->replace_check();
    $self->replace_obfuscated();
    $self->replace_init_form();
    $self->replace_control();
    $self->save() if $self->verify();

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
    $self->{'plugin'}->add_env( 'forms_plugin', $self->{'name'}, 'attempts', $self->{'attempts'} );

    return;
  }

  sub captcha_check {
    my $self = shift;

    my $captcha = nes_plugin->get( 'captcha_plugin', $self->{'captcha_name'} );
    return (1) if $captcha->{'is_ok'};

    return (0);
  }

  sub replace_check {
    my $self = shift;

    if ( $self->{'form_is_start'} ) {
      $self->{'out'} =~
        s/($self->{'pre_start'}\s*$self->{'tag_plugin'}\s*$self->{'tag_form_check'}\s*(\([^\(]*\)|[^\s]*)\s*$self->{'pre_end'})/$self->check_field($2)/gei;
    } else {
      $self->{'out'} =~ s/($self->{'pre_start'}\s*$self->{'tag_plugin'}\s*$self->{'tag_form_check'}\s*(\([^\(]*\)|[^\s]*)\s*$self->{'pre_end'})//gi;
    }

    return;
  }

  sub check_field {
    my $self     = shift;
    my ($params) = @_;
    my @param    = $self->param_block($params);

    undef $self->{'error_check'};

    foreach my $this (@param) {
      my ( $field, $option ) = split( /\s*:\s*/, $this );
      my ( $min, $max, $type ) = split( ',', $option );
      my $this_field = $self->{'query'}->get($field);
      my $error;
      if ($min) {
        $error .= 'min, ' if length($this_field) < $min;
      }
      if ($max) {
        $error .= 'max, ' if length($this_field) > $max;
      }
      if ( $type eq 'num' ) {
        $error .= 'num, ' if $this_field =~ /\D+/;
      }
      if ( $type eq 'email' ) {

        if ($this_field) {    # sólo da error si el campo no esta vacío, podía ser opcional
          $error .= 'email, ' if $this_field !~ /[a-z0-9!#$%&'*+\/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+\/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?/;
        }

      }
      if ( $type =~ /^\/(.*)\/(.*)$/ ) {
        my $regex = "(?x$2)$1";

        if ($this_field) {    # sólo da error si el campo no esta vacío, podía ser opcional
          $error .= 'regular expression' if $this_field !~ /$regex/;
        }

      }
      $self->{'error_check'} = 1 if $error;

      $self->{'plugin'}->add_error( 'forms_plugin', $self->{'name'}, 'field_' . $field, $error ) if $error;
      $self->{'plugin'}->add_error( 'forms_plugin', $self->{'name'}, 'field',           $error ) if $error;

    }

    return;
  }

  sub replace_obfuscated {
    my $self = shift;
    
#    $self->{'out'} =~ s/$self->{'pre_start'}\s*$self->{'tag_plugin'}\s*$self->{'tag_obfuscated'}\s*(.+?)\s*$self->{'pre_end'}/$self->{'obfuscated'}{$1} = $self->get_key( 5 + int rand 4 )/egi;
#    return;
    
    my $obfuscated_tag = qr{(?six)
                        \s*$self->{'pre_start'}\s*
                            $self->{'tag_plugin'}
                            \s*
                            $self->{'tag_obfuscated'}    # tag del plugin
                            \s*
                            (\([^\(\)]+\)|[^\(\)]\S+)    # parametros
                            \s*
                        $self->{'pre_end'}\s*
                        };  
    
    $self->{'out'} =~ s/$obfuscated_tag/$self->obfuscated($self->param_block($1))/ge;     
   
    return;
  }
  
  sub obfuscated {
    my $self = shift;
    my ( $field ) = @_;

    return $self->{'obfuscated'}{$field} = $self->get_key( 5 + int rand 4 );
  }  
  
  sub replace_init_form {
    my $self = shift;

    # siempre, indica que se ha iniciado el formulario
    $self->{'out'} =~ s/(\<\/form\>)/$self->{'form_start_field'}$1/;

    return;
  }

  sub replace_control {
    my $self = shift;

    # errores en check
    return if $self->{'error_check'};

    if ( $self->{'captcha_name'} ) {
      if ( $self->{'captcha_last'} ) {
        $self->{'form_is_finish'} = 0 if !$self->captcha_check();
      } else {
        return if !$self->captcha_check();
      }
    }

    # desactivar los campos en el segundo paso.
    if ( $self->{'form_is_start'} && !$self->{'form_is_finish'} && !$self->{'error_check'} ) {

      # es posible que falten tag a desactivar
      $self->{'out'} =~ s/<input /<input readonly=\"readonly\" /gi;
      $self->{'out'} =~ s/<textarea /<textarea readonly=\"readonly\" /gi;
      $self->{'out'} =~ s/<select /<input readonly=\"readonly\" /gi;

      # excluimos submit y captcha
      $self->{'out'} =~ s/<input readonly=\"readonly\" (.*type\s*=\s*\"?hidden\"?)/<input $1/gi;
      $self->{'out'} =~ s/<input readonly=\"readonly\" (.*type\s*=\s*\"?submit\"?)/<input $1/gi;
      $self->{'out'} =~ s/<input readonly=\"readonly\" (.*name\s*=\s*\"?$self->{'CFG'}{'captcha_plugin_start'}_$self->{'captcha_name'}\"?)/<input $1/gi if $self->{'captcha_name'};
      $self->{'out'} =~ s/<input readonly=\"readonly\" (.*name\s*=\s*\"?$self->{'captcha_name'}\"?)/<input $1/gi if $self->{'captcha_name'};
      $self->{'out'} =~ s/<input readonly=\"readonly\" (.*this_is_captcha_field)/<input $1/gi;
    }

    $self->{'auto_submit_field'} = ''  if !$self->{'auto_submit'};
    if ( $self->{'form_is_start'} && !$self->{'form_is_finish'} ) {
      $self->{'last_step'} = 1;
      $self->{'plugin'}->add_env( 'forms_plugin', $self->{'name'}, 'last_step', '1' );
      $self->{'key_name'}  = $self->get_key( 9 + int rand 9 );
      $self->{'key_value'} = $self->get_key( 9 + int rand 9 );
      my $form_key = '<input type="hidden" name="' . $self->{'key_name'} . '"  value="' . $self->{'key_value'} . '" />';
      my $js_code  = $form_key;
      my $js_var   = $self->get_key( 9 + int rand 9 );
      $js_code =
        '<script>' . $js_var . ' = unescape(\'' . utl::escape($js_code) . '\');document.write(' . $js_var . ');' . $self->{'auto_submit_field'} . '</script>';
      $self->{'out'} =~ s/(\<\/form\>)/$self->{'form_finish_field'}$js_code\n$1/;
    }

    return;
  }

  sub out {
    my $self = shift;

    return $self->{'out'};

  }

  sub is_ok {
    my $self = shift;

    $self->{'fatal_error'} = 0;

    # no se ha terminado de llenar el formulario
    $self->{'last_error'} = 'no form start';
    $self->{'fatal_error'} = 0;
    $self->{'plugin'}->add_last_error( 'forms_plugin', $self->{'name'}, 'no form start' );
    $self->{'plugin'}->add_fatal_error( 'forms_plugin', $self->{'name'}, '' );
    return 0 if !$self->{'form_is_start'};

    # maximo de intentos
    $self->{'last_error'}  = "5 max attempts, wait $self->{'max_time'} minutes";
    $self->{'fatal_error'} = 5;
    $self->{'plugin'}->add_fatal_error( 'forms_plugin', $self->{'name'}, '5' );
    $self->{'plugin'}->add_last_error( 'forms_plugin', $self->{'name'}, "max attempts, wait $self->{'max_time'} minutes" );
    return 0 if $self->{'attempts'} > $self->{'max_attempts'};

    # no existe la cookie
    $self->{'last_error'}  = 'no cookie';
    $self->{'fatal_error'} = 1;
    $self->{'plugin'}->add_fatal_error( 'forms_plugin', $self->{'name'}, '1' );
    $self->{'plugin'}->add_last_error( 'forms_plugin', $self->{'name'}, 'no cookie o expire' );
    return 0 if !$self->{'cookie'};

    # la cookie ha expirado, expiración interna, "posible" manipulación de la cookie
    $self->{'last_error'}  = 'cookie expired, posible manipulate cookie';
    $self->{'fatal_error'} = 2;
    $self->{'plugin'}->add_fatal_error( 'forms_plugin', $self->{'name'}, '2' );
    $self->{'plugin'}->add_last_error( 'forms_plugin', $self->{'name'}, 'cookie expired, posible manipulate cookie' );
    return 0 if $self->{'expired'};

    # no se ha terminado de llenar el formulario
    $self->{'last_error'} = 'no form finish';
    $self->{'fatal_error'} = 0;
    $self->{'plugin'}->add_last_error( 'forms_plugin', $self->{'name'}, 'no form finish' );
    $self->{'plugin'}->add_fatal_error( 'forms_plugin', $self->{'name'}, '' );
    return 0 if !$self->{'form_is_finish'};

    # hash no coninciden, seguramente la cookie ha sido manipulada
    $self->{'last_error'}  = 'posible manipulate cookie data';
    $self->{'fatal_error'} = 3;
    $self->{'plugin'}->add_fatal_error( 'forms_plugin', $self->{'name'}, '3' );
    $self->{'plugin'}->add_last_error( 'forms_plugin', $self->{'name'}, 'posible manipulate cookie data' );
    return 0 if $self->{'generated_hash'} ne $self->{'load_hash'};

    # no se ha definido la "key", tal vez no tenga javascript habilitado
    $self->{'last_error'}  = 'no javascript key, javascript enabled?';
    $self->{'fatal_error'} = 4;
    $self->{'plugin'}->add_fatal_error( 'forms_plugin', $self->{'name'}, '4' );
    $self->{'plugin'}->add_last_error( 'forms_plugin', $self->{'name'}, 'no javascript key, javascript enabled?' );
    return 0 if !$self->{'query'}->get( $self->{'key_name'} );

    # se intenta usar una cookie válida ya usada
    $self->{'last_error'}  = "already been used";
    $self->{'fatal_error'} = 6;
    $self->{'plugin'}->add_fatal_error( 'forms_plugin', $self->{'name'}, '6' );
    $self->{'plugin'}->add_last_error( 'forms_plugin', $self->{'name'}, "already been used" );
    return 0 if $self->{'used_key'} eq $self->{'key_value'};

    # javascript está habilitado, posible manipulación del formulario
    $self->{'last_error'}  = 'no javascript key value, posible manipulate form';
    $self->{'fatal_error'} = 7;
    $self->{'plugin'}->add_fatal_error( 'forms_plugin', $self->{'name'}, '7' );
    $self->{'plugin'}->add_last_error( 'forms_plugin', $self->{'name'}, 'no javascript key value, posible manipulate form' );
    return 0 if $self->{'key_value'} ne $self->{'query'}->get( $self->{'key_name'} );

    $self->{'last_error'}  = '';
    $self->{'fatal_error'} = 0;
    $self->{'plugin'}->add_fatal_error( 'forms_plugin', $self->{'name'}, 0 );
    $self->{'plugin'}->add_last_error( 'forms_plugin', $self->{'name'}, 'ok' );
#    my $data = time . ':' . $self->{'key_value'};
#    $self->{'tmp'}->clear($data);

    $self->{'is_ok'} = 1;

    return 1;
  }

  sub verify {
    my $self = shift;

    # no se ha comenzado el formulario
    return 1 if !$self->{'form_is_start'};

    $self->{'fatal_error'} = 1;
    $self->{'last_error'}  = '1 no cookie o expire';
    $self->{'plugin'}->add_fatal_error( 'forms_plugin', $self->{'name'}, '1' );
    $self->{'plugin'}->add_last_error( 'forms_plugin', $self->{'name'}, 'no cookie o expire' );
    return 0 if !$self->{'cookie'};

    $self->{'fatal_error'} = 2;
    $self->{'last_error'}  = '2 manipulate expire';
    $self->{'plugin'}->add_fatal_error( 'forms_plugin', $self->{'name'}, '2' );
    $self->{'plugin'}->add_last_error( 'forms_plugin', $self->{'name'}, 'manipulate expire' );
    return 0 if $self->{'expired'};

    if ( $self->{'form_is_finish'} ) {
      if ( $self->{'generated_hash'} ne $self->{'load_hash'} ) {
        $self->{'fatal_error'} = 3;
        $self->{'last_error'}  = '3 manipulate data';
        $self->{'plugin'}->add_fatal_error( 'forms_plugin', $self->{'name'}, '3' );
        $self->{'plugin'}->add_last_error( 'forms_plugin', $self->{'name'}, 'manipulate data' );
        return 0;
      }
    }

    return 1;
  }

  sub load {
    my $self = shift;

    use Digest::MD5 qw(md5_hex);
    $self->{'cookie'} = $self->{'cookies'}->get( $self->{'name'} );

    my $pass;
    my $time;
    my $hash;
    my %obfuscated;

    my @lines = split( /\n/, $self->{'cookie'} );
    my $first_line = shift @lines;
    ( $self->{'key_name'}, $self->{'key_value'} ) = split( '=', $first_line );

    foreach my $line (@lines) {

      my ( $var, $value ) = split( '=', $line );

      if ( $var eq $self->{'form_start_name'} . '_time' ) {
        $time = $value;
        next;
      }
      if ( $var eq $self->{'form_start_name'} . '_pass' ) {
        $hash = $value;
        next;
      }
      $obfuscated{$var} = $value;
      $pass .= $self->{'query'}->{'q'}{$var};
    }
    $self->{'generated_hash'} = md5_hex($pass);
    $self->{'load_hash'}      = $hash;
    $self->{'expired'}        = ( ( $time + utl::expires_time( $self->{'expire'} ) ) < time );

    foreach my $key ( keys %obfuscated ) {
      my $key_value = $self->{'query'}->get($key);
      my $field     = $obfuscated{$key};
      $self->{'query'}->set( $field, $key_value );
    }

    $self->{'top_container'}->init_nes_env();

    return;
  }

  sub save {
    my $self = shift;

    use Digest::MD5 qw(md5_hex);
    my $pass;
    my %obfuscated = %{ $self->{'obfuscated'} };
    $self->{'data'} = '';
    $self->{'data'} .= $self->{'key_name'} . '=' . $self->{'key_value'};
    $self->{'data'} .= "\n";

    foreach my $key ( keys %obfuscated ) {
      $self->{'data'} .= $obfuscated{$key} . '=' . $key . "\n";
      $pass .= $self->{'query'}->{'q'}{$key};
    }
    $self->{'save_hash'} = md5_hex($pass);

    # controla la expiración de la cookie
    $self->{'data'} .= $self->{'form_start_name'} . '_time' . '=' . time;
    $self->{'data'} .= "\n";
    $self->{'data'} .= $self->{'form_start_name'} . '_pass' . '=' . $self->{'save_hash'};

    $self->{'cookies'}->create( $self->{'name'}, $self->{'data'}, $self->{'expire'} );

  }

}

# don't forget to return a true value from the file
1;

