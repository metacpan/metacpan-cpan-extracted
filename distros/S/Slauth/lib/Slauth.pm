package Slauth;
# this module is just to provide the version number and POD docs for the
# Slauth package.  It doesn't do anything itself.

use 5.008005;
use strict;
use warnings;

our $VERSION = '0.02';
our $RELEASE = '0_pre9h';

1;
__END__

=head1 NAME

Slauth - authentication system for Apache 2 with plugin architecture

=head1 SYNOPSIS

  use Slauth::User::Web;

  my $web = new Slauth::User::Web ( "request" => $r );
  return $web->interface;

=head1 DESCRIPTION

TBA

=head1 SEE ALSO

Slauth::Config, Slauth::AAA::Authen, Slauth::AAA::Authz,
Slauth::Storage::User_DB, Slauth::Storage::DB, Slauth::Storage::Session_DB,
Slauth::Storage::Confirm_DB, Slauth::Config::Apache, Slauth::User::Web

See the project web site at http://www.slauth.org/

Project mail lists are at http://www.slauth.org/mailman/listinfo

=head1 AUTHOR

Ian Kluft, E<lt>ikluft-slauth@thunder.sbay.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ian Kluft

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
