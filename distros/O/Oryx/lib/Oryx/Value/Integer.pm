package Oryx::Value::Integer;
use base qw(Oryx::Value);

use Data::Types qw(is_int to_int);

sub primitive { 'Integer' }

sub check_type {
    my ($self, $value) = @_;
    return is_int($value);
}

sub check_size {
    my ($self, $value) = @_;
    if (defined $self->meta->size) {
	return $value <= $self->meta->size;
    }
    return 1;
}

sub inflate {
    my ($self, $value) = @_;
    return to_int($value);
}

sub deflate {
    my ($self, $value) = @_;
    return to_int($value);
}

1;
__END__

=head1 NAME

Oryx::Value::Integer - Values containing integers

=head1 SYNOPSIS

  package CMS::Counter;

  use base qw( Oryx::Class );

  our $schema = {
      attributes => [ {
          name => 'url',
          type => 'String',
      }, {
          name => 'hit_count',
          type => 'Integer',
      } ],
  };

  $x = CMS::Picture->create({
      url       => 'http://example.com/',
      hit_count => 12_542,
  });

=head1 DESCRIPTION

A field with this value type will store integers.

The value will be checked that it is an integer and is stored in an "Integer" primitive type.

=head1 SEE ALSO

L<Oryx::Value>

=head1 AUTHOR

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software and may be used under the same terms as Perl itself.

=cut
