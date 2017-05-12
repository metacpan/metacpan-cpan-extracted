package Test::PlugAuth::Plugin;

use strict;
use warnings;

# ABSTRACT: Private package for Test::PlugAUth::Plugin::* modules
our $VERSION = '0.35'; # VERSION


BEGIN {
  $ENV{LOG_LEVEL} = "ERROR";

  unless($INC{'File/HomeDir/Test.pm'}) 
  {
    require File::HomeDir::Test;
    File::HomeDir::Test->import;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::PlugAuth::Plugin - Private package for Test::PlugAUth::Plugin::* modules

=head1 VERSION

version 0.35

=head1 SEE ALSO

L<PlugAuth>,
L<Test::PlugAuth::Plugin::Auth>,
L<Test::PlugAuth::Plugin::Authz>,
L<Test::PlugAuth::Plugin::Refresh>

=head1 AUTHOR

Graham Ollis <gollis@sesda3.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
