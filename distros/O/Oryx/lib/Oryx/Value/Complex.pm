package Oryx::Value::Complex;

use base qw(Oryx::Value);

use YAML;

sub primitive { 'Text' }

sub inflate {
    my ($self, $value) = @_;
    if (defined $value) {
	return YAML::Load($value);
    }
}

sub deflate {
    my ($self, $value) = @_;
    return YAML::Dump($value);
}

1;
__END__

=head1 NAME

Oryx::Value::Complex - Values containing complex Perl types

=head1 SYNOPSIS

  package CMS::Setting;

  use base qw( Oryx::Class );

  our $schema = {
      attributes => [ {
          name => 'setting_key',
          type => 'String',
      }, {
          name => 'setting_value',
          type => 'Complex',
      } ],
  };

  $x = CMS::Setting->create({
      setting_key   => 'my_setting',
      setting_value => {
          foo => 1,
          bar => 2,
          baz => [ 1, 2, 3 ],
      },
  });

=head1 DESCRIPTION

This is a good catch-all type for many kinds of Perl data. It can store any arbitrarily complex data structure that is serializable with L<YAML>. This includes almost anything. However, you should probably see that documentation and test your particular data first as YAML cannot serialize everything.

This value type does not perform any work to check, but uses YAML to inflate and deflate the data into the "Text" primitive type.

=head1 SEE ALSO

L<Oryx::Value>, L<YAML>

=head1 AUTHORS

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software and may be used under the same terms as Perl itself.

=cut
