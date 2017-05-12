#  File: Stem/Trace.pm

#  This file is part of Stem.
#  Copyright (C) 1999, 2000, 2001 Stem Systems, Inc.

#  Stem is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.

#  Stem is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with Stem; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

#  For a license to use the Stem under conditions other than those
#  described here, to purchase support for this software, or to purchase a
#  commercial warranty contract, please contact Stem Systems at:

#       Stem Systems, Inc.		781-643-7504
#  	79 Everett St.			info@stemsystems.com
#  	Arlington, MA 02474
#  	USA

package Stem::Trace ;

use strict;

use Stem::Vars ;
use Stem::Log::Entry ;

sub import {

	my( $class, %trace_args ) = @_ ;

	$class = caller ;

	my $sub              = $trace_args{ 'sub' }        || 'Trace' ;
	my $type             = $trace_args{ 'type' }       || 'textlist' ;
	my $def_level        = $trace_args{ 'level' }      || 5 ;
	my $def_label        = $trace_args{ 'label' }      || 'trace' ;
	my $def_log          = $trace_args{ 'log' }        || 'trace' ;
	my $def_env          = $trace_args{ 'env' }        || "$class\::$sub" ;
	my $def_env_level    = $trace_args{ 'env_level' }  || 0 ;
	my $def_prefix       = $trace_args{ 'prefix' }     || '%P-%L - ' ;

	no strict 'refs';

	if ( $type eq 'args' ) {

		*{ "${class}::$sub" } = sub {

			return if
				( $Stem::Vars::Env{ $def_env } || 0 ) <
							$def_env_level ;

			my $prefix = $def_prefix ;
			my( $line_num ) = (caller)[2] ;

			$prefix =~ s/%P/$class/ ;
			$prefix =~ s/%L/$line_num/ ;

# if only 1 arg, it is text.
# if 2 args, it is level, text
# if 3 args, it is label, level, text

			my $text = pop ;
			my $level = pop || $def_level ;
			my $label = pop || $def_label ;
			my $log = pop || $def_log ;

			Stem::Log::Entry->new (
			       'logs'	=> $log,
			       'level'	=> $level,
			       'label'	=> $label,
			       'text'	=> "$prefix$text\n"
			) ;
		} ;

		return ;
	}

	if ( $type eq 'keyed' ) {

		*{ "${class}::$sub" } = sub {

			my ( %args ) = @_;

			my $env	      = $args{ 'env' }   || $def_env ;
			my $env_level = $args{ 'env_level' } || $def_env_level ;

			return if
				( $Stem::Vars::Env{ $env } || 0 ) < $env_level ;

			my $text      = $args{ 'text' }   || '' ;
			my $log	      = $args{ 'log' }    || $def_log ;
			my $level     = $args{ 'level' }  || $def_level ;
			my $label     = $args{ 'label' }  || $def_label ;
			my $prefix    = $args{ 'prefix' } || $def_prefix ;

			my( $line_num ) = (caller)[2] ;
			$prefix =~ s/%P/$class/ ;
			$prefix =~ s/%L/$line_num/ ;

			Stem::Log::Entry->new (
				'logs'	=> $log,
				'level'	=> $level,
				'label'	=> $label,
				'text'	=> "$prefix$text\n",
			) ;
		} ;

		return ;
	}

	if ( $type eq 'textlist' ) {

		*{ "${class}::$sub" } = sub {

			return if
				( $Stem::Vars::Env{ $def_env } || 0 ) <
							$def_env_level ;

			my $text = join '', @_ ;

			my( $line_num ) = (caller)[2] ;

			my $prefix = $def_prefix ;

			$prefix =~ s/%P/$class/ ;
			$prefix =~ s/%L/$line_num/ ;


			Stem::Log::Entry->new (
			       'logs'	=> $def_log,
			       'level'	=> $def_level,
			       'label'	=> $def_label,
			       'text'	=> "$prefix$text\n",
			) ;
		} ;

		return ;
	}
}

1 ;
