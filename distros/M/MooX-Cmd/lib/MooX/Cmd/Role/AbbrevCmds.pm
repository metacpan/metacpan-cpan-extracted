package MooX::Cmd::Role::AbbrevCmds;
# ABSTRACT: Text::Abbrev support role for MooX::Cmd
use strict;
use warnings;
our $VERSION = '1.001';

use Moo::Role;

use Carp qw(croak);


requires "command_commands";

around _build_command_commands => sub {
    my $next     = shift;
    my $class    = shift;
    my $params   = shift;
    my $cmd_cmds = $class->$next($params, @_);

    eval { require Text::Abbrev; 1 }
      or croak "MooX::Cmd::Role::AbbrevCmds requires Text::Abbrev, please install it: $@";

    my %abbrevs  = Text::Abbrev::abbrev(keys %$cmd_cmds);
    my %cmd_cmds = map { $_ => $cmd_cmds->{$abbrevs{$_}} } keys %abbrevs;

    return \%cmd_cmds;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooX::Cmd::Role::AbbrevCmds - Text::Abbrev support role for MooX::Cmd

=head1 VERSION

version 1.001

=head1 DESCRIPTION

When this role is applied, commands can be called by any unambiguous prefix.
For example, if your app has commands C<frobnicate> and C<format>, typing
C<frob> will match C<frobnicate>. Uses L<Text::Abbrev> internally.

Compose into your top-level command class alongside L<MooX::Cmd>:

  package MyApp;
  use Moo;
  use MooX::Cmd with_abbrev_cmds => 1;

Or apply the role explicitly:

  package MyApp;
  use Moo;
  with 'MooX::Cmd::Role';
  with 'MooX::Cmd::Role::AbbrevCmds';

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-moox-cmd/issues>.

=head2 IRC

Join C<#web-simple> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
