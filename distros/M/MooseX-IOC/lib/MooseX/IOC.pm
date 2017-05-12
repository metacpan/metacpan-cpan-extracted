
package MooseX::IOC;
use Moose;

use MooseX::IOC::Meta::Attribute;

our $VERSION = '0.03';

1;

__END__

=pod

=head1 NAME

MooseX::IOC - Moose attributes with IOC integration

=head1 SYNOPSIS

  # in a startup script somewhere ...

  use IOC;
  use IOC::Service::Parameterized;
  use IOC::Registry;
  use MooseX::IOC;

  {
      my $container = IOC::Container->new('MyProject');
      $container->register(IOC::Service::Literal->new('log_file' => "logfile.log"));
      $container->register(IOC::Service->new('FileLogger' => sub {
          my $c = shift;
          return FileLogger->new($c->get('log_file'));
      }));

      my $reg = IOC::Registry->new;
      $reg->registerContainer($container);
  }

  # in a .pm file somewhere ...

  package MyApplication;
  use Moose;

  has 'logger' => (
      metaclass => 'IOC',
      is        => 'ro',
      isa       => 'FileLogger',
      service   => '/MyProject/FileLogger',
  );

  # in a script file somewhere ...

  my $app = MyApplication->new;
  $app->logger; # automatically gotten from IOC

=head1 DESCRIPTION

This module provides a bridge between IOC registries and Moose objects through a
custom attribute metaclass. It compliments the C<default> option with a C<service>
option which contains a L<IOC::Registry> path (and optional parameters).

The C<service> option can be in one of the following formats:

=over 4

=item I<IOC::Registry path string>

This is the simplest version available, it is simply a path string which
can be passed to L<IOC::Registry>'s C<locateService> method.

=item I<IOC::Registry path string and parameters>

This version is for use with L<IOC::Service::Parameterized> services, and
allows you to pass additional parameters to the C<locateService> method.
It looks like this:

  has 'logger' => (
      metaclass => 'IOC',
      is        => 'ro',
      isa       => 'FileLogger',
      service   => [ '/MyProject/FileLogger' => (log_file => 'foo.log') ],
  );

=item I<CODE reference>

The last version is the most flexible, it is CODE reference which is
expected to return an ARRAY ref similar to the above version.

  has 'logger' => (
      metaclass => 'IOC',
      is        => 'ro',
      isa       => 'FileLogger',
      lazy      => 1,
      service   => sub {
          my $self = shift;
          [ '/MyProject/FileLogger' => (
                log_file => $self->log_file
            ) ]
      },
  );

=back

If the C<service> is not found and a C<default> option has been set, then
it will return the value in C<default>. This can be useful for writing
code which can potentially be run both under IOC and not under IOC.

=head1 METHODS

=over 4

=item B<meta>

=back

=head1 SEE ALSO

=over 4

=item L<IOC>

=item L<IOC::Registry>

=item L<Moose>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
