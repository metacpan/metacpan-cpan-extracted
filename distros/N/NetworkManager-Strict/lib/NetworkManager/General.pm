# PODNAME: General.pm
# ABSTRACT: NetworkManager properties general class

use v5.37.9;
use experimental qw( class builtin try );

package NetworkManager::General;
class NetworkManager::General {

  use Path::Tiny qw();

  field $path = Path::Tiny -> new( '/etc/NetworkManager/system-connections/' );
  # Configuration directory path

  field $ethernet = 'Wired connection 1';
  # Network interface profile name

  field $extension = 'nmconnection';
  # Network interface profile file extension

  method path ( ) { $path; }


  method ethernet ( ) { $ethernet; }


  method extension ( ) { $extension; }


}

__END__

=pod

=encoding UTF-8

=head1 NAME

General.pm - NetworkManager properties general class

=head1 VERSION

version 0.230480

=head1 ATTRIBUTES

=head2 path()

Returns NetworkManager configuration directory path

=head2 ethernet()

Returns NetworkManager Ethernet interface profile name

This is set as I<Wired connection 1>

=head2 extension()

Returns NetworkManager profile file extension

This is set as I<nmconnection>

=head1 AUTHOR

Elvin Aslanov <rwp.primary@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Elvin Aslanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
