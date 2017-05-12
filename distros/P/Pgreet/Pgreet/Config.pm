package Pgreet::Config;
#
# File: Config.pm
######################################################################
#
#                ** PENGUIN GREETINGS (pgreet) **
#
# A Perl CGI-based web card application for LINUX and probably any
# other UNIX system supporting standard Perl extensions.
#
#   Edouard Lagache, elagache@canebas.org, Copyright (C)  2003-2005
#
# Penguin Greetings (pgreet) consists of a Perl CGI script that
# handles interactions with users wishing to create and/or
# retrieve cards and a system daemon that works behind the scenes
# to store the data and email the cards.
#
# ** This program has been released under GNU GENERAL PUBLIC
# ** LICENSE.  For information, see the COPYING file included
# ** with this code.
#
# For more information and for the latest updates go to the
# Penguin Greetings official web site at:
#
#     http://pgreet.sourceforge.net/
#
# and the SourceForge project page at:
#
#     http://sourceforge.net/projects/pgreet/
#
# ----------
#
#           Perl Module: Pgreet::Config
#
# This is the Penguin Greetings (pgreet) shared library for
# configuration settings.  This provide a uniform interface to
# settings shared between the CGI Application and the daemon.
# It provides for systematic updating of configuration information,
# interrupt handling, and so on.
######################################################################
# $Id: Config.pm,v 1.35 2005/05/31 16:44:38 elagache Exp $

$VERSION = "1.0.0"; # update after release

# Module exporter declarations
@ISA       = qw(Exporter);
@EXPORT    = qw();
@EXPORT_OK = qw();

# Perl modules.
use FileHandle;
use File::Basename;
use CGI qw(:standard escape);
use CGI::Carp;
use Config::General;
use User::pwent;
use String::Checker;
use Data::Dumper; # Needed only for debugging.
use I18N::AcceptLanguage;
use Pgreet;

# Perl Pragmas
use strict;

# List of Penguin Greetings configuration parameters which cannot be set
# on a secondary ecard website without breaking daemon, CGI-app interface.
# Subject to change but hardwired into apps.
our %set_primary_only =   (PID_file => 1,
						   PID_path => 1,
						   batch_pause => 1,
						   tmpdir => 1,
						   today_pause => 1,
						   data_file_prefix => 1,
						   state_file_prefix => 1,
						   delete_state => 1,
						   scheduled_email_queue => 1,
						   pgreet_uid => 1,
						   pgreet_gid => 1,
						   SMTP_server => 1,
						   user_access => 1,
						   User_Pgreets => 1,
						   flush_pause => 1,
						   purge_pause => 1,
						   purge_db_hour => 1,
						   reload_config => 1,
						  );

# List of tests to be performed on Penguin Greetings configuration
# parameters via the String::Checker interface
our %check_configs =
    (cgidir => ['is_directory'],
	 imagedir => ['is_directory'],
	 datadir => ['is_directory'],
	 confdir => ['is_directory'],
	 templatedir => ['is_directory'],
	 tmpdir => ['is_directory'],
	 scheduled_mail_queue => ['is_directory'],
	 pgreet_uid => ['want_int', ['num_min' => 1], 'existing_uid'],
	 pgreet_gid => ['want_int', ['num_min' => 1], 'existing_gid'],
	 Timeout => ['want_int', ['num_min' => 1]],
	 MaxRuns  => ['want_int', ['num_min' => 1]],
	 SMTP_server =>
	     {SMTP_Timeout => ['want_int', ['num_min' => 1]],
		 },
	 today_pause => ['want_int', ['num_min' => 1]],
	 batch_pause => ['want_int', ['num_min' => 1]],
	 batch_send_hour => ['want_int', ['num_min' => 0]],
	 delete_state => ['want_int', ['num_min' => 1]],
	 flush_pause => ['want_int', ['num_min' => 1]],
	 purge_pause => ['want_int', ['num_min' => 1]],
	 purge_db_hour => ['want_int', ['num_min' => 0]],
	 reload_config => ['want_int', ['num_min' => 1]],
	 PID_path => ['is_directory'],
	);


############### Extensions to String::Checker #################

String::Checker::register_check("is_directory",
#
# Test if this parameter is an existing local directory
#
        sub {
		     my($s) = shift;
			 if ((defined($$s)) && (not -d $$s)) {
			   return 1;
			 }
			 return undef;
		   }
);

