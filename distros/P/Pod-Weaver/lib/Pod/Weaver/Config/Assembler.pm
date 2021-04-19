package Pod::Weaver::Config::Assembler;
# ABSTRACT: Pod::Weaver-specific subclass of Config::MVP::Assembler
$Pod::Weaver::Config::Assembler::VERSION = '4.017';
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

version 4.017

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
