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
#  file_upload.pl
#
# -----------------------------------------------------------------------------

  use strict;
  use Nes;
  
  my $nes     = Nes::Singleton->new();
  my $query   = $nes->{'query'};
  my $cfg     = $nes->{'CFG'};
  my $data    = '('.$query->{'q'}{'file_upload_param_1'}.')';
  my %vars    = eval "$data";
  my @thefiles;
  my $error = 0;
  
  $vars{'modal_loading'} = 'file_upload_loading.nhtml' if !exists $vars{'modal_loading'};
  $vars{'msg_loading'}   = 'Uploading file...' if !$vars{'msg_loading'};
  $vars{'msg_wait'}      = 'Please wait.' if !$vars{'msg_wait'};
  $vars{'msg_cancel'}    = 'Cancel' if !$vars{'msg_cancel'};
  $vars{'msg_error_max'} = '<img src="'.$cfg->{'img_dir'}.'/error_i.gif"> A file or whole post exceeding the size limit.' if !$vars{'msg_error_max'};
  $vars{'cancel_page'}   = 'http://'.$ENV{'SERVER_NAME'}.$ENV{'REQUEST_URI'} if !$vars{'cancel_page'};
  $vars{'p_loading'}     = '<p>'.$vars{'msg_loading'}.'<br><img src="/cgi-bin/nes/images/f_loading.gif"><br>'.$vars{'msg_wait'}.'</p>' if !$vars{'p_loading'};
  $vars{'p_cancel'}      = '<p><a href="'.$vars{'cancel_page'}.'"><small>'.$vars{'msg_cancel'}.'</small></a></p>' if !$vars{'p_cancel'};

  foreach my $this ( @{ $vars{'uploads'} } ) {
    $this->{'size'} = 10 if !$this->{'size'};
    $error = $vars{'error_max'} = $vars{'msg_error_max'} if $query->upload_max_size || $query->post_max_size;
    push(@thefiles, $this) if $query->{'q'}{$this->{'field_name'}};
  }

  if ( @thefiles && !$error ) {
   
    foreach my $this ( @thefiles ) {
      $this->{'filename'} = $query->get_upload_name($this->{'field_name'});
      to_dir($this) if $vars{'to_dir'};
    }
    
  }

  $nes->out(%vars);
  
  sub to_dir {
    my $file = shift;
    
    my $filename = $vars{'to_dir'}.'/'.$file->{'filename'};
    
    open(my $fh,'>',$filename) or warn "Can't write file : $file";
    binmode $fh;
    if ( $query->upload_is_tmp($file->{'field_name'}) ) {
      my $buffer;
      while ( $query->get_upload_buffer($file->{'field_name'},\$buffer) ) {
        print $fh $buffer;
      }
    } else {
      print $fh $query->{'q'}{$file->{'field_name'}};
    }
    close $fh;

  }
        

# don't forget to return a true value from the file
1;
