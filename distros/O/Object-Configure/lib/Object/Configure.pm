package Object::Configure;

use strict;
use warnings;

use Carp;
use Config::Abstraction 0.25;
use Log::Abstraction 0.15;
use Params::Get;

=head1 NAME

Object::Configure - Runtime Configuration for an Object

=head1 VERSION

0.08

=cut

our $VERSION = 0.08;

=head1 SYNOPSIS

The C<Object::Configure> module is a lightweight utility designed to inject runtime parameters into other classes,
primarily by layering configuration and logging support.

L<Log::Abstraction> and L<Config::Abstraction> are modules developed to solve a specific need:
runtime configurability without needing to rewrite or hardcode behaviours.
The goal is to allow individual modules to enable or disable features on the fly, and to do it using whatever configuration system the user prefers.

Although the initial aim was general configurability,
the primary use case that's emerged has been fine-grained logging control,
more flexible and easier to manage than what you'd typically do with L<Log::Log4perl>.
For example,
you might want one module to log verbosely while another stays quiet,
and be able to toggle that dynamically - without making invasive changes to each module.

To tie it all together,
there is C<Object::Configure>.
It sits on L<Log::Abstraction> and L<Config::Abstraction>,
and with just a couple of extra lines in a class constructor,
you can hook in this behaviour seamlessly.
The intent is to keep things modular and reusable,
especially across larger systems or in situations where you want user-selectable behaviour.

Add this to your constructor:

   package My::Module;

   use Object::Configure;
   use Params::Get;

   sub new {
        my $class = shift;
        my $params = Params::Get(undef, \@_);

        $params = Object::Configure::configure($class, $params);	# Reads in the runtime configuration settings

        return bless $params, $class;
    }

Throughout your class, add code such as:

    sub method
    {
        my $self = shift;

        $self->{'logger'}->trace(ref($self), ': ', __LINE__, ' entering method');
    }

=head2 CHANGING BEHAVIOUR AT RUN TIME

=head3 USING A CONFIGURATION FILE

To control behavior at runtime, C<Object::Configure> supports loading settings from a configuration file via L<Config::Abstraction>.

A minimal example of a config file (C<~/.conf/local.conf>) might look like:

   [My::Module]

   logger.file = /var/log/mymodule.log

The C<configure()> function will read this file,
overlay it onto your default parameters,
and initialize the logger accordingly.

If the file is not readable and no config_dirs are provided,
the module will throw an error.

This mechanism allows dynamic tuning of logging behavior (or other parameters you expose) without modifying code.

More details to be written.

=head3 USING ENVIRONMENT VARIABLES

C<Object::Configure> also supports runtime configuration via environment variables,
without requiring a configuration file.

Environment variables are read automatically when you use the C<configure()> function,
thanks to its integration with L<Config::Abstraction>.
These variables should be prefixed with your class name, followed by a double colon.

For example, to enable syslog logging for your C<My::Module> class,
you could set:

    export My::Module::logger__file=/var/log/mymodule.log

This would be equivalent to passing the following in your constructor:

     My::Module->new(logger => Log::Abstraction->new({ file => '/var/log/mymodule.log' });

All environment variables are read and merged into the default parameters under the section named after your class.
This allows centralized and temporary control of settings (e.g., for production diagnostics or ad hoc testing) without modifying code or files.

Note that environment variable settings take effect regardless of whether a configuration file is used,
and are applied during the call to C<configure()>.

More details to be written.

=head1 SUBROUTINES/METHODS

=head2 configure

Configure your class at runtime.

Takes two arguments:

=over 4

=item * C<class>

=item * C<params>

A hashref containing default parameters to be used in the constructor.

=back

Returns the new values for the constructor.

Now you can set up a configuration file and environment variables to configure your object.

=cut

sub configure
{
	my $class = shift;	# Name of the calling class
	my $params = shift;	# Variables passed to the calling class's constructor
	my $array;

	if(ref($params->{'logger'}) eq 'ARRAY') {
		$array = delete $params->{'logger'};	# The merge seems to lose this
	}

	# Load the configuration from a config file, if provided
	if(exists($params->{'config_file'})) {
		# my $config = YAML::XS::LoadFile($params->{'config_file'});
		my $config_dirs = $params->{'config_dirs'};
		if((!$config_dirs) && (!-r $params->{'config_file'})) {
			croak("$class: ", $params->{'config_file'}, ": $!");
		}

		if(my $config = Config::Abstraction->new(config_dirs => $config_dirs, config_file => $params->{'config_file'}, env_prefix => "${class}::")) {
			$params = $config->merge_defaults(defaults => $params, section => $class, merge => 1, deep => 1);
		} elsif($@) {
			croak("$class: Can't load configuration from ", $params->{'config_file'}, ": $@");
		} else {
			croak("$class: Can't load configuration from ", $params->{'config_file'});
		}
	} elsif(my $config = Config::Abstraction->new(env_prefix => "${class}::")) {
		$params = $config->merge_defaults(defaults => $params, section => $class, merge => 1, deep => 1);
	}

	# Load the default logger, which may have been defined in the config file or passed in
	if(my $logger = $params->{'logger'}) {
		if(ref($logger) eq 'HASH') {
			if($logger->{'syslog'}) {
				$params->{'logger'} = Log::Abstraction->new({ carp_on_warn => 1, syslog => $logger->{'syslog'}, %{$logger} });
			} else {
				$params->{'logger'} = Log::Abstraction->new({ carp_on_warn => 1, %{$logger} });
			}
		} else {
			$params->{'logger'} = Log::Abstraction->new({ carp_on_warn => 1, logger => $logger });
		}
	} elsif($array) {
		$params->{'logger'} = Log::Abstraction->new(array => $array, carp_on_warn => 1);
		undef $array;
	} else {
		$params->{'logger'} = Log::Abstraction->new(carp_on_warn => 1);
	}

	if($array && !$params->{'logger'}->{'array'}) {
		# Put it back
		$params->{'logger'}->{'array'} = $array;
	}
	return $params;
}

=head2 instantiate($class,...)

Create and configure an object of the given class.
This is a quick and dirty way of making third-party classes configurable at runtime.

=cut

sub instantiate
{
	my $params = Params::Get::get_params('class', @_);

	my $class = $params->{'class'};

	$params = configure($class, $params);

	return bless $class->new($params), $class;
}

=head1 SEE ALSO

=over 4

=item * L<Config::Abstraction>

=item * L<Log::Abstraction>

=back

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-object-configure at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Object-Configure>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Object::Configure

=head1 LICENSE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
