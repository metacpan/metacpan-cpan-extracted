package Pgreet::CGIUtils;
#
# File: CGIUtils.pm
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
#           Perl Module: Pgreet::CGIUtils
#
# This is the Penguin Greetings (pgreet) module for sharing CGI
# specific routines between the CGI program and associated modules.

# In particular it houses the routines that create the transfer
# hash reference for Embperl.
######################################################################
# $Id: CGIUtils.pm,v 1.29 2005/05/31 16:44:38 elagache Exp $

$VERSION = "1.0.0"; # update after releases

# Perl modules.
use CGI qw(:standard escape);
use CGI::Carp;

# Conditionally use Wrapper functions for Embedded Perl to avoid
# bloat of both Embperl and HTML::Mason unless both are in use.
# use Pgreet::ExecEmbperl qw(ExecEmbperl ExecObjEmbperl);
use autouse 'Pgreet::ExecEmbperl' => qw(ExecEmbperl ExecObjEmbperl);
# use Pgreet::ExecMason qw(ExecMason ExecObjMason);
use autouse 'Pgreet::ExecMason' => qw(ExecMason ExecObjMason);

# Perl Pragmas
use strict;
sub new {
#
# Create new object and squirrel away CGI query object
# so that it is available for methods.
#
  my $class = shift;
  my $Pg_config = shift;
  my $cgi_script = shift;
  my $query = shift;
  my $VERSION = shift;
  my $SpeedyCGI = shift;
  my $Invocations = shift;
  my $StartTime = shift;

  my $self = {};
  bless $self, $class;

  $self->{'Pg_config'} = $Pg_config;
  $self->{'cgi_script'} = $cgi_script;
  $self->{'query'} = $query;
  $self->{'VERSION'} = $VERSION;
  $self->{'SpeedyCGI'} = $SpeedyCGI;
  $self->{'Invocations'} = $Invocations;
  $self->{'StartTime'} = $StartTime;

  return($self);
}

sub set_site_conf {
#
# Subroutine to set pgreet_conf and card_conf objects when
# pgreet.pl.cgi has bootstrapped itself and knows which site
# it is acting upon.
#
  my $self = shift;
  my $Pg_config = shift;
  my $card_conf = shift;
  my $BackVarStr = shift;
  my $BackHiddenFields = shift;

  $self->{'Pg_config'} = $Pg_config;
  $self->{'card_conf'} = $card_conf;
  $self->{'BackVarStr'} = $BackVarStr;
  $self->{'BackHiddenFields'} = $BackHiddenFields;
}

sub set_value {
#
# Convenience method to set a value in object
#
  my $self = shift;
  my $key = shift;
  my $value = shift;

  $self->{$key} = $value;
}

sub ChangeVars {
#
# Create hash with variables needed for Embperl to process templates.
#
  my $self = shift;
  my $Transfer = {};
  my $URL_site;
  my $separator;

  # Retrieve values from object
  my $Pg_config = $self->{'Pg_config'};
  my $card_conf = $self->{'card_conf'};
  my $BackVarStr = $self->{'BackVarStr'};
  my $BackHiddenFields = $self->{'BackHiddenFields'};
  my $query = $self->{'query'};
  my $SpeedyCGI = $self->{'SpeedyCGI'};
  my $Invocations = $self->{'Invocations'};
  my $StartTime = $self->{'StartTime'};
  my $cgi_script = $self->{'cgi_script'};

  # List of configuration file items to pass to Embperl
  my @config_values = ('cgiurl', 'imageurl', 'mailprog',
					   'tmpdir', 'templatedir', 'hostname',
					   'login_only'
					  );

  # Transfer the variables needed from the configuration hash.
  foreach my $config (@config_values) {
	$Transfer->{$config} = $Pg_config->access($config);
  }

  # If Card configuration object is defined, add it to transfer hash.
  if (ref($card_conf) eq 'Pgreet::Config') {
	$Transfer->{'card_hash'} = $card_conf->get_hash();
  }

  # Transfer the variables needed from the CGI state
  foreach my $CGI ($query->param()) {
	$Transfer->{$CGI} = $query->param($CGI);
  }

  # Special values
  $Transfer->{'script'} = $cgi_script;
  $Transfer->{'cgi_script'} = $cgi_script;
  $Transfer->{'number'} = $self->{'CardLogin'};
  $Transfer->{'error_hash'} = $self->{'error_hash'};
  $Transfer->{'error_no'} = $self->{'error_no'};
  $Transfer->{'VERSION'} = $self->{'VERSION'};
  # SpeedyCGI values
  $Transfer->{'SpeedyCGI'} = $SpeedyCGI;
  $Transfer->{'StartTime'} = $StartTime;
  $Transfer->{'Invocations'} = $Invocations;
  # Values for back buttons
  $Transfer->{'BackVarStr'} = $BackVarStr;
  $Transfer->{'BackHiddenFields'} = $BackHiddenFields;

  # Create URL to access card (for secondary ecard sites.)
  if ($query->param('site')) {
	$URL_site = join('',
					   $Pg_config->access('cgiurl'),
					   "/$cgi_script",
					   "?site=",$query->param('site')
					  );
	$separator = "&";
  } else {
	$URL_site = join('',
					   $Pg_config->access('cgiurl'),
					   "/$cgi_script",
					  );
	$separator = "?";
  }

  # In any case - provide developers with URL to site (primary or secondary.)
  $Transfer->{'URL_site'} = $URL_site;

  # Create URL short-cut to save typing for user.
  if ($Pg_config->access('allow_quick_views') and
	  exists($self->{'CardLogin'}) and
	  defined($query->param('password'))
	 ) {
	$Transfer->{'URL_short_cut'} = join('',
										$URL_site, $separator,
										"action=view&",
										"next_template=view&",
										"code=", $self->{'CardLogin'},
										"&password=",
										escape($query->param('password'))
									   );
  } else {
	$Transfer->{'URL_short_cut'} = $URL_site;
  }

  # Return hash reference
  return($Transfer);
}

