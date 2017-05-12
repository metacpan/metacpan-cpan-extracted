
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
#  Nes.pm
#
# -----------------------------------------------------------------------------

use strict;
#use warnings;

# cgi environment no defined in command line
no warnings 'uninitialized';

our $VERSION          = '1.03';
our $CRLF             = "\015\012";
our $MAX_INTERACTIONS = 500;
our $MOD_PERL         = $ENV{'MOD_PERL'} || 0;
our $MOD_PERL1        = $MOD_PERL =~ /mod_perl\/1/ || 0;
our $MOD_PERL2        = $MOD_PERL =~ /mod_perl\/2/ || 0;

use Nes::Setting;
use Nes::Singleton;

{

  package Nes;

  my %instance;

  sub new {
    my $class = shift;
    my $self  = bless {}, $class;
    $self->{'previous'} = $class->get_obj();
    $instance{$class}   = $self;
  
#    utl::cleanup(\%instance) if $ENV{'MOD_PERL'};
  
    $self->{'top_container'}    = nes_top_container->get_obj();
    $self->{'CFG'}              = Nes::Setting->get_obj();
    $self->{'cookies'}          = nes_cookie->get_obj();
    $self->{'session'}          = nes_session->get_obj();
    $self->{'query'}            = nes_query->get_obj();    
    $self->{'container'}        = nes_container->get_obj();
    $self->{'register'}         = nes_register->get_obj();
    $self->{'nes'}              = $self;
    $self->{'MAX_INTERACTIONS'} = $MAX_INTERACTIONS;
    
    return $self;
  }
  
  sub get_obj {
    my $self  = shift;
    my $class = ref($self);

    $self = $instance{$self} if !$class;

    return $self;
  }
  
  sub forget {
    my $self  = shift;
    my $class = ref($self);
    
    $instance{$class} = $self->{'previous'};

    return $instance{$class};
  }    

  sub get_key {
    my $self  = shift;
    my ($max) = @_;

    my @kletters = @{ $self->{'CFG'}{'kletters'} };
    my @kletnum  = @{ $self->{'CFG'}{'kletnum'} };

    # siempre comienza por letra por si se usa como nombre de variable o campo
    my $key = $kletters[ int( rand( $#kletters + 1 ) ) ];
    for ( 1 .. ( $max - 1 ) ) {
      $key .= $kletnum[ int( rand( $#kletnum + 1 ) ) ];
    }

    return $key;
  }
  
}


{

  package nes_tmp;
  use vars qw(@ISA);
  @ISA = qw( Nes );

  sub new {
    my $class = shift;
    my ($suffix,$name) = @_;
    my $self  = $class->SUPER::new();

    $self->{'suffix'}     = $suffix;
    $self->{'tmp_suffix'} = $self->{'CFG'}{'tmp_suffix'};
    $self->{'name'}       = $self->get_name($name);
    $self->{'tmp_dir'}    = $self->{'CFG'}{'tmp_dir'};
    $self->{'file'}       = $self->{'tmp_dir'}.'/'.$self->{'name'};
    $self->{'expired'}    = utl::expires_time($self->{'CFG'}{'tmp_clear'});

    $self->clear_expired if $self->{'CFG'}{'tmp_clear'};

    return $self;
  }

  sub clear_expired {
    my $self  = shift;
    
    # borra de vez en cuando los temporales ( 1 de cada rand x veces )
    # si hay muchos puede ser lento, sólo será lento una de cada rand x veces
    return if 1 < (rand 100);    
    
    # --------------------------------------------------------------------------
    # si por error en el archivo de configuración se hace: tmp_dir = '/'
    # podía ser desastroso... de ahí tantas comprobaciones antes de borrar
    # Indicar 0 en tmp_clear del archivo de configuración para no borrar nunca.
    # --------------------------------------------------------------------------

    # nos aseguramos que tmp_dir tiene valor
    # la ruta más corta es /tmp 
    return if length $self->{'tmp_dir'} < 4;
    
    # nos aseguramos que tmp_suffix tiene valor
    return if length $self->{'tmp_suffix'} < 4;    
    
    opendir(DIR,$self->{'tmp_dir'});  
    foreach my $file (readdir(DIR)) {  
      if ( $file =~ /$self->{'tmp_suffix'}$/ ) {
        # nos aseguramos que sea un archivo temporal
        next if $file !~ /tmp/;           
        my $last_mod = (stat ($self->{'tmp_dir'}.'/'.$file))[10];
        unlink($self->{'tmp_dir'}.'/'.$file) if ( (time - $last_mod) > $self->{'expired'} );
      }
        
    }  
    closedir DIR;
    
    return;
  }   

  sub save {
    my $self  = shift;
    my ($data) = @_;

    if ( ! -d $self->{'tmp_dir'} ) {
      my @level = split('/',$self->{'tmp_dir'});
      my $dir;
      foreach my $this_level ( @level ) {
        $dir .= '/'.$this_level;
        mkdir $dir if ! -d $dir;
        if ( ! -d $dir ) {
          warn "Can't create tmp dir : $dir";
          return;
        }        
      }
    }

    open(my $fh,'>>',$self->{'file'}) or warn "Can't write tmp file : $self->{'file'}";
    print $fh $data,"\n";
    close $fh;
    
    return;
  }   

  sub load {
    my $self  = shift;
    
    return if ! -e $self->{'file'};

    open(my $fh, '<', $self->{'file'}) or warn "Can't read tmp file : $self->{'file'}";
    my @data = <$fh>;
    chomp @data;
    close $fh;
    
    return @data;
  }  
  
  sub clear {
    my $self  = shift;
    my ($data) = @_;

    return if ! -e $self->{'file'};
    
    open(my $fh,'>',$self->{'file'}) or warn "Can't write tmp file : $self->{'file'} $!";
    print $fh $data."\n" if $data;
    close $fh;
    
    return;
  }  
  
  sub get_name {
    my $self  = shift;
    my ($name) = @_;

    my $remote = $ENV{'REMOTE_ADDR'};
    $remote = $ENV{'HTTP_X_REMOTE_ADDR'} if $ENV{'HTTP_X_REMOTE_ADDR'} && ( !$remote || $remote =~ /^(127|192)\./);

    $name  .= '.ip.'.$remote.$self->{'suffix'}.$self->{'tmp_suffix'};
    
    return $name;
  }   

}

{

  package nes_register;
  use vars qw(@ISA);
  @ISA = qw( Nes );

  sub new {
    my $class = shift;
    my $self = $class->SUPER::new();

    return $self;
  }

  sub set_data {
    my $self  = shift;
    my ($class, $name, $data) = @_;

    $self->{'data'}{$class}{$name} = $data;
      
    return;
  }  
  
  sub get_data {
    my $self  = shift;
    my ($class, $name, $data) = @_;
      
    return $self->{'data'}{$class}{$name};
  }    
  
  sub tag {
    my $self  = shift;
    my ($class, $tag, $handler) = @_;

    $self->{'tag'}{$tag}{'handler'} = $handler;
    $self->{'obj'}{$class}{'tag'}{$tag} = $handler;
      
    return;
  }
  
  sub handler {
    my $self  = shift;
    my ($class, $name_handler, $handler) = @_;

    $self->{'obj'}{'handler'}{$class}{$name_handler} = $handler;
      
    return;
  }  
  
  sub add_obj {
    my $self  = shift;
    my ($class, $name, $obj) = @_;

    my $cfg_file = $self->{'CFG'}{'plugin_top_dir'}.'/.'.$class.'.nes.cfg';
    Nes::Setting->load_cfg($cfg_file);  

    $self->{'obj'}{$class}{$name} = $obj;

    return $self;
  }
  
  sub get {
    my $self  = shift;
    my ($class, $name) = @_;

    return $self->{'obj'}{$class}{$name};
  }
  
  sub get_tags {
    my $self  = shift;

    return keys %{ $self->{'tag'} };
  }
  
  sub get_plugins {
    my $self  = shift;

    return keys %{ $self->{'obj'} };
  }
  
  sub get_names {
    my $self  = shift;
    my ($class) = @_;

    return keys %{ $self->{'obj'}{$class} };
  }    
  
  sub get_tag_class {
    my $self  = shift;
    my ($tag) = @_;

    return $self->{'tag'}{$tag}{'class'};
  }  
  
  sub get_tag_handler {
    my $self  = shift;
    my ($tag) = @_;
    
    return \&{$self->{'tag'}{$tag}{'handler'}};
  }
  
  sub get_handler {
    my $self  = shift;
    my ($class, $name_handler) = @_;

    return \&{$self->{'obj'}{'handler'}{$class}{$name_handler}};
  }    
  
  sub add_last_error {
    my $self  = shift;
    my ($class, $name, $error) = @_;

    $self->{'top_container'}->set_nes_env( 'nes_'.$class.'_'.$name.'_error_last', $error );
    
    return;
  }
  
  sub add_fatal_error {
    my $self  = shift;
    my ($class, $name, $ok) = @_;

    $self->{'top_container'}->set_nes_env( 'nes_'.$class.'_'.$name.'_error_fatal', $ok );

    return;
  }  
  
  sub add_error {
    my $self  = shift;
    my ($class, $name, $type, $error) = @_;

    $self->{'top_container'}->set_nes_env( 'nes_'.$class.'_'.$name.'_error_'.$type, $error );

    return;
  }   
  
  sub add_env {
    my $self  = shift;
    my ($class, $name, $type, $value) = @_;

    $self->{'top_container'}->set_nes_env( 'nes_'.$class.'_'.$name.'_'.$type, $value );

    return;
  } 

}


{

  # obsoleto, se mantiene por compatibilidad
  package nes_plugin;
  use vars qw(@ISA);
  @ISA = qw( Nes );

  my %instance = ();

  sub new {
    my $class = shift;
    my ( $obj_class, $name, $obj ) = @_;
    my $self = $class->SUPER::new();
    
#    utl::cleanup(\%instance) if $ENV{'MOD_PERL'};

    $self->{'plugin'} = $obj_class;
    $self->{'obj'}{$name} = $obj;

    my $cfg_file = $self->{'CFG'}{'plugin_top_dir'} . '/.' . $name . '.nes.cfg';
    Nes::Setting->load_cfg($cfg_file);

    $instance{$obj_class} = $self;
 
    return $self;
  }
  
  # add object for this class
  sub add_obj {
    my $self  = shift;
    my ($name, $obj) = @_;

    $self->{'obj'}{$name} = $obj;
    
    return $obj;
  }  
  
  sub add_last_error {
    my $self  = shift;
    my ($class, $name, $error) = @_;

    $self->{'top_container'}->set_nes_env( 'nes_'.$class.'_'.$name.'_error_last', $error );
    
    return;
  }
  
  sub add_fatal_error {
    my $self  = shift;
    my ($class, $name, $ok) = @_;

    $self->{'top_container'}->set_nes_env( 'nes_'.$class.'_'.$name.'_error_fatal', $ok );

    return;
  }  
  
  sub add_error {
    my $self  = shift;
    my ($class, $name, $type, $error) = @_;

    $self->{'top_container'}->set_nes_env( 'nes_'.$class.'_'.$name.'_error_'.$type, $error );

    return;
  }   
  
  sub add_env {
    my $self  = shift;
    my ($class, $name, $type, $value) = @_;

    $self->{'top_container'}->set_nes_env( 'nes_'.$class.'_'.$name.'_'.$type, $value );

    return;
  }     
  
  sub get {
    my $self  = shift;
    my ($class, $name) = @_;

    return $instance{$class}->{'obj'}{$name} if $name;
    return $instance{$class}->{'obj'}{$class};
   
  }
  
  sub get_obj {
    my $self  = shift;
    my ($class) = @_;

    return $instance{$class} if $class;
    return $self->SUPER::get_obj();
    
  }  
  
}


{

  package nes_cookie;
  use vars qw(@ISA);
  @ISA = qw( Nes );

  sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();

    $self->get_user_cookies();

    return $self;
  }

  sub get_cookies {
    my $self  = shift;

    my @cookies;

    # primero las que borran, para no machacar las que valen
    foreach my $cookie ( keys %{ $self->{'c_set'} } ) {
      push( @cookies, $cookie ) if $cookie =~ /_delete$/;
    }
    foreach my $cookie ( keys %{ $self->{'c_set'} } ) {
      push( @cookies, $cookie ) if $cookie !~ /_delete$/;
    }

    return @cookies;
  }

  sub get {
    my $self  = shift;
    my ( $name, $pass ) = @_;
    
    return if !$self->{'c_get'}{$name};
    $pass = '' if !$pass;

    my $key = $self->{'CFG'}{'private_key'} . $pass;
    require Crypt::CBC;
    my $cipher = Crypt::CBC->new(
      -key    => $key,
      -cipher => 'Blowfish'
    );
    my $text = '';
    eval { $text = $cipher->decrypt_hex( $self->{'c_get'}{$name} ); };

    return $text;
  }

  sub create {
    my $self  = shift;
    my ( $name, $value, $expiration, $path, $domain, $pass ) = @_;
    $pass = '' if !$pass;

    my $expires = &utl::expires($expiration);
    my $key     = $self->{'CFG'}{'private_key'} . $pass;

    require Crypt::CBC;
    my $cipher = Crypt::CBC->new(
      -key    => $key,
      -cipher => 'Blowfish'
    );

    $value = $cipher->encrypt_hex($value);
    $path = '/' if !$path;

    $self->{'c_set'}{$name} = "Set-Cookie: $name=$value; expires=$expires; path=$path; ";
    $self->{'c_set'}{$name} .= "domain=$domain; " if $domain;

    return;
  }

  sub del {
    my $self  = shift;
    my ($name,$path) = @_;
    $path = '/' if !$path;

    my $expires = &utl::expires('1s');
    my $value   = 'deleted';

    $self->{'c_set'}{ $name . '_delete' } = "Set-Cookie: $name=$value; expires=$expires; path=$path; ";

    return;
  }

  sub get_user_cookies {
    my $self  = shift;
    
    return if !$ENV{'HTTP_COOKIE'};

    my @cookies = split( /[;,]\s*/, $ENV{'HTTP_COOKIE'} );
    foreach my $cookie (@cookies) {
      my ( $key, $value ) = split( /=/, $cookie );
      $value = '' if !$value;
      next if $value eq 'deleted';
      $self->{'c_get'}{$key} = $value;
    }
  }
 
  sub out {
    my $self  = shift;

    my $cookies = '';
    foreach my $cookie ( $self->get_cookies() ) {
      $cookies .= $self->{'c_set'}{$cookie}."\n";
    } 
    
    return $cookies;
  }  
   
  sub get_c_get {
    my $self  = shift;

    my @cookies;

    foreach my $cookie ( keys %{ $self->{'c_get'} } ) {
      push( @cookies, $cookie );
    }

    return @cookies;    
  }   
   
}


{ 

  package nes_session;
  use vars qw(@ISA);
  @ISA = qw( nes_cookie );

  sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();
    
    $self->{'session_prefix'} = $self->{'CFG'}{'session_prefix'};
    $self->{'session_ok'}     = 0;
    $self->{'user'}           = '';
    $self->get;
    
    return $self;
  }

  sub get {
    my $self  = shift;
    my ($pass) = @_ || '';

    my $key = $self->{'CFG'}{'private_key'} . $pass;
    $self->{'sess'} = $self->SUPER::get( $self->{'session_prefix'}, $key );
    return if !$self->{'sess'};

    my ( $session_name, $expire, $user, $refuse ) = split( /::/, $self->{'sess'} );

    return if time > $expire;
    return if $session_name ne $self->{'session_prefix'};
    
    $self->{'session_ok'} = 1;
    $self->{'user'} = $user;   
    
    return $user;
  }

  sub create {
    my $self  = shift;
    my ( $user, $expiration, $pass ) = @_;
    $pass = '' if !$pass;

    my $key = $self->{'CFG'}{'private_key'} . $pass;
    my $expire  = time +  utl::expires_time( $expiration );
    my $refuse  = $self->get_key( 10 + int rand 10 );
    my $value   = $self->{'session_prefix'} . '::' . $expire . '::' . $user . '::' . $refuse;
    my $path    = '/';

    $self->{'cookies'}->create( $self->{'session_prefix'}, $value, $expiration, $path,'',$key );

    return;
  }
  
  sub del {
    my $self  = shift;

    return if !$self->{'user'};
    $self->{'cookies'}->del( $self->{'session_prefix'} );
    
    return;
  }  

}


{ # todo, add "<SELET MULTIPLE>" support

  package nes_query;
  use vars qw(@ISA);
  @ISA = qw( Nes );

  sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();
    
    $self->{'q'} = {};
    my $clength = $ENV{'CONTENT_LENGTH'} || 0;
    $self->{'save_buffer'} = 0;

    return $self if !$clength && !$ENV{'QUERY_STRING'};

    require Nes::Minimal;    
    $self->{'save_buffer'} = 1 if $self->{'top_container'}->{'php_wrapper'} && 
                                  $clength > ($self->{'CFG'}{'tmp_upload'}*1024) &&
                                  $self->{'CFG'}{'tmp_upload'};      
    Nes::Minimal::allow_hybrid_post_get(1);
    Nes::Minimal::max_read_size( $self->{'CFG'}{'max_post'}*1024 );
    Nes::Minimal::use_tmp( $self->{'CFG'}{'tmp_upload'}*1024 );
    Nes::Minimal::max_upload( $self->{'CFG'}{'max_upload'}*1024 );
    Nes::Minimal::save_buffer(1) if $self->{'save_buffer'};
    Nes::Minimal::sub_filter( \&utl::no_nes_remove ) if $self->{'top_container'}->{'php_wrapper'}; 
    $self->{'CGI'} = Nes::Minimal->new;
    $self->set_query();
    
    return $self;
  }

  sub set_query {
    my $self  = shift;
 
    foreach my $param ( $self->{'CGI'}->param() ) {
      $self->{'q'}{$param} = $self->{'CGI'}->param($param);
    }

    return;
  }
  
  sub param {
    my $self  = shift;
    my ($param) = @_;

    return $self->{'CGI'}->param($param);
  }  
  
#  sub get_upload {
#    my $self  = shift;
#    my ($param,$buffer) = @_;
# 
#    my $fh = $self->{'CGI'}->upload($param);
#    return if !$fh;
#    
#    return read($fh, $$buffer, 8192);
#  }  
  
  sub get_upload_buffer {
    my $self  = shift;
    my ($param,$buffer) = @_;
 
    my $fh = $self->{'CGI'}->upload($param);
    return if !$fh;
    
    return read($fh, $$buffer, 8192);
  }
  
  sub get_upload_name {
    my $self  = shift;
    my ($param) = @_;

    return $self->{'CGI'}->param_filename($param);
  }
  
  sub get_upload_fh {
    my $self  = shift;
    my ($param) = @_;
 
    return $self->{'CGI'}->upload($param);
  }
  
  sub upload_is_tmp {
    my $self  = shift;
    my ($param) = @_;
 
    return $self->{'CGI'}->upload_is_tmp($param);
  }
  
  sub upload_max_size {
    my $self  = shift;
 
    return $self->{'CGI'}->upload_max_size();
  }  
  
  sub post_max_size {
    my $self  = shift;
 
    return $self->{'CGI'}->post_max_size();
  }  
  
  sub url_encode {
    my $self  = shift;
    my ($value) = @_;

    return $self->{'CGI'}->url_encode($value);
  }  
  
  sub url_decode {
    my $self  = shift;
    my ($value) = @_;

    return $self->{'CGI'}->url_decode($value);
  }    
  
  sub get_buffer {
    my $self  = shift;
    my $buffer;
    
    return if !$self->{'CGI'};
    
    if ( $ENV{'REQUEST_METHOD'} ne 'GET' ) {
      return $buffer if $self->{'CGI'}->raw_saved(\$buffer, 8192);
    } 
    return;

  }  
  
  sub get_buffer_raw {
    my $self  = shift;
    
    return if !$self->{'CGI'};
    
    if ( $ENV{'REQUEST_METHOD'} ne 'GET' ) {
      return $self->{'CGI'}->raw;
    } 
    return;

  }

  sub get {
    my $self  = shift;
    my ($key) = @_;
    
#    return $self->{'CGI'}->param($key);
    return $self->{'q'}{$key};
  }

  sub set {
    my $self  = shift;
    my ( $name, $value ) = @_;

    $self->{'q'}{$name} = $value;

    return;
  }
  
  sub del {
    my $self  = shift;
    my ( $name ) = @_;

    undef $self->{'q'}{$name};

    return;
  }  

}


{

  package nes_top_container;
  use vars qw(@ISA);
  @ISA = qw( Nes );

  sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();
    my ($file,$dir) = @_;

    # maximo de interactiones, para evitar un bucle infinito.
    $self->{'max_inter'} = $MAX_INTERACTIONS;
    
    $self->init($file,$dir) if $file;

    return $self;
  }
  
  sub init {
    my $self  = shift;
    my ($file,$dir) = @_;
    
    $self->{'url'}  = '';
    $self->{'dir'}  = $dir;   
    $self->{'file'} = $file;
    
    $self->set_parent_dir( $self->{'dir'} );
  
    $self->{'file'} =~ s/(.*[\\\/])/\//;
    $self->{'file'} = $self->{'dir'} . $self->{'file'};
    
    $self->{'php_wrapper'} = 1 if $self->{'file'} =~ /php$/i;

    $self->{'query'}     = nes_query->new();
    $self->{'cookies'}   = nes_cookie->new();
    $self->{'session'}   = nes_session->new();
    $self->{'register'}  = nes_register->new();
   
    $self->init_nes_env();
    $self->init_cgi_env();

    $self->{'container'} = nes_container->new( $self->{'file'} );    

    return;
  }  
  
  sub get_out {
    my $self  = shift;

    return $self->{'out'};
  }  

  sub get_session {
    my $self  = shift;

    return $self->{'session'};
  }

  sub get_query {
    my $self  = shift;

    return $self->{'query'};
  }

  sub get_file_path {
    my $self  = shift;
    my ( $file ) = @_;
   
    my $parent_dir = $self->get_parent_dir();
    $parent_dir    =~ s/\/$//;
    my $this_dir   = $file;
    $this_dir      =~ s/[^\/]*$//;
    $this_dir      =~ s/^\.\///;    
    my $this_file  = $file;
    $this_file     =~ s/(.*)(\\|\/)//;

    my $file_path;
    
    if ( $this_dir =~ /^\// ) {
      $self->{'this_dir'} = $this_dir;  
      $file_path = $file;
    } else {
      while ( $this_dir =~ s/^\.\.\/// ) {
        $parent_dir =~ s/\/[^\/]*$//;
      }    
      $self->{'this_dir'} = $parent_dir.'/'.$this_dir;
      $file_path = $parent_dir.'/'.$this_dir.$this_file;
    }
    
    # Insecure dependency in require while running with -T switch at
    if ($file_path =~ /^([-\@\w.\\\/]+)$/) {
        $file_path = $1;                     
    }    

    return $file_path; 
  }

  sub get_dir {
    my $self  = shift;
    my ($file) = @_;

    my $dir = $file;
    $dir =~ s/(.*)(\\|\/).*/$1/;

    return $dir;
  }
  
  sub set_parent_dir {
    my $self  = shift;
    my ($dir) = @_;

    $self->{'parent_dir'} = $dir;

    return $dir;
  }  
  
  sub get_parent_dir {
    my $self  = shift;

    return $self->{'parent_dir'};
  }   

  sub init_nes_env {
    my $self  = shift;
    my ( $var, $value ) = @_;

    foreach my $key ( keys %{ $self->{'query'}->{'q'} } ) {
      my $name_env = 'q_' . $key;
      my $value    = $self->{'query'}->{'q'}{$key};
      $self->{'nes_env'}{$name_env} = $value;
    }

    foreach my $key ( keys %{ $self->{'CFG'} } ) {
      my $name_env = 'cfg_' . $key;
      my $value = $self->{'CFG'}->{$key};
      $value = "@{$self->{'CFG'}->{$key}}" if ref $self->{'CFG'}->{$key} eq 'ARRAY';
      $value = keys %{$self->{'CFG'}->{$key}} if ref $self->{'CFG'}->{$key} eq 'HASH';
      $self->{'nes_env'}{$name_env} = $value;
    }

    ( $self->{'nes_env'}{'nes_accept_language'} ) = split(/,/, $ENV{'HTTP_ACCEPT_LANGUAGE'}, 2);
    $self->{'nes_env'}{'nes_dir_self'}  = $self->{'dir'};
    $self->{'nes_env'}{'nes_this_dir'}  = $self->{'dir'};
    $self->{'nes_env'}{'nes_this_file'} = $self->{'file'};
    $self->{'nes_env'}{'nes_ver'}       = $VERSION;
    $self->{'nes_env'}{'nes_remote_ip'} = $ENV{'REMOTE_ADDR'};
    $self->{'nes_env'}{'nes_remote_ip'} = $ENV{'HTTP_X_REMOTE_ADDR'} 
      if $ENV{'HTTP_X_REMOTE_ADDR'} && ( !$ENV{'REMOTE_ADDR'} || $ENV{'REMOTE_ADDR'} =~ /^(127|192|169|10)\./);
      
    $self->{'nes_env'}{'nes_session_ok'}   = $self->{'session'}->{'session_ok'};
    $self->{'nes_env'}{'nes_session_user'} = $self->{'session'}->{'user'};

    return;
  }

  sub init_cgi_env {
    my $self  = shift;
    my ( $var, $value ) = @_;

    foreach my $key ( keys %ENV ) {
      my $name_env = 'env_' . $key;
      my $value    = $ENV{$key};
      $self->{'nes_env'}{$name_env} = $value;
    }

    return;
  }

  sub set_nes_env {
    my $self  = shift;
    my ( $var, $value ) = @_;

    $self->{'nes_env'}{$var} = $value;
    
    return;
  }
  
  sub del_nes_env {
    my $self  = shift;
    my ( $var ) = @_;

    undef $self->{'nes_env'}{$var};
    
    return;
  }  

  sub get_nes_env {
    my $self  = shift;
    my ($var) = @_;

    return $self->{'nes_env'}{$var};
    
    return;
  }

}

{

  package nes_container;
  use vars qw(@ISA);
  @ISA = qw( Nes );

  sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();
    my ( $file ) = @_;

    $self->{'file_dir'}  = $self->{'top_container'}->get_parent_dir();
    $self->{'file_name'} = $self->{'top_container'}->get_file_path($file);
    
    $self->{'top_container'}->set_parent_dir($self->{'top_container'}->{'this_dir'});
    
    $self->{'top_container'}->{'max_inter'}-- || die "Possible infinite loop";
    $self->{'this_inter'} = $MAX_INTERACTIONS - $self->{'top_container'}->{'max_inter'};

    $self->{'souce_types'}{'unknown'} = 'unknown';
    $self->{'souce_types'}{'html'}    = 'html,htm,nhtm,nhtml';
    $self->{'souce_types'}{'nsql'}    = 'nsql';
    $self->{'souce_types'}{'php'}     = 'php';
    $self->{'souce_types'}{'perl'}    = 'pl';
    $self->{'souce_types'}{'txt'}     = 'txt';
    $self->{'souce_types'}{'bash'}    = 'sh';
    $self->{'souce_types'}{'python'}  = 'py';
    $self->{'souce_types'}{'js'}      = 'njs,js';
    #$self->{'souce_types'}{'mail'}    = 'eml';
    # ...

    $self->get_source();      #  set @{$self->{'file_souce'}}
    $self->set_out();         #  set $self->{'file_script'}, $self->{'out'}
    $self->get_type();        #  set $self->{'type'}, $self->{'content_obj'}
    $self->add_parent_tags(); #  hereda los tags

    return $self;
  }
   
  sub get_type {
    my $self  = shift;

    my $extension = $self->{'file_name'};
    $extension =~ s/(.*)\.([^\.]*)$/$2/;

    $self->{'type'} = 'unknown';
    foreach my $type ( keys %{ $self->{'souce_types'} } ) {
      $self->{'type'} = $type if $self->{'souce_types'}{$type} =~ /[\,\s]?$extension[\,\s]?/i;
    }

    if ( $self->{'type'} eq 'html' ) {
      $self->{'content_obj'} = nes_html->new( $self );
      
    } elsif ( $self->{'type'} eq 'nsql' ) {
      $self->{'content_obj'} = nes_nsql->new( $self );
      
    } elsif ( $self->{'type'} eq 'php' ) {
      $self->{'content_obj'} = nes_php->new( $self );
    
    } elsif ( $self->{'type'} eq 'perl' ) {
      $self->{'content_obj'} = nes_perl->new( $self );
      
    } elsif ( $self->{'type'} eq 'txt' ) {
      $self->{'content_obj'} = nes_txt->new( $self );
      
    } elsif ( $self->{'type'} eq 'bash' ) {
      $self->{'content_obj'} = nes_shell->new( $self );
      
    } elsif ( $self->{'type'} eq 'python' ) {
      $self->{'content_obj'} = nes_python->new( $self );
               
    } elsif ( $self->{'type'} eq 'js' ) {
      $self->{'content_obj'} = nes_js->new( $self );
               
    } else {
      $self->{'content_obj'} = nes_unknown->new( $self );
    }

    return;
  }

  sub get_source {
    my $self  = shift;

    if ( open my $fh, '<', "$self->{'file_name'}" ) {
      @{ $self->{'file_souce'} } = <$fh>;
      chomp $self->{'file_souce'}[$#{$self->{'file_souce'}}];
      close $fh;
    } else {
      warn "couldn't open $self->{'file_name'}";
      $self->{'top_container'}->set_nes_env( 'nes_error_file_not_exist', $self->{'file_name'} );
    }

    return;
  }

  sub add_tags {
    my $self  = shift;
    my (%tags) = @_;

    $self->{'content_obj'}->add_tags(%tags);

    return;
  }
  
  sub add_parent_tags {
    my $self  = shift;
  
    foreach my $tag ( keys %{ $self->{'previous'}->{'content_obj'}->{'tags'} } ) {
      $self->{'content_obj'}->{'tags'}{$tag} = $self->{'previous'}->{'content_obj'}->{'tags'}{$tag};
    }    

    return;
  }  

  sub set_out_content {
    my $self  = shift;
    my ($out) = @_;

    $self->{'content_obj'}->set_out($out);

    return;
  }
  
  sub get_out_content {
    my $self  = shift;
    
    return $self->{'content_obj'}->{'out'};
  }

  sub set_tags {
    my $self  = shift;
    my (%tags) = @_;

    $self->{'content_obj'}->set_tags(%tags);

    return;
  }
  
  sub get_tag {
    my $self  = shift;
    my ($tag) = @_;

    return $self->{'content_obj'}->{'tags'}{$tag};
  }  

  sub set_out {
    my $self  = shift;

    $self->{'file_nes_line'} = $self->{'file_souce'}[0] 
      if $self->{'file_souce'}[0] =~ /{:\s*NES/i || '';
       
    my $interpret = nes_interpret->new();
    my @param     = $interpret->replace_NES( $self->{'file_nes_line'} );

    if ( $param[0] ) {
      shift @{ $self->{'file_souce'} };    # eliminamos la primera linea
      $self->{'script_ver'} = shift @param;
      @{ $self->{'file_script'} } = @param;
    }

    $self->{'out'} = '';
    foreach my $line (@{$self->{'file_souce'}}) {
       $self->{'out'} .= $line;
    }
    
    foreach my $script ( @{ $self->{'file_script'} } ) {
      $script = 'none' if !$script;
      next if $script eq 'none';    
    }

    return;
  }

  sub go {
    my $self  = shift;

    $self->{'content_obj'}->go();
    $self->{'top_container'}->set_parent_dir($self->{'file_dir'});

    return;
  }
  
  sub interpret {
    my $self  = shift;

    $self->{'content_obj'}->interpret();

    return;
  }    
 
  sub get_out {
    my $self  = shift;

    return $self->{'content_obj'}->get_out();
  }

  sub out {
    my $self  = shift;

    if ( ! $self->{'content_obj'}->{'is_binary'} ) {
      while ( $self->{'content_obj'}->{'out'} =~ s/{:(\s*(\$|\*|\~|sql|\%|inc|\#|\&|nes).+?):}//gsio ) 
      { 
        # impedir que los tags con error o no reemplazados aparezcan en la salida 
      }
    }

    $self->{'content_obj'}->out();

    return;
  }

}


{

  package nes_content;
  use vars qw(@ISA);
  @ISA = qw( Nes );

  sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();
    my ($container) = @_;

    $self->{'container'}   = $container;
    $self->{'file_script'} = $self->{'container'}->{'file_script'};
    $self->{'out'}         = $self->{'container'}->{'out'};

    # default content type
    $self->{'Content-type'} = "Content-type: text/html";
    $self->{'HTTP-status'}  = "200 Ok";
    $self->{'X-Powered-By'} = "Nes/$VERSION";
    $self->{'TAG_HTTP-headers'} = '';
    
    return $self;
  }

  sub add_tags {
    my $self  = shift;
    my %tags;
    (%tags) = @_;

    foreach my $tag ( keys %tags ) {
      $self->{'tags'}{$tag} = $tags{$tag};
    }
    
    $self->{'TAG_HTTP-headers'} = $self->{'tags'}{'HTTP-headers'};
    $self->{'tags'}{'HTTP-headers'} = undef;

    return;
  }

  sub set_tags {
    my $self  = shift;
    my %tags;
    (%tags) = @_;

    foreach my $tag ( keys %tags ) {
      $self->{'tags'}{$tag} = $tags{$tag};
    }
    
    $self->{'TAG_HTTP-headers'} = $self->{'tags'}{'HTTP-headers'};
    $self->{'tags'}{'HTTP-headers'} = undef;    

    return;
  }
  
  sub interpret {
    my $self  = shift;
    my %tags;

    $self->{'interpret'} = nes_interpret->new( $self->{'out'} );
    $self->{'out'} = $self->{'interpret'}->go( %{ $self->{'tags'} } );

    return;
  }

  sub get_out {
    my $self  = shift;

    return $self->{'out'};
  }
  
  sub set_out {
    my $self  = shift;
    my ($out) = @_;

    $self->{'out'} = $out;
    
    return;
  }  
  
  sub go_plugin_first {
    my $self  = shift;
    
    my $self_file = $self->{'container'}->{'file_name'};
    my $top_file  = $self->{'top_container'}->{'file'};    
    
    if ( $self_file eq $top_file ) {
      foreach my $plugin ( @{$self->{'CFG'}{'auto_load_plugin_top_first'}} ) {
        my $interpret = nes_interpret->new( $plugin );
        $plugin = $interpret->go( %{ $self->{'tags'} } );
        $self->do_script( $plugin );       
      }
    }    

    foreach my $plugin ( @{$self->{'CFG'}{'auto_load_plugin_all_first'}} ) {
      my $interpret = nes_interpret->new( $plugin );
      $plugin = $interpret->go( %{ $self->{'tags'} } );
      $self->do_script( $plugin );       
    }

    return;
  }

  sub go_plugin_last {
    my $self  = shift;
    
    my $self_file = $self->{'container'}->{'file_name'};
    my $top_file  = $self->{'top_container'}->{'file'};    

    if ( $self_file eq $top_file ) {
      foreach my $plugin ( @{$self->{'CFG'}{'auto_load_plugin_top_last'}} ) {
        my $interpret = nes_interpret->new( $plugin );
        $plugin = $interpret->go( %{ $self->{'tags'} } );
        $self->do_script( $plugin );       
      }
    }
    
    foreach my $plugin ( @{$self->{'CFG'}{'auto_load_plugin_all_last'}} ) {
      my $interpret = nes_interpret->new( $plugin );
      $plugin = $interpret->go( %{ $self->{'tags'} } );
      $self->do_script( $plugin );       
    } 

    return;
  }

  sub go {
    my $self  = shift;
    
    $self->go_plugin_first();
  
    foreach my $script ( @{ $self->{'file_script'} } ) {
      if ( $script eq 'none' ) {
        do {
          my $nes_obj = Nes::Singleton->new();
          $nes_obj->out();
        };
        next;
      }
      if ( $script ) {   
        $self->do_script( $script ); 
      }
    }
   
    $self->go_plugin_last();
      
    return;
  }
  
  sub do_script {

    my $self  = shift;
    my ($script) = @_;

    $script = $self->{'top_container'}->get_file_path( $script );
    
    my $script_dir = $script;
    $script_dir =~ s/(.*)(\\|\/).*/$1/;
    push( @INC, $script_dir ) if !$self->{'top_container'}->{'in_inc'}->{$script_dir};
    $self->{'top_container'}->{'in_inc'}->{$script_dir} = 1;

    my $return = do $script;
    unless ($return) {
      
      # mod_perl muestra un error cuando se usa exit
      return if $@ =~ /ModPerl::Util::exit/;
      
      warn "couldn't parse $script: $@" if $@;
      warn "couldn't do $script: $!" unless defined $return;
      warn "couldn't run $script" unless $return;
    }  

    return;
  }
  
  sub out {
    my $self  = shift;
   
    print $self->{'cookies'}->out;
    print "X-Powered-By: $self->{'X-Powered-By'}\n";
#    print "Status: $self->{'HTTP-status'}\n" if !$self->{'tags'}{'HTTP-headers'};
    print $self->{'TAG_HTTP-headers'} || $self->{'Content-type'}."\n\n";
    print $self->{'out'};

  }
  
  sub location {
    my $self  = shift;
    my ($location, $status) = @_;
    $status = "302 Found" if !$status;

    print $self->{'cookies'}->out;
    print "X-Powered-By: $self->{'X-Powered-By'}\n";
    print "Status: $status\n";
    print "Location: $location\n\n";
    exit;
  }

}

{

  package nes_html;
  use vars qw(@ISA);
  @ISA = qw( nes_content );

  sub new {
    my $class = shift;
    my ( $container ) = @_;
    my $self = $class->SUPER::new($container);

    $self->{'Content-type'} = "Content-type: text/html";

    return $self;
  }
  
}


{

  package nes_nsql;
  use vars qw(@ISA);
  @ISA = qw( nes_content );

  sub new {
    my $class = shift;
    my ( $container ) = @_;
    my $self = $class->SUPER::new($container);

#    @{ $self->{'file_script'} } = @scripts;
    $self->{'Content-type'} = "Content-type: text/html";

    return $self;
  }
  
}


{

  package nes_txt;
  use vars qw(@ISA);
  @ISA = qw( nes_content );

  sub new {
    my $class = shift;
    my ( $container ) = @_;
    my $self = $class->SUPER::new($container);

#    @{ $self->{'file_script'} } = @scripts;
    $self->{'Content-type'} = "Content-type: text/plain";

    return $self;
  }
   
}


{

  package nes_perl;
  use vars qw(@ISA);
  @ISA = qw( nes_content );

  sub new {
    my $class = shift;
    my ( $container ) = @_;
    my $self = $class->SUPER::new($container);

#    @{ $self->{'file_script'} } = @scripts;
    $self->{'Content-type'} = "Content-type: text/html";

    return $self;
  }
  
  sub go {
    my $self  = shift;
 
    $self->SUPER::go() if @{ $self->{'file_script'} };
    
    require IO::String;
    my $out;
    my $str_fh = IO::String->new($out);
    my $old_fh = select($str_fh);

    eval $self->{'out'};

    select($old_fh) if defined $old_fh;
    
    $self->{'out'} = $out;
    
    return;

  }

}


{

  package nes_shell;
  use vars qw(@ISA);
  @ISA = qw( nes_content );

  sub new {
    my $class = shift;
    my ( $container ) = @_;
    my $self = $class->SUPER::new($container);

#    @{ $self->{'file_script'} } = @scripts;
    $self->{'Content-type'} = "Content-type: text/html";

    return ($self);
  }

  sub go {
    my $self  = shift;

    $self->SUPER::go() if @{ $self->{'file_script'} };

    if ( $MOD_PERL ) {

      require IPC::Run;
      # IPC::Open2/Open3 no funcionan con mod_perl
      
      local $| = 1;
      my @command = ( $self->{'CFG'}{'shell_cline'} );
      my ( $writer, $reader, $error );
      my $h = IPC::Run::start (\@command, \$writer, \$reader, \$error, IPC::Run::timeout( 10 ));
      $writer =  $self->{'out'} || "\n";
      IPC::Run::pump $h;
      IPC::Run::finish $h;
      $self->{'out'} = $reader;
  
    } else {
      
      require IPC::Open3;
      my ( $writer, $reader, $error );   
      my $pid = IPC::Open3::open3( $writer, $reader, $error, "$self->{'CFG'}{'shell_cline'}" );
      print $writer $self->{'out'};
      close $writer;
      $self->{'out'} = '';
      while (<$reader>) {
        $self->{'out'} .= $_;
      }
      close $reader;
      waitpid( $pid, 0 );      
      
    }
    
    return;
  }

}


{ 

  package nes_php;
  use vars qw(@ISA);
  @ISA = qw( nes_content );

  sub new {
    my $class = shift;
    my ( $container ) = @_;
    my $self = $class->SUPER::new($container);

#    @{ $self->{'file_script'} } = @scripts;
    $self->{'Content-type'} = "Content-type: text/html";
    $self->{'is_binary'} = 0;
    $self->{'file_name'} = $self->{'container'}->{'file_name'};
    
    $self->{'php_wrapper'} = 0;
    $self->{'php_wrapper'} = 1 if $self->{'file_name'} eq $self->{'top_container'}->{'file'};
    
    # damos soporte a include PHP al método GET
    $self->{'start_script'} = '<?php parse_str($_SERVER[\'QUERY_STRING\'], $_GET); ?>'."\n";
    
    return ($self);
  }

  sub go {
    my $self  = shift;

    $self->SUPER::go() if !$self->{'php_wrapper'};

    my $cline       = $self->{'CFG'}{'php_cline'};
    $cline          = $self->{'CFG'}{'php_cgi_cline'} if $self->{'php_wrapper'};

    if ( $self->{'php_wrapper'} || $MOD_PERL ) {    
      # por seguridad 
      require Env::C;
      foreach (keys %ENV) {
        my $var = $ENV{$_};
        utl::no_nes_remove(\$var);
        Env::C::setenv( $_, $var );
      }
    }
    
    
    if ( $MOD_PERL ) {
      
      local $| = 1;
      require IPC::Run;
      
      my @command = split(' ', $cline );
      my ( $writer, $reader, $error );
      my $h = IPC::Run::start (\@command, \$writer, \$reader, \$error, IPC::Run::timeout( 30 ));

      if ( $self->{'php_wrapper'} ) {
        if ( $ENV{'REQUEST_METHOD'} ne 'GET' ) {
          if ( $self->{'query'}->{'save_buffer'} ) {
            # todo: es posible que esto consuma mucha memoria en POST grandes
            # $writer .= $buffer; sin IPC::Run::pump, pero haciendo pump da 
            # errores en mod_perl, comprobar
            while ( my $buffer = $self->{'query'}->get_buffer ) {
              $writer .= $buffer;
            }
          } else {
            $writer = $self->{'query'}->get_buffer_raw;
          }
        }
      } else {
        # include PHP no soporta el metodo POST, de momento
        $writer = $self->{'start_script'}.$self->{'out'};
      }    

      IPC::Run::pump $h;
      IPC::Run::finish $h;
      $self->{'out'} = $reader; 
      warn $error if $error; 

    } else {

      require IPC::Open3;
      my ( $writer, $reader, $error, $out_error );
      my $pid = IPC::Open3::open3( $writer, $reader, $error, $cline );
      
      binmode $writer;
      binmode $reader;

      if ( $self->{'php_wrapper'} ) {
        if ( $ENV{'REQUEST_METHOD'} ne 'GET' ) {
          if ( $self->{'query'}->{'save_buffer'} ) {
            while ( my $buffer = $self->{'query'}->get_buffer ) {
              print $writer $buffer;
            }
          } else {
            print $writer $self->{'query'}->get_buffer_raw;
          }
        }
      } else {
        # include PHP no soporta el metodo POST
        print $writer $self->{'start_script'}.$self->{'out'};
      }
      close $writer;

      my $buffer;
      $self->{'out'} = '';
      while ( read($reader, $buffer, 8190) ) {
        $self->{'out'} .= $buffer;
      }
      close $reader;
      waitpid( $pid, 0 );
    }  

    if ( $self->{'php_wrapper'} ) {
      ( $self->{'HTTP-headers'}, $self->{'out'} ) = split(/$CRLF$CRLF/, $self->{'out'},2);
      $self->{'is_binary'} = $self->{'HTTP-headers'} !~ /Content-Type: text/is;
      $self->SUPER::go() if !$self->{'is_binary'};
    }

    return;
  }
    
  sub out {
    my $self  = shift;

    binmode STDOUT;
    print $self->{'cookies'}->out;
    print "X-Powered-By: $self->{'X-Powered-By'}\n";
#    print "Status: $self->{'HTTP-status'}\n" if !$self->{'tags'}{'HTTP-headers'};
#    print $self->{'TAG_HTTP-headers'} || $self->{'Content-type'}."\n\n";
    print $self->{'HTTP-headers'}."\n\n" if !$self->{'TAG_HTTP-headers'};
    print $self->{'out'};

  }

}


{ 

  package nes_python;
  use vars qw(@ISA);
  @ISA = qw( nes_content );

  sub new {
    my $class = shift;
    my ( $container ) = @_;
    my $self = $class->SUPER::new($container);

#    @{ $self->{'file_script'} } = @scripts;
    $self->{'Content-type'} = "Content-type: text/html";
    $self->{'file_name'} = $self->{'container'}->{'file_name'};
#    $self->{'file_name'} = $file_name;
    
    return ($self);
  }

  sub go {
    my $self  = shift;

    $self->SUPER::go() if @{ $self->{'file_script'} };

    my $cline = $self->{'CFG'}{'python_cline'};
    my @command = ( $cline );

    if ( $MOD_PERL ) {

      require IPC::Run;
      # IPC::Open2/Open3 no funcionan con mod_perl
      # *** php_cgi no funciona con IPC::Run
      
      local $| = 1;
      my ( $writer, $reader, $error );
      my $h = IPC::Run::start (\@command, \$writer, \$reader, \$error, IPC::Run::timeout( 10 ));
      $writer = $self->{'out'} || "\n";
      IPC::Run::pump $h;
      IPC::Run::finish $h;
      $self->{'out'} = $reader;

    } else {

      require IPC::Open2;
      my ( $reader, $writer );     
      my $pid = IPC::Open2::open2( $reader, $writer, "@command" );
      print $writer $self->{'out'};
      close $writer;
      $self->{'out'} = '';
      while (<$reader>) {
        $self->{'out'} .= $_;
      }
      close $reader;
      waitpid( $pid, 0 );
      
    }
    
    return;
  }
   
}

{

  package nes_js;
  use vars qw(@ISA);
  @ISA = qw( nes_content );

  sub new {
    my $class = shift;
    my ( $container ) = @_;
    my $self = $class->SUPER::new($container);

    $self->{'Content-type'} = "Content-type: text/javascript";

    return $self;
  }
  
}

# lo intenta como si fuese un archivo de texto plano
{

  package nes_unknown;
  use vars qw(@ISA);
  @ISA = qw( nes_content );

  sub new {
    my $class = shift;
    my ($container) = @_;
    my $self  = $class->SUPER::new($container);
    
    $self->{'Content-type'} = "Content-type: text/plain";

    return ($self);
  }

}


{

  package nes_interpret;
  use vars qw(@ISA);
  @ISA = qw( Nes );

  sub new {
    my $class = shift;
    my ($out) = @_;
    my $self  = $class->SUPER::new();

    $self->{'tag_start'} = '{:';
    $self->{'tag_end'}   = ':}';
    $self->{'pre_start'} = '〈';
    $self->{'pre_end'}   = '〉';    
    
    $self->{'tag_nes'}   = 'NES';

    $self->{'tag_var'}     = '\$';
    $self->{'tag_env'}     = '\*';
    $self->{'tag_expre'}   = '\~';
    $self->{'tag_tpl'}     = '\@';
    $self->{'tag_sql'}     = 'sql';
    $self->{'tag_hash'}    = '\%';
    $self->{'tag_field'}   = '\@\$';
    $self->{'tag_include'} = 'include';
    $self->{'tag_comment'} = '\#';
    $self->{'tag_plugin'}  = '\&';
    
    $self->{'pre_subs_start'} = ':&rang;:';
    $self->{'pre_subs_end'}   = ':&loz;:';

    $self->{'out'} = $out;
    $self->preformat() if $out;

    # banderas para eliminar de las variables código malicioso
    $self->{'security_options'}{'no_sql'}   = 0;
    $self->{'security_options'}{'no_html'}  = 1;
    $self->{'security_options'}{'no_br'}    = 0;
    $self->{'security_options'}{'no_nes'}   = 1;

    return $self;
  }

  sub preformat {
    my $self  = shift;

    my $reg_block;
    my $reg_param;
    my $reg_tag;
    my $all_tag;
    my $reg_tag_plugin;
    my $param_bracket;
    my $comment;

    no warnings;
    use re 'eval';
    $reg_block = qr/
                      (          
                          $self->{'pre_start'}       
                            (?>                
                            (?> [^$self->{'pre_start'}$self->{'pre_end'}]+ )  
                          |                 
                            (??{$reg_block})       
                            )*               
                          $self->{'pre_end'}
                      )
                      ( ?)             
                 /ix;
                 
    $param_bracket = qr/
                          (                    
                           \(             # parametros con paréntesis
                              (?>                
                              (?> [^\(\)]+ ) 
                            |                 
                              (??{$param_bracket})       
                              )*               
                           \)
                            |
                            [^\(\)]\S*   # o sin paréntesis
                          )                     
                    /ix;

    $reg_tag = qr/
                    ^\s*$self->{'pre_start'}\s*
                    (
                    $self->{'tag_var'}    |
                    $self->{'tag_env'}    |
                    $self->{'tag_expre'}  |
                    $self->{'tag_tpl'}    |
                    $self->{'tag_sql'}    |
                    $self->{'tag_field'}  |
                    $self->{'tag_hash'}   |
                    $self->{'tag_plugin'} |
                    $self->{'tag_include'} 
                    )\s*
                    $param_bracket
                    (.*)
                    \s*$self->{'pre_end'}\s*$
                /isx;
                
    $reg_tag_plugin = qr{(?six)
                        ^\s*$self->{'pre_start'}\s*
                            $self->{'tag_plugin'} 
                            \s*
                            (\S+)                           # tag del plugin
                            \s*
                            $param_bracket                  # parametros
                            (.*)                            # code
                        $self->{'pre_end'}\s*$
                        };

    $comment = qr/
                      (          
                          $self->{'pre_start'}\s*$self->{'tag_comment'}      
                            (?>                
                            (?> [^$self->{'pre_start'}$self->{'pre_end'}]+ )  
                          |                 
                            (??{$reg_block})       
                            )*               
                          $self->{'pre_end'}
                      )
                      ( ?)(\s*)             
                 /ix;

    $self->{'blocks'}        = $reg_block;
    $self->{'block_tag'}     = $reg_tag;
    $self->{'block_plugin'}  = $reg_tag_plugin;
    $self->{'param_bracket'} = $param_bracket;
    $self->{'block_comment'} = $comment;

    $self->{'out'} =~ s/$self->{'pre_start'}/$self->{'pre_subs_start'}/g;
    $self->{'out'} =~ s/$self->{'pre_end'}/$self->{'pre_subs_end'}/g;

    $self->{'out'} =~ s/$self->{'tag_start'}/$self->{'pre_start'}/g;
    $self->{'out'} =~ s/$self->{'tag_end'}/$self->{'pre_end'}/g;

    # elimina los comentarios, eliminándolos aquí ahorramos CPU
    $self->{'out'} =~ s/$self->{'block_comment'}//g;

    return;
  }

  sub clear_tags {
    my $self  = shift;

    $self->{'out'} =~ s/$self->{'blocks'}//g;
    
#    $self->{'out'} =~ s/$self->{'pre_start'}/$self->{'tag_start'}/g;
#    $self->{'out'} =~ s/$self->{'pre_end'}/$self->{'tag_end'}/g;
#
#    $self->{'out'} =~ s/$self->{'pre_subs_start'}/$self->{'pre_start'}/g;
#    $self->{'out'} =~ s/$self->{'pre_subs_end'}/$self->{'pre_end'}/g;    

    return;
  }

  sub postformat {
    my $self  = shift;
    my ($out) = @_;

    $out =~ s/$self->{'pre_start'}/$self->{'tag_start'}/g;
    $out =~ s/$self->{'pre_end'}/$self->{'tag_end'}/g;

    $out =~ s/$self->{'pre_subs_start'}/$self->{'pre_start'}/g;
    $out =~ s/$self->{'pre_subs_end'}/$self->{'pre_end'}/g;

    return $out;
  }
  
  sub postformat2 {
    my $self  = shift;

    $self->{'out'} =~ s/$self->{'pre_start'}/$self->{'tag_start'}/g;
    $self->{'out'} =~ s/$self->{'pre_end'}/$self->{'tag_end'}/g;

    $self->{'out'} =~ s/$self->{'pre_subs_start'}/$self->{'pre_start'}/g;
    $self->{'out'} =~ s/$self->{'pre_subs_end'}/$self->{'pre_end'}/g;

    return;
  }  

  sub go {
    my $self  = shift;
    my (%tags) = @_;

    foreach my $tag ( keys %tags ) {
      $self->{'tags'}{$tag} = $tags{$tag};
    }

    while ( $self->{'out'} =~ s/$self->{'blocks'}/$self->replace_block($1,($2 || ''),($3 || ''))/e ) {

      # con los "$space" se "intenta" dejar el HTML como estaba sin huecos
      # $self->replace_block($1).$2.$3.$4 No funciona, $1... pierden su valor
      # cuando vuelven de la función
      # $2.$3.$4$self->replace_block($1) Sí funcionaría, curiosamente?
    }

    $self->postformat2;
    return $self->{'out'};
  }

  sub param_block {
    my $self  = shift;
    my ($params,$skip_inclusion) = @_;

    return if !$params;

    # los parámetros pueden tener estos formatos:
    # parámetro:
    #   sin paréntesis, sin comomillas, sin espacios, un sólo parámetro
    # (parámetro,parámetro):
    #   con paréntesis, sin espacios, con o sin comillas, uno o más parámetros
    #   separados por comas
    # ('parámetro uno','parámetro,dos'):
    #   comillas necesarias cuando hay espacios o comas en los parámetros.
    # ('parámetro \'uno'):
    #   las comillas requieren barra invertida
    # las comillas dobles no se utilizan, se reservan para su uso en futuras
    # versiones, requieren barra invertida.
    
    # 1.02.2 soporte para dobles comillas en parámetros:
    # ("parámetro \"uno\"", "parámetro 'dos'"):

    $params =~ s/^\s*\(//;
    $params =~ s/\)\s*$//;
    my @param;
    my $this = '';
    while ( $params =~ s/\s*"([^\"\\]*(?:\\.[^\"\\]*)*)"\s*,?|\s*'([^\'\\]*(?:\\.[^\'\\]*)*)'\s*,?|\s*([^,\s]+)\s*,?|\s*,// ) {
      $this = $+;
      $this =~ s/\\'/'/g if $this;
      $this =~ s/\\"/"/g if $this;

      if ( !$skip_inclusion ) { # Permite la inclusión en los parámetros
        if ($this =~ /$self->{'pre_start'}/) {
          my $interpret = nes_interpret->new( $self->postformat($this) );
          $this = $interpret->go( %{ $self->{'tags'} } );
        }
        if ($this =~ /$self->{'tag_start'}/) {
          my $interpret = nes_interpret->new( $this );
          $this = $interpret->go( %{ $self->{'tags'} } );
        }
      }   
 
      push @param, $this;
    }

    return @param;
  }

  sub replace_block {
    my $self  = shift;
    my ( $block, $space1, $space2 ) = @_;
    my ( $tag, $params, $code ) = $block =~ /$self->{'block_tag'}/;
    my $out;

    if ( $tag =~ /^$self->{'tag_expre'}$/ ) {

      $out = $self->replace_expre( $code, $params );

    } elsif ( $tag =~ /^$self->{'tag_tpl'}$/ ) {

      $out = $self->replace_tpl( $code, $self->param_block($params) );

    } elsif ( $tag =~ /^$self->{'tag_sql'}$/ ) {

      $out = $self->replace_nsql( $code, $self->param_block($params,1) );

    } elsif ( $tag =~ /^$self->{'tag_hash'}$/ ) {

      $out = $self->replace_hash( $code, $self->param_block($params) );

    } elsif ( $tag =~ /^$self->{'tag_include'}$/ ) {

      $out = $self->replace_ind( $self->param_block($params) );

    } elsif ( $tag =~ /^$self->{'tag_var'}$/ ) {

      $out = $self->replace_var( $self->param_block($params) );

    } elsif ( $tag =~ /^$self->{'tag_env'}$/ ) {

      $out = $self->replace_env( $self->param_block($params) );

    } elsif ( $tag =~ /^$self->{'tag_plugin'}$/ ) {

      $out = $self->replace_plugin( $block, $space1, $space2 );

    } else {

      # si no conoce el tag lo deja como estaba
      $block =~ s/(^\s*)($self->{'pre_start'})/$1$self->{'tag_start'}/g;
      $block =~ s/($self->{'pre_end'})(\s*$)/$self->{'tag_end'}$2/g;

      return $block;
    }

    $out .= $space1;
    return $out;
  }

  sub security {
    my $self  = shift;
    my ($value, @security_options) = @_;

    return $value if $value =~ /^\d*$/;

    my $tmp_no_html = $self->{'security_options'}{'no_html'};
    my $tmp_no_nes  = $self->{'security_options'}{'no_nes'};
    my $tmp_no_br   = $self->{'security_options'}{'no_br'};
    my $tmp_no_sql  = $self->{'security_options'}{'no_sql'};    
    
    my @yes_tag;
    foreach my $key ( @security_options ) {
      my $val = 1;
      if ($key =~ /^yes_tag_(.*)/) {
        push(@yes_tag, $1);
      } else {  
        $val = 0 if $key =~ /^yes_/i;
        $key   =~ s/^yes_/no_/;
        $self->{'security_options'}{$key} = $val;
      }
    }
    push(@yes_tag, 'br') if !$self->{'security_options'}{'no_br'};
    
    $value = utl::quote($value)        if $self->{'security_options'}{'no_sql'};
    $value = utl::no_nes($value)    if $self->{'security_options'}{'no_nes'};
    $value = utl::no_html( $value, @yes_tag ) if $self->{'security_options'}{'no_html'};

    $self->{'security_options'}{'no_html'} = $tmp_no_html;
    $self->{'security_options'}{'no_nes'}  = $tmp_no_nes;
    $self->{'security_options'}{'no_br'}   = $tmp_no_br;
    $self->{'security_options'}{'no_sql'}  = $tmp_no_sql;      

    return $value;
  }

  sub replace_NES {
    my $self  = shift;
    my ($block) = @_;

    return if !$block =~ /$self->{'tag_start'}\s*$self->{'tag_nes'}/;

    my $tagnes = qr{(?ix)
                     $self->{'tag_start'}\s*$self->{'tag_nes'}
                     \s*([^\s]*)\s*                             # vesión
                     (.*)                                       # parametros
                     \s*
                     $self->{'tag_end'}
                 };

    my ( $version, $params ) = $block =~ /$tagnes/;
    my @param = $self->param_block($params);

    unshift( @param, $version );

    return @param;
  }

  sub replace_var {
    my $self  = shift;
    my ($var, @security_options) = @_;

    return $self->security( $self->{'tags'}{$var}, @security_options );
  }

  sub replace_expre {
    my $self  = shift;
    my ( $code, $expre ) = @_;

    $expre =~ s/\$/:-:var:-:/g;
    $expre =~ s/\*/:-:env:-:/g;

    my $nodef = undef;
    my %vars;
    my $reg = qr{(?x) ((:-:var:-:|:-:env:-:)\s*(\w*)) };

    while ( $expre =~ /$reg/ ) {
      my $tvar = $1;
      my $tag  = $2;
      my $var  = $3;
      if ( $tag =~ /^:-:var:-:$/ ) {

        if ( defined $self->{'tags'}{$var} ) {
          $vars{$var} = $self->{'tags'}{$var};
          $expre =~ s/$reg/\$vars\{\'$var\'\}/;
          next;
        } else {
          $expre =~ s/$reg/\$nodef/;
          next;
        }

      }
      if ( $tag =~ /^:-:env:-:$/ ) {

        if ( defined $self->{'top_container'}->{'nes_env'}{$var} ) {
          $vars{$var} = $self->{'top_container'}->{'nes_env'}{$var};
          $expre =~ s/$reg/\$vars\{\'$var\'\}/;
          next;
        } else {
          $expre =~ s/$reg/\$nodef/;
          next;
        }

      }
    }

    return $code if ( eval $expre );
    return '';
  }

  sub replace_ind {
    my $self  = shift;
    my (@param) = @_;

    my $file = shift @param;

    my $obj_name = $file;
    $obj_name =~ s/.*\///;
    $obj_name =~ s/\.[^\.]*$//;
    
    unless ( $file ) {
      warn "Void include in $self->{'container'}->{'file_name'}";
      return '';
    }    

    my $count = 0;
    $self->{'top_container'}->set_nes_env( 'q_obj_param_' . $count, $obj_name );
    $self->{'query'}->set( 'obj_param_' . $count, $obj_name );
    foreach my $this (@param) {
      $count++;
      $self->{'top_container'}->set_nes_env( 'q_' . $obj_name . '_param_' . $count, $this );
      $self->{'query'}->set( $obj_name . '_param_' . $count, $this );
    }

    my $container = nes_container->new($file);
    $container->go();
    
    $count = 0;
    $self->{'top_container'}->del_nes_env( 'q_obj_param_' . $count );
    $self->{'query'}->del( 'obj_param_' . $count );    
    foreach my $this (@param) {
      $count++;
      $self->{'top_container'}->del_nes_env( 'q_' . $obj_name . '_param_' . $count );
      $self->{'query'}->del( $obj_name . '_param_' . $count );
    }
    
    my $out = $container->get_out();
    $container->forget();

    return $out;
  }

  sub replace_hash {
    my $self  = shift;
    my ( $code, $name_hash ) = @_;
    $name_hash =~ s/\s*//g;

    if ( $name_hash =~ /$self->{'tag_field'}/ ) {
      $code =~ s/\s*(.+?)\.(\S*)\s*/$self->security($self->{'tags'}{$1}{$2})/egi;
      return $code;
    }

    my %hash = %{ $self->{'tags'}{$name_hash} };

    my $out_code;
    foreach my $key ( keys %hash ) {
      my $tmp_code = $code;
      $tmp_code =~ s/$self->{'pre_start'}\s*$self->{'tag_field'}\s*($name_hash\._name)\s*$self->{'pre_end'}/$self->security($key)/egi;
      $tmp_code =~ s/$self->{'pre_start'}\s*$self->{'tag_field'}\s*($name_hash\._value)\s*$self->{'pre_end'}/$self->security($hash{$key})/egi;
      $out_code .= $tmp_code;
    }

    return $out_code;
  }

  sub replace_nsql {
    my $self  = shift;
    my ( $code, $sql ) = @_;

    return if $sql !~ /^SELECT/;
    
    my $tmp_no_html = $self->{'security_options'}{'no_html'};
    my $tmp_no_nes  = $self->{'security_options'}{'no_nes'};
    my $tmp_no_br   = $self->{'security_options'}{'no_br'};
    my $tmp_no_sql  = $self->{'security_options'}{'no_sql'};        

    if ( $sql =~ /$self->{'pre_start'}/ ) {
      my $interpret = nes_interpret->new( $self->postformat($sql) );
      $interpret->{'security_options'}{'no_sql'} = 1;
      $sql = $interpret->go( %{ $self->{'tags'} } );
    }
    
    my $name     = $self->{'CFG'}{'DB_base'};
    my $user     = $self->{'CFG'}{'DB_user'};
    my $pass     = $self->{'CFG'}{'DB_pass'};
    my $driver   = $self->{'CFG'}{'DB_driver'};
    my $host     = $self->{'CFG'}{'DB_host'};
    my $port     = $self->{'CFG'}{'DB_port'};    

    require Nes::DB;
    my $obj_name = $self->{'query'}->{'q'}{'obj_param_0'};
    if ( $self->{'container'}->{'type'} eq 'nsql' ) {
      $name     = $self->{'query'}->{'q'}{ $obj_name . '_param_1' } || $self->{'CFG'}{'DB_base'};
      $user     = $self->{'query'}->{'q'}{ $obj_name . '_param_2' } || $self->{'CFG'}{'DB_user'};
      $pass     = $self->{'query'}->{'q'}{ $obj_name . '_param_3' } || $self->{'CFG'}{'DB_pass'};
      $driver   = $self->{'query'}->{'q'}{ $obj_name . '_param_4' } || $self->{'CFG'}{'DB_driver'};
      $host     = $self->{'query'}->{'q'}{ $obj_name . '_param_5' } || $self->{'CFG'}{'DB_host'};
      $port     = $self->{'query'}->{'q'}{ $obj_name . '_param_6' } || $self->{'CFG'}{'DB_port'};
    }

    my $base = Nes::DB->new( $name, $user, $pass, $driver, $host, $port ); 
    my @result = $base->sen_select($sql);
    
    $self->{'top_container'}->set_nes_env( 'DBnes_error_last_error', $base->{'errstr'} );
    $self->{'top_container'}->set_nes_env( 'DBnes_rows', $base->{'rows'} );

    $self->{'security_options'}{'no_nes'}  = 1;
    $self->{'security_options'}{'no_html'} = 1;

    my $out_code;
    foreach my $reg (@result) {
      my $tmp_code = $code;
      $tmp_code =~ s/$self->{'pre_start'}\s*$self->{'tag_field'}\s*($self->{'param_bracket'})\s*$self->{'pre_end'}/$self->replace_field($reg,'\S*',$1)/egi;
      $out_code .= $tmp_code;
    }

    $self->{'security_options'}{'no_html'} = $tmp_no_html;
    $self->{'security_options'}{'no_nes'}  = $tmp_no_nes;
    $self->{'security_options'}{'no_br'}   = $tmp_no_br;
    $self->{'security_options'}{'no_sql'}  = $tmp_no_sql;      

    return $out_code;
  }
  
  sub replace_tpl {
    my $self  = shift;
    my ( $code, $name ) = @_;

    my $out_code;
    foreach my $reg ( @{ $self->{'tags'}{$name} } ) {
      my $tmp_code = $code;
      $tmp_code =~ s/$self->{'pre_start'}\s*$self->{'tag_field'}\s*($self->{'param_bracket'})\s*$self->{'pre_end'}/$self->replace_field($reg,$name,$1)/egi;
      $out_code .= $tmp_code;
    }

    return $out_code;
  }
  
  sub replace_field {
    my $self  = shift;
    my ( $reg, $name, $params ) = @_;
    my @param = $self->param_block($params);

    my $var = shift @param;
    $var =~ s/$name\.//;

    return $self->security($reg->{$var},@param);
  }  

  sub replace_env {
    my $self  = shift;
    my ($var, @security_options) = @_;

    my $tmp_no_html = $self->{'security_options'}{'no_html'};
    my $tmp_no_nes  = $self->{'security_options'}{'no_nes'};

    # comportamiento por defecto:
    $self->{'security_options'}{'no_html'} = 1 if $var =~ /^q_/;
    $self->{'security_options'}{'no_nes'}  = 1 if $var =~ /^q_/;

    $var = $self->security( $self->{'top_container'}->get_nes_env($var), @security_options );

    $self->{'security_options'}{'no_html'} = $tmp_no_html;
    $self->{'security_options'}{'no_nes'}  = $tmp_no_nes;

    return $var;
  }
  
  sub replace_plugin {
    my $self  = shift;
    my ( $block, $space1, $space2 ) = @_;
    my ( $tag, $params, $code ) = $block =~ /$self->{'block_plugin'}/;
    my $out;
    my ( @register_tags ) = $self->{'register'}->get_tags();

    foreach my $tag_plugin ( @register_tags ) { 
      if ( $tag =~ /^$tag_plugin$/i ) {
        my $handler = $self->{'register'}->get_tag_handler($tag_plugin);
        if ( !$handler ) {
          warn "No handler for plugin Tag: $tag_plugin ";
          next;
        }       
        $out = $handler->( $code,$self->param_block($params) );
        return $out;
      } 
    }
    
    return '';    
  }  

}


{

  package utl;

  sub get_file_path {

    use FindBin qw($Bin $Script);
    my $file = $ENV{'PATH_TRANSLATED'} || $ENV{'SCRIPT_FILENAME'} || "$Bin\\$Script";

    return $file;
  }

  sub get_file_dir {

    use FindBin qw($Bin $Script);
    my $dir = $ENV{'PATH_TRANSLATED'} || $ENV{'SCRIPT_FILENAME'} || "$Bin\\$Script";
    $dir =~ s/(.*)(\\|\/).*/$1/;

    return $dir;
  }

  sub get_root_dir {

    use FindBin '$Bin';
    my ($root_dir) = split( "$ENV{'PATH_INFO'}", $ENV{'PATH_TRANSLATED'} );
    my $dir = $root_dir || $Bin;    # en entornos no cgi da el directorio en el que se ejecuta el script o directorio de trabajo
    $dir =~ s/[\/\\]$//;

    return $dir;
  }

  sub expires {
    my ($expire) = @_;

    my (@MON)   = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
    my (@WDAY)  = qw/Sun Mon Tue Wed Thu Fri Sat/;
    my (%formt) = (
      's' => 1,
      'm' => 60,
      'h' => 60 * 60,
      'd' => 60 * 60 * 24,
      'M' => 60 * 60 * 24 * 30,
      'y' => 60 * 60 * 24 * 365
    );

    $expire =~ /(\-?\d*)(.)/;
    my $second = $1;
    my $factor = $2;
    my $time   = time + ( $second * $formt{$factor} );
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday ) = gmtime($time);
    $year += 1900;

    return sprintf( "%s, %02d-%s-%04d %02d:%02d:%02d GMT", $WDAY[$wday], $mday, $MON[$mon], $year, $hour, $min, $sec );
  }
  
  sub expires_time {
    my ($expire) = @_;

    my (%formt) = (
      's' => 1,
      'm' => 60,
      'h' => 60 * 60,
      'd' => 60 * 60 * 24,
      'M' => 60 * 60 * 24 * 30,
      'y' => 60 * 60 * 24 * 365
    );

    $expire =~ /(\-?\d*)(.)/;
    my $second = $1 || 0;
    my $factor = $2 || 's';
    my $time   = $second * $formt{$factor};

    return $time;
  }  

  sub escape {
    my $string = shift;

    $string =~ s/(.)/'%'.sprintf("%X", ord($1))/ge;

    return $string;
  }

  sub js_escape {
    my $string = shift;

    use Encode qw(encode FB_PERLQQ);
    $string =~ s{([\x00-\x29\x2C\x3A-\x40\x5B-\x5E\x60\x7B-\x7F])}
                {'%' . uc(unpack('H2', $1))}eg;    # XXX JavaScript compatible
    $string = encode( 'ascii', $string, sub { sprintf '%%u%04X', $_[0] } );

    return $string;
  }

  sub js_unescape {
    my $escaped = shift;

    $escaped =~ s/%u([0-9a-f]+)/chr(hex($1))/eig;
    $escaped =~ s/%([0-9a-f]{2})/chr(hex($1))/eig;

    return $escaped;
  }
  
  sub quote {
    my ($value) = @_;

    require DBI;

    return DBD::_::db->quote($value);
  }

  sub no_html {
    my ( $value, @yes_tag ) = @_;
    
    return if !$value;

    my $tags = '';
    foreach my $tag (@yes_tag) {
      $tags .= '\/?'.$tag.'\W|';
    }
    $tags =~ s/\|$//;

    if (!$tags) {
      $value =~ s/\</&lt;/sg;
      $value =~ s/\>/&gt;/sg;
    } else {
      while ( $value =~ s/\<((?!$tags)[^\>\<]*)\>/&lt;$1&gt;/sig ) {}
    }

    return $value;
  }
  
  sub no_nes {
    my ($value) = @_;
    
    return if !$value;
    
    my $tags = qr/
                    \{:
                    (
                    \s*
                    (\$|\*|\~|sql|\%|inc|\#|\&|nes)
                    (.+?)
                    )
                    :\}
                 /six;
                 
    while ( $value =~ s/$tags/&#123;:$1:&#125;/go ) {}

    return $value;
  }

  sub no_nes_remove {
    my ($data) = @_;
    
    my $start = '(\{|\%7B)(\:|\%3A)';
    my $end   = '(?:\:|\%3A)(?:\%7D|\})';
    
    $$data =~ s/$start/{_/gis;
    $$data =~ s/$end/_}/gis;
    
    return;
  }  

  sub cleanup {
    my (@vars) = @_;
    
    if ( $MOD_PERL2 ) {
      require Apache2::RequestUtil;
      require Apache2::RequestIO;
      require APR::Pool;
      Apache2::RequestUtil->request->pool->cleanup_register(\&utl::cleanup_callback, @vars);

    }
      
    if ( $MOD_PERL1 ) {
      require Apache;
      Apache->request->register_cleanup(\&utl::cleanup_callback, @vars);
    }
    
    return 1;
  }
  
  sub cleanup_callback {
    my (@vars) = @_;
    
    foreach my $var (@vars) {
      my $ref = ref $var;
      undef $$var if $ref eq 'SCALAR' || $ref eq 'REF' ;
      undef %$var if $ref eq 'HASH';
      undef @$var if $ref eq 'ARRAY';
    }
  
    return 1;
  }  

}




1;
