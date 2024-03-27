package Pod::Weaver::Config::Assembler 4.020;
# ABSTRACT: Pod::Weaver-specific subclass of Config::MVP::Assembler

use Moose;
extends 'Config::MVP::Assembler';
with 'Config::MVP::Assembler::WithBundles';

use String::RewritePrefix;

use namespace::autoclean;

sub expand_package {
  my $str = $_[1];

  return scalar String::RewritePrefix->rewrite(
    {
      ''  => 'Pod::Weaver::Section::',
      '-' => 'Pod::Weaver::Plugin::',
      '@' => 'Pod::Weaver::PluginBundle::',
      '=' => '',
    },
    $str,
  );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Config::Assembler - Pod::Weaver-specific subclass of Config::MVP::Assembler

=head1 VERSION

version 4.020

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
