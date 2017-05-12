package MojoX::Log::Any;
# ABSTRACT: Use the current Log::Any adapter from Mojolicious

use strict;
use warnings;

our $VERSION = '0.005';

use Log::Any;
use Log::Any::Plugin;
use Class::Load qw( is_class_loaded );
use Class::Method::Modifiers qw( install_modifier );

sub import {
  my $class = shift;
  my $caller = caller;

  my $lite = is_class_loaded( 'Mojolicious::Lite' );
  my $mojo = $caller->isa( 'Mojolicious' );

  my $log = Log::Any->get_logger(
    default_adapter => 'MojoLog',
    category => $caller,
    @_,
  );

  Log::Any::Plugin->add( 'History', size => 10 );
  Log::Any::Plugin->add( 'Format' );

  # Manually inflate nulls, since we are not doing automatic assignment
  $log->inflate_nulls if $log->isa('Log::Any::Proxy::Null');

  if ($lite) {
    # Using Mojolicious::Lite

    return if $caller->app->log->isa('Log::Any::Proxy');
    $caller->app->log( $log );
  }
  elsif ($mojo) {
    # Caller inherits from Mojolicious

    # Entirely replace Mojolicious log method, so we return a reference to
    # the Log::Any proxy instead of to Mojo::Log
    install_modifier( $caller, 'around', log => sub {
      my $orig = shift;
      my $self = shift;

      $log = $_[1] if @_ > 1;
      return $log;
    });
  }
}

1;

__END__

=encoding utf8

=head1 NAME

MojoX::Log::Any - Use the current Log::Any adapter from Mojolicious

=head1 SYNOPSIS

  use Mojolicious::Lite;

  # Use Mojo::Log by default when importing
  use MojoX::Log::Any;

  # Or you can specify a different default adapter
  use MojoX::Log::Any default_adapter => 'Stderr';

  get '/' => sub {
    my $c = shift;

    app->log->debug('Using Log::Any::Adapter::MojoLog');

    # They can be redefined
    use Log::Any::Adapter;
    Log::Any::Adapter->set('Stderr');
    app->log->warning('Using Log::Any::Adapter::Stderr')
      if app->log->is_warning;

    # Or use whatever adapter you've set
    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($ERROR);

    Log::Any::Adapter->set('Log4perl');
    app->log->fatalf('Formatting with %s', 'Log::Any::Adapter::Log4perl');

    $c->render(text => 'OK!');
  };

  app->start;

=head1 DESCRIPTION

L<MojoX::Log::Any> makes it easy to use a L<Log::Any::Adapter> from within
L<Mojolicious> without getting in the way of the user.

When imported from within a Mojolicious application (of from within a
package into which Mojolicious' app function has been exported), it sets
that application's log attribute to a L<Log::Any::Proxy> connected to
whatever adapter is currently available.

When imported, the logger defaults to using L<Log::Any::Adapter::MojoLog>,
which seems to be the currently maintained adapter for L<Mojo::Log>. Any
parameters passed to the module's C<import> function are passed I<as is>
to the C<get_logger> function from L<Log::Any>, to allow for user
customisation and to maintain a coherent interface with that package.

=head1 MOTIVATION

There are numerous packages in the "MojoX::Log" namespace providing an
interface with the various different logging mechanisms on CPAN; except
Log::Any.

There is also a Log::Any adapter for Mojo::Log, which makes it
possible to use that logger from any application using Log::Any; but
not Mojolicious apps.

This package attempts to fill that void by offering Mojolicious
applications an easy way to plug into the current Log::Any::Adapter
(whatever it may be).

=head1 INTERNALS AND CAVEATS

This module does a fair amount of meddling in the namespace of the caller and
that of the currently available L<Log::Any::Adapter>, so use at your own risk.

The module detects L<Mojolicious> apps by checking the inheritance tree of the
caller; while L<Mojolicious::Lite> apps are detected by checking whether that
module is loaded.

With Mojolicious::Lite apps, the application's C<log> attribute is simply set
to the current adapter. With Mojolicious apps, this overrides the C<log>
function in that module to set or get a reference to the Log::Any::Proxy object.

In order to more closely mimic the behaviour of L<Mojo::Log>, this module also
installs the L<Format|Log::Any::Plugin::Format> and
L<History|Log::Any::Plugin::History> plugins from L<Log::Any::Plugin>, which
will make the adapter usable with the default Mojolicious HTML templates.

Since the message formatting in most adapters is hard coded (or configured
through external configuration files), the starting set by this module is a
no-op. This means that the formatting won't perfectly mimic that of Mojo::Log,
but avoids clashes with other logging mechanisms.

=head1 CONTRIBUTIONS AND BUG REPORTS

The main repository for this distribution is on
L<GitLab|https://gitlab.com/jjatria/MojoX-Log-Any>, which is where patches
and bug reports are mainly tracked. Bug reports can also be sent through the
CPAN RT system, or by mail directly to the developers at the address below,
although these will not be as closely tracked.

=head1 SEE ALSO

=over 4

=item * L<Log::Any>

=item * L<Log::Any::Plugin>

=item * L<Log::Any::Adapter::MojoLog>

=item * L<Log::Any::Adapter::Mojo>

=back

=head1 AUTHOR

=over 4

=item * José Joaquín Atria <jjatria@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016-2017 by José Joaquín Atria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
