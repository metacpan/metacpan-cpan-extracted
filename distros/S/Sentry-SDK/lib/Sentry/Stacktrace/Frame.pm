package Sentry::Stacktrace::Frame;
use Mojo::Base -base, -signatures;

use Mojo::Home;

has [qw(package filename line subroutine)];
has _source_file_registry => sub { Sentry::SourceFileRegistry->new };
has _home                 => sub { Mojo::Home->new->detect };

sub _is_in_app ($self) {
  return $self->filename !~ /\.cpan/
    && index($self->filename, $self->_home) > -1;
}

sub _map_file_to_context ($self) {
  return $self->_source_file_registry->get_context_lines($self->filename,
    $self->line);
}

sub TO_JSON ($self) {
  return {
    in_app    => \($self->_is_in_app()),
    abs_path  => $self->filename,
    file_name => 'bla',
    lineno    => $self->line,
    package   => $self->package,
    function  => $self->subroutine,
    %{ $self->_map_file_to_context() },
  };
}

sub from_caller ($package, $pkg, $filename, $line, $subroutine, @args) {
  return $package->new({
    package    => $pkg,
    filename   => $filename,
    line       => $line,
    subroutine => $subroutine
  });
}

1;
