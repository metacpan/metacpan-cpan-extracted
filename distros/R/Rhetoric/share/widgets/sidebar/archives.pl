use common::sense;
use File::Basename;
use Data::Dump 'pp';

# archive list
sub {
  my ($self)  = @_;
  my $v       = $self->v;
  my $tt      = $self->env->{tt};
  my $storage = $self->env->{storage};
  my $template;
  my ($file, $dir, $suffix) = fileparse(__FILE__, '.pl');
  $template = $file;
  $template =~ s/\d+_//;
  $template .= ".html";
  my $out;

  $v->{archives} = [ $storage->archives() ];
  $tt->process($template, $v, \$out);
  $out;
}
