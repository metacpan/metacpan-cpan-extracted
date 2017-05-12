package # hide from PAUSE
  RTest::TestDB;

use base qw/DBIx::Class::Schema/;

use DateTime;

__PACKAGE__->load_classes;

sub setup_test_data {
  my $self = shift;
  $self->populate('Foo' => [
    [ qw/ first_name last_name / ],
    map { (
      [ "Joe", "Bloggs $_" ],
      [ "John", "Smith $_" ],
    ) } (1 .. 50)
  ]);
  $self->populate('Baz' => [
    [ qw/ name description/ ],
    map { [ "Baz $_", ("lorem ipsum dolor sit amet," x $_) ] } (1 .. 4)
  ]);
  $self->populate('Bar' => [
    [ qw/ name foo_id / ],
    map { [ "Bar $_", $_ ] } (1 .. 4)
  ]);
}

1;
