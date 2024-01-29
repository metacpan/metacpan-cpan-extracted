package Term::Completion::Multi;

use strict;
use warnings;
use File::Spec;

our $VERSION = '0.90';

our @EXPORT_OK = qw(Complete);
use base qw(Term::Completion);

our %DEFAULTS = (
    delim => ' '
);

sub _get_defaults
{
  return(__PACKAGE__->SUPER::_get_defaults(), %DEFAULTS, delim => $DEFAULTS{delim});
}

sub complete
{
  my __PACKAGE__ $this = shift;
  my $result = $this->SUPER::complete(@_);
  my $delim = $this->{delim};
  return split(/[$delim]+/, $result);
}

sub Complete
{
  my ($prompt,@choices) = @_;
  $prompt = '' unless defined $prompt;
  __PACKAGE__->new(prompt => $prompt, choices => \@choices)->complete;
}

sub get_choices
{
  my __PACKAGE__ $this = shift;
  my $in = shift;
  my $delim = $this->{delim};
  my $prefix = '';
  # remove all up to and including last separator
  ($in =~ s/^(.*[$delim]+)//) && ($prefix = $1);
  #... and use that to match the choices
  map { $prefix.$_ } grep(/^\Q$in/,@{$this->{choices}});
}

sub show_choices
{
  my __PACKAGE__ $this = shift;
  my $return = shift;
  # start new line - cursor was on input line
  $this->{out}->print($this->{eol});
  my $delim = $this->{delim};
  $return =~ s/^.*[$delim]//; # delete everything up to last delimiter
  $this->_show_choices($this->get_choices($return));
}

sub post_process
{
  my __PACKAGE__ $this = shift;
  my $return = $this->SUPER::post_process(shift);
  my $delim = $this->{delim};
  $return =~ s/^[$delim]+|[$delim]+$//g;
  $return;
}

sub validate
{
  my __PACKAGE__ $this = shift;
  my $return = shift;
  unless($this->{validate}) {
    return $return;
  }
  my $ok = 1;
  my $delim = $this->{delim};
  my @ok_vals;
  foreach my $val (split(/[$delim]+/, $return)) {
    my $return = $this->SUPER::validate($val);
    unless(defined $return) {
      $ok = 0;
    } else {
      push(@ok_vals, $return);
    }
  }
  return unless $ok;
  return join($delim, @ok_vals);
}

1;

__END__

=head1 NAME

Term::Completion::Multi - read one line of user input with multiple values

=head1 USAGE

  use Term::Completion::Multi;
  my $tc = Term::Completion::Multi->new(
    prompt  => "Enter your first names: ",
    choices => [ qw(Alice Bob Chris Dave Ellen Frank George Heidi Ida) ]
  );
  my @names = $tc->complete();
  print "You entered: @names\n";

=head1 DESCRIPTION

Term::Completion::Multi is a derived class of L<Term::Complete>. It allows
to enter one line with multiple choices from a list of choices, delimited
by a configurable delimiter character (typically one space).
The return value of the C<complete()> method is the list of values.

See L<Term::Complete> for details.

=head2 Configuration

Term::Completion::Multi adds one additional configuration parameter,
namely "delim". The default is one space. You can change this to e.g.
a comma character if you prefer the user to separate the choices with a comma
instead of a space:

  my $tc = Term::Completion->new(
    delim => ',',
    ...

=head2 Validation

The input validation works very much like in L<Term::Completion>. Here
however the input is first split upon the delimiter character, and then
each item is validated. Consecutive delimiter characters are treated as one.
If any single validation fails, the entire input is canceled. If all items
validate OK, then the return value is built by concatenating the items
returned from validation with the delimiter character.

If you don't like the above then you are free to write a class that is
derived from Term::Completion::Multi and overrides the C<validate> method.

=head1 SEE ALSO

L<Term::Completion>

=head1 AUTHOR

Marek Rouchal, E<lt>marekr@cpan.org<gt>

=head1 BUGS

Please submit patches, bug reports and suggestions via the CPAN tracker
L<http://rt.cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2013 by Marek Rouchal

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

