# ------------------------------------------------------------------------------
#
#  This is a patched version by Skriptke of CGI::Minimal ver 1.29 by
#  Benjamin Franz <snowhare@nihongo.org>
#  http://search.cpan.org/dist/CGI-Minimal/
#
#  Licensed under the GNU GPL.
#  http://nes.sourceforge.net/
# 
#  NES Version 1.03
#
#  Minimal.pm
#
# ------------------------------------------------------------------------------

package Nes::Minimal;

use strict;

# I don't 'use warnings;' here because it pulls in ~ 40Kbytes of code and
# interferes with 5.005 and earlier versions of Perl.
#
# I don't use vars qw ($_query $VERSION $form_initial_read $_BUFFER); for
# because it also pulls in warnings under later versions of perl.
# The code is clean - but the pragmas cause performance issues.

$Nes::Minimal::_query                   = undef;
$Nes::Minimal::form_initial_read        = undef;
$Nes::Minimal::_BUFFER                  = undef;
$Nes::Minimal::_allow_hybrid_post_get   = 0;
$Nes::Minimal::_mod_perl                = 0;
$Nes::Minimal::_no_subprocess_env       = 0;

$Nes::Minimal::_use_tmp                 = 0;
$Nes::Minimal::_max_upload              = 0;
$Nes::Minimal::_save_BUFFER             = undef;
$Nes::Minimal::_save_BUFFER_String      = undef;
$Nes::Minimal::_ERROR_max_upload        = 0;
$Nes::Minimal::_ERROR_max_post          = 0;
$Nes::Minimal::              = undef;

$Nes::Minimal::VERSION = "1.2902";

if (exists ($ENV{'MOD_PERL'}) && (0 == $Nes::Minimal::_mod_perl)) {
  local	$| = 1;
	my $env_mod_perl = $ENV{'MOD_PERL'};
	if ($env_mod_perl =~ m#^mod_perl/1.99#) { # Redhat's almost-but-not-quite ModPerl2....
		require Apache::compat;
		require Nes::Minimal::Misc;
		require Nes::Minimal::Multipart;
		$Nes::Minimal::_mod_perl = 1;

	} elsif (exists ($ENV{MOD_PERL_API_VERSION}) && ($ENV{MOD_PERL_API_VERSION} == 2)) {
		require Apache2::RequestUtil;
		require Apache2::RequestIO;
		require APR::Pool;
		require Nes::Minimal::Misc;
		require Nes::Minimal::Multipart;
		$Nes::Minimal::_mod_perl = 2;

	} else {
		require Apache;
		require Nes::Minimal::Misc;
		require Nes::Minimal::Multipart;
		$Nes::Minimal::_mod_perl = 1;
	}
}
binmode STDIN;
reset_globals();

####

sub import {
	my $class = shift;
	my %flags = map { $_ => 1 } @_;
	if ($flags{':preload'}) {
		require Nes::Minimal::Misc;
		require Nes::Minimal::Multipart;
	}
	$Nes::Minimal::_no_subprocess_env = $flags{':no_subprocess_env'};
}

####

sub new {
	my $proto = shift;
	my $pkg   = __PACKAGE__;

	if ($Nes::Minimal::form_initial_read) {
		binmode STDIN;
		$Nes::Minimal::_query->_read_form;
		$Nes::Minimal::form_initial_read = 0;
	}
	if (1 == $Nes::Minimal::_mod_perl) {
		Apache->request->register_cleanup(\&Nes::Minimal::reset_globals);

	} elsif (2 == $Nes::Minimal::_mod_perl) {
		Apache2::RequestUtil->request->pool->cleanup_register(\&Nes::Minimal::reset_globals);
	}

	return $Nes::Minimal::_query;
}

####

sub reset_globals {
	$Nes::Minimal::form_initial_read = 1;
	$Nes::Minimal::_allow_hybrid_post_get = 0;
	
	$Nes::Minimal::_save_BUFFER         = undef;
	$Nes::Minimal::_save_BUFFER_String  = undef;
  $Nes::Minimal::_use_tmp             = 0;
  $Nes::Minimal::_max_upload          = 0;
  $Nes::Minimal::_ERROR_max_upload    = 0;
  $Nes::Minimal::_ERROR_max_post      = 0;	
  $Nes::Minimal::_sub_filter           = undef;
	
	$Nes::Minimal::_query = {};
	bless $Nes::Minimal::_query;
	my $pkg = __PACKAGE__;

	$Nes::Minimal::_BUFFER = undef;
	max_read_size(1000000);
	$Nes::Minimal::_query->{$pkg}->{'field_names'} = [];
	$Nes::Minimal::_query->{$pkg}->{'field'} = {};
	$Nes::Minimal::_query->{$pkg}->{'form_truncated'} = undef;
	
	$Nes::Minimal::_query->{$pkg}->{'from_file'} = {};

	return 1; # Keeps mod_perl from complaining
}

# For backward compatibility 
sub _reset_globals { reset_globals; }

###

sub subprocess_env {
	if (2 == $Nes::Minimal::_mod_perl) {
		Apache2::RequestUtil->request->subprocess_env;
	}
}

###

sub allow_hybrid_post_get {
	if (@_ > 0) {
		$Nes::Minimal::_allow_hybrid_post_get = $_[0];
	} else {
		return $Nes::Minimal::_allow_hybrid_post_get;
	}
}

sub use_tmp {
  if (@_ > 0) {
    $Nes::Minimal::_use_tmp = $_[0];
  } else {
    return $$Nes::Minimal::_use_tmp;
  }
}

sub save_buffer {
  if (@_ > 0) {
    $Nes::Minimal::_save_BUFFER = $_[0];
  } else {
    return $$Nes::Minimal::_save_BUFFER;
  }
}

sub sub_filter {
  if (@_ > 0) {
    $Nes::Minimal::_sub_filter = $_[0];
  } else {
    return $Nes::Minimal::_sub_filter;
  }
}

sub max_upload {
  if (@_ > 0) {
    $Nes::Minimal::_max_upload = $_[0];
  } else {
    return $$Nes::Minimal::_max_upload;
  }
}



###

sub delete_all { 
	my $self = shift;
	my $pkg  = __PACKAGE__;
	$Nes::Minimal::_query->{$pkg}->{'field_names'} = [];
	$Nes::Minimal::_query->{$pkg}->{'field'} = {};
	$Nes::Minimal::_query->{$pkg}->{'from_file'} = {};
	return;
}

####

sub delete {
	my $self = shift;
	my $pkg  = __PACKAGE__;
	my $vars = $self->{$pkg};
	
	my @names_list   = @_;
	my %tagged_names = map { $_ => 1 } @names_list;
	my @parm_names   = @{$vars->{'field_names'}};
	my $fields       = [];
	my $data         = $vars->{'field'};
	foreach my $parm (@parm_names) {
		if ($tagged_names{$parm}) {
			delete $data->{$parm};
		} else {
			push (@$fields, $parm);
		}
	}
	$vars->{'field_names'} = $fields;
	return;
}

####

sub upload {
  my $self = shift;
  my $pkg = __PACKAGE__;
  my ($field_name) = @_;
  my $vars = $self->{$pkg};
  
  return if !defined($vars->{'field'}->{$field_name});
  return $vars->{'from_file'}->{'fh'}->{$field_name} if exists $vars->{'from_file'}->{'fh'}->{$field_name};
  
  # if not tmp file, the data is in var in old style =< 1.29
  if ( !$vars->{'from_file'}->{$field_name} ) {
    require IO::String;
    $vars->{'from_file'}->{'fh'}->{$field_name} = IO::String->new($vars->{'field'}->{$field_name}->{'value'}[0]);
  } else {
    $vars->{'from_file'}->{'fh'}->{$field_name} = $vars->{'from_file'}->{$field_name};
  }
  binmode $vars->{'from_file'}->{'fh'}->{$field_name};  

  return $vars->{'from_file'}->{'fh'}->{$field_name}; 
}

sub upload_is_tmp {
  my $self = shift;
  my $pkg = __PACKAGE__;
  my ($field_name) = @_;
  my $vars = $self->{$pkg};
  
  return 1 if $vars->{'from_file'}->{$field_name};
  return 0; 
}

sub upload_max_size {
  my $self = shift;
  my $pkg = __PACKAGE__;
  my $vars = $self->{$pkg};
  
  return 1 if $Nes::Minimal::_ERROR_max_upload;
  return 0; 
}

