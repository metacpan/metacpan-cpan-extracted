package Taskwarrior::Kusarigama::Plugin::Command::Shelf;
our $VERSION = '0.003';

#ABSTRACT: Move tasks to and from the shelf.

use strict;
use warnings;

use Moo;
use MooseX::MungeHas;
use JSON;

use Clone 'clone';

extends 'Taskwarrior::Kusarigama::Plugin';

with 'Taskwarrior::Kusarigama::Hook::OnCommand';

has custom_uda => sub {
  +{
    shelved => 'On shelf',
    shelf_ts => 'Shelf date',
  }
};

sub on_command {
  my $self = shift;

  my $args = $self->args;
  my( $cmd, $query ) = $args =~ /^task\s+shelf(?:\s+(put|get))?\s+(?<query>.*)$/g;

  $cmd //= 'put';
  die "no task query provided\n" unless $query;

  my @tasks = $self->export_tasks($query);
  $self->$cmd(\@tasks);
};

sub put {
  my ( $self, $tasks ) = @_;

  return unless $tasks;

  foreach my $task (@$tasks) {
    my $new = clone $task;

    $new->{shelved} = $JSON::true;
    $new->{shelf_ts} = time() =~ s/\.\d+$//r unless $task->{shelved};

    $self->import_task($new);
  }

}

sub get {
  my ( $self, $tasks ) = @_;

  return unless $tasks;

  foreach my $task (@$tasks) {
    my $new = clone $task;

    $new->{ shelved } = $JSON::false;

    $self->import_task($new);
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Taskwarrior::Kusarigama::Plugin::Command::Shelf - Move tasks to and from the shelf.

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    # add the `shelf` command
    $ task-kusarigama add Command::Shelf

    # Shelf all tasks in the Lazy-List project
    $ task shelf put project:List-Lazy

    # Retreieve all the tasks in the Lazy-List project
    $ task shelf get project:List-Lazy

    # Individual tasks can be shelved or retrieved
    $ task shelf 28
    $ task shelf get 28

    # filter shelved tasks from next report
    $ task config report.next.filter '!shelved:true status:pending limit:papge'

=head1 DESCRIPTION

Sometimes projects aren't just put on the back burner, they're entirely put on
hold. For these times the C<shelf> command sets a C<shelved> C<uda> allowing
those tasks to be filtered out.

Without specifying C<get> or C<put> the C<shelf> command defaults to C<put>.

The C<shelf> commands work with any filtering that is supported by
L<Taskwarrior|http://taskwarrior.org/>.

=head1 ACKNOWLEDGEMENTS

Yanick Champoux for creating the extremely useful L<Taskwarrior::Kusarigama>

=head1 AUTHOR

Shawn Sorichetti <shawn@coloredblocks.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Shawn Sorichetti.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
