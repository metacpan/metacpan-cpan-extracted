use common::sense;
use File::Basename;

sub {
  my ($self, @args) = @_;
  my $tt = $self->env->{tt};
  my $template;
  my ($file, $dir, $suffix) = fileparse(__FILE__, '.pl');
  $template = $file;
  $template =~ s/\d+_//;
  $template .= ".html";
  my $out;
  $tt->process($template, $self->v, \$out);
  $out;
}
