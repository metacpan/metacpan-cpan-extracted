package Oryx::Value::String;
use base qw(Oryx::Value);

use Data::Types qw(is_string to_string);

sub primitive { 'String' }

sub check_size {
    my ($self, $value) = @_;
    if (defined $self->meta->size) {
	return length($value) <= $self->meta->size;
    }
    return 1;
}

sub check_type {
    my ($self, $value) = @_;
    return is_string($value);
}

sub inflate {
    my ($self, $value) = @_;
    return to_string($value);
}

sub deflate {
    my ($self, $value) = @_;
    return to_string($value);
}

1;
__END__

=head1 NAME

Oryx::Value::String - Values containing short strings

=head1 SYNOPSIS

  package CMS::Person;

  use base qw( Oryx::Class );

  our $schema = {
      attributes => [ {
          name => 'full_name',
          type => 'String',
      }, {
          name => 'email_address',
          type => 'String',
      } ],
  };

  $x = CMS::Person->create({
      full_name     => 'Richard Hundt',
      email_address => 'richard NO SPAM AT protea-systems.com',
  });

=head1 DESCRIPTION

This value type stores relatively short strings. Most databases will allow strings to be stored in these fields up to 255 characters in length. There is an optional "size" metadata attribute for this type which can set this to an arbitrary value (defaults to 255).

The value is stored as a "String" primitive type.

=head1 SEE ALSO

L<Oryx::Value>

=head1 AUTHOR

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software and may be used under the same terms as Perl itself.

=cut
