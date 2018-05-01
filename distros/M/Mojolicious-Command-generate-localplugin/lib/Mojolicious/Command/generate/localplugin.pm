package Mojolicious::Command::generate::localplugin;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util qw(camelize class_to_path decamelize);
use Mojolicious;

our $VERSION = '0.01';

has description => 'Generate Mojolicious plugin directory structure for application';
has usage => sub { shift->extract_usage };

sub run {
  my ($self, $name) = @_;
  $name ||= 'MyPlugin';

  # Class
  my $class = $name =~ /^[a-z]/ ? camelize $name : $name;
  my $app = class_to_path $class;
  $self->render_to_rel_file('class', "lib/$app", $class, $name);

  # Test
  my $testname = decamelize $class;
  $self->render_to_rel_file('test', "t/$testname.t", $name);
}

1;

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Command::generate::localplugin

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  Usage: APPLICATION generate localplugin [OPTIONS] [NAME]

    mojo generate localplugin
    mojo generate localplugin TestPlugin

  Options:
    -h, --help   Show this summary of available options

=head1 DESCRIPTION

L<Mojolicious::Command::generate::localplugin> generates directory structures for
fully functional L<Mojolicious> plugins.

See L<Mojolicious::Commands/"COMMANDS"> for a list of commands that are
available by default.

=head1 NAME

Mojolicious::Command::generate::localplugin - Plugin generator command

=head1 ATTRIBUTES

L<Mojolicious::Command::generate::localplugin> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.

=head2 description

  my $description = $plugin->description;
  $plugin         = $plugin->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage = $plugin->usage;
  $plugin   = $plugin->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::generate::plugin> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 run

  $plugin->run(@ARGV);

Run this command.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Renee Baecker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

@@ class
% my ($class, $name) = @_;
package <%= $class %>;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.01';

sub register {
  my ($self, $app) = @_;
}

1;
<% %>__END__

<% %>=encoding utf8

<% %>=head1 NAME

<%= $class %> - Mojolicious Plugin

<% %>=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('<%= $name %>');

  # Mojolicious::Lite
  plugin '<%= $name %>';

<% %>=head1 DESCRIPTION

L<<%= $class %>> is a L<Mojolicious> plugin.

<% %>=head1 METHODS

L<<%= $class %>> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

<% %>=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

<% %>=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

<% %>=cut

@@ test
% my $name = shift;
use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin '<%= $name %>';

get '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello Mojo!');
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is('Hello Mojo!');

done_testing();
