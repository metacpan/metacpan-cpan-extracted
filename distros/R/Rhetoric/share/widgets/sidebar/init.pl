use common::sense;
use Template;
use File::Basename;

# initialize some objects for the rest of the widgets to use
sub {
  my ($self) = @_;
  my $tt = Template->new({ POST_CHOMP => 1, INCLUDE_PATH => [ dirname(__FILE__) ] });
  $self->env->{tt} = $tt;
  undef;
  # returning undef means this widget is invisible
}
