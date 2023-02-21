# ABSTRACT: NetworkManager strict settings class

use v5.37.9;
use experimental qw( class builtin try );

package NetworkManager::Strict;

  # @formatter:off
class NetworkManager::Strict :isa( NetworkManager::General ) {
# @formatter:on
  use Path::Tiny qw();
  use System::Command;
  my %dns = (
    OpenDNS    => [ '208.67.222.123' , '208.67.220.123' ] ,
    CloudFlare => [ '1.1.1.3' , '1.0.0.3' ] ,
  );


  method lock ( $profile = $self -> ethernet ) {
    my $file = $self -> path -> child( join '.' , $profile , $self -> extension );
    $file -> chmod( 'a-w' );
    # Default permissions: -rw------- 1 root root
  }


    method set_dns ( $profile = $self -> ethernet , $provider = $dns{OpenDNS} ) {
    my $command = System::Command -> new( # Debug with: env SYSTEM_COMMAND_TRACE=3
      'nmcli' , 'connection' ,
      'modify' , $profile ,
      'ipv4.dns' , join( ',' , $provider -> @* )
    );


  }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

NetworkManager::Strict - NetworkManager strict settings class

=head1 VERSION

version 0.230480

=head1 DESCRIPTION

=head2 DNS

=head3 OpenDNS

L<opendns.com/setupguide/#familyshield|https://www.opendns.com/setupguide/#familyshield>

=head3 CloudFlare

L<blog.cloudflare.com/introducing-1-1-1-1-for-families|https://blog.cloudflare.com/introducing-1-1-1-1-for-families/>

=head1 METHODS

=head2 lock([$profile])

Lock writing to NetworkManager profile file with C<a-w> C<chmod> permissions

The default proofile is F</etc/NetworkManager/system-connections/Wired connection 1.nmconnection>

=head2 set_dns([$profile, $provider])

set DNS providers on NetworkManager interface profile using C<nmcli> command

The default provider is I<OpenDNS FamilyShield>

This generates the section below:

  [ipv4]
  dns=208.67.222.123;208.67.220.123;

=head1 AUTHOR

Elvin Aslanov <rwp.primary@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Elvin Aslanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
