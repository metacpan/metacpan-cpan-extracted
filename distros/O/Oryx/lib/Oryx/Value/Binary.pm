package Oryx::Value::Binary;
use base qw(Oryx::Value);
sub primitive { 'Binary' }
1;

__END__

=head1 NAME

Oryx::Value::Binary - Values containing large amounts of binary data

=head1 SYNOPSIS

  package CMS::Picture;

  use base qw( Oryx::Class );

  our $schema = {
      attributes => [ {
          name => 'filename',
          type => 'String',
      }, {
          name => 'picture',
          type => 'Binary',
      } ],
  };

  $x = CMS::Picture->create({
      filename => 'filename.jpg',
      picture  => $binary_data,
  });

=head1 DESCRIPTION

This is a basic binary field. It should be able to contain a very large amount of binary data. The limit on the amount will be database dependent.

This value type does not perform any work to check, inflate, or deflate the value. The binary data is stored as-is using the "Binary" primitive type.

=head1 SEE ALSO

L<Oryx::Value>

=head1 AUTHOR

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software and may be used under the same terms as Perl itself.

=cut
