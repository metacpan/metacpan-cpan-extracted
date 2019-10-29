package Mojolicious::Command::Author::generate::role 0.002;

use Mojo::Base 'Mojolicious::Command';

use Mojo::Util qw(camelize class_to_path getopt);

has description => 'Generate Mojolicious role directory structure';
has usage       => sub { shift->extract_usage };

sub run {
    my ( $self, @args ) = @_;

    getopt \@args, 'f|full' => \( my $full );

    # Class
    my $name  = pop @args // 'MyRole';
    my $consumer  = pop @args;
    my $class = $consumer && !$full ? "${consumer}::Role::${name}" : $name;
    ( $consumer, $name ) = ( $1, $2 )
      if ( !$consumer && $class =~ m/^(.*)::Role::(.*)/ );
    my $sname = $consumer && $class =~ m/^${consumer}::Role::(.*)/ ? "+$1" : $class;
    $consumer //= 'Mojo::Base';

    my $dir  = join '-', split( '::', $class );
    my $app  = class_to_path $class;
    my $vars = {
        class      => $class,
	use_consumer   => !exists $INC{class_to_path($consumer)},
        consumer => $consumer,
        name       => $name,
        sname      => $sname,
        path       => $app
    };
    $self->render_to_rel_file( 'class', "$dir/lib/$app", $vars );

    # Test
    $self->render_to_rel_file( 'test', "$dir/t/basic.t", $vars );

    # Makefile
    $self->render_to_rel_file( 'makefile', "$dir/Makefile.PL", $vars );
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::Author::generate::role - Role generator command

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  Usage: APPLICATION generate role [OPTIONS] [[CONSUMER_CLASS] NAME]

    mojo generate role
    mojo generate role MyRole
    mojo generate role Mojo::Whatever MyRole
    mojo generate role Mojo::Whatever::Role::MyRole
    mojo generate role -f Mojo::Whatever MyRole

  Options:
    -f, --full   NAME is the full role name (omit 'CONSUMER_CLASS::Role::')
    -h, --help   Show this summary of available options

=head1 DESCRIPTION

L<Mojolicious::Command::Author::generate::role> generates directory structures
for fully functional roles to use with L<Mojolicious> objects/classes.

If the intended consumer class is not specified it will be inferred from the
role name given (whatever precedes C<::Role::> in the name) or otherwise
default to L<Mojo::Base>.

=head1 ATTRIBUTES

L<Mojolicious::Command::Author::generate::role> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones:

=head2 description

  my $description = $role_cmd->description;
  $role_cmd       = $role_cmd->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage = $role_cmd->usage;
  $role_cmd = $role_cmd->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::Author::generate::role> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 run

  $role_cmd->run(@ARGV);

Run this command.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019, Roger Crew.

This program is free software, you can redistribute it and/or
modify it under the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut

__DATA__

@@ class
package <%= $class %>;
use Mojo::Base -role;

our $VERSION = '0.01';

# whatever
sub the_answer_to_everything {
  my $self = shift;
  return 42;
}

1;
<% %>__END__

<% %>=encoding utf8

<% %>=head1 NAME

<%= $class %> - Add important functionality to L<<%= $consumer %>> objects

<% %>=head1 SYNOPSIS

  $new_class = <%= $consumer %>->with_roles('<%= $sname %>');
  $object = <%= $consumer %>->new(...)->with_roles('<%= $sname %>');

  $result = $object->the_answer_to_everything;

<% %>=head1 DESCRIPTION

L<<%= $class %>> is a role that adds some important functionality to L<<%= $consumer %>> objects.

<% %>=head1 METHODS

L<<%= $class %>> supplies the following methods to the host object/class:

<% %>=head2 the_answer_to_everything

  $answer = $obj->the_answer_to_everything();

This method implements the important functionality
(but is actually an example that should be deleted; surprise).

<% %>=head1 SEE ALSO

L<<%=$consumer%>>, L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

<% %>=cut

@@ test
use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
% if ($use_consumer) {
use <%=$consumer%> ();
% }
use Test::Mojo;

my $class = <%=$consumer%>->with_roles('<%=$sname%>');
ok(defined $class, "class->with_roles works");

get '/' => sub {
  my $c = shift;
  my $result = $class->new->the_answer_to_everything;
  $c->render(text => "$result");
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is('42');

done_testing();

@@ makefile
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => '<%= $class %>',
  VERSION_FROM => 'lib/<%= $path %>',
  AUTHOR       => 'A Good Programmer <nospam@cpan.org>',
  PREREQ_PM    => {
      'Mojolicious' => '<%= $Mojolicious::VERSION %>',
      'Role::Tiny' => '2.000001',
      # 'Class::Method::Modifiers' => 0,
  },
  test         => {TESTS => 't/*.t'}
);
