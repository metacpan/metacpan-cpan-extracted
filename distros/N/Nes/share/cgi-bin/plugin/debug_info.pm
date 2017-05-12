#!/usr/bin/perl

# -----------------------------------------------------------------------------
#
#  NES by Skriptke
#  Copyright 2009 - 2010 Enrique F. Castañón
#  Licensed under the GNU GPL.
#
#  Sample:
#  http://nes.sourceforge.net/
#
#  Repository:
#  http://github.com/Skriptke/nes
# 
#  Version 1.00_01
#
#  debug_info.pm
#
# -----------------------------------------------------------------------------

use strict;
use Nes;

{

  package debug_info;
  use vars qw(@ISA);
  @ISA = qw( Nes );

  my $instance;
  
  sub new {
    my $class  = shift;
    my $plugin = nes_plugin->get_obj('debug_info');
    my $self   = $instance || $class->SUPER::new();
    my ($template) = @_;

    $self->{'first_time'} = 1;
    $self->init($template) if !$instance;
    $self->{'first_time'} = 0 if $instance; 
      
    $instance = $self;
    return $self;
  }

  sub init {
    my $self = shift;
    my ($template) = @_;
    
    $self->{'plugin'}    = nes_plugin->new( 'debug_info', 'debug_info', $self );
    $self->{'objects'}   = ();
    $self->{'template'}  = $template;
    $self->{'remote_ip'} = $self->{'top_container'}->get_nes_env('nes_remote_ip');
    
    use POSIX qw(strftime);
    my $gmt = POSIX::strftime( "%a %e %b %Y %H:%M:%S", gmtime );
    $self->{'starting'}  = "*----------------------------------";
    $self->{'starting'} .= "* debug_info starting at $gmt GMT *";
    $self->{'starting'} .= "----------------------------------*\n\n";    
    
    my $interpret = nes_interpret->new( $self->{'CFG'}->{'debug_info_template'} );
    $self->{'debug_info_template'} = $interpret->go();
    
    return;
  }
  
  sub add {
    my $self = shift;

    $self->{'obj'} = debug_obj->new;
    push( @{$self->{'objects'}}, $self->{'obj'} );
    
    $self->{'top'} = nes_top_container->new();  
    
    $self->{'top'}->{'container'} = nes_container->new($self->{'debug_info_template'});
    $self->{'top'}->{'container'}->set_tags(%{$self->{'obj'}->{'tags'}});
    $self->{'top'}->{'container'}->interpret(); 
    $self->{'obj'}->{'out'} = $self->{'top'}->{'container'}->get_out;
    $self->{'out'}         .= $self->{'obj'}->{'out'};
    
    $self->save;
    
    $self->{'top'}->{'container'}->forget();
    $self->{'top'}->forget();

    return;
  }
  
  sub save {
    my $self = shift;

    if ( $self->{'CFG'}->{'debug_info_save_to_log'} ) {
      open(my $log, '>>', $self->{'CFG'}->{'debug_info_save_to_log'}) || warn "couldn't open $self->{'CFG'}->{'debug_info_save_to_log'}";
      print $log $self->{'starting'} if $self->{'first_time'};
      print $log $self->{'obj'}->{'out'};
      close $log;
    }  

    return;
  }
  
  sub del_instance {
    my $self = shift;

    utl::cleanup(\$instance) if $ENV{'MOD_PERL'}; 

    return;
  }   
  
{

  package debug_obj;
  use vars qw(@ISA);
  @ISA = qw( Nes );

  sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();

    $self->{'tags'}              = {};
    $self->{'tags'}->{'cfg'}     = [ {} ];
    $self->{'tags'}->{'env_cgi'} = [ {} ];
    $self->{'tags'}->{'env_nes'} = [ {} ]; 
    $self->{'template'} = $self->{'container'};
    
    $self->add_top if $self->{'container'}->{'file_name'} eq $self->{'top_container'}->{'file'};
    $self->add;

    return $self;
  }
  
  sub add_top {
    my $self = shift;

    my $obj     = $self->{'template'};
    my $object  = $self->{'tags'};
    
    $object->{'top_template'} = 1;
    $object->{'url'} = $ENV{'SERVER_NAME'}.$ENV{'REQUEST_URI'};

    $object->{'GET'}   = $ENV{'QUERY_STRING'};
#    if ( $self->{'query'}->{'save_buffer'} ) {
#      while ( my $buffer = $self->{'query'}->get_buffer ) {
#        $object->{'POST'} .= $buffer;
#      }
#    } else {
      $object->{'POST'}  = $self->{'query'}->get_buffer_raw;
#    }    
    
    $object->{'cookies'} = $obj->{'cookies'}->out;
    $object->{'headers'} = $obj->{'content_obj'}->{'HTTP-headers'} || 
                           $obj->{'content_obj'}->{'TAG_HTTP-headers'} || 
                           $obj->{'content_obj'}->{'Content-type'};


    return;
  }  
  
  sub add {
    my $self = shift;

    my $obj = $self->{'template'};
    my $object  = $self->{'tags'};

    $object->{'object'}            = $obj->{'file_name'};
    $object->{'object_no_path'}    = $obj->{'file_name'};
    $object->{'object_no_path'}    =~ s/.*\///;
    $object->{'parent'}            = $obj->{'previous'}->{'file_name'};
    $object->{'type'}              = $obj->{'container'}->{'type'};
    $object->{'top_container_obj'} = $obj->{'top_container'};
    $object->{'container_obj'}     = $obj;
    $object->{'content_obj'}       = $obj->{'container'}->{'content_obj'};
    $object->{'interactions'}      = $obj->{'container'}->{'this_inter'};
    $object->{'scripts'}           = "@{ $obj->{'file_script'} }";
    $object->{'source'}            = $obj->{'container'}->{'file_nes_line'}."@{ $obj->{'container'}->{'file_souce'} }";
    $object->{'out'}               = $obj->get_out_content();
    use Data::Dumper;
    $Data::Dumper::Varname = 'Dumper_VARS';
    $Data::Dumper::Maxdepth = 2;
    $object->{'dumper_top'}        = Data::Dumper::Dumper($obj->{'top_container'});
    $object->{'dumper_container'}  = Data::Dumper::Dumper($obj->{'container'});
    $object->{'dumper_template'}   = Data::Dumper::Dumper($obj->{'container'}->{'content_obj'});
    $object->{'dumper_cookies'}    = Data::Dumper::Dumper($obj->{'cookies'});
    $object->{'dumper_session'}    = Data::Dumper::Dumper($obj->{'session'});
    $object->{'dumper_query'}      = Data::Dumper::Dumper($obj->{'query'});
    $object->{'dumper_CFG'}        = Data::Dumper::Dumper($obj->{'CFG'});
    $object->{'dumper_nes'}        = Data::Dumper::Dumper($obj->{'nes'});
    $Data::Dumper::Maxdepth = 5;
    $object->{'dumper_tags'}       = Data::Dumper::Dumper($obj->{'container'}->{'content_obj'}->{'tags'});
#    $object->{'unknown_tags'}      = $1 = $object->{'out'} =~ /({:[^}]*.?|[^{]*:})/g;
  
    $self->env();   

    return;
  }  

  sub env {
    my $self = shift;
    
    my $obj = $self->{'template'};
    
    my $cfg     = $self->{'tags'}->{'cfg'};
    my $env_cgi = $self->{'tags'}->{'env_cgi'};
    my $env_nes = $self->{'tags'}->{'env_nes'};

    my $c = 0;
    foreach my $key ( sort keys %{ $self->{'CFG'} } ) {
      my $value = $self->{'CFG'}->{$key};
      $value = "@{$self->{'CFG'}->{$key}}" if ref $self->{'CFG'}->{$key} eq 'ARRAY';
      $value = keys %{$self->{'CFG'}->{$key}} if ref $self->{'CFG'}->{$key} eq 'HASH';      
      $cfg->[$c]->{'key'}   = $key;
      $cfg->[$c]->{'value'} = $value;
      $cfg->[$c]->{'value'} = '***removed for safety***' if $key =~ /priv|pass/;
      $c++;
    }

    $c = 0;
    foreach my $key ( sort keys %ENV ) {
      $env_cgi->[$c]->{'key'}   = $key;
      $env_cgi->[$c]->{'value'} = $ENV{$key};
      $env_cgi->[$c]->{'value'} = '***removed for safety***' if $key =~ /priv|pass/;
      $c++;
    }    
    
    $c = 0;
    foreach my $key ( sort keys %{ $self->{'top_container'}->{'nes_env'} } ) {
      $env_nes->[$c]->{'key'}   = $key;
      $env_nes->[$c]->{'value'} = $self->{'top_container'}->{'nes_env'}{$key};
      $env_nes->[$c]->{'value'} = '***removed for safety***' if $key =~ /priv|pass/;
      $c++;
    }       
    
  }  

}  


}




# don't forget to return a true value from the file
1;

