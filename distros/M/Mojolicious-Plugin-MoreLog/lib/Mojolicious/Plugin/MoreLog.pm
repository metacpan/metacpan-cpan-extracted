package Mojolicious::Plugin::MoreLog;

# ABSTRACT: Adds printf and dump to Mojo::Log

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util qw/dumper monkey_patch/;

sub register {
    my ($self, $app, $conf) = @_;
    monkey_patch "Mojo::Log", "dump" => sub {
	my $self = shift;
	if (scalar @_ > 1) {
	    $self->info(dumper \@_)
	} else {
	    $self->info(dumper shift)
	}
    };  
    monkey_patch "Mojo::Log", "printf" => sub {
	my $self = shift;
	$app->log->info(sprintf shift, @_);
    };
}

1;

=pod

=head1 NAME

Mojolicious::Plugin::MoreLog - Add printf and dump methods to Mojo::Log

=head1 SYNOPSIS

  plugin 'MoreLog';

  # Later in your app
  $app->log->printf("User %s logged in", $user);
  $app->log->dump($data);

=head1 DESCRIPTION

L<Mojolicious::Plugin::MoreLog> is a plugin for Mojolicious that monkey-patches
L<Mojo::Log> to add two convenience methods: C<dump> and C<printf>.

These methods allow quick structured logging and formatted message logging
respectively.

=head1 METHODS

=head2 register

  $plugin->register($app, \%conf);

Registers the plugin and injects the following methods into L<Mojo::Log>:

=over 4

=item * dump(@args)

Logs a data dump of the arguments using L<Mojo::Util/dumper> at C<info> level.

  $app->log->dump($user);
  $app->log->dump($user, $session, \%env);

=item * printf($format, @args)

Logs a message using C<sprintf> with the provided format string and arguments,
also at C<info> level.

  $app->log->printf("Logged in user %s with ID %d", $name, $id);

=back

=head1 SEE ALSO

L<Mojolicious>, L<Mojo::Log>, L<Mojo::Util/monkey_patch>, L<Mojo::Util/dumper>

=head2 AUTHORS

Simone Cesano <scesano@cpan.org>

=head2 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Simone Cesano.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