String::Checker::register_check("num_min",
#
# Test if this parameter is greater than numerical lower bound
#
        sub {
		     my($s) = shift;
			 my($t) = shift;
			 if ((defined($$s)) && (not ($t <= $$s))) {
			   return 1;
			 }
			 return undef;
		   }
);

String::Checker::register_check("existing_uid",
#
# Test if this parameter is an existing user ID number
#
        sub {
		     my($s) = shift;
			 if ((defined($$s)) && (not getpwuid($$s))) {
			   return 1;
			 }
			 return undef;
		   }
);


String::Checker::register_check("existing_gid",
#
# Test if this parameter is an existing group ID number
#
        sub {
		     my($s) = shift;
			 if ((defined($$s)) && (not getgrgid($$s))) {
			   return 1;
			 }
			 return undef;
		   }
);


########################### METHODS ###########################

sub new {
#
# Traditional empty contructor.
# Assign values needed by
# particular instances of object
#
  my $class = shift;
  my $config_file = shift;
  my $Pg_error = shift;
  my $default_config = shift;
  my $no_merge = shift;

  my $self = {};
  bless $self, $class;
  my $default_config_hash = {};
  my $config_hash = {};
  my $cache_conf;

  # Have we cached this secondary ecard site already? - if so just return it.
  if ($default_config and
	  ($cache_conf = $default_config->fetch_cache_site($config_file))
	 ) {
	return($cache_conf);

  # Otherwise we need to construct new object and read data from a file.
  } else {
	# If we have an existing Error object, bind that to object.
	if (defined($Pg_error)) {
	  $self->{'Pg_error'} = $Pg_error;
	}

	# Set value of configuration file and read data
	$self->{'config_file'} = $config_file;
	$config_hash = $self->_read_config_file($config_file);

	# Do we have a default configuration to merge into this object?
	if(defined($default_config)) {
	  # If needed, merge settings from secondary ecard site with primary
	  $self->{'default_config'} = $default_config;
	  unless ($no_merge) {
		$default_config_hash = $default_config->get_hash();
		$config_hash =
		  $self->_merge_configs($default_config_hash, $config_hash);
	  }
	  $self->{'config'} = $config_hash;
	  # Cache resulting configuration
	  $default_config->cache_site($config_file, $self);
	  return($self);
	}
	# Else if we have a configuration hash, set that and return object ref.
	elsif ($config_hash) {
	  $self->{'config'} = $config_hash;
	  $self->{'secondary_cache'} = {};
	  return($self);
	  # If opening default configuration fails - returns 0 (false).
	} else {
	  return(0);
	}
  }
} # End object constructor.

sub add_error_obj {
#
# Since this is the first module to be loaded, so it cannot
# depend on a error object existing when first created.
# This method attaches an error object once Penguin
# Greetings has bootstrapped itself.
#
  my $self = shift;
  my $Pg_error = shift;

  return($self->{'Pg_error'} = $Pg_error);
}

sub _read_config_file {
#
# Subroutine to read the contents of a configuration file and
# return the contents.
#
  my $self = shift;
  my $config_file = shift;
  my $config_obj;
  my $config_ref = {};

  # Read configuation file variables
  unless ( (-r $config_file) and
		   ($config_obj = new Config::General(-ConfigFile => $config_file,
											  -AllowMultiOptions => 'yes',
											  -CComments => 'no',
											 )
		   ) and
		   (%{$config_ref} = $config_obj->getall())
		 ) {
	# If we have an error either report via error object or ... don't!
	if (exists($self->{'Pg_error'})) {
	  my $Pg_error = $self->{'Pg_error'};
	  $Pg_error->report('error', 22,
						"Unable to read configuration data from ",
						"file: $config_file - bailing"
					   );
	} else {
	  # If first call, we have no error object yet - deal in app.
	  return(0);
	}
  }

  # Attach hash to object and return.
  return($config_ref);

} # End sub _read_config_file

sub access {
#
# A method that, depending on the number of arguments,
# either returns the value of the given parameter,
# or sets that parameter to the supplied additional value
#

  my $self = shift;
  my $parameter = shift;
  my $value = shift;

  # If value is defined, modify hash, otherwise return value.
  if (defined($value)) {
	return($self->{'config'}->{$parameter} = $value);
  } else {
	if (defined($self->{'config'}->{$parameter})) {
	  return($self->{'config'}->{$parameter});
	} else {
	  return(0);
	}
  }
} # End sub access

