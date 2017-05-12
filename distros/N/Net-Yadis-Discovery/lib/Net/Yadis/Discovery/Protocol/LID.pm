package Net::Yadis::Discovery::Protocol::LID;

sub import { }

package Net::Yadis::Discovery;

sub lid_servers { 
    my $self = shift;
#    my $ver = defined($_[0]) ? ref($_[0]) eq 'ARRAY' ? $_[0] : \@_ : [];
    $self->servers('lid',@_);
}

sub lid_regex { 'http://lid.netmesh.org/sso/\ver' }

1;
__END__

=head1 NAME

Net::Yadis::Discovery::Protocol::LID - Extension module that add proposal LID API to Net::Yadis::Discovery;

=head1 SYNOPSIS

  use Net::Yadis::Discovery;
  my $disc = Net::Yadis::Discovery->new();
  $disc->discover("http://id.example.com/") or Carp::croak($disc->err);

  my @openid_xrd = $disc->lid_servers(['1.0','2.0']);
                                   # Argument is Array ref of version numbers, and it's optional.

  foreach my $srv (@xrd) {         # Loop for Each Service in LID's Yadis Resourse Descriptor
    print $srv->Type;              # http://lid.netmesh.org/sso/1.0 or http://lid.netmesh.org/sso/2.0
    print $srv->URI;               # URI that resolves to a resource providing the service (scalar, array or array ref)
  }

=head1 DESCRIPTION

Add Proposal API interface (L<http://yadis.org/wiki/Proposed_Yadis_API>) to L<Net::Yadis::Discovery>.

=head1 METHODS

=over 4

=item $disc->B<lid_servers>( [$version, ...] )

Returns the LID servers as array hashes of L<Net::Yadis::Object>.
Optionally accepts a array ref of versions supported by the client as a argument.

=head1 COPYRIGHT, WARRANTY, AUTHOR

See L<Net::Yadis::Discovery> for author, copyrignt and licensing information.

=head1 SEE ALSO

L<Net::Yadis::Discovery>

Yadis website:  L<http://yadis.org/>