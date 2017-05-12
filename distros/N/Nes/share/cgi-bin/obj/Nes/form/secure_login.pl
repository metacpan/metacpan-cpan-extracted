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
#  secure_login.pl
#
#  DOCUMENTATION:
#  perldoc Nes::Obj::secure_login
#
# -----------------------------------------------------------------------------

use Nes;
use secure_login;

my $nes     = Nes::Singleton->new('./secure_login.nhtml');
my $vars    = secure_login->new;
my $top     = $nes->{'top_container'};
my $obj     = $nes->{'query'}->{'q'}{'obj_param_0'};
my $nes_env = $top->{'nes_env'};

$vars->{'login_id'}  = '';

# fields names
my $fld_user = $vars->{'form_name'}.'_User';
my $fld_pass = $vars->{'form_name'}.'_Password';
my $fld_reme = $vars->{'form_name'}.'_Remember';

# fields
$vars->{'Remember'} = 'checked="checked"' if $nes->{'query'}->{'q'}{$fld_reme};
$vars->{'User'}     = $nes->{'query'}->{'q'}{$fld_user};
$vars->{'Password'} = $nes->{'query'}->{'q'}{$fld_pass};

# errors vars
$vars->{'error_field_user'}     = $nes_env->{'nes_forms_plugin_'.$vars->{'form_name'}.'_error_field_'.$fld_user};
$vars->{'error_field_password'} = $nes_env->{'nes_forms_plugin_'.$vars->{'form_name'}.'_error_field_'.$fld_pass};
$vars->{'form_max_attempts'}    = 1 if $nes_env->{'nes_forms_plugin_'.$vars->{'form_name'}.'_attempts'} > $vars->{'attempts'};
$vars->{'last_step'}            = $nes_env->{'nes_forms_plugin_'.$vars->{'form_name'}.'_last_step'};
$vars->{'form_error_fatal'}     = $nes_env->{'nes_forms_plugin_'.$vars->{'form_name'}.'_error_fatal'};
$vars->{'captcha_error_fatal'}  = $nes_env->{'nes_captcha_plugin_'.$vars->{'captcha_name'}.'_error_fatal'};

# get form 
my $form    = nes_plugin->get( 'forms_plugin',   $vars->{'form_name'} );
my $captcha = nes_plugin->get( 'captcha_plugin', $vars->{'captcha_name'} );

# errors
$vars->{'fatal_error'} = 0;
if ( $form->{'fatal_error'}      ||
  $captcha->{'fatal_error'} == 1 ||
  $captcha->{'fatal_error'} == 3 ||
  $captcha->{'fatal_error'} == 4 ) {

  $vars->{'fatal_error'} = 1;
}

# action if ok form
if ( $form->{'is_ok'} ) {
   {
      if ( $vars->{'script_handler'} && $vars->{'function_handler'} ) {
        require "$vars->{'script_handler'}";
        my $handler = \&{$vars->{'function_handler'}};
        $vars->{'login_id'} = $handler->($vars->{'User'},$vars->{'Password'});
      } 
      if ( $vars->{'from_table'} && $vars->{'from_user_field'} && $vars->{'from_pass_field'} ) {
        $vars->{'login_id'} = from_table();
      }       
      if ( $vars->{'login_id'} ) {
        $form->{'tmp'}->clear();
      } else {
        $vars->{'error_user_pass'} = 1;
      }     
   }
}

$nes->out(%$vars);

sub from_table {

  return '' if !$vars->{'User'} || !$vars->{'Password'};
  
  my $user = '\''.$vars->{'User'}.'\'';
     $user = $vars->{'from_user_function'}.'(\''.$vars->{'User'}.'\')' if $vars->{'from_user_function'};
  my $pass = '\''.$vars->{'Password'}.'\'';
     $pass = $vars->{'from_pass_function'}.'(\''.$vars->{'Password'}.'\')' if $vars->{'from_pass_function'};

  my $query = qq~SELECT `$vars->{'from_user_field'}`  
                 FROM  `$vars->{'from_table'}`
                 WHERE ( 
                         `$vars->{'from_user_field'}` = $user  AND 
                         `$vars->{'from_pass_field'}` = $pass
                         
                       )
                 LIMIT 0,1;~;  

  use Nes::DB;
  my $config    = $nes->{'CFG'};
  my $db_name   = $vars->{'DB_base'}   || $config->{'DB_base'};
  my $db_user   = $vars->{'DB_user'}   || $config->{'DB_user'};
  my $db_pass   = $vars->{'DB_pass'}   || $config->{'DB_pass'};
  my $db_driver = $vars->{'DB_driver'} || $config->{'DB_driver'};
  my $db_host   = $vars->{'DB_host'}   || $config->{'DB_host'};
  my $db_port   = $vars->{'DB_port'}   || $config->{'DB_port'};
  my $base      = Nes::DB->new( $db_name, $db_user, $db_pass, $db_driver, $db_host, $db_port );

  my @result  = $base->sen_select($query);
  my $user_id = $result[0]->{$vars->{'from_user_field'}};

  return $user_id;
}

# don't forget to return a true value from the file
1;



 