use common::sense;

# category list
sub {
  my ($self) = @_;
  my $v = $self->v;
  my $tt = $self->env->{tt};
  my $storage = $self->env->{storage};
  my $template;
  my ($file, $dir, $suffix) = fileparse(__FILE__, '.pl');
  $template = $file;
  $template =~ s/\d+_//;
  $template .= ".html";
  my $out;

  $v->{categories} = [ $storage->categories() ];
  $tt->process($template, $v, \$out);
  $out;
}
