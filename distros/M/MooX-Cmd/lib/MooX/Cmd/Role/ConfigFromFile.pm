package MooX::Cmd::Role::ConfigFromFile;
# ABSTRACT: MooX::ConfigFromFile support role for MooX::Cmd
our $VERSION = '1.000';
use strict;
use warnings;

use Moo::Role;


requires "config_prefixes";

around _build_config_prefixes => sub {
    my $next     = shift;
    my $class    = shift;
    my $params   = shift;
    my $cfg_pfxs = $class->$next($params, @_);

    ref $params->{command_chain} eq "ARRAY"
      and push @{$cfg_pfxs},
      grep { defined $_ } map { $_->command_name } grep { $_->can("command_name") } @{$params->{command_chain}};

    return $cfg_pfxs;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooX::Cmd::Role::ConfigFromFile - MooX::ConfigFromFile support role for MooX::Cmd

=head1 VERSION

version 1.000

=head1 DESCRIPTION

Extends L<MooX::ConfigFromFile::Role> config prefix support to include the
current command chain. Each command name in the chain is appended to the
config prefixes, allowing per-command configuration file sections.

Enable via L<MooX::Cmd>:

  package MyApp;
  use Moo;
  use MooX::Cmd with_config_from_file => 1;

This will automatically compose both L<MooX::ConfigFromFile::Role> and this
role into your command classes.

=head1 SEE ALSO

L<MooX::ConfigFromFile>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-moox-cmd/issues>.

=head2 IRC

Join C<#web-simple> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
