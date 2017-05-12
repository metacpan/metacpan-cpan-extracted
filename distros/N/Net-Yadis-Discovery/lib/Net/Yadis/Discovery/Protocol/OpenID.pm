package Net::Yadis::Discovery::Protocol::OpenID;

sub import { }

package Net::Yadis::Discovery;

sub openid_servers { 
    my $self = shift;
#    my $ver = defined($_[0]) ? ref($_[0]) eq 'ARRAY' ? $_[0] : \@_ : [];
    $self->servers('openid',@_);
}

sub openid_regex { 'http://openid.net/signon/\ver' }

sub openid_objectclass { 'Net::Yadis::Object::OpenID' }

package Net::Yadis::Object::OpenID;

use base qw(Net::Yadis::Object);

sub Delegate {
    shift->extra_field('Delegate','http://openid.net/xmlns/1.0');
}

1;
__END__

=head1 NAME

Net::Yadis::Discovery::Protocol::OpenID - Extension module that add proposal OpenID API to Net::Yadis::Discovery;

=head1 SYNOPSIS

  use Net::Yadis::Discovery;
  my $disc = Net::Yadis::Discovery->new();
  $disc->discover("http://id.example.com/") or Carp::croak($disc->err);

  my @openid_xrd = $disc->openid_servers(['1.0','1.1']);
                                   # Argument is Array ref of version numbers, and it's optional.

  foreach my $srv (@xrd) {         # Loop for Each Service in OpenID's Yadis Resourse Descriptor
    print $srv->Type;              # http://openid.net/signon/1.0 or http://openid.net/signon/1.1
    print $srv->URI;               # URI that resolves to a resource providing the service (scalar, array or array ref)
    print $srv->Delegate;          # To get OpenID's Delegate attribute 
  }

=head1 DESCRIPTION

Add Proposal API interface (L<http://yadis.org/wiki/Proposed_Yadis_API>) to L<Net::Yadis::Discovery>.

=head1 METHODS

=over 4

=item $disc->B<openid_servers>( [$version, ...] )

Returns the OpenID servers as array hashes of L<Net::Yadis::Object::OpenID>.
Optionally accepts a array ref of versions supported by the client as a argument.

=item $srv->B<Delegate>

L<Net::Yadis::Object::OpenID>'s method to get OpenID's Delegate attribute.

=head1 COPYRIGHT, WARRANTY, AUTHOR

See L<Net::Yadis::Discovery> for author, copyrignt and licensing information.

=head1 SEE ALSO

L<Net::Yadis::Discovery>

Yadis website:  L<http://yadis.org/>