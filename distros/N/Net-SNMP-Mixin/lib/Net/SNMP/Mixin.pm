package Net::SNMP::Mixin;

use 5.006;
use strict;
use warnings;

=head1 NAME

Net::SNMP::Mixin - mixin framework for Net::SNMP

=head1 VERSION

Version 0.14

=cut

our $VERSION = '0.14';

=head1 ABSTRACT

Thin framework to access cooked SNMP information from SNMP agents with various mixins to Net::SNMP.

=cut

#
# store this package name in a handy variable,
# used for unique prefix of mixin attributes
# storage in instance hash
#
my $prefix = __PACKAGE__;

#
# this module import config
#
use Carp ();
use Scalar::Util 'refaddr';
use Package::Generator;
use Package::Reaper;
use Net::SNMP::Mixin::Util qw/push_error get_init_slot/;

#
# this module export config
#
my @mixin_methods;

BEGIN {
  @mixin_methods = (
    qw/ mixer init_mixins init_ok errors /
  );
}

use Sub::Exporter -setup => {
  into    => 'Net::SNMP',
  exports => [@mixin_methods],
  groups  => { default => [@mixin_methods] }
};

# needed for housekeeping of already mixed in modules
# in order to find double mixins
my @class_mixins;

=head1 SYNOPSIS

  use Net::SNMP;
  use Net::SNMP::Mixin;

  my $session = Net::SNMP->session( -hostname => 'example.com' );
  
  # method mixin and initialization
  $session->mixer(qw/Net::SNMP::Mixin::Foo Net::SNMP::Mixin::Bar/);
  $session->init_mixins();
  
  # event_loop in case of nonblocking sessions
  snmp_dispatcher();

  # check for initialization errors
  $session->init_ok();

  die scalar $session->errors if $session->errors;

  # use mixed-in methods to retrieve cooked SNMP info
  my $a = $session->get_foo_a();
  my $b = $session->get_bar_b();

=head1 DESCRIPTION

Net::SNMP implements already the methods to retrieve raw SNMP values from the agents. With the help of specialized mixins, the access to these raw SNMP values is simplified and necessary calculations on these values are already done for gaining high level information.

This module provides helper functions in order to mixin methods into the inheritance tree of the Net::SNMP session instances or the Net::SNMP class itself.

The standard Net::SNMP get_... methods are still supported and the mixins fetch itself the needed SNMP values during initialization with these standard get_... methods. Blocking and non blocking sessions are supported. The mixins don't change the Net::SNMP session instance, besides storing additional payload in the object space prefixed with the unique mixin module names as the hash key.

=cut

=head1 DEFAULT EXPORTS

These methods are exported by default into the B<< Net::SNMP >> namespace:

=over 4

=item *

mixer

=item *

init_mixins

=item *

init_ok

=item *

errors

=back

Please see the following description for details.

=head2 B<< mixer(@module_names) >>

  # class method
  Net::SNMP->mixer(qw/Net::SNMP::Mixin::Foo/);

  # instance method
  $session->mixer(qw/Net::SNMP::Mixin::Yazz Net::SNMP::Mixin::Brazz/)

Called as class method mixes the methods for all session instances. This is useful for agents supporting the same set of MIBs.

Called as instance method mixes only for the calling session instance. This is useful for SNMP agents not supporting the same set of MIBs and therefore not the same set of mixin modules.

Even the SNMP agents from a big network company don't support the most useful standard MIBs. They always use proprietary private enterprise MIBs (ring, ring, Cisco, do you hear the bells, grrrmmml).

The name of the modules to mix-in is passed to this method as a list. You can mix class and instance mixins as you like, but importing the same mixin module twice is an error.

Returns the invocant for chaining method calls, dies on error.

=cut

sub mixer {
  my ( $self, @mixins ) = @_;

  for my $mixin (@mixins) {

    # check: already mixed-in as class-mixin?
    Carp::croak "$mixin already mixed into class,"
      if grep m/^$mixin$/, @class_mixins;

    # instance- or class-mixin?
    if ( ref $self ) {

      # register array for instance mixins
      $self->{$prefix}{mixins} ||= [];

      # check: already mixed-in as instance-mixin?
      Carp::croak "$mixin already mixed into instance $self,"
        if grep m/^$mixin$/, @{ $self->{$prefix}{mixins} };

      _obj_mixer( $self, $mixin );

      # register instance mixins in the object itself
      push @{ $self->{$prefix}{mixins} }, $mixin;
    }
    else {
      _class_mixer( $self, $mixin );

      # register class mixins in a package variable
      push @class_mixins, $mixin;
    }
  }

  return $self;
}

