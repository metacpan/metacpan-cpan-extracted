package Mojolicious::Command::generate::module;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util qw(class_to_file class_to_path decamelize);

has description => "Generate Mojolicious module directory structure.\n";
has usage => sub { shift->extract_usage };

sub run {
  my ($self, $mod) = @_;
  $mod ||= 'MyModule';

  die <<EOF unless $mod =~ /^[A-Z](?:\w|::)+$/;
Your module name has to be a well formed (CamelCase) Perl module name like "MyModule".
EOF

  unless (-f './config/application.yaml') {
    $self->render_to_rel_file('appconf', "./config/application.yaml", $mod);
  } else {
    say 'Add module ' . $mod . ' to ./config/application.yaml to enable.';
  }
  
  my $path = $mod;
  $path =~ s/::/\//g;
  my $lc_path = decamelize($path);
  $lc_path =~ s/\/_/\//g;
  
  if (-d './module/' . $lc_path) {
    say 'Module ' . $mod . ' already exists.';
  } else {
    $self->render_to_rel_file('mod', './module/' . $lc_path . '/lib/' . $path . '.pm', $mod);
  }
}

1;

__DATA__

@@ appconf
% my $mod = shift;
---
modules:
  - <%= $mod %>

@@ mod
% my $mod = shift;
package <%= $mod %>;
use Mojo::Base 'Mojolicious::Plugin::Module::Abstract';

sub init_config {
  my ($app, $path) = @_;
}

sub init_routes {
  my ($self, $app) = @_;
  my $r = $app->routes;
}

sub init_templates {
  my ($self, $app) = @_;
}

sub init_helpers {
  my ($self, $app) = @_;
}

sub startup {
  my ($self, $app) = @_;
}

1;

__END__

=encoding utf8

=head1 NAME

Mojolicious::Command::generate::module - Mojolicious::Plugin::Module generator command

=head1 SYNOPSIS

Usage: APPLICATION generate module [NAME]

=head1 DESCRIPTION

L<Mojolicious::Command::generate::module> generates module directory
structures for modular L<Mojolicious> applications.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Plugin::Module>.

=cut