sub get_hash {
#
# A method to return the entire hash reference of
# parameters.  This is an transitional function
# that probably shouldn't be used too often.
#
  my $self = shift;

  return($self->{'config'});
}

sub put_hash {
#
# A method to replace the entire hash reference
# of parameters.  Needed to fix a quirk in the
# way that cards are stored in categories.
#
# Move this problem into a derivate class of
# Config.pm?
#
  my $self = shift;
  my $config_hash = shift;

  return($self->{'config'} = $config_hash);
}

sub choose_localized_site {
#
# Subroutine to see if the site selected is actually
# one of a number of localized sites and if so, to
# choose which of those sites is the one appropriate
# given the user's language settings.
#

  my $self = shift;
  my $site_name = shift;
  my $localize = $self->access('Localize');
  my $Pg_error = $self->{'Pg_error'};
  my $language;
  # XXX strict setting should become a configuration option.
  my $acceptor = I18N::AcceptLanguage->new(strict => 0);

  # If there are any localization settings for this site
  if (exists($localize->{$site_name})) {
	# If there is localization information try to match to user language
	my $site_options = $localize->{$site_name};
	my @keys = keys(%{$site_options});
	$language = $acceptor->accepts($ENV{HTTP_ACCEPT_LANGUAGE}, \@keys);

	# If we have a match return that.
	if ($language) {
	  return($site_options->{$language}, $language);
	}
	# Else if we have a default - return that
	elsif ($site_options->{'default'}) {
	  return($site_options->{'default'}, $language);
	# Otherwise issue warning and return site name - gotta return something.
	} else {
	  $Pg_error->report('warn',
						"Localized site \'$site_name\' lacks a default value"
					   );
	  return($site_name, $language);
	}
  } else {
	return($site_name, $language); # No localization lookup, not localized(??)
  }
} # End sub choose_localized_site

sub is_valid_site {
#
# Method to test if a given web site exists in
# default configuration list of secondary sites.
#
  my $self = shift;
  my $site = shift;
  my $User_Pgreets = $self->access('User_Pgreets');
  my $Pg_error = $self->{'Pg_error'};

  if ($User_Pgreets and exists($User_Pgreets->{$site})) {
	return(1);
  } else {
	$Pg_error->report('error', 4,
					  "Attempt to use a nonexistent secondary Penguin ",
					  "Greetings ecard site: ",
					  $site
					 );
	return(0);
  }
}

sub _merge_configs {
#
# Internal method to take two configuration hashes and
# merge the contents so that new values replace old ones
# but values not set in the configuration revert to
# defaults
#
  my $self = shift;
  my $default_hash = shift;
  my $config_hash = shift;
  my $new_hash = {};
  my $Pg_error = $self->{'Pg_error'};

  # Create a copy of default hash.
  %{$new_hash} = %{$default_hash};

  # Delete any Embperl_Object setting - this cannot be inherited.
  if (exists($new_hash->{Embperl_Object})) {
	delete($new_hash->{Embperl_Object});
  }

  # Change values to reflect changes from secondary site.
  foreach my $value (keys(%{$config_hash})) {
	if (exists($set_primary_only{$value})) {
	  $Pg_error->report('error', 5,
						"Attempt to set parameter: $value in a secondary ",
						"configuration file.  This parameter may only be ",
						"set the Penguin Greeting primary configuration file"
					   );
	} else {
	  $new_hash->{$value} = $config_hash->{$value};
	}
  }

  # Return copy of configuration information.
  return($new_hash);

}

sub expand_config_file {
#
# Internal method test if configuration file path is relative
# to a user account and if so to expand the path via the
# home directory.
#
  my $self = shift;
  my $account = shift;

  my $User_Pgreets = $self->access('User_Pgreets');
  my $file_path = $User_Pgreets->{$account};
  my $Pg_error = $self->{'Pg_error'};
  my $pw_obj;

  if ($file_path =~ /~/) {
	# Get home directory via system call
	unless ($pw_obj = getpwnam($account)) {
	  $Pg_error->report('error', 4,
						"Attempt to use user account $account for Penguin ",
						"Greetings that does not exist on system.",
					   );
	}
	my $home = $pw_obj->dir();
	$file_path =~ s/~/$home/;
	return($file_path);
  } else {
	return($file_path);
  }
}

