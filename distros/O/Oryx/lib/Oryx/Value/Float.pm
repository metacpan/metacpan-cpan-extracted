package Oryx::Value::Float;
use base qw(Oryx::Value);

use Data::Types qw(is_float to_float);

sub primitive { 'Float' }

sub check_type {
    my ($self, $value) = @_;
    return is_float($value);
}

sub check_size {
    my ($self, $value) = @_;
    my $p = $self->meta->getMetaAttribute("precision");
    if (defined $p) {
	my $rx = '^\d+\.\d{0,'.$p.'}$';
	return $value =~ /$rx/;
    }
    return 1;
}

1;
__END__

=head1 NAME

Oryx::Value::Float - Values containing floating-point data

=head1 SYNOPSIS

  package CMS::LedgerEntry;

  use base qw( Oryx::Class );

  our $schema = {
      attributes => [ {
          name => 'summary',
          type => 'String',
      }, {
          name => 'amount',
          type => 'Float',
      } ],
  };

  $x = CMS::Picture->create({
      summary => 'New PDA',
      amount  => 342.17,
  });

=head1 DESCRIPTION

This value stores floating-point data. It has an optional field called "precision" that can be used to set how many decimal places should be stored in the database.

This value type is checked to see that it is in fact a decimal number and is stored with the "Float" primitive type.

=head1 SEE ALSO

L<Oryx::Value>

=head1 AUTHOR

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software and may be used under the same terms as Perl itself.

=cut
