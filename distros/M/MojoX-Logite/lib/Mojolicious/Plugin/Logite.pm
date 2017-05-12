package Mojolicious::Plugin::Logite;

use strict;
use warnings;

use base 'Mojolicious::Plugin';

use MojoX::Logite;

sub register
{
  my ($self, $app, $conf) = @_;

  $conf ||= {};

  my $stash_key = delete $conf->{stash_key} || 'logite';

  $conf->{'path'} = $app->home->rel_file('log/mojo_log.db')
    unless (exists $conf->{'path'});

  my $logite = MojoX::Logite->new (%$conf);

  # Default
  $app->defaults($stash_key => $logite);

  return $logite;
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::Logite - Mojo::Log ORLite (Logite) plugin for Mojolicious

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('logite');

    # or customized
    $self->plugin('logite' => {
        path  => '/var/log/mojo.db',
        level => 'warn',
        package => 'MyApp::Logite'
        });

    # Mojolicious::Lite
    plugin logite => {
  	path  => '/var/log/mojo.db',
	level => 'warn',
        package => 'MyApp::Logite'
	};

=head1 DESCRIPTION

L<Mojolicious::Plugin::Logite> is a Mojo::Log ORLite (Logite) plugin for L<Mojolicious>.

=head2 Options

=over

=item  MojoX::Logite options

  # Mojolicious::Lite
  plugin logite => {
    path  => '/var/log/mojo.db',
    level => 'warn',
    package => 'MyApp::Logite'
  };

Replace default log db settings. See MojoX::Logite documentation.

=item stash_key

  # Mojolicious::Lite
  plugin logite => {stash_key => 'logdb'};

The plugin automatically register a new DB logger into the 'logite' stash. With this option
the name of the stash filed can be customized.

=back

=head1 METHODS

L<Mojolicious::Plugin::Logite> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

    $plugin->register;

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<MojoX::Logite>

L<Mojolicious>

=cut