sub is_bypass {
#
# Helper subroutine to test if a given template file is excluded
# from object-oriented interpretation by either Embperl or Mason
#
  my $self = shift;
  my $template_file = shift;
  my $bypass_info = shift;
  my @except_templates;

  # Get a list (even of one item) of excluded files.
  if (ref($bypass_info) eq 'ARRAY') {
	@except_templates = @{$bypass_info};
  } else {
	@except_templates = ( $bypass_info );
  }

  foreach my $file (@except_templates) {
	# If this is an excluded file - forced standard processing.
	if ($file eq $template_file) {
      return(1);
	}
  }

  return(0); # If we get here, file wasn't excluded
}

sub Embperl_Execute {
#
# Subroutine to call the Embperl execute function wrappers (either
# direct object-oriented version) in a consistent fashion from either
# the CGI application of command-line test programs.
#
  my $self = shift;
  my $templatedir = shift;
  my $Embperl_file = shift;
  my $Transfer = shift;
  my $Embperl_Object = shift;
  my @except_templates;
  my $result_str;

  # If this is an object-oriented call, check if template isn't excluded
  if ($Embperl_Object and exists($Embperl_Object->{'bypass_object'})) {

	# If this is an excluded file - forced standard processing.
	if ( $self->is_bypass($Embperl_file,
                          $Embperl_Object->{'bypass_object'})
        ) {
	  $Embperl_Object = 0; # If excluded file - don't use Embperl::Object
	}

  }

  # If this is still an Embperl::Object call provide all parameters for call
  if ($Embperl_Object) {
	$Embperl_Object->{'inputfile'} = "$templatedir/$Embperl_file";
	$Embperl_Object->{'output'} = \$result_str;
	$Embperl_Object->{'param'} = [$Transfer];

	# If an object addpath convert from UNIX to Perl arrayref.
	if (exists($Embperl_Object->{'object_addpath'})) {
	  my @path_array = split(':', $Embperl_Object->{'object_addpath'});
	  $Embperl_Object->{'object_addpath'} = \@path_array;
	# If user doesn't provide an object_addpath - assume template path
	} else {
	  my $Pg_config = $self->{'Pg_config'};
	  $Embperl_Object->{'object_addpath'} =
		[ $Pg_config->access('templatedir') ];

	}

	# Provide a dummy application if none is provided.
	unless (exists($Embperl_Object->{'appname'})) {
	  $Embperl_Object->{'appname'} = "Default App";
	}

	# Use wrapper to call Object-Oriented version of Embperl
	ExecObjEmbperl($Embperl_Object);

  # Else use wrapper to execute "direct" Embperl
  } else {
	ExecEmbperl( {inputfile  => "$templatedir/$Embperl_file",
				  output => \$result_str,
				  param  => [$Transfer],
				 }
			   );

  }

  return($result_str);
}

