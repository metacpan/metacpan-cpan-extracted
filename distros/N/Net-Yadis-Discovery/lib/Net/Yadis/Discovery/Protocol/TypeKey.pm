package Net::Yadis::Discovery::Protocol::TypeKey;

sub import { }

package Net::Yadis::Discovery;

sub typekey_servers { 
    my $self = shift;
#    my $ver = defined($_[0]) ? ref($_[0]) eq 'ARRAY' ? $_[0] : \@_ : [];
    $self->servers('typekey',@_);
}

sub typekey_regex { 'http://www.sixapart.com/typekey/sso/\ver' }

sub typekey_objectclass { 'Net::Yadis::Object::TypeKey' }

package Net::Yadis::Object::TypeKey;

use base qw(Net::Yadis::Object);

sub MemberName {
    shift->extra_field('MemberName','http://www.sixapart.com/typekey/xmlns/1.0');
}

1;
__END__

=head1 NAME

Net::Yadis::Discovery::Protocol::TypeKey - Extension module that add TypeKey API to Net::Yadis::Discovery;

=head1 SYNOPSIS

  use Net::Yadis::Discovery;
  my $disc = Net::Yadis::Discovery->new();
  $disc->discover("http://id.example.com/") or Carp::croak($disc->err);

  my @openid_xrd = $disc->typekey_servers(['1.0','1.1');
                                   # Argument is Array ref of version numbers, and it's optional.

  foreach my $srv (@xrd) {         # Loop for Each Service in TypeKey's Yadis Resourse Descriptor
    print $srv->Type;              # http://www.sixapart.com/typekey/sso/1.0
    print $srv->URI;               # URI value is no meaning in TypeKey protocol...
    print $srv->MemberName;        # To get TypeKey Account attribute 
  }

=head1 DESCRIPTION

Add Proposal API interface (L<http://yadis.org/wiki/Proposed_Yadis_API>) to L<Net::Yadis::Discovery>.

=head1 METHODS

=over 4

=item $disc->B<typekey_servers>( [$version, ...] )

Returns the TypeKey accounts as array hashes of L<Net::Yadis::Object::TypeKey>.
Optionally accepts a array ref of versions supported by the client as a argument.

Notice: TypeKey has only one login server, so API name B<typekey_servers> seems funny.
But this is to give same interface to other protocol.

=item $srv->B<MemberName>

L<Net::Yadis::Object::TypeKey>'s method to get TypeKey account name.

=head1 COPYRIGHT, WARRANTY, AUTHOR

See L<Net::Yadis::Discovery> for author, copyrignt and licensing information.

=head1 SEE ALSO

L<Net::Yadis::Discovery>

Yadis website:  L<http://yadis.org/>