sub post_max_size {
  my $self = shift;
  my $pkg = __PACKAGE__;
  my $vars = $self->{$pkg};
  
  return 1 if $Nes::Minimal::_ERROR_max_post;
  return 0; 
}

####

sub param {
	my $self = shift;
	my $pkg = __PACKAGE__;

	if (1 < @_) {
		my $n_parms = @_;
		if (($n_parms % 2) == 1) {
			require Carp;
			Carp::confess("${pkg}::param() - Odd number of parameters (other than 1) passed");
		}

		my $parms = { @_ };
		require Nes::Minimal::Misc;
		$self->_internal_set($parms);
		return;

	} elsif ((1 == @_) and (ref ($_[0]) eq 'HASH')) {
		my $parms = shift;
		require Nes::Minimal::Misc;
		$self->_internal_set($parms);
		return;
	}

	# Requesting parameter values

	my $vars = $self->{$pkg};
	my @result = ();
	if ($#_ == -1) {
		@result = @{$vars->{'field_names'}};

	} else {
		my ($fname) = @_;
		if (defined($vars->{'field'}->{$fname})) {
			@result = @{$vars->{'field'}->{$fname}->{'value'}};
		}
	}

	if    (wantarray)     { return @result;    }
	elsif ($#result > -1) { return $result[0]; }
	return;
}

####

sub raw {
	return if (! defined $Nes::Minimal::_BUFFER);
	return $$Nes::Minimal::_BUFFER;
}

sub raw_saved {
  my $self = shift;
  my ( $buffer, $read_length ) = @_;
  
  my $fh = $Nes::Minimal::_BUFFER_saved || $Nes::Minimal::_save_BUFFER_String;
  
  return if !$fh;
  return read($fh, $$buffer, $read_length);
}

####

sub truncated {
	my $pkg = __PACKAGE__;
	shift->{$pkg}->{'form_truncated'};
}

####

sub max_read_size {
	my $pkg = __PACKAGE__;
	$Nes::Minimal::_query->{$pkg}->{'max_buffer'} = $_[0];
}

####
# Wrapper for form reading for GET, HEAD and POST methods

sub _read_form {
	my $self = shift;

	my $pkg  = __PACKAGE__;
	my $vars = $self->{$pkg};

	$vars->{'field'} = {};
	$vars->{'field_names'} = [];

	my $req_method=$ENV{"REQUEST_METHOD"};
	if ((2 == $Nes::Minimal::_mod_perl) and (not defined $req_method)) {
		$req_method = Apache2::RequestUtil->request->method;
	}

	if (! defined $req_method) {
	  # todo, no funciona cuando hacemos ./script.cgi, revisar
#		my $input = <STDIN>;
#		$input = '' if (! defined $input);
#		$ENV{'QUERY_STRING'} = $input;
#		chomp $ENV{'QUERY_STRING'};
#		$self->_read_get;
    # ---------------------------------------------------------
		return;
	}
	if ($req_method eq 'POST') {
		$self->_read_post; 
		if ($Nes::Minimal::_allow_hybrid_post_get) {
			$self->_read_get;
		}
	} elsif (($req_method eq 'GET') || ($req_method eq 'HEAD')) {
		$self->_read_get;
	} else {
		my $package = __PACKAGE__;
		require Carp;
		Carp::carp($package . " - Unsupported HTTP request method of '$req_method'. Treating as 'GET'");
		$self->_read_get;
	}
}

####
# Performs form reading for POST method

sub _read_post {
	my $self = shift;
	my $pkg  = __PACKAGE__;
	my $vars = $self->{$pkg};

	my $r;
	if (2 == $Nes::Minimal::_mod_perl) {
		$r = Apache2::RequestUtil->request;
	}

	my $read_length = $vars->{'max_buffer'};
	my $clen = $ENV{'CONTENT_LENGTH'};
	if ((2 == $Nes::Minimal::_mod_perl) and (not defined $clen)) {
		$clen = $r->headers_in->get('Content-Length');
	}
	if ($clen < $read_length) {
		$read_length = $clen;
	}
	
  my $content_type = defined($ENV{'CONTENT_TYPE'}) ? $ENV{'CONTENT_TYPE'} : '';
  if ((!$content_type) and (2 == $Nes::Minimal::_mod_perl)) {
    $content_type = $r->headers_in->get('Content-Type');
  }	

  my $bdry = $1 if $content_type =~ m/^multipart\/form-data; boundary=(.*)$/i;  

	my $buffer = '';
	my $read_bytes = 0;
	
	if ( ($bdry && $Nes::Minimal::_sub_filter) || 
	     ($bdry && $ENV{'CONTENT_LENGTH'} > $Nes::Minimal::_use_tmp && $Nes::Minimal::_use_tmp) ) {
	       
    if ($ENV{'CONTENT_LENGTH'} > $Nes::Minimal::_max_upload) {
      $Nes::Minimal::_ERROR_max_upload = 1;
      require Carp;
      Carp::carp($pkg . " The POST is greater than max_upload: $ENV{'CONTENT_LENGTH'} > $Nes::Minimal::_max_upload");
      return;
    }     
	       
	       
    if (2 == $Nes::Minimal::_mod_perl) {
      $read_bytes = $self->_read_post_bdry(\$buffer,$bdry,$r);
    } else {
      $read_bytes = $self->_read_post_bdry(\$buffer,$bdry);
    }

	} else {
	  
    if ($ENV{'CONTENT_LENGTH'} > $vars->{'max_buffer'}) {
      $Nes::Minimal::_ERROR_max_post = 1;
      require Carp;
      Carp::carp($pkg . "  The POST is greater than max_post: $ENV{'CONTENT_LENGTH'} > $vars->{'max_buffer'}");
      return;
    }  	  

  	if ($read_length) {
  		if (2 == $Nes::Minimal::_mod_perl) {
  			$read_bytes = $r->read($buffer,$read_length,0);
  		} else {
  			$read_bytes = read(STDIN, $buffer, $read_length,0);
  		}
  		$self->filter_data(\$buffer) if $Nes::Minimal::_sub_filter;
  	}
  	
	}
	$Nes::Minimal::_BUFFER = \$buffer;
	$vars->{'form_truncated'} = ($read_bytes < $clen) ? 1 : 0;

  if ( !defined $Nes::Minimal::_BUFFER_saved ) {
    require IO::String;
    $Nes::Minimal::_save_BUFFER_String = IO::String->new($Nes::Minimal::_BUFFER);
  } 
  
	# Boundaries are supposed to consist of only the following
	# (1-70 of them, not ending in ' ') A-Za-z0-9 '()+,_-./:=?

  if ( $content_type =~ m/^multipart\/form-data; boundary=(.*)$/i ) {
    my $bdry = $1;
    require Nes::Minimal::Multipart;
    $self->_burst_multipart_buffer ($buffer,$bdry);

  } else {
    $self->_burst_URL_encoded_buffer($buffer,'[;&]');
  }
  
}

sub _read {
  my $self = shift;
  my ( $buffer, $read_length, $r ) = @_;
   
  if ($r) {
    return $r->read($$buffer, $read_length);
  } else {
    return read(STDIN, $$buffer, $read_length);
  }
  
}

####
# Use tmp file from big POST

sub _read_post_bdry {
  my $self = shift;
  my ( $buffer, $bdry, $r ) = @_;
  my $pkg  = __PACKAGE__;
  my $vars = $self->{$pkg};

  my $use_tmp = $ENV{'CONTENT_LENGTH'} > $Nes::Minimal::_use_tmp && $Nes::Minimal::_use_tmp;
  my $tmp_fh;
  my $size_buffer = 8192; 
  my $rbuffer;
  my $bbuffer;
  my $buffer_fh;
  my $data;
  my $read_bytes = 0;
  my $field_name = '';
  my $file_name  = '';
  my $content_type = '';
  
  if ( $Nes::Minimal::_save_BUFFER ) {
    require IO::File;
    $buffer_fh = IO::File->new_tmpfile;
    $Nes::Minimal::_BUFFER_saved = $buffer_fh;
  }
  
  while ( (my $readb = $self->_read(\$rbuffer, $size_buffer, $r)) || $data ) {
    $read_bytes += $readb;

    if ($read_bytes > $Nes::Minimal::_max_upload) {
      $Nes::Minimal::_ERROR_max_upload = 1;
      require Carp;
      Carp::carp($pkg . " - The POST is greater than max_upload: $ENV{'CONTENT_LENGTH'} > $Nes::Minimal::_max_upload");
      last;
    }

    $data .= $rbuffer;
    if ( $data =~ /^(--\Q$bdry\E\015\012Content-Disposition:[^\015\012]* name\=\"([^\"]*)\"(?:[^\015\012]* filename\=\"([^\"]*)"[^\015\012]*|[^\015\012]*)\015\012([^\015\012]*)\015\012)/si ) {
      $field_name   = $2;
      $file_name    = $3;
      $content_type = $4;
      $$buffer     .= $1;
      $data         = $';
      print $buffer_fh $1 if $buffer_fh;
      if ( $file_name && $use_tmp ) {
        $data =~ s/([^\015\012]*\015\012)//si;
        $$buffer      .= $1;
        print $buffer_fh $1 if $buffer_fh;        
        require IO::File;
        $tmp_fh = IO::File->new_tmpfile;
        binmode $tmp_fh;
        $vars->{'from_file'}->{$field_name} = $tmp_fh;
      }      
      next;
    } elsif ( $data =~ /^(\015\012--\Q$bdry\E--.*)/si ) {
      $$buffer      .= $1; 
      print $buffer_fh $1 if $buffer_fh;
      $data = '';
      last;
    } 

    if ( $data =~ m/(\015\012)(--\Q$bdry\E\015\012)/ ) {
      $data = $2.$';
      my $sdata = $`;
      $self->filter_data(\$sdata) if $content_type =~ m/Content-Type: text/i || !$content_type;
      if ( $file_name && $use_tmp ) {
        $$buffer      .= "$file_name\015\012";
        print $tmp_fh    $sdata;
        print $buffer_fh $sdata."\015\012" if $buffer_fh;
        $file_name = '';
        $content_type = '';
        seek($tmp_fh, 0, 0);
      } else {
        $$buffer      .= $sdata."\015\012";
        print $buffer_fh $sdata."\015\012" if $buffer_fh;
      }
    } else {
      $self->filter_data(\$data) if $content_type =~ m/Content-Type: text/i || !$content_type;
      $$buffer      .= $data if !$file_name || !$use_tmp;
      print $tmp_fh    $data if $file_name && $use_tmp;
      print $buffer_fh $data if $buffer_fh;
      $data = '';
    }
     
  } 

  seek($buffer_fh, 0, 0) if $buffer_fh;
  return $read_bytes;
  
}

sub filter_data {
  my $self = shift;
  my ($data) = @_;
  
  return if !$Nes::Minimal::_sub_filter;
  
  $Nes::Minimal::_sub_filter->($data);
  
  return;
}

####
# GET and HEAD

sub _read_get {
	my $self = shift;

	my $buffer = '';
	my $req_method = $ENV{'REQUEST_METHOD'};
	if (1 == $Nes::Minimal::_mod_perl) {
		$buffer = Apache->request->args;
	} elsif (2 == $Nes::Minimal::_mod_perl) {
		my $r = Apache2::RequestUtil->request;
		$buffer = $r->args;
		$r->discard_request_body();
                unless (exists($ENV{'REQUEST_METHOD'}) || $Nes::Minimal::_no_subprocess_env) {
			$r->subprocess_env;
		}
		$req_method = $r->method unless ($req_method);
	} else {
		$buffer = $ENV{'QUERY_STRING'} if (defined $ENV{'QUERY_STRING'});
	}
	if ($req_method ne 'POST') {
		$Nes::Minimal::_BUFFER = \$buffer;
	}
	$self->_burst_URL_encoded_buffer($buffer,'[;&]');
}

####
# Bursts URL encoded buffers
#  $buffer -  data to be burst
#  $spliton   - split pattern

sub _burst_URL_encoded_buffer {
	my $self = shift;
	my $pkg = __PACKAGE__;
	my $vars = $self->{$pkg};

	my ($buffer,$spliton)=@_;

	my ($mime_type) = "text/plain";
	my ($filename) = "";

	my @pairs = $buffer ? split(/$spliton/, $buffer) : ();

	foreach my $pair (@pairs) {
		my ($name, $data) = split(/=/,$pair,2);

		$name = '' unless (defined $name);
		$name =~ s/\+/ /gs;
		$name =~ s/%(?:([0-9a-fA-F]{2})|u([0-9a-fA-F]{4}))/
		defined($1)? chr hex($1) : _utf8_chr(hex($2))/ge;
		$data = '' unless (defined $data);
		$data =~ s/\+/ /gs;
		$data =~ s/%(?:([0-9a-fA-F]{2})|u([0-9a-fA-F]{4}))/
		defined($1)? chr hex($1) : _utf8_chr(hex($2))/ge;

		if (! defined ($vars->{'field'}->{$name}->{'count'})) {
			push (@{$vars->{'field_names'}},$name);
			$vars->{'field'}->{$name}->{'count'} = 0;
		}
		my $record  = $vars->{'field'}->{$name};
		my $f_count = $record->{'count'};
		$record->{'count'}++;
		$record->{'value'}->[$f_count] = $data;
		$record->{'filename'}->[$f_count]  = $filename;
		$record->{'mime_type'}->[$f_count] = $mime_type;
	}
}

####
#
# _utf8_chr() taken from Nes::Util
# Copyright 1995-1998, Lincoln D. Stein.  All rights reserved.  
sub _utf8_chr {
	my $c = shift(@_);
	return chr($c) if $] >= 5.006;

	if ($c < 0x80) {
		return sprintf("%c", $c);
	} elsif ($c < 0x800) {
		return sprintf("%c%c", 0xc0 | ($c >> 6), 0x80 | ($c & 0x3f));
	} elsif ($c < 0x10000) {
		return sprintf("%c%c%c",
					   0xe0 |  ($c >> 12),
					   0x80 | (($c >>  6) & 0x3f),
					   0x80 | ( $c & 0x3f));
	} elsif ($c < 0x200000) {
		return sprintf("%c%c%c%c",
					   0xf0 |  ($c >> 18),
					   0x80 | (($c >> 12) & 0x3f),
					   0x80 | (($c >>  6) & 0x3f),
					   0x80 | ( $c & 0x3f));
	} elsif ($c < 0x4000000) {
		return sprintf("%c%c%c%c%c",
					   0xf8 |  ($c >> 24),
					   0x80 | (($c >> 18) & 0x3f),
					   0x80 | (($c >> 12) & 0x3f),
					   0x80 | (($c >>  6) & 0x3f),
					   0x80 | ( $c & 0x3f));

	} elsif ($c < 0x80000000) {
		return sprintf("%c%c%c%c%c%c",
					   0xfc |  ($c >> 30),
					   0x80 | (($c >> 24) & 0x3f),
					   0x80 | (($c >> 18) & 0x3f),
					   0x80 | (($c >> 12) & 0x3f),
					   0x80 | (($c >> 6)  & 0x3f),
					   0x80 | ( $c & 0x3f));
	} else {
		return _utf8_chr(0xfffd);
	}
}

####

sub htmlize {
	my $self = shift;

	my ($s)=@_;
	return ('') if (! defined($s));
	$s =~ s/\&/\&amp;/gs;
	$s =~ s/>/\&gt;/gs;
	$s =~ s/</\&lt;/gs;
	$s =~ s/"/\&quot;/gs;
	$s;
}

####

sub url_encode {
	my $self = shift;
	my ($s)=@_;
	return '' if (! defined ($s));
	$s= pack("C*", unpack("C*", $s));
	$s=~s/([^-_.a-zA-Z0-9])/sprintf("%%%02x",ord($1))/eg;
	$s;
}

####

sub param_mime     { require Nes::Minimal::Multipart; &_internal_param_mime(@_);      }
sub param_filename { require Nes::Minimal::Multipart; &_internal_param_filename(@_);  }
sub date_rfc1123   { require Nes::Minimal::Misc; &_internal_date_rfc1123(@_);         }
sub dehtmlize      { require Nes::Minimal::Misc; &_internal_dehtmlize(@_);            }
sub url_decode     { require Nes::Minimal::Misc; &_internal_url_decode(@_);           }
sub calling_parms_table { require Nes::Minimal::Misc; &_internal_calling_parms_table(@_); }

####

1;

