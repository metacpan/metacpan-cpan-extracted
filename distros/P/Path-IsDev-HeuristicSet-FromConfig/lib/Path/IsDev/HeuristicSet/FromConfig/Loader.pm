
use strict;
use warnings;

package Path::IsDev::HeuristicSet::FromConfig::Loader;
BEGIN {
  $Path::IsDev::HeuristicSet::FromConfig::Loader::AUTHORITY = 'cpan:KENTNL';
}
{
  $Path::IsDev::HeuristicSet::FromConfig::Loader::VERSION = '0.002000';
}

# ABSTRACT: Configuration loader and decoder for C<::FromConfig>

sub _path {
  require Path::Tiny;
  goto \&Path::Tiny::path;
}


use Class::Tiny {
  dist             => sub { 'Path-IsDev-HeuristicSet-FromConfig' },
  module           => sub { 'Path::IsDev::HeuristicSet::FromConfig' },
  config_file      => sub { 'config.json' },
  config_file_full => sub { _path( $_[0]->config->configdir )->child( $_[0]->config_file ) },
  config           => sub {
    require File::UserConfig;
    return File::UserConfig->new(
      dist   => $_[0]->dist,
      module => $_[0]->module,
    );
  },
  decoder => sub {
    require JSON;
    return JSON->new();
  },
  data => sub {
    $_[0]->decoder->decode( $_[0]->config_file_full->slurp_utf8 );
  },
  heuristics => sub {
    return $_[0]->data->{heuristics} || [];
  },
  negative_heuristics => sub {
    return $_[0]->data->{negative_heuristics} || [];
  },
};








1;

__END__

=pod

=encoding utf-8

=head1 NAME

Path::IsDev::HeuristicSet::FromConfig::Loader - Configuration loader and decoder for C<::FromConfig>

=head1 VERSION

version 0.002000

=head1 ATTRIBUTES

=head2 C<dist>

The name of the C<dist> for C<sharedir> mechanics and C<config> paths.

    Path-IsDev-HeuristicSet-FromConfig

=head2 C<module>

The name of the C<module> for C<sharedir> mechanics and C<config> paths.

    Path::IsDev::HeuristicSet::FromConfig

=head2 C<config_file>

The name of the file relative to the configuration C<dir>

    config.json

=head2 C<config_file_full>

The full path to the C<config> file.

If not specified, combined from C<config> and C<config_file> wrapped in a C<Path::Tiny>

=head2 C<config>

Returns a C<File::UserConfig> object preconfigured with a few things ( namely, C<dist> and C<module> )

=head2 C<decoder>

Returns a C<JSON> object to perform decoding with

=head2 C<data>

Returns decoded data by slurping C<config_file_full> and throwing it in C<decoder>

=head2 C<heuristics>

Proxy for C<< data->{heuristics} >>

=head2 C<negative_heuristics>

Proxy for C<< data->{negative_heuristics} >>

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Path::IsDev::HeuristicSet::FromConfig::Loader",
    "interface":"class",
    "inherits":"Class::Tiny::Object"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
