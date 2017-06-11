package Mojolicious::Plugin::Log::Timestamp;
use Mojolicious::Plugin -base;

use Mojar::Log;

our $VERSION = 0.041;

sub register {
  my ($self, $app, $cfg) = @_;
  my $log = Mojar::Log->new($cfg);
  $app->log($log);
  $app->log->debug(q{Customised log timestamps});
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::Log::Timestamp - Provide customised log timestamps

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Log::Timestamp');

  # Mojolicious::Lite
  plugin 'Log::Timestamp';

=head1 DESCRIPTION

Mojolicious::Plugin::Log::Timestamp is a L<Mojolicious> plugin for customising
log timestamps in your web application.

=head1 USAGE

Simply add the plugin as shown above and you will get fairly compact ISO-style
timestamps as '%Y%m%d %H:%M:%S'.  To set a custom timestamp pattern, just pass
it to the plugin.

  # Mojolicious
  $self->plugin('Log::Timestamp' => {pattern => '%F %X '});

  # Mojolicious::Lite
  plugin 'Log::Timestamp' => {pattern => '%F %X '};

See L<Mojar::Log> for more examples.  If you want ISO 8601, use '%FT%X ',
optionally omitting the 'T'.  Trailing whitespace is significant.  If you want
ultra compact, try '%y%m%d%H%M%S'.

In addition to 'pattern', you can include any of the usual L<Mojo::Log>
parameters such as 'path' and 'level'.

=head1 METHODS

L<Mojolicious::Plugin::Log::Timestamp> inherits all methods from
L<Mojolicious::Plugin>.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 RATIONALE

Usually you want your log timestamps to just do their job in the fewest
characters practical.  And everyone is entitled to their own view as to what a
log timestamp should look like.  Personally I usually choose '%y%m%d %X'.  But
none of this merits absorbing your attention, so you just use the plugin and
get on with the real work.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014--2017, Nic Sandfield.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojar::Log>, L<Mojo::Log>, L<Mojolicious::Plugin::Log::Access>.
