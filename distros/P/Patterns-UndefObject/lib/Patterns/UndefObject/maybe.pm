package Patterns::UndefObject::maybe;

=head1 NAME

Patterns::UndefObject::maybe - Install a 'maybe' top lwvel package

=head1 SYNOPSIS

    use Patterns::UndefObject::maybe;

    my $name = $user_rs->maybe::find(100)->name
      || 'Unknown Username';

=head1 DESCRIPTION

See L<Patterns::UndefObject> for project details.  This package does
everything that those documents describe, but instead if doing it via
an importable method (Maybe) or via a factory method, it installs a
top level 'maybe' namespace.  You may find this approach more appealoing,
or you might find it to be a namespace polluter.  You decide.

=head1 AUTHOR

See L<Patterns::UndefObject>

=head1 COPYRIGHT & LICENSE

See L<Patterns::UndefObject>

=cut

package maybe;

use Patterns::UndefObject;

sub AUTOLOAD {
  my $invocant = shift;
  my ($method) = our $AUTOLOAD =~ /^maybe::(.+)$/;
  return Patterns::UndefObject->maybe($invocant->$method(@_));
}

1;