#
# Mix the module into Net::SNMP with the help of Sub::Exporter.
#
sub _class_mixer {
  my ( $class, $mixin ) = @_;

  eval "use $mixin {into => 'Net::SNMP'}";
  Carp::croak $@ if $@;
  return;
}

#
# Create a new package as a subclass of Net::SNMP
# Rebless $session in the new package.
# Mix the module into the new package with the help of Sub::Exporter.
#
sub _obj_mixer {
  my ( $session, $mixin )      = @_;
  my ( $package, $pkg_reaper ) = _make_package($session);

  # created a new PACKAGE with an armed reaper,
  # this is the first call to mixer for this $session
  if ($pkg_reaper) {

    # rebless $session to new PACKAGE, this is still a
    # subclass of Net::SNMP
    bless $session, $package;

    # When this instance is garbage collected, the $pkg_reaper
    # is DESTROYed and the PACKAGE is deleted from the symbol table.
    $session->{$prefix}{reaper} = $pkg_reaper;
  }

  eval "use $mixin {into => '$package'}";
  Carp::croak $@ if $@;
  return;
}

#
# Make unique mixin subclass for this session with name.
# Net::SNMP::<refaddr $session> und make it a subclass of Net::SNMP.
# Arm a package reaper, see perldoc Package::Reaper.
#
sub _make_package {
  my $session  = shift;
  my $pkg_name = 'Net::SNMP::__mixin__' . '::' . refaddr $session;

  # already buildt this package for this session object,
  # just return the package name
  return $pkg_name if Package::Generator->package_exists($pkg_name);

  # build this package, make it a subclass of Net::SNMP and ...
  my $package = Package::Generator->new_package(
    {
      make_unique => sub { return $pkg_name },
      isa         => ['Net::SNMP'],
    }
  );

  # ... arm a package reaper
  my $pkg_reaper = Package::Reaper->new($package);

  return ( $package, $pkg_reaper );
}

=head2 B<< init_mixins($reload) >>

This method should be called in void context.

  $session->init_mixins();
  $session->init_mixins(1);

This method redispatches to every I<< _init() >> method in the loaded mixin modules. The raw SNMP values for the mixins are loaded during this call - or via callbacks during the snmp_dispatcher event loop for nonblocking sessions - and stored in the object space. The mixed methods deliver afterwards cooked meal from these values.

The MIB values are reloaded for the mixins if the argument $reload is true. It's an error calling this method twice without forcing $reload.

If there is an error in a mixin, the rest of the initialization is skipped to preserve the current Net::SNMP error message. 

With the init_ok() method, after the snmp_dispatcher run, the successful initialization must be checked.

  $session->init_mixins;
  snmp_dispatcher;
  $session->init_ok();
  die scalar $session->errors if $session->errors;

=cut

sub init_mixins {
  my ( $session, $reload ) = @_;

  Carp::croak "pure instance method called as class method,"
    unless ref $session;

  my $agent = $session->hostname;

  my @instance_mixins = @{ $session->{$prefix}{mixins} }
    if defined $session->{$prefix}{mixins};

  # loop over all class-mixins and instance-mixins
  my @all_mixins = ( @class_mixins, @instance_mixins );

  unless ( scalar @all_mixins ) {
    Carp::carp "$agent: please use first the mixer() method, nothing to init\n";
    return;
  }

  # for each mixin module ...
  foreach my $mixin (@all_mixins) {

    # call the _init() method in module $mixin
    my $mixin_init = $mixin . '::_init';
    eval { $session->$mixin_init($reload) };

    # fatal error during mixin initialization, normally wrong
    # calling convention with $reload
    Carp::croak $@ if $@;

  }
  return;
}

=head2 B<< init_ok($mixin) >>

  $session->init_ok();
  $session->init_ok('Net::SNMP::Mixin::MyMixin');

Test if all mixins or a single mixin is proper initialized.

Returns undef on error. The error is pushed on the sessions error buffer.

  die scalar $session->errors unless $session->init_ok();

=cut

sub init_ok {
  my ( $session, $mixin, ) = @_;

  die "missing attribute 'session'," unless defined $session;

  die "'session' isn't a Net::SNMP object,"
    unless ref $session && $session->isa('Net::SNMP');

  my $agent = $session->hostname;

  #
  # test for single mixin initialization
  #

  if ( defined $mixin ) {
    if ( exists get_init_slot($session)->{$mixin}
      && get_init_slot($session)->{$mixin} == 0 )
    {
      return 1;
    }
    else {
      push_error($session, "$agent: $mixin not initialized");
      return;
    }
  }

  #
  # test for for all mixins initialization
  #

  my $init_error_flag = 0;    # reset error flag
  foreach my $mixin ( keys %{ get_init_slot($session) } ) {

    # check for init errors, pushes error msg on session error buffer
    $init_error_flag++ if not $session->init_ok($mixin);
  }

  # return undef if any mixin isn't proper initialized
  $init_error_flag ? return : return 1;
}

