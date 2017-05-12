#!/bin/perl

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
#  DOCUMENTATION:
#  perldoc Nes::Obj::secure_login
#  
# -----------------------------------------------------------------------------

use Nes;

package secure_login;

{
  
  sub new {
    my $class = shift;
    my $self =  bless {}, $class;
  
    my $nes     = Nes::Singleton->new();
    my $obj     = $nes->{'query'}->{'q'}{'obj_param_0'};
    my $cfg     = $nes->{'CFG'};
    my $ddumper = '('.$nes->{'query'}->{'q'}{$obj.'_param_1'}.')';
    my %param    =  eval "$ddumper";
    
    # get parameters
    $self->{'script_handler'}    = '';
    $self->{'function_handler'}  = '';
    
    $self->{'from_table'}          = undef;
    $self->{'from_user_field'}     = undef;
    $self->{'from_pass_field'}     = undef;
    $self->{'from_user_function'}  = undef;
    $self->{'from_pass_function'}  = undef;    
    
    $self->{'min_len_name'}      = 2;
    $self->{'max_len_name'}      = 15;
    $self->{'min_len_pass'}      = 2;
    $self->{'max_len_pass'}      = 15;
    $self->{'attempts'}          = 3;
    $self->{'form_attempts'}     = '10/5';
    $self->{'form_location'}     = 'none';
    $self->{'form_exp_last'}     = '1m';
    $self->{'form_expire'}       = '10m';
    $self->{'form_name'}         = 'secure_login';
    $self->{'captcha_name'}      = 'secure_login';
    $self->{'captcha_type'}      = 'ascii';
    $self->{'captcha_digits'}    = 6;
    $self->{'captcha_size'}      = 2;
    $self->{'captcha_noise'}     = 3;
    $self->{'captcha_sig'}       = '';
    $self->{'captcha_spc'}       = ' ';
    $self->{'captcha_expire'}    = '1m';
    $self->{'captcha_atempts'}   = '10/5';
    $self->{'captcha_tag_start'} = '<pre style="font-size:2px; line-height:1.0;">';
    $self->{'captcha_tag_start'} = '' if $param{'captcha_size'} ne 'none';
    $self->{'captcha_tag_end'}   = '<br></pre>';
    $self->{'captcha_tag_end'}   = '' if $param{'captcha_size'} ne 'none';
    $self->{'out_page'}          = 'http://'.$ENV{'SERVER_NAME'}.$ENV{'REQUEST_URI'};
    $self->{'expire_session'}    = '12h';
    $self->{'expire_session_re'} = '48h';
    $self->{'msg_legend'}        = '';
    $self->{'msg_name'}          = 'User:';
    $self->{'msg_pass'}          = 'Password:';
    $self->{'msg_remember'}      = '';
    $self->{'msg_login'}         = 'Enter';
    $self->{'msg_captcha'}       = 'Security code';
    $self->{'msg_error_form'}    = '<img src="'.$cfg->{'img_dir'}.'/error.gif"> Incorrect User/Pass<br>';
    $self->{'msg_error_captcha'} = '<img src="'.$cfg->{'img_dir'}.'/error.gif">';
    $self->{'id_form'}           = 'secure_login_id';
    $self->{'class_form'}        = 'secure_login_class';
    $self->{'msg_error_name'}    = '<img src="'.$cfg->{'img_dir'}.'/error.gif">';
    $self->{'msg_error_pass'}    = '<img src="'.$cfg->{'img_dir'}.'/error.gif">';
    $self->{'tpl_errors'}        = 'secure_login_errors.nhtml';
    $self->{'tpl_options'}       = '';
    
    
    foreach my $this (keys %param) {
      $self->{$this} = $param{$this};
    }
    
    $self->{'expire_session'} = $self->{'expire_session_re'} if $nes->{'query'}->{'q'}{'l_Remember'};                                      
    
    return $self;    
  }
  
}

# don't forget to return a true value from the file
1;



 