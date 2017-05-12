package Test::Apache2;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.05';

use Test::Apache2::Server;
use Test::Apache2::Override;

1;
__END__

=head1 NAME

Test::Apache2 - Simple test harness of mod_perl handler

=head1 SYNOPSIS

  use Test::More tests => 1;
  use Test::Apache2;
  
  my $server = Test::Apache2::Server->new;
  $server->location('/myapp', {
      PerlResponseHandler => 'MyAppHandler',
  });
  
  my $resp = $server->get('/myapp');
  is($resp->content, 'hello world');

=head1 DESCRIPTION

This module provides a simple test harness of mod_perl handler.

The difference between the module and Apache::Test is that
the former don't spawn an real Apache process.

=head1 AUTHOR

KATO Kazuyoshi E<lt>kzys@8-p.infoE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Apache::Test>, L<Test::Environment>, L<Apache2::ASP>

=cut