sub Mason_Execute {
#
# Subroutine to call the HTML::Mason execute function wrappers (either
# direct object-oriented version) in a consistent fashion from either
# the CGI application of command-line test programs.
#
  my $self = shift;
  my $templatedir = shift;
  my $Mason_file = shift;
  my $Transfer = shift;
  my $Mason_Object = shift;
  my $comp_root = $Mason_Object->{'comp_root'};
  my $data_dir =  $Mason_Object->{'data_dir'};
  my $result_str;

  # Create Hash_ref of arguments to Mason::Interp->new
  my $Interp_obj_args = {comp_root  => $comp_root,
						 data_dir   => $data_dir,
						 out_method => \$result_str,
						};

  # Get relative path from component root for template
  my $comp_path = "$templatedir/$Mason_file";
  $comp_path =~ s/$comp_root//;

  # If we have bypass objects call version of wrapper that disables
  # use of autohandlers.
  if ( $Mason_Object->{'bypass_object'} and
       $self->is_bypass($Mason_file,
						$Mason_Object->{'bypass_object'}) ) {

	  ExecMason($Interp_obj_args, $comp_path, $Transfer);

    # Otherwise use object-oriented Mason wrapper function.
	} else {
	  ExecObjMason($Interp_obj_args, $comp_path, $Transfer);
  }

  return($result_str);
}

=head1 NAME

Pgreet::CGIUtils - Penguin Greetings shared routines for CGI functions.

=head1 SYNOPSIS

  # Constructor:
  $Pg_cgi = new Pgreet::CGIUtils($Pg_default_config, $cgi_script,
                                 $query, $SpeedyCGI, $Invocations,
                                 $StartTime
                                );

  # Set card site specific configuration
  $Pg_cgi->set_site_conf($Pg_config, $card_conf, $BackVarStr,
                         $BackHiddenFields
                        );

  # Assign a value to be passed on to Embperl
  $Pg_cgi->set_value('error_hash', $error_hash);

  # Create Transfer hash for Embperl
  my $Transfer = $Pg_cgi->ChangeVars();

  # Test if file $Embperl_file is excluded from object-oriented
  # Embperl interpretation:
  if ( $Pg_cgi->is_bypass($Embperl_file,
                          $Embperl_Object->{'bypass_object'})
     ) { }

  # Execute the Embperl template file: $file in an object-oriented
  # environment
  $result_str = $Pg_cgi->Embperl_Execute($templatedir, $file,
                                         $Transfer,
                                         $Embperl_Object
                                         );

  # Execute the Mason template file: $file
  $result_str = $Pg_cgi->Mason_Execute($templatedir, $file,
                                       $Transfer,
                                       $Mason_Object,
                                      );


=head1 DESCRIPTION

The module C<Pgreet::CGIUtils> is the Penguin Greetings module for any
routines that must be shared between the CGI application and other
modules.  This includes the creation of a hash of values to be
transferred from Penguin Greetings to Embperl for processing of
templates and providing a uniform interface between Penguin Greetngs
and Embedded Perl Enviroments (Embperl and HTML::Mason.)

Like the other modules associated with Penguin Greetings, there is a
certain bit of bootstrapping involved.  The constructor is used as
soon as the other main objects associated with Penguin Greetings are
created.  However, that information may not be up-to-date once
secondary ecard sites have been selected.  So the state of the
CGIUtils object is updated once an ecard site is definitely selected.

For the matter of setting up the Transfer hash to Embperl/Mason, the
method C<ChangeVars> is used in two settings.  It is used within the
main CGI Application itself and used with C<Pgreet::Error> to allow
for error templates to have access to all of the state variables that
content developers would have access to in a normal (non-error)
situation.

=head1 CONSTRUCTING A CGIUTILS OBJECT

The C<Pgreet::CGIUtils> constructor should be called after a query
object has been obtained from the CGI module and a Penguin Greetings
Configuration object has been created.  In addition,
C<Pgreet::CGIUtils> requires one additional argument and has three
other arguments related to the SpeedyCGI version of Penguin Greetings.
The required argument is the name of the script creating the object
(usually the basename of C<$0>.)  The three optional arguments are a
boolean which if true indicates that this script is running as a
SpeedyCGI process, the number of SpeedyCGI innovcations, and the UNIX
time when this SpeedyCGI process was started.  The calling syntax is
illustrated below:

  $Pg_cgi = new Pgreet::CGIUtils($Pg_default_config, $cgi_script,
                                 $query, $SpeedyCGI, $Invocations,
                                 $StartTime
                                 );