sub scalar_to_array {
#
# Method to go through and process the the 'Force_to_array'
# specification in a card configuration hash.  This is
# just the access method.  The real work is done by the
# internal subroutine: _int_scalar_to_array.
#
  my $self = shift;
  my $config_hash = $self->get_hash();
  my $new_hash = {};
  %{$new_hash} = %{$config_hash};

  $self->_int_scalar_to_array($new_hash);

  $self->put_hash($new_hash);

}

sub _int_scalar_to_array {
#
# Recursive subroutine to go through configuration file
# and locate every specification for where a field could
# be containing a single item but must be maintained as
# a array reference for looping simplicity.
#
  my $self = shift;
  my $config_piece = shift;

  if ((not ref($config_piece)) or (ref($config_piece) eq "ARRAY")) {
	return(1);
  }
  elsif (ref($config_piece) eq "HASH") {
	if ($config_piece->{'Force_to_array'}) {
	  $self->_swap_arrays_for_scalars($config_piece);
	}
	foreach my $element (keys(%{$config_piece})) {
	  $self->_int_scalar_to_array($config_piece->{$element});
	}
  }

} # End: sub _int_scalar_to_array

sub _swap_arrays_for_scalars {
#
# Subroutine to "slice in" the array references to replace
# single scalar values in configuration hash.
#
  my $self = shift;
  my $config_piece = shift;
  my $fields = $config_piece->{'Force_to_array'}->{'fields'};

  unless (ref($fields) eq 'ARRAY') {
	$fields = [ $fields ];
  }

  foreach my $entry (keys(%{$config_piece})) {
	foreach my $field (@{$fields}) {
	  if (not ref($config_piece->{$entry}->{$field})) {
		$config_piece->{$entry}->{$field} =
		  [ $config_piece->{$entry}->{$field} ];
	  }
	}
  }
  delete($config_piece->{'Force_to_array'});
} # End: sub _swap_arrays_for_scalars

sub chk_params {
#
# Convenience Method to start check pgreet
# configuration parameters to see if they make
# sense for the application.  Calls recursive
# internal method _chk_params_helper to do the
# real work.
#
  my $self = shift;

  my $to_test = $self->{'config'};
  my $test_results = {};

  $self->_chk_params_helper($to_test, \%check_configs, $test_results);
  return($test_results);

}

sub _chk_params_helper {
#
# Go through list of configuration parameters and
# apply String::Checker tests as appropriate.  If
# parameter has a nexted hash reference, process
# the reference recursively as needed.
#
  my $self = shift;
  my $to_test = shift;
  my $chk_conf_ref = shift;
  my $test_results = shift;

  # Loop through every configuration parameter.
  foreach my $param (keys(%{$to_test})) {
	# Is this a reference to more parameters?
	if ((ref($to_test->{$param}) eq 'HASH') and
		(ref($chk_conf_ref->{$param}) eq 'HASH')
		) {
	      # If so recursively call subroutine to process hash references
		  $self->_chk_params_helper($to_test->{$param},
									$chk_conf_ref->{$param},
									$test_results
								   );
		}
	    # Are tests defined for this parameter?
		elsif (exists($chk_conf_ref->{$param})) {
		  # If so, perform tests
		  my $result =
			String::Checker::checkstring($to_test->{$param},
										 $chk_conf_ref->{$param}
										);
		  # If any tests failed, add them to hash of param with failed tests.
		  if(@{$result}) {
			$test_results->{$param} = $result;
		  }
		}
  }
} # end sub _chk_params_helper

sub cache_site {
#
# Method to cache the read of a secondary ecard site
# on the primary object to avoid unnecessary disk
# reloading.
#
  my $self = shift;
  my $config_file = shift;
  my $secondary_obj = shift;

  return($self->{'secondary_cache'}->{$config_file} = $secondary_obj);

}

sub fetch_cache_site {
#
# Method to return value of a previously cached
# secondary ecard site configuration object.
#
  my $self = shift;
  my $config_file = shift;

  return($self->{'secondary_cache'}->{$config_file});

}


=head1 NAME

Pgreet::Config - Configuration object for Penguin Greetings.

=head1 SYNOPSIS

  # Bootstrap Initialization:
  $Pg_config = new Pgreet::Config($config_file);
  $Pg_config->add_error_obj($Pg_error);

  # Normal Initialization:
  $Pg_config = new Pgreet::Config($config_file,
                                  $Pg_error,
                                  $Pg_default_config
                                 );
  # Access methods:
  $Pg_config->access('config_parameter');
  $Pg_config->access('config_parameter', $Value_to_set_parameter_to);
  $Pg_config->get_hash();
  $Pg_config->put_hash($new_hash);

  # Other Misc. methods:
  $Pg_default_config->is_valid_site($site);
  $Pg_default_config->expand_config_file($site);
  $card_conf->scalar_to_array();
  $results = $Pg_config->chk_params();

=head1 DESCRIPTION

The module C<Pgreet::Config> is the Penguin Greetings interface to
configuration information.  It, in turn, uses the CPAN module
L<Config::General> to actually access the configuration files.  This
module provides methods to maintain the configuration of the
parameters needed to operate the Penguin Greetings applications, the
configuration of primary and secondary sites and the configuration
related to the ecards themselves.  This module can either construct a
default object in a bootstrap mode or create objects for secondary
sites that merge new information into the primary site's setup.

=head1 BOOTSTRAPPED INITIALIZATION

One of the main purposes of these modules was to provide a consistent
interface to error handling.  However, the error handling module
requires configuration information in order to deal with some error
conditions.  Therefore when when this method is first called, there is
no error handling apparatus yet available.  To cope with this, the
first attempt to construct a Pgreet::Config object simply tries to
open a configuration file and read it's contents.  If it fails, the
constructor returns a false value.  If the returned value is false,
the calling program must cope as best it can:

  unless ($Pg_default_config = new Pgreet::Config($config_file)) {
          die;
         }

When bootstrapping, the constructor to Pgreet::Config is given one
argument: the complete path to the configuration file.  The
constructor always needs at least this one argument.  If the
configuration object is successfully constructed, it can then be used
to create a new error object (illustrated for example by the call
below:)

  $Pg_error = new Pgreet::Error($Pg_default_config, 'CGIApp');

Once this is done, an error object must be immediately added to the
configuration object.  If an error occurs without an error object
attached to the configuration object, it will crash in about as
inelegant a manner as is possible.

  $Pg_default_config->add_error_obj($Pg_error);

Once this is done, the bootstrapped configuration object may be used
in the manner presented below.

=head1 NORMAL CONSTRUCTION

Once an Error object is constructed, successive Penguin Greeting
configuration objects can be created directly by providing two
arguments the complete path to the configuration file, and the error
object.  For example, creating a configuration object to hold card
configuration data would be as follows:

  $card_conf = new Pgreet::Config($card_conf_file, $Pg_error);

There is a third possible way to use the constructor object.  If one
is defining a configuration object that is using an existing object
for default information (for example defining a secondary ecard site)
then three arguments are expected in constructing the object:

  $Pg_config = new Pgreet::Config($config_file,
                                  $Pg_error,
                                  $Pg_default_config
                                 );

When used in this way, the values in the configuration file are merged
with the values already in the default object C<$Pg_default_config>
via the internal method C<_merge_configs>.  Note that certain values
cannot be overridden from the default configuration.  Those values
are: C<PID_file>, C<PID_path>, C<batch_pause>, C<tmpdir>,
C<today_pause>, C<data_file_prefix>, C<state_file_prefix>,
C<delete_state>, C<scheduled_email_queue>, C<pgreet_uid>,
C<pgreet_gid>, C<SMTP_server>, C<user_access>, C<User_Pgreets> and
C<flush_on_cycle>.  Attempting to change these values will cause an
error to be generated via the attached Penguin Greetings error object,
and calling application will be terminated via the C<Pgreet::Error>
object.

=head1 METHODS

=over

=item add_error_obj()

This method attaches a Penguin Greetings error object to a
configuration object that has been "bootstrapped" into existence.
Usage:

  $Pg_default_config->add_error_obj($Pg_error);

=item access()

This is the bread'n'butter method for this object.  It can be used in
one of two ways.  If given one parameter, it retrieves the value of
the configuration variable (or returns undef.)  A sample use is below:

  $Pg_config->access('config_parameter');

