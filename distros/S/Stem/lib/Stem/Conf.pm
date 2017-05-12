#  File: Stem/Conf.pm

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

package Stem::Conf ;

use Data::Dumper ;
use strict ;

use Stem::Vars ;

use Stem::Trace 'log' => 'stem_status', 'sub' => 'TraceStatus' ;
use Stem::Trace 'log' => 'stem_error' , 'sub' => 'TraceError'  ;

Stem::Route::register_class( __PACKAGE__, 'conf' ) ;

my @conf_paths = split ':', $Env{ 'conf_path' } || '' ;
if ( my $add_conf_path = $Env{ 'add_conf_path' } ) {

	push @conf_paths, split( ':', $add_conf_path ) ;
}

my $attr_spec = [

	{
		'name'		=> 'path',
		'required'	=> 1,
		'help'		=> <<HELP,
This is the full path of the configuration file.
HELP
	},

	{
		'name'		=> 'to_hub',
		'help'		=> <<HELP,
This is the Hub that this configuration will be sent to.
HELP
	},
] ;

# this does not construct anything. just loads a conf file locally or remotely

sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec, @_ ) ;
	return $self unless ref $self ;

	if ( my $to_hub = $self->{'to_hub'} ) {

		my $conf_data = load_conf_file( $self->{'path'} ) ;

		return $conf_data unless ref $conf_data ;

		my $msg = Stem::Msg->new(
				'to_hub'	=> $to_hub,
				'to_cell'	=> __PACKAGE__,
				'from_cell'	=> __PACKAGE__,
				'type'		=> 'cmd',
				'cmd'		=> 'remote',
				'data'		=> $conf_data,
		) ;

		$msg->dispatch() ;

		return ;
	}

	my $err = load_conf_file( $self->{'path'}, 1 ) ;

TraceError $err if $err ;

	return $err if $err ;

	return ;
}


sub load_cmd {

	my( $self, $msg ) = @_ ;

	my $data = $msg->data() ;

	my @conf_names ;

	push( @conf_names, @{$data} ) if ref $data eq 'ARRAY' ;
	push( @conf_names, ${$data} ) if ref $data eq 'SCALAR' ;

	my $err = load_confs( @conf_names ) ;

TraceError $err if $err ;

	return $err if $err ;

	return ;
}

sub remote_cmd {

	my( $self, $msg ) = @_ ;

	my $err = configure( $msg->data() ) ;

TraceError $err if $err ;

	return $err if $err ;

	return ;
}

sub load_conf_file {

	my( $conf_path, $do_conf ) = @_ ;

	-r $conf_path or return "$conf_path can't be read: $!" ;

	my $conf_data = Stem::Util::load_file( $conf_path ) ;

	return "Stem::Conf load error:\n$conf_data" unless ref $conf_data ;

	return $conf_data unless $do_conf ;

	my $conf_err = configure( $conf_data ) ;

	return <<ERR if $conf_err ;
Configuration error in '$conf_path'
$conf_err
ERR

#	TraceStatus "$conf_path configuration loaded." ;

	return ;
}


sub load_confs {

	my ( @conf_names ) = @_ ;

	NAME:
	foreach my $conf_name ( @conf_names ) {

		$conf_name =~ s/\.stem$// ;

		for my $path ( @conf_paths ) {

			my $conf_path = "$path/$conf_name.stem" ;

			next unless -e $conf_path ;

			my $err = load_conf_file( $conf_path, 1 ) ;

			return $err if $err ;

			next NAME ;
		}

		local( $" ) = "\n\t" ;

		return <<ERR ;
Can't find config file '$conf_name.stem' in these directories:
	@conf_paths
ERR
	}

	return ;
}

my $eval_error ;

sub configure {

	my ( $conf_list_ref ) = @_ ;

	my $class ;
	my @notify_done; # list of objects/packages to call config_done on

	foreach my $conf_ref ( @{$conf_list_ref} ) {

		my %conf ;

		if ( ref $conf_ref eq 'HASH' ) {

			%conf = %{$conf_ref} ;
		}
		elsif ( ref $conf_ref eq 'ARRAY' ) {

			%conf = @{$conf_ref} ;
		}
		else {
			return "config entry is not an HASH or ARRAY ref\n" .
					Dumper($conf_ref). "\n" ;
		}

		unless ( $class = $conf{'class'} ) {

			return "Missing class entry in conf\n" .
			     Dumper($conf_ref) . "\n" ;
		}

# get the config name for registration

		my $reg_name = $conf{'name'} || '' ;

		no strict 'refs' ;

		unless ( %{"::${class}"} ) {

			my $module = $class ;
			$module =~ s{::}{/}g ;
			$module .= '.pm' ;

			while( 1 ) {

				my $err = eval { require $module } ;

				return <<ERR if $err && $err !~ /^1/ ;
Configure error FOO in Cell '$reg_name' from class '$class' FOO
$eval_error
$err
ERR
				last if $err ;

				if ( $@ =~ /Can't locate $module/ ) {

# this could be a subclass so try to load the parent class
# is this used?
					next if $module =~ s{/\w+\.pm$}{.pm} ;

					die
				 "Conf: can't find module for class $class" ;
				}

				return "eval $@\n" if $@ ;
			}

		}

# if arguments, call the method or new to get a possible object

		if ( my $args_ref = $conf{'args'} ) {

			my @args ;

			if ( ref $args_ref eq 'HASH' ) {

				@args = %{$args_ref} ;
			}
			elsif ( ref $args_ref eq 'ARRAY' ) {

				@args = @{$args_ref} ;
			}
			else {
				return
				 "args entry is not an HASH or ARRAY ref\n" .
					Dumper($args_ref). "\n" ;
			}

			my $method = $conf{'method'} || 'new' ;


# register if we have an object

#print "NAME: $reg_name\n" ;

			if ( my $obj = $class->$method(
						'reg_name' => $reg_name,
						@args ) ) {

				return <<ERR unless ref $obj ;
Configure error in Cell '$reg_name' from class '$class'
$obj
ERR

# register the object by the conf name or the class

				my $err = Stem::Route::register_cell(
						$obj,
						$reg_name || $class ) ;

				return $err if $err ;
				push @notify_done, $obj if $obj->can('config_done');
				next;
			}

		     }
# or else register the class if we have a name

		my $err = Stem::Route::register_class( $class, $reg_name ) ;

		return $err if $err ;
		push @notify_done, $class if $class->can('config_done');
	}

	foreach my $class (@notify_done) {
	   $class->config_done();
	}

	return ;
}

1 ;
