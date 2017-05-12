package Oryx::Value::DateTime;

use base qw(Oryx::Value);
use Class::Date qw(:errors date);

sub primitive { 'DateTime' }

sub check_type {
    my ($self, $value) = @_;
    my $date = date($value);
    if ($date->error == E_INVALID) {
	return 0;
    }
    return 1;
}

sub inflate {
    my ($self, $value) = @_;
    return date($value);
}

sub deflate {
    my ($self, $value) = @_;
    return date($value)->string;
}

1;
__END__

=head1 NAME

Oryx::Value::DateTime - Values storing dates and times

=head1 SYNOPSIS

  package CMS::Event;

  use base qw( Oryx::Class );

  use Class::Date qw( now );

  our $schema = {
      attributes => [ {
          name => 'summary',
          type => 'String',
      }, {
          name => 'when',
          type => 'DateTime',
      } ],
  };

  $x = CMS::Event->create({
      summary => 'Meet with Joe',
      when    => now,
  });

=head1 DESCRIPTION

This type stores dates and times by using L<Class::Date> objects.

This value will check to see that the value stored is a proper date and will inflate and deflate the date using L<Class::Date> to be stored in a "DateTime" primitive type field.

=head1 SEE ALSO

L<Class::Date>, L<Oryx::Value>

=head1 AUTHOR

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software and may be used under the same terms as Perl itself.

=cut
