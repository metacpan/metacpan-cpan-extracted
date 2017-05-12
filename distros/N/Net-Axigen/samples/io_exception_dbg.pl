# ****************************************************************
# io_exception_dbg
# Processing of exceptions for debugging
# ****************************************************************
# Версия 1.0.0, 06.04.2009
# ****************************************************************
# Copyright (c) Alexandre Frolov, 2001-2009
# alexandre@frolov.pp.ru  
# http://www.shop2you.ru
# ****************************************************************
package io_exception_dbg;
use HTML::Entities;

# ==================================================================
# new
# ==================================================================
sub new
{
  my $this = shift @_;
  my $err_msg = shift @_;
  
  my $stack_trace;
  my $i = 0;
  while ((my $pack, my $file, my $line, my $subname, my $hasargs, my $wantarray, my $evaltext, my $is_require) = caller($i++)) 
	{
	 	$stack_trace = $stack_trace."\n\npackage: ".$pack.', file: '.$file.', line: '.$line.', subroutine: '.$subname;
    if($hasargs and $hasargs != 0)
		{
		  $stack_trace = $stack_trace.'	, args: '.$hasargs;
		}		 	
    if($wantarray and $wantarray != 0)
		{
		  $stack_trace = $stack_trace.'	, wantarray: '.$wantarray;
		}		 	
	  if($evaltext and $evaltext != 0)
		{
		  $stack_trace = $stack_trace.'	, evaltext: '.$evaltext;
		}		 	
	  if($is_require and $is_require != 0)
		{
			$stack_trace = $stack_trace.'	, is_require: '.$is_require;
		}		 	
	}
  
  my $self = {};
  $self->{ STACK_TRACE } = $stack_trace;
  $self->{ ERR_MSG } = $err_msg;
  return(bless($self, $this));
}

# ==================================================================
# catch
# ==================================================================
sub catch
{
	my $this = shift @_;
	my $mod_ref = shift @_;
	
	if($mod_ref) 
	{
		if(ref($mod_ref) eq 'io_exception') { $mod_ref->send_error_msg_debug(); }
		else { io_exception_dbg->new($mod_ref)->send_error_msg_debug(); }
	}
}

# ==================================================================
# send_error_msg_debug
# ==================================================================
sub send_error_msg_debug
{
  my $this = shift @_;
  my $stack_trace = $this->{ STACK_TRACE };
  my $err_msg = $this->{ ERR_MSG };
  
  print "\n* >>>>>>>> TRACE >>>>>>>>\n";
  print "Error: ".$err_msg."\n";
  print "Stack trace: ".$stack_trace."\n";
  exit;
}

return 1;
