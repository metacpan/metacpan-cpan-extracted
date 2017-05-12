package MooseX::LogDispatch;

use 5.008001;

our $VERSION = '1.2002';

use Moose::Role;
use Log::Dispatch::Config;
use MooseX::LogDispatch::ConfigMaker;
use Moose::Exporter;
use MooseX::LogDispatch::Logger;

Moose::Exporter->setup_import_methods(
    as_is => [ \&MooseX::LogDispatch::Logger::Logger ]
);

use Moose::Util::TypeConstraints;

my $ldc_type = subtype 'LogDispatchConfigurator' => as 'Object' => where { $_->isa('Log::Dispatch::Configurator') };

coerce 'LogDispatchConfigurator'
  => from 'Str' => via { 
    require Log::Dispatch::Configurator::AppConfig;
    Log::Dispatch::Configurator::AppConfig->new($_)
  }
  => from 'HashRef' => via { return MooseX::LogDispatch::ConfigMaker->new($_) };


has logger => (
    isa      => 'Log::Dispatch',
    is       => 'rw',
    lazy_build => 1,
);

has use_logger_singleton => (
    isa => "Bool",
    is  => "rw",
    default => 0,
);

sub _build_logger {
    my $self = shift;

    unless ( Log::Dispatch::Config->__instance and $self->use_logger_singleton ) {
        Log::Dispatch::Config->configure( $self->_build_configurator );
    }

    return Log::Dispatch::Config->instance;
}

sub _build_configurator {
    my $self = shift;
    my $meta = $self->meta;

    my $conf_method =
      $self->can('log_dispatch_conf') ||
      $self->can('config_filename');

    return $ldc_type->coercion->coerce($self->$conf_method)
      if $conf_method;

    return MooseX::LogDispatch::ConfigMaker->new({
      class     => 'Log::Dispatch::Screen',
      min_level => 'debug',
      stderr    => 1,
      format    => '[%p] %m at %F line %L%n',
    });
}


1;
__END__

=head1 NAME

MooseX::LogDispatch - A Logging Role for Moose

=head1 VERSION

This document describes MooseX::LogDispatch version 1.1000

=head1 SYNOPSIS

 package MyApp;
 use Moose;
 with 'MooseX::LogDispatch';
 # or
 # with 'MooseX::LogDispatch::Levels'
    
 # This is optional. Will log to screen if not provided
 has log_dispatch_conf => (
   is => 'ro',
   lazy => 1,
   default => sub {
     my $self = shift;
     My::Configurator->new( # <- you write this class!
         file => $self->log_file,
         debug => $self->debug,
     );
          
   }
 );

 # This is the same as the old FileBased config parameter to the role. If you
 # prefer you could name the attribute 'config_filename' instead.
 has log_dispatch_conf => (
   is => 'ro',
   lazy => 1,
   default => "/path/to/my/logger.conf"
 );

 # Here's another variant, using a Log::Dispatch::Configurator-style 
 #  hashref to configure things without an explicit subclass
 has log_dispatch_conf => (
   is => 'ro',
   isa => 'HashRef',
   lazy => 1,
   required => 1,
   default => sub {
     my $self = shift;
     return $self->debug ?
        {
          class     => 'Log::Dispatch::Screen',
          min_level => 'debug',
          stderr    => 1,
          format    => '[%p] %m at %F line %L%n',
        }
        : {
            class     => 'Log::Dispatch::Syslog',
            min_level => 'info',
            facility  => 'daemon',
            ident     => $self->daemon_name,
            format    => '[%p] %m',
        };
    },
 );


 sub foo { 
   my ($self) = @_;
   $self->logger->debug("started foo");
   ....
   $self->logger->debug('ending foo');
 }
  
=head1 DESCRIPTION

L<Log::Dispatch> role for use with your L<Moose> classes.

=head1 ACCESSORS

=head2 logger

This is the main L<Log::Dispatch::Config> object that does all the work. It 
has methods for each of the log levels, such as C<debug> or C<error>.

=head2 log_dispatch_conf

This is an optional attribute you can give to your class.  If you define it as
a hashref value, that will be interpreted in the style of the configuration
hashrefs documented in L<Log::Dispatch::Config> documents where they show
examples of using a
L<PLUGGABLE CONFIGURATOR|Log::Dispatch::Configurator/PLUGGABLE CONFIGURATOR> 
for pluggable configuration.

You can also gain greater flexibility by defining your own complete
L<Log::Dispatch::Configurator> subclass and having your C<log_dispatch_config>
attribute be an instance of this class.

If this attribute has a value of a string, it will be taken to by the path to
a config file for L<Log::Dispatch::Configurator::AppConfig>.

By lazy-loading this attribute (C<< lazy => 1 >>), you can have the
configuration determined at runtime.  This is nice if you want to change your
log format and/or destination at runtime based on things like
L<MooseX::Getopt> / L<MooseX::Daemonize> parameters.

If you don't provide this attribute, we'll default to sending everything to
the screen in a reasonable debugging format.

=head2 use_logger_singleton

If this attribute has a true value, and L<Log::Dispatch::Config> has a
configured log instance, this will be used in preference to anything set via
C<log_dispatch_config>.

The main use for this attribute is when you want to use this module in another
library module - i.e. the consumer of this role is not the end user. Setting
this attribute to true makes it much easier for the end user to configure 
logging.

Note: If you are using a class consuming this one as a role, and plan on 
reinstantiating that class, its probably a good idea to set this to 1 to avoid
errors.

=head1 SEE ALSO

L<MooseX::LogDispatch::Levels>, L<Log::Dispatch::Configurator>,
L<Log::Dispatch::Config>, L<Log::Dispatch>.

=head1 DEPRECATION NOTICE

The old C<with Logger(...)> style has been deprecated in favour of just 
using one of two roles and making the config much more flexible. As of 
version 1.2000 of this module, attempting to use it will make your code die.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-moosex-logdispatch@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

Or come bother us in C<#moose> on C<irc.perl.org>.

=head1 AUTHOR

Ash Berlin C<< <ash@cpan.org> >>
v1.2000 fixes by Mike Whitaker C<< <penfold@cpan.org> >>

Based on work by Chris Prather  C<< <perigrin@cpan.org> >>

Thanks to Brandon Black C<< <blblack@gmail.com> >> for showing me a much nicer
way to configure things.

=head1 LICENCE AND COPYRIGHT

Some development sponsored by Takkle Inc.

Copyright (c) 2007, Ash Berlin C<< <ash@cpan.org> >>. Some rights reserved.

Copyright (c) 2007, Chris Prather C<< <perigrin@cpan.org> >>. Some rights 
reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


