package Tak::ModuleLoader::Hook;

use Moo;

has sender => (is => 'ro', required => 1, weak_ref => 1);

sub Tak::ModuleLoader::Hook::INC { # unqualified INC forced into package main
  my ($self, $module) = @_;
  my $result = $self->sender->result_of(source_for => $module);
  if ($result->is_success) {
    my $code = $result->get;
    open my $fh, '<', \$code;
    return $fh;
  }
  return;
}

1;
