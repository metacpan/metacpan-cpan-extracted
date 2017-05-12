package Mojolicious::Command::generate::controller;
# ABSTRACT: Mojolicious command generator for controllers
use Mojo::Base 'Mojolicious::Command';
  
# version
our $VERSION = '0.02';

use Mojolicious;
use Mojo::Util qw(class_to_path);


has description => 'This aplication generate controller classes';
has usage => sub{ shift->_show_usage };

sub run {
  my ($self, $class, $actions) = (shift, shift, [@_]);
  
  $self->usage unless $class;
  
  # error - controller name malformed
  die 'Your controller name has to be a well formed (CamelCase) like "MyController".'
    unless $class =~ /^[A-Z](?:\w|::)+$/;

  # controller
  my $controller = "${class}";
  my $path       = class_to_path $controller;

  $self->render_to_rel_file('controller', "lib/$path", $controller, $actions);
}

sub _show_usage {
  say qq{
Usage: APPLICATION generate controller [CONTROLLER] [ACTION_LIST]

  mojo generate controller MyAPP::Controller::User
  mojo generate controller MyAPP::Controller::User index create show update remove

Options:
  -h, --help   Show this summary of available options
  };

  exit;
}
 
1;


=encoding utf8
 
=head1 NAME
 
Mojolicious::Command::generate::controller - Controller generator command
 
=head1 SYNOPSIS
 
  Usage: APPLICATION generate controller [CONTROLLER] [ACTION_LIST]
 
    mojo generate controller MyAPP::Controller::User
    mojo generate controller MyAPP::Controller::User index create show update remove
 
  Options:
    -h, --help   Show this summary of available options
 
=head1 DESCRIPTION
 
L<Mojolicious::Command::generate::controller> generates controller directory
structure, file and action methods for a L<Mojolicious::Controller> class.

This command extends core command b<generate> to help developers criating
quickly controller class files.

See L<Mojolicious::Commands/"COMMANDS"> for a list of commands that are
available by default.
 
=head1 ATTRIBUTES
 
L<Mojolicious::Command::generate::controller> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.
 
=head2 usage
 
  my $usage = $app->usage;
 
Usage information for this command, used for the help screen.
 
=head1 METHODS
 
L<Mojolicious::Command::generate::controller> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.
 
=head2 run
 
  $app->run(@ARGV);
 
Run this command.
 
=head1 SEE ALSO
 
L<Mojolicious::Command>, L<Mojolicious::Guides>, L<http://mojolicious.org>.
 
=head1 AUTHOR

Daniel Vinciguerra <daniel.vinciguerra@bivee.com.br>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Daniel Vinciguerra.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

@@ controller
% my ($class, $actions) = @_;
package <%= $class %>;
use Mojo::Base 'Mojolicious::Controller';
 
% for my $a ( sort @$actions ){
# action for <%= $a %>
sub <%= $a %> {
  my $self = shift;
}

% }
 
1;
