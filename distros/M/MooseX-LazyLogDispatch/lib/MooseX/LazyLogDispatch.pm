
########################################################################
# A quickie inline helper class:
########################################################################

package ## hide me from PAUSE
  MooseX::LazyLogDispatch::_ConfigMaker;
use strict; use base qw/Log::Dispatch::Configurator/;
sub new { bless { x => $_[1] } => $_[0] }
sub get_attrs_global {{format => undef, dispatchers => ['x']}}
sub get_attrs { shift->{x} }
sub needs_reload { 0 }
1;

########################################################################
# The real class:
########################################################################

package MooseX::LazyLogDispatch;

use strict;
use warnings;

our $VERSION = '0.02';

use Moose::Role;

use Log::Dispatch::Config ();

sub _get_log_dispatch_configurator_instance {
    my $self = shift;

    if(my $ldcmeta = $self->meta->find_attribute_by_name('log_dispatch_conf')) {
        if($ldcmeta->type_constraint->is_a_type_of('Object')
            && $self->log_dispatch_conf->isa('Log::Dispatch::Configurator')) {
            return $self->log_dispatch_conf;
        }
        elsif($ldcmeta->type_constraint->is_a_type_of('HashRef')) {
            return MooseX::LazyLogDispatch::_ConfigMaker->new($self->log_dispatch_conf);
        }
        else {
            die "log_dispatch_conf must be a HashRef- or "
                . "Log::Dispatch::Configurator-derived object";
        }
    }
    else {
        return MooseX::LazyLogDispatch::_ConfigMaker->new({
            class     => 'Log::Dispatch::Screen',
            min_level => 'debug',
            stderr    => 1,
            format    => '[%p] %m at %F line %L%n',
        });
    }
}

has 'logger' => (
    is => 'ro',
    isa => 'Log::Dispatch::Config',
    lazy => 1,
    required => 1,
    default => sub {
        Log::Dispatch::Config->configure(
            shift->_get_log_dispatch_configurator_instance()
        );
        Log::Dispatch::Config->instance;
    },
);

no Moose::Role; 1;
__END__

=head1 NAME

MooseX::LazyLogDispatch - A Logging Role for Moose

=head1 VERSION

This document describes MooseX::LazyLogDispatch version 0.01

=head1 SYNOPSIS

    package MyApp;
    use Moose;

    with MooseX::LazyLogDispatch;
    # or alternately, use this role instead to give your
    # class the logger methods "debug", "warning", etc...
    # with MooseX::LazyLogDispatch::Levels;

    # This part optional
    #  without it you get some default logging to the screen
    has log_dispatch_conf => (
       is => 'ro',
       isa => 'Log::Dispatch::Configurator',
       lazy => 1,
       required => 1,
       default => sub {
           my $self = shift;
           My::Configurator->new( # <- you write this class!
               file => $self->log_file,
               debug => $self->debug,
           );
       },
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
           return $self->debug
               ? {
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

=head1 INTERFACE

=head2 logger

This method is provided by this role, and it is an L<Log::Dispatch>
instance, which you can call level-names on, as in the debug
examples in the synopsis.

If you want the level-names as direct methods in your class, you
should use the L<MooseX::LazyLogDispatch::Levels>
role instead.

=head2 log_dispatch_config

This is an optional attribute you can give to your class.  If you
define it as a hashref value, that will be interpreted in the style
of the configuration hashrefs documented in L<Log::Dispatch::Config>
documents when they show examples of using L<Log::Dispatch::Configurator>
for pluggable configuration.

You can also gain greater flexibility by defining your own complete
L<Log::Dispatch::Configurator> subclass and having your C<log_dispatch_config>
attribute be an instance of this class.

By lazy-loading either one (C<lazy => 1>), you can have the configuration
determined at runtime.  This is nice if you want to change your log
format and/or destination at runtime based on things like
L<MooseX::Getopt> / L<MooseX::Daemonize> parameters.

If you don't provide this attribute, we'll default to sending everything to
the screen in a reasonable debugging format.

=head1 SEE ALSO

L<MooseX::LazyLogDispatch::Levels>
L<MooseX::LogDispatch>
L<Log::Dispatch::Configurator>
L<Log::Dispatch::Config>
L<Log::Dispatch>

=head1 AUTHOR

Brandon Black C<< <blblack@gmail.com> >>

Based in part on L<MooseX::LogDispatch> by Ash Berlin C<< <ash@cpan.org> >> and C<< <perigrin@cpan.org> >>

=head1 LICENCE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

