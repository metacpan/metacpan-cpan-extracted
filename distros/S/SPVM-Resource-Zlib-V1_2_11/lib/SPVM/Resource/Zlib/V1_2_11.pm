package SPVM::Resource::Zlib::V1_2_11;

our $VERSION = '0.01';

1;

=head1 NAME

SPVM::Resource::Zlib::V1_2_11 - zlib v1.2.11 Resource

=head1 SYNOPSYS
  
  # SPVM/MyZlib.config
  use strict;
  use warnings;

  my $config = SPVM::Builder::Config->new_gnu99(file => __FILE__);

  $config->use_resource('Resource::Zlib::V1_2_11');

  $config;
  
=head1 DESCRIPTION

C<SPVM::Resource::Zlib::V1_2_11> is a resource of zlib v1.2.11

See L<SPVM::Resource::Zlib>.

=head1 AUTHOR

Yuki Kimoto

=head1 COPYRIGHT & LICENSE

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
