package Net::Yadis::Object;

use strict;
use warnings;

sub URI { Net::Yadis::Discovery::_pack_array(shift->{'URI'}) }
sub Type { Net::Yadis::Discovery::_pack_array(shift->{'Type'}) }
sub priority { shift->{'priority'} }

sub extra_field {
    my $self = shift;
    my ($field,$xmlns) = @_;
    $xmlns and $field = "\{$xmlns\}$field";
    $self->{$field};
}

1;
__END__

=head1 NAME

Net::Yadis::Object - a class of Yadis Resourse Descriptor's Service Object

=head1 SYNOPSIS

  use Net::Yadis::Discovery;
  my $disc = Net::Yadis::Discovery->new();
  my @xrd = $disc->discover("http://id.example.com/") or Carp::croak($disc->err);

  foreach my $srv (@xrd) {         # Loop for Each Service in Yadis Resourse Descriptor
    print $srv->priority;          # Service priority (sorted)
    print $srv->Type;              # Identifier of some version of some service (scalar, array or array ref)
    print $srv->URI;               # URI that resolves to a resource providing the service (scalar, array or array ref)
    print $srv->extra_field("Delegate","http://openid.net/xmlns/1.0");
                                   # Extra field of some service
  }

=head1 DESCRIPTION

After L<Net::Yadis::Discovery> crawls Yadis URL, finds Yadis Resource
Descriptor URL, and reads XRD file, you get this objects. 

=head1 METHODS

=over 4

=item $srv->B<priority>

This field specified preferences for the service.

=item $srv->B<Type>

Returns URI or XRI type identifier of some version of some service.

=item $srv->B<URI>

Returns URI that resolves to a resource providing the service.

=item $srv->B<extra_field>( $fieldname , $namespace )

Accessor of extra service fields.
Argument $namespace is optional, and if specified, can access to other xml namespace fields.

=head1 COPYRIGHT, WARRANTY, AUTHOR

See L<Net::Yadis::Discovery> for author, copyrignt and licensing information.

=head1 SEE ALSO

L<Net::Yadis::Discovery>

Yadis website:  L<http://yadis.org/>