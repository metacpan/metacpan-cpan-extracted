package Pod::Weaver::Role::Plugin;
# ABSTRACT: a Pod::Weaver plugin
$Pod::Weaver::Role::Plugin::VERSION = '4.017';
use Moose::Role;

use Params::Util qw(_HASHLIKE);

use namespace::autoclean;

#pod =head1 IMPLEMENTING
#pod
#pod This is the most basic role that all plugins must perform.
#pod
#pod =attr plugin_name
#pod
#pod This name must be unique among all other plugins loaded into a weaver.  In
#pod general, this will be set up by the configuration reader.
#pod
#pod =cut

has plugin_name => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

#pod =attr weaver
#pod
#pod This is the Pod::Weaver object into which the plugin was loaded.  In general,
#pod this will be set up when the weaver is instantiated from config.
#pod
#pod =cut

has weaver => (
  is  => 'ro',
  isa => 'Pod::Weaver',
  required => 1,
  weak_ref => 1,
);

has logger => (
  is   => 'ro',
  lazy => 1,
  handles => [ qw(log log_debug log_fatal) ],
  default => sub {
    $_[0]->weaver->logger->proxy({
      proxy_prefix => '[' . $_[0]->plugin_name . '] ',
    });
  },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Role::Plugin - a Pod::Weaver plugin

=head1 VERSION

version 4.017

=head1 ATTRIBUTES

=head2 plugin_name

This name must be unique among all other plugins loaded into a weaver.  In
general, this will be set up by the configuration reader.

=head2 weaver

This is the Pod::Weaver object into which the plugin was loaded.  In general,
this will be set up when the weaver is instantiated from config.

=head1 IMPLEMENTING

This is the most basic role that all plugins must perform.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
