package Rose::Conf;

use strict;

use Carp();

our $VERSION = '0.021';

our $ExportLevel = 0;

sub import
{
  my($pkg, $export_name) = @_;

  return  unless(@_ > 1 && length $export_name);

  my($callpkg) = caller($ExportLevel);

  return if($pkg eq __PACKAGE__);

  #
  # Mostly lifted from Exporter.pm
  #

  # Make import warnings look like they're coming from the "use"
  local $SIG{'__WARN__'} = sub
  {
    my($text) = shift;

    if($text =~ s/ at \S*Rose\/Conf.pm line \d+.*\n//)
    {
      local $Carp::CarpLevel = 1; # ignore package calling us too.
      carp $text;
    }
    else
    {
      warn $text;
    }
  };

  local $SIG{'__DIE__'} = sub
  {
    local $Carp::CarpLevel = 1; # ignore package calling us too.
    Carp::croak "$_[0] Illegal null symbol in \@${1}::EXPORT"
      if($_[0] =~ /^Unable to create sub named "(.*?)::"/);
  };

  unless($export_name =~ /^%\w+$/)
  {
    local $Carp::CarpLevel = 0;
    Carp::croak "Usage: use $pkg qw(%SOME_HASH)";
  }

  # Chop off the %
  $export_name = substr($export_name, 1);

  # Alias the %CONF hash
  no strict 'refs';
  *{"${callpkg}::$export_name"} = \%{"${pkg}::CONF"}
}

sub param
{
  my($class) = shift;

  my $conf = $class->conf_hash;

  if(@_)
  {
    my $param = shift;

    if(@_)
    {
      return $conf->{$param} = shift;
    }
    else
    {
      Carp::croak "No such conf parameter in $class: '$param'\n"
        unless(exists $conf->{$param});

      if(ref $conf->{$param} eq 'HASH')
      {
        return bless $conf->{$param}, 'Rose::Conf::Setting';
      }

      return $conf->{$param};
    }
  }

  Carp::croak "Cannot get param() without parameter name";
}

sub conf_hash
{
  my($class) = shift;

  no strict 'refs';

  return \%{$class . '::CONF'};
}

sub param_exists
{
  my($class, $param) = @_;

  Carp::croak "Cannot check if param_exists() without parameter name"
    unless(defined $param);

  my $conf = $class->conf_hash;

  return exists $conf->{$param};
}

BEGIN
{
  package Rose::Conf::Setting;
  our @ISA = qw(Rose::Conf);
  sub conf_hash { $_[0] }
}


1;

__END__

=head1 NAME

Rose::Conf - Configuration module base class.

=head1 SYNOPSIS

    # File: My/System/Conf.pm
    package My::System::Conf;

    use strict;
    use Rose::Conf;
    our @ISA = qw(Rose::Conf);

    our %CONF =
    (
      COLOR => 'blue',
      SIZE  => 'big',
      PORTS =>
      {
        ssh => 22,
        ftp => 21,
      },
      ...
    );

    ...

    # File: My/System.pm

    # Import conf hash under name of your choice
    use My::System::Conf qw(%SYS_CONF);
    ...
    $color = $SYS_CONF{'COLOR'}; # get
    $SYS_CONF{'COLOR'} = 'red';  # set
    $port = $SYS_CONF{'PORTS'}{'ssh'}; # get nested
    $SYS_CONF{'PORTS'}{'ssh'} = 2200;  # set nested

    or

    # File: My/System.pm
    use My::System::Conf; # Don't import any symbols
    ...
    $color = My::System::Conf->param('COLOR'); # get
    My::System::Conf->param(COLOR => 'red');   # set
    # get/set nested values
    $port = My::System::Conf->param('PORTS')->param{'ssh'};
    My::System::Conf->param('PORTS')->param{'ssh' => 2200};

    or

    # File: My/System.pm
    use My::System::Conf; # Don't import any symbols
    ...
    $conf  = My::System::Conf->conf_hash;
    $color = $conf->{'COLOR'}; # get
    $conf->{'COLOR'} = 'red';  # set
    $port = $conf->{'PORTS'}{'ssh'}; # get nested
    $conf->{'PORTS'}{'ssh'} = 2200;  # set nested

=head1 DESCRIPTION

Traditionally, module configuration information is stored in package globals
or lexicals, possibly with class methods as accessors.   This system works,
but it also means that looking up configuration information requires loading
the entire module.

C<Rose::Conf> is a base class that promotes the collect all configuration
information for a module into a separate, lighter-weight module. Configuration
information may be imported as a hash into other packages under any desired
name, accessed via a C<param()> class method, or through a reference to the
configuration hash returned by the C<conf_hash()> class method.

This strategy will make even more sense once you read about
C<Rose::Conf::FileBased> and the (currently unreleased) build and
configuration system that leverages it.

Configuration modules should inherit from C<Rose::Conf> and define a
package global C<%CONF> hash.  Example:

    package Site::Conf;

    use strict;
    use Rose::Conf;
    our @ISA = qw(Rose::Conf);

    our %CONF =
    (
      NAME => 'MySite',
      HOST => 'mysite.com',
      IP   => '123.123.123.123',
      PORTS =>
      {
        main => 80,
        ssl  => 443,
      },
      ...
    );

Modules or scripts that want to import this configuration have three
choices: importing a hash, using the C<param()> class method, or using
the C<conf_hash()> class method.

=head2 IMPORTING A HASH

To import the configuration hash, C<use> the configuration module and
provide the name of the hash that will be used to access it.  Examples:

    # Alias %SITE_CONF to %Site::Conf::CONF
    use Site::Conf qw(%SITE_CONF);

    # Alias %REMOTE_CONF to %Remote::Conf::CONF
    use Remote::Conf qw(%REMOTE_CONF);

    $site_name = $SITE_CONF{'NAME'}; # get
    $REMOTE_CONF{'NAME'} = 'Remote'; # set
    $port = $SITE_CONF{'PORTS'}{'main'}; # get nested
    $SITE_CONF{'PORTS'}{'main'} = 8000;  # set nested

=head2 USING THE param() CLASS METHOD

To use the C<param()> class method, C<use> the configuration module
without any arguments, then call C<param()> with one argument to get a
value, and two arguments to set a value.  Example:

    use Site::Conf;
    ...
    $name = Site::Conf->param('NAME');      # get
    Site::Conf->param(NAME => 'MyNewSite'); # set

Calls to the C<param()> method can be chained in order to access configuration
values in nested hashes.  Example:

    # get/set nested values
    $port = Site::Conf->param('PORTS')->param('ssh');
    Site::Conf->param('PORTS')->param('ssh' => 2200);

=head2 USING THE conf_hash() CLASS METHOD

To use the C<conf_hash()> class method, C<use> the configuration module
without any arguments, then call C<conf_hash()> to retrieve a reference
to the configuration hash.  Example:

    use Site::Conf;
    ...
    $conf = Site::Conf->conf_hash;

    $name = $conf->{'NAME'};         # get
    $conf->{'NAME'} = 'MyNewSite';   # set
    $port = $conf->{'PORTS'}{'ssl'}; # get nested
    $conf->{'PORTS'}{'ssl'} = 4430;  # set nested

=head2 WHICH METHOD SHOULD I USE?

Each methods has its advantages.  The biggest advantage of using C<param()> is
that it will croak if you try to access a nonexistent configuration parameter
(see class method documentation below). Directly accessing the configuration
hash by importing it, or through the hash reference returned by C<conf_hash>,
is faster than calling the C<param()> method, but offers no safeguards for
nonexistent configuration parameters (it will autovivify them just like a
regular hash).

=head1 CONVENTIONS

The convention for naming a configuration class is to take the name of the
module being configured and add "::Conf" to the end.  So the configuration
module for C<My::Class> would be C<My::Class::Conf>.

By convention, top-level configuration parameter names should use uppercase
letters. (e.g., "COLOR" or "SIZE", not "color" or "Size")

=head1 CLASS METHODS

=over 4

=item B<conf_hash>

Returns a reference to the configuration hash.

=item B<param NAME [, VALUE]>

When passed a single NAME argument, returns the value of that configuration
parameter, or croaks if the parameter does not exist.

If an optional VALUE argument is passed, the configuration parameter specified
by NAME is set to VALUE.  The parameter is created if it does not already
exist.  The new value is returned.

Calls to C<param()> can be chained in order to access configuration values in
nested hashes.  Example:

    # get/set nested values
    $port = Site::Conf->param('PORTS')->param('ssh');
    Site::Conf->param('PORTS')->param('ssh' => 2200);

If VALUE is a reference to a hash, it is blessed into an undocumented class
that you should not be concerned with.  It is safe to simply treat the
now-blessed reference as a regular hash reference, just be aware that calling
C<ref()> on it will not return "HASH".

=item B<param_exists NAME>

Returns true if a configuration parameter named NAME exists, false otherwise.

Calls to C<param_exists()> can be placed at the end of a chain of calls to
C<param()> in order to check for the existence of configuration values in
nested hashes.  Example:

    Site::Conf->param('PORTS')->param_exists('ssh');

=back

=head1 AUTHOR

John C. Siracusa (siracusa@mindspring.com)

=head1 COPYRIGHT

Copyright (c) 2004 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
