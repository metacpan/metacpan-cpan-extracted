package Mojolicious::Command::Author::generate::cpanfile;

our $VERSION = '0.01';

use Mojo::Base 'Mojolicious::Command';

has description => 'Generate "cpanfile"';

has usage       => sub { shift->extract_usage };

sub run { shift->render_to_rel_file('cpanfile', 'cpanfile') }

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::Author::generate::cpanfile - cpanfile generator command

=head1 SYNOPSIS

  Usage: APPLICATION generate cpanfile [OPTIONS]

    mojo generate cpanfile

  Options:
    -h, --help   Show this summary of available options

=head1 DESCRIPTION

L<Mojolicious::Command::Author::generate::cpanfile> generates C<cpanfile> files
for applications.

=head1 ATTRIBUTES

L<Mojolicious::Command::Author::generate::cpanfile> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.

=head2 description

  my $description = $cpanfile->description;
  $cpanfile       = $cpanfile->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage = $cpanfile->usage;
  $cpanfile = $cpanfile->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::Author::generate::cpanfile> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 run

  $cpanfile->run(@ARGV);

Run this command.

=head1 LICENSE

Copyright (C) Bernhard Graf.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernhard Graf E<lt>augensalat@gmail.comE<gt>

=cut

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut

__DATA__

@@ cpanfile
# https://metacpan.org/pod/distribution/Module-CPANfile/lib/cpanfile.pod

requires 'Mojolicious', '<%= $Mojolicious::VERSION %>';

# requires 'Some::Module', 'VERSION';

on test => sub {
    requires 'Test::More', '0.99';
};

