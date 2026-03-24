use v5.36.0;
package Sieve::Generator::Lines::PrettyCommand 0.001;
# ABSTRACT: a Sieve command statement with arguments aligned across multiple lines

use Moo;
with 'Sieve::Generator::Lines';

use Params::Util qw(_ARRAY0);

#pod =head1 DESCRIPTION
#pod
#pod A C<PrettyCommand> is like a L<Sieve::Generator::Lines::Command>, but renders
#pod its arguments in groups, with each group on its own line and arguments within
#pod a group aligned to the column after the command identifier.  This is useful
#pod for commands with many tagged arguments, such as C<fileinto>.
#pod
#pod =attr identifier
#pod
#pod This attribute holds the name of the Sieve command.
#pod
#pod =cut

has identifier  => (is => 'ro', required => 1);

#pod =attr arg_groups
#pod
#pod This attribute holds the list of argument groups.  Each group is either an
#pod arrayref of arguments (rendered together on one line) or a single argument.
#pod Groups are rendered on successive lines, aligned after the command name.
#pod
#pod =cut

has _arg_groups => (is => 'ro', required => 1, init_arg => 'arg_groups');
sub arg_groups { $_[0]->_arg_groups->@* }

#pod =method args
#pod
#pod   my @args = $cmd->args;
#pod
#pod This method returns the flat list of all arguments, with arrayref groups
#pod expanded in place.
#pod
#pod =cut

sub args ($self) {
  return map {; _ARRAY0($_) ? @$_ : $_ } $self->arg_groups;
}

sub as_sieve ($self, $i = undef) {
  my $indent  = q{  } x ($i // 0);
  my $indent2 = q{ } x (1 + length $self->identifier);

  my $str = $indent . $self->identifier;
  my $n = 0;

  my @queue = $self->arg_groups;
  while (@queue) {
    my @next = shift @queue;
    @next = $next[0]->@* if _ARRAY0($next[0]);

    my $hunk = join q{ }, map {; ref ? $_->as_sieve(0) : $_ } @next;
    $hunk .= ";" unless @queue;
    $hunk .= "\n";

    $str .= $n++ ? "$indent$indent2$hunk" : " $hunk";
  }

  return $str;
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sieve::Generator::Lines::PrettyCommand - a Sieve command statement with arguments aligned across multiple lines

=head1 VERSION

version 0.001

=head1 DESCRIPTION

A C<PrettyCommand> is like a L<Sieve::Generator::Lines::Command>, but renders
its arguments in groups, with each group on its own line and arguments within
a group aligned to the column after the command identifier.  This is useful
for commands with many tagged arguments, such as C<fileinto>.

=head1 PERL VERSION

This module is shipped with no promise about what version of perl it will
require in the future.  In practice, this tends to mean "you need a perl from
the last three years," but you can't rely on that.  If a new version of perl
ship, this software B<may> begin to require it for any reason, and there is
no promise that patches will be accepted to lower the minimum required perl.

=head1 ATTRIBUTES

=head2 identifier

This attribute holds the name of the Sieve command.

=head2 arg_groups

This attribute holds the list of argument groups.  Each group is either an
arrayref of arguments (rendered together on one line) or a single argument.
Groups are rendered on successive lines, aligned after the command name.

=head1 METHODS

=head2 args

  my @args = $cmd->args;

This method returns the flat list of all arguments, with arrayref groups
expanded in place.

=head1 AUTHOR

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