Because the Penguin Greetings error object needs a reference to the
C<Pgreet::CGIUtils> object, you should use the C<add_cgi_obj> method
of C<Pgreet::Error> to attach that reference as soon as you have
created the new CGIUtils object:

  # Attach new CGIUtils object to Error obj.
  $Pg_error->add_cgi_obj($Pg_cgi);

  $Pg_error = new Pgreet::Error($Pg_default_config, 'CGIApp');

From that point on, this error object can be used to report errors in
the application with all state variables available for error template.

=head1 METHODS TO UPDATE STATE

Once the C<Pgreet::CGIUtils> object has been created, you may need to
update some of the settings with which it was created.  There is a
very particular point when this must be done, when the choice of ecard
sites has been made and the object needs to now reflect those
configuration settings.  There is a specific method for the post ecard
site adjustment and a general method for all other cases.

Once an ecard site is selected, use the C<set_site_conf> method to
update the essential parameters.  It expects 4 parameters: the Penguin
Greetings configuration object (for that site,) the card configuration
object, and the URL get parameter and URL post hidden fields needed to
"back up" via a new CGI request.  The call look like:

  # Set card site specific configuration
  $Pg_cgi->set_site_conf($Pg_config, $card_conf, $BackVarStr,
                         $BackHiddenFields
                        );

As the CGI Application is run, it may create other values that must be
passed to Embperl.  To set these values generally, use the
C<set_value> method.  It takes two parameters: the name of the value
to set and the value to assign to it.  These values are simply added
to the hash associated with the C<Pgreet::CGIUtils> object.  So it is
possible to reset anything.  Thus documented, it becomes a feature and
programmers are thus warned.  An example call is provided below:

  $Pg_cgi->set_value('error_hash', $error_hash);

=head1 CGI UTILITY METHODS

The utility functions that can be used from C<Pgreet::CGIUtils> are
listed below.

=over

=item ChangeVars()

This is the method that creates a transfer hash to pass on to Embperl.
It takes no parameters and instead provides a "snapshot" of the
current state of the CGI application at the time of its invocation.  A
sample call is provided below:

  # Create Transfer hash for Embperl
  my $Transfer = $Pg_cgi->ChangeVars();

=item is_bypass()

This method tests if a template file is on a list of templates to be
excluded from object-oriented processing (typically text-only email
messages.)  It is used in the methods that prep calls to either
Embperl or Mason but could be of use outside.  A sample call would be
as follows (assuming an Embperl Object configuration setting:)

  # Test if file $Embperl_file is excluded from object-oriented
  # Embperl interpretation:
  if ( $Pg_cgi->is_bypass($Embperl_file,
                          $Embperl_Object->{'bypass_object'})
     ) { }

=item Embperl_Execute()

This function provides a uniform interface for Penguin Greetings to
the Embperl Perl within HTML environment.  The same function is used
within C<PgTemplateTest> and C<pgreet.pl.cgi>.  It also provides the
abstraction that allows for Embperl to be 'autoused' as needed at
runtime.  It requires 3 to 4 arguments: the directory where templates
are stored, the filename of the template to execute, a C<$Transfer>
styled hash-ref of parameters to the template and if appropriate the
C<Embperl_Object> configuration hash-ref.  The method call returns a
string containing the rendered HTML from the template.A sample call is
shown below:

  # Execute the Embperl template file: $file in an object-oriented
  # environment
  $result_str = $Pg_cgi->Embperl_Execute($templatedir, $file,
                                         $Transfer,
                                         $Embperl_Object
                                        );

=item Mason_Execute()

This function provides for the HTML::Mason environment the same
uniform interface that Embperl_Execute provides for Embperl.  It takes
the same arguments and returns the rendered HTML as a string.  A
sample call is shown below:

  # Execute the Mason template file: $file
  $result_str = $Pg_cgi->Mason_Execute($templatedir, $file,
                                       $Transfer,
                                       $Mason_Object,
                                      );

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

L<Pgreet>, L<Pgreet::Config>, L<Pgreet::Error>, L<Pgreet::ExecEmbperl>,
L<Pgreet::ExecMason>, L<CGI::Carp>

=cut

1;
