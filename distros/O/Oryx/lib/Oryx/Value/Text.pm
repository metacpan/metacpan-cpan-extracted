package Oryx::Value::Text;
use base qw(Oryx::Value);

use Data::Types qw(is_string to_string);

sub primitive { 'Text' }

sub check_type {
    my ($self, $value) = @_;
    return is_string($value);
}

1;
__END__

=head1 NAME

Oryx::Value::Text - Values containing large amounts of text data

=head1 SYNOPSIS

  package CMS::Paragraph;

  use base qw( Oryx::Class );

  our $schema = {
      attributes => [ {
          name => 'heading',
          type => 'String',
      }, {
          name => 'paragraph',
          type => 'Text',
      } ],
  };

  $x = CMS::Picture->create({
      filename => 'Section 3.',
      picture  => <<LONG_TEXT,
Lorem ipsum dolar sit amet, consectetuer adipiscing elit. Nullam a eros eu
erat facibus bibendum. Fusce arcu. Cras non neque. Proin tempus, turpis
vitae malesuada tinicidunt, justo magna eleifend felis, non posuere tortor
pede quis quam. Nam magna. Donec volutpat, urna eu luctus cursus, nulla
ipsum congue lorem, nec venenatis purus odio sit amet metus. Maecenas quam
quam, egestas vel, eleifend eu, aliquet id, augue. Aenean sit amet massa.
Curabitur tempus. Ut eleifend. Donec ante. Vivamus posuere lacus site amet
ipsum. Donec condimentum ligula sed sapien. Proin sem dui, elementum et,
sollicitudin a, cursus eu, urna.
LONG_TEXT
  });

=head1 DESCRIPTION

Any large amount of text stored in a field can be stored in a Text value. This is stored using the "Text" primitive, which should be able to store large amounts of text data. 

The actual maximum length will depend upon the database, but is usually measured in Megabytes, which should be sufficient for nearly anything.

=head1 SEE ALSO

L<Oryx::Value>

=head1 AUTHOR

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software and may be used under the same terms as Perl itself.

=cut
