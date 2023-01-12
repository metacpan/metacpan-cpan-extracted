package Pod::Weaver::Config 4.019;
# ABSTRACT: stored configuration loader role

use Moose::Role;

use Config::MVP 2;
use Pod::Weaver::Config::Assembler;

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod The config role provides some helpers for writing a configuration loader using
#pod the L<Config::MVP|Config::MVP> system to load and validate its configuration.
#pod
#pod =attr assembler
#pod
#pod The L<assembler> attribute must be a Config::MVP::Assembler, has a sensible
#pod default that will handle the standard needs of a config loader.  Namely, it
#pod will be pre-loaded with a starting section for root configuration.
#pod
#pod =cut

sub build_assembler {
  my $assembler = Pod::Weaver::Config::Assembler->new;

  my $root = $assembler->section_class->new({
    name    => '_',
  });

  $assembler->sequence->add_section($root);

  return $assembler;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Config - stored configuration loader role

=head1 VERSION

version 4.019

=head1 DESCRIPTION

The config role provides some helpers for writing a configuration loader using
the L<Config::MVP|Config::MVP> system to load and validate its configuration.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 ATTRIBUTES

=head2 assembler

The L<assembler> attribute must be a Config::MVP::Assembler, has a sensible
default that will handle the standard needs of a config loader.  Namely, it
will be pre-loaded with a starting section for root configuration.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