The second syntax is use to set a configuration variable.  In this
case a second parameter is the value that the configuration variable
should be set to:

  $Pg_config->access('config_parameter', $Value_to_set_parameter_to);

=item get_hash()

This method can be used to get the entire hash reference that is the
L<Config::General> representation of the configuration file.  This is
used only for example to pass that hash to the L<Embperl> templates
for content developers to use.  Usage requires no parameters:

  $Pg_config->get_hash();

=item put_hash()

This method is the complement of the C<get_hash> method.  It is only
used internally to this object, but could be used for meatball surgery
of the configuration parameters.  It requires one parameter:

  $Pg_config->put_hash($new_hash);

=item is_valid_site()

This predicate method is used to see if a site exists in the list of
secondary ecard sites recorded in the primary Penguin Greetings
configuration.  It takes a name of a site as a parameter:

  $Pg_default_config->is_valid_site($site);

=item expand_config_file()

This method is used to expand directory paths for the configuration
files of secondary ecard sites that are specified relative to a
particular UNIX user on the system.  It takes the site name as an
argument and returns a full UNIX path name with any tilde '~' replaced
by the full path to the users home directory.

  $Pg_default_config->expand_config_file($site);

=item scalar_to_array()

This method is specific to user created configuration files that may
contain ambiguous situations of scalars and arrays mixed together.  It
goes through the hash reference looking for occurrences of the pseudo
configuration item: C<Force_to_array>.  It then looks for all
instances of the listed C<fields> in that configuration item, and if it
finds one of those fields containing a single scalar item, it replaces
with with an array reference containing that scalar item.  The purpose
of this is to simplify the creation of C<Embperl> C<foreach> loops
which might otherwise be handed a scalar instead of an array of one
item to loop through.  This method takes no arguments and should only
be called on card configuration information.

  $card_conf->scalar_to_array();

=item chk_params()

This method applies a set of tests to configuration variables for the
Penguin Greetings main configuration files (not the card configuration
files which are developer defined.)  The tests are a series of "sanity
checks" that insure that the values allow Penguin Greetings to
function at all and are implemented using C<String::Checker>.

The method returns a hash reference.  If any errors are encountered
the hash keys will be the configuration variables that had failed the
tests and the hash value will be a list reference of C<String::Checker>
expectations that failed.

In order to provide meaningful tests, some additional expectations are
defined: C<is_directory> - is this an existing directory on system?,
C<num_min> - is this value less than supplied number?, C<existing_uid>
is this an existing UID on this system?, and C<existing_gid> is this
an existing GID on this system?  These names are turned in the array
reference.  The Penguin Greetings utility C<PgreetConfTest> has a
translation table of these expectations to provide "human-friendly"
diagnostics for administrators.

=item choose_localized_site()

This method takes a site name that is expected to be the prefix for a
number of sites localized in different languages.  It then uses the
CPAN module: C<I18N::AcceptLanguage> to match among the options
provided in the C<Localize> configuration parameters which available
sites among those sites with multiple language support best fits the
user's language profile as represented by their
C<HTTP_ACCEPT_LANGUAGE> environmental string.  If no acceptable match
is found, it returns the default site is specified.  If no default is
provided, it will create a warning and return the argument supplied.
If there is no C<Localize> lookup for the site name it is just
returned assuming that this is a non-localized site.

=back

=over

=item Internal methods

There are four methods used internally by C<Pgreet::Config> that
should never be of interest to those working on the application layer
of Penguin Greetings.  they are listed here for completeness:

  $self->_read_config_file($config_file);
  $self->_merge_configs($default_config_hash, $config_hash);
  $self->_int_scalar_to_array($new_hash);
  $self->_swap_arrays_for_scalars($config_piece);
  $self->_chk_params_helper($to_test, \%check_configs, $test_results);

=back

=head1 COPYRIGHT

Copyright (c) 2003-2005 Edouard Lagache

This software is released under the GNU General Public License, Version 2.
For more information, see the COPYING file included with this software or
visit: http://www.gnu.org/copyleft/gpl.html

=head1 BUGS

No known bugs at this time.

=head1 AUTHOR

Edouard Lagache <pgreetdev@canebas.org>

=head1 VERSION

1.0.0

=head1 SEE ALSO

L<Config::General>, L<Pgreet>, L<Pgreet::Error>, L<Pgreet::CGIUtils>

=cut


1;
