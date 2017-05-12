package Oryx::Value::Boolean;
use base qw(Oryx::Value);

sub primitive { 'Integer' }

sub check_type {
    my ($self, $value) = @_;
    return 1 if ($value =~ /^[01]$/);
}

sub inflate {
    my ($self, $value) = @_;
    return +$value;
}

sub deflate {
    my ($self, $value) = @_;
    return +$value;
}

1;
__END__

=head1 NAME

Oryx::Value::Boolean - Values containing a single boolean value

=head1 SYNOPSIS

  package CMS::ReadWritePermission;

  use base qw( Oryx::Class );

  our $schema = {
      attributes => [ {
          name => 'filename',
          type => 'String',
      }, {
          name => 'read',
          type => 'Boolean',
      }, {
          name => 'write',
          type => 'Boolean',
      } ],
  };

  $x = CMS::ReadWritePermission->create({
      filname => 'file.txt',
      read    => 1,
      write   => 0,
  });

=head1 DESCRIPTION

This is a basic boolean field. The value stored is either true or false, but this value enforces the convention that 0 is false and 1 is true and no other values are acceptable.

This value type checks the types to make sure they are correct provides methods to make sure that any values stored are stored as an integer. The boolean data is stored using the "Integer" primitive type.

=head1 SEE ALSO

L<Oryx::Value>

=head1 AUTHOR

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software and may be used under the same terms as Perl itself.

=cut