=head2 B<< errors($clear) >>

  @errors = $session->errors();
  @errors = $session->errors(1);

Net::SNMP::error() has only one slot for errors. During nonblocking calls it's possible that an error followed by a successful transaction is cleared before the user gets the chance to see the error. For the mixin modules we use an error buffer until they are explicit cleared.

This method returns the list of all errors pushed by any mixin module. Called in scalar context returns a string of all @errors joined with "\n".

The error buffer is cleared if the argument $clear is true.

=cut

sub errors {
  my ( $session, $clear ) = @_;

  # prepare the error buffer if not already done
  $session->{'Net::SNMP::Mixin'}{errors} ||= [];
  my @errors = @{ $session->{'Net::SNMP::Mixin'}{errors} };

  # show also the last Net::SNMP::error if available
  # and if not already included in the mixin error buffer
  if ( my $net_snmp_error = $session->error ) {
    unshift @errors, $net_snmp_error
      unless grep m/\Q$net_snmp_error\E$/, @errors;
  }

  if ($clear) {

    # clear the mixin error accumulator
    $session->{'Net::SNMP::Mixin'}{errors} = [];

    # clear the Net::SNMP error; with a private method, sigh.
    $session->_error_clear;
  }

  return wantarray ? @errors : join( "\n", @errors );
}

=head1 GUIDELINES FOR MIXIN AUTHORS

See the L<< Net::SNMP::Mixin::System >> module as a blueprint for a simple mixin module.

As a mixin-module author you must respect the following design guidelines:

=over 4

=item *

Write more separate mixin-modules instead of 'one module fits all'.

=item *

Don't build mutual dependencies with other mixin-modules.

=item *

In no circumstance change the given attributes of the calling Net::SNMP session instance. In any case stay with the given behavior for blocking, translation, debug, retries, timeout, ... of the object. Remember it's a mixin and no sub- or superclass.

=item *

Don't assume the translation of the SNMP values by default. Due to the asynchronous nature of the SNMP calls, you can't rely on the output of $session->translate. If you need a special representation of a value, you have to check the values itself and perhaps translate or untranslate it when needed. See the source of Net::SNMP::Mixin::Dot1qVlanStatic for an example.

=item *

Implement the I<< _init() >> method and fetch SNMP values only during this call. If the session instance is nonblocking use a callback to work properly with the I<< snmp_dispatcher() >> event loop. In no circumstance load additonal SNMP values outside the  I<< _init() >> method.

=item *

Don't die() on SNMP errors during I<< _init() >>, just return premature with no value. The caller is responsible to check the I<< $session->error() >> method.

=item *

Use Sub::Exporter and export the mixin methods by default.

=back

=head1 DEVELOPER INFORMATION

If mixer() is called as a class method, the mixin-methods are just imported into the Net::SNMP package.

If called as an instance method for the first time, the methods are imported into a newly generated, unique package for this session. The session instance is B<< reblessed >> into this new package. The new package B<< inherits >> from the Net::SNMP class. Successive calls for this session instance imports just the additional mixin-methods into the already generated package for this instance.

=head1 SEE ALSO

L<< Sub::Exporter >>, and the Net::SNMP::Mixin::... documentations for more details about the provided mixin methods.

=head1 REQUIREMENTS

L<Net::SNMP>, L<Sub::Exporter>, L<Package::Generator>, L<Package::Reaper>

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a bug or are experiencing difficulties that are not explained within the POD documentation, please submit a bug to the RT system (see link below). However, it would help greatly if you are able to pinpoint problems or even supply a patch. 

Fixes are dependant upon their severity and my availablity. Should a fix not be forthcoming, please feel free to (politely) remind me by sending an email to gaissmai@cpan.org .

  RT: http://rt.cpan.org/Public/Dist/Display.html?Name=Net-SNMP-Mixin

=head1 AUTHOR

Karl Gaissmaier <karl.gaissmaier at uni-ulm.de>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2015 Karl Gaissmaier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

unless ( caller() ) {
  print __PACKAGE__ . " compiles and initializes successful.\n";
}

1;

# vim: sw=2
