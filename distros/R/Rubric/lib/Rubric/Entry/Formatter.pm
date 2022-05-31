use strict;
use warnings;
package Rubric::Entry::Formatter 0.157;
# ABSTRACT: a base class for entry body formatters

#pod =head1 DESCRIPTION
#pod
#pod This class serves as a single point of dispatch for attempts to format entry
#pod bodies from their native format into rendered output.
#pod
#pod =cut

use Carp ();
use Rubric::Config;

#pod =head1 METHODS
#pod
#pod =head2 C< format >
#pod
#pod   my $formatted = Rubric::Entry::Formatter->format(\%arg);
#pod
#pod This method accepts a set of named arguments and returns formatted output in
#pod the requested format.  If it is unable to do so, it throws an exception.
#pod
#pod Valid arguments are:
#pod
#pod  markup - the markup format used to mark up the text (default: _default)
#pod  text   - the text that has been marked up and should be formatted (required)
#pod  format - the requested output format (required)
#pod
#pod Formatting requests are dispatched according to the configuration in
#pod C<markup_formatter>.  
#pod
#pod =cut

sub _load_formatter {
  my ($class, $formatter) = @_;

  return 1 if eval { $formatter->can('as_text'); };

  ## no critic (StringyEval)
  return 1 if eval qq{require $formatter};
  ## use critic

  return 0;
}

sub _formatter_for {
  my ($class, $markup) = @_;

  my $markup_formatter = Rubric::Config->markup_formatter;
  $markup_formatter->{_default} = 'Rubric::Entry::Formatter::Nil'
    unless $markup_formatter->{_default};

  Carp::croak "no formatter is registered for $markup markup"
    unless my $formatter = $markup_formatter->{ $markup };

  return $formatter;
}

sub format {
  my ($class, $arg) = @_;
  my $config = {}; # extra configuration for formatter code

  my $formatter = $class->_formatter_for($arg->{markup});

  if (ref $formatter) {
    $config = { %$formatter };
    Carp::croak "formatter config for $arg->{markup} includes no class"
      unless $formatter = delete $config->{class};
  }

  $class->_load_formatter($formatter)
    or Carp::croak "couldn't load formatter '$formatter': $@";

  my $formatter_code = $formatter->can("as_$arg->{format}")
    or Carp::croak "$formatter does not implement formatting to $arg->{format}";

  $formatter_code->($formatter, $arg, $config);
}

#pod =head1 WRITING FORMATTERS
#pod
#pod Writing a formatter should be very simple; the interface is very simple,
#pod although it's also very young and so it may change when I figure out the
#pod problems in the current implementation.
#pod
#pod A formatter must implement an C<as_FORMAT> method for each format to which it
#pod claims to be able to output formatted text.  When Rubric::Entry::Formatter
#pod wants to dispatch text for formatting, it will call that method as follows:
#pod
#pod   my $formatted = Formatter->as_whatever(\%arg);
#pod
#pod The arguments in C<%arg> will be the same as those passed to
#pod Rubric::Entry::Formatter.
#pod
#pod Actually, the method is found and called via C<can>, so a suitably programmed
#pod module can respond to C<can> to allow it to render into all the format it likes
#pod -- or at least to claim to.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rubric::Entry::Formatter - a base class for entry body formatters

=head1 VERSION

version 0.157

=head1 DESCRIPTION

This class serves as a single point of dispatch for attempts to format entry
bodies from their native format into rendered output.

=head1 PERL VERSION

This code is effectively abandonware.  Although releases will sometimes be made
to update contact info or to fix packaging flaws, bug reports will mostly be
ignored.  Feature requests are even more likely to be ignored.  (If someone
takes up maintenance of this code, they will presumably remove this notice.)
This means that whatever version of perl is currently required is unlikely to
change -- but also that it might change at any new maintainer's whim.

=head1 METHODS

=head2 C< format >

  my $formatted = Rubric::Entry::Formatter->format(\%arg);

This method accepts a set of named arguments and returns formatted output in
the requested format.  If it is unable to do so, it throws an exception.

Valid arguments are:

 markup - the markup format used to mark up the text (default: _default)
 text   - the text that has been marked up and should be formatted (required)
 format - the requested output format (required)

Formatting requests are dispatched according to the configuration in
C<markup_formatter>.  

=head1 WRITING FORMATTERS

Writing a formatter should be very simple; the interface is very simple,
although it's also very young and so it may change when I figure out the
problems in the current implementation.

A formatter must implement an C<as_FORMAT> method for each format to which it
claims to be able to output formatted text.  When Rubric::Entry::Formatter
wants to dispatch text for formatting, it will call that method as follows:

  my $formatted = Formatter->as_whatever(\%arg);

The arguments in C<%arg> will be the same as those passed to
Rubric::Entry::Formatter.

Actually, the method is found and called via C<can>, so a suitably programmed
module can respond to C<can> to allow it to render into all the format it likes
-- or at least to claim to.

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
