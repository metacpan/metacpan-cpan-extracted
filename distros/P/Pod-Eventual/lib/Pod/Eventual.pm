use strict;
use warnings;
package Pod::Eventual 0.094003;
# ABSTRACT: read a POD document as a series of trivial events
use Mixin::Linewise::Readers 0.102;

use Carp ();

#pod =head1 SYNOPSIS
#pod
#pod   package Your::Pod::Parser;
#pod   use base 'Pod::Eventual';
#pod
#pod   sub handle_event {
#pod     my ($self, $event) = @_;
#pod
#pod     print Dumper($event);
#pod   }
#pod
#pod =head1 DESCRIPTION
#pod
#pod POD is a pretty simple format to write, but it can be a big pain to deal with
#pod reading it and doing anything useful with it.  Most existing POD parsers care
#pod about semantics, like whether a C<=item> occurred after an C<=over> but before
#pod a C<back>, figuring out how to link a C<< LE<lt>E<gt> >>, and other things like
#pod that.
#pod
#pod Pod::Eventual is much less ambitious and much more stupid.  Fortunately, stupid
#pod is often better.  (That's what I keep telling myself, anyway.)
#pod
#pod Pod::Eventual reads line-based input and produces events describing each POD
#pod paragraph or directive it finds.  Once complete events are immediately passed
#pod to the C<handle_event> method.  This method should be implemented by
#pod Pod::Eventual subclasses.  If it isn't, Pod::Eventual's own C<handle_event>
#pod will be called, and will raise an exception.
#pod
#pod =head1 EVENTS
#pod
#pod There are four kinds of events that Pod::Eventual will produce.  All are
#pod represented as hash references.
#pod
#pod =head2 Command Events
#pod
#pod These events represent commands -- those things that start with an equals sign
#pod in the first column.  Here are some examples of POD and the event that would be
#pod produced.
#pod
#pod A simple header:
#pod
#pod   =head1 NAME
#pod
#pod   { type => 'command', command => 'head1', content => "NAME\n", start_line => 4 }
#pod
#pod Notice that the content includes the trailing newline.  That's to maintain
#pod similarity with this possibly-surprising case:
#pod
#pod   =for HTML
#pod   We're actually still in the command event, here.
#pod
#pod   {
#pod     type    => 'command',
#pod     command => 'for',
#pod     content => "HTML\nWe're actually still in the command event, here.\n",
#pod     start_line => 8,
#pod   }
#pod
#pod Pod::Eventual does not care what the command is.  It doesn't keep track of what
#pod it's seen or whether you've used a command that isn't defined.  The only
#pod special case is C<=cut>, which is never more than one line.
#pod
#pod   =cut
#pod   We are no longer parsing POD when this line is read.
#pod
#pod   {
#pod     type    => 'command',
#pod     command => 'cut',
#pod     content => "\n",
#pod     start_line => 15,
#pod   }
#pod
#pod Waiving this special case may be an option in the future.
#pod
#pod =head2 Text Events
#pod
#pod A text event is just a paragraph of text, beginning after one or more empty
#pod lines and running until the next empty line (or F<=cut>).  In Perl 5's standard
#pod usage of Pod, text content that begins with whitespace is a "verbatim"
#pod paragraph, and text content that begins with non-whitespace is an "ordinary"
#pod paragraph.
#pod
#pod Pod::Eventual doesn't care.
#pod
#pod Text events look like this:
#pod
#pod   {
#pod     type    => 'text',
#pod     content => "a string of text ending with a\n",
#pod     start_line =>  16,
#pod   }
#pod
#pod =head2 Blank events
#pod
#pod These events represent blank lines (or many blank lines) within a Pod section.
#pod
#pod Blank events look like this:
#pod
#pod   {
#pod     type    => 'blank',
#pod     content => "\n\n\n\n",
#pod     start_line => 21,
#pod   }
#pod
#pod =head2 Non-Pod events
#pod
#pod These events represent non-Pod segments of the input.
#pod
#pod Non-Pod events look like this:
#pod
#pod   {
#pod     type    => 'nonpod',
#pod     content => "#!/usr/bin/perl\nuse strict;\n\nuse Acme::ProgressBar\n\n",
#pod     start_line => 1,
#pod   }
#pod
#pod =method read_handle
#pod
#pod   Pod::Eventual->read_handle($io_handle, \%arg);
#pod
#pod This method iterates through the lines of a handle, producing events and
#pod calling the C<handle_event> method.
#pod
#pod The only valid argument in C<%arg> (for now) is C<in_pod>, which indicates
#pod whether we should assume that we are parsing pod when we start parsing the
#pod file.  By default, this is false.
#pod
#pod This is useful to behave differently when reading a F<.pm> or F<.pod> file.
#pod
#pod B<Important:> the handle is expected to have an encoding layer so that it will
#pod return text, not bytes, on reads.
#pod
#pod =method read_file
#pod
#pod This behaves just like C<read_handle>, but expects a filename rather than a
#pod handle.  The file will be assumed to be UTF-8 encoded.
#pod
#pod =method read_string
#pod
#pod This behaves just like C<read_handle>, but expects a string containing POD
#pod text rather than a handle.
#pod
#pod =cut

sub read_handle {
  my ($self, $handle, $arg) = @_;
  $arg ||= {};

  my $in_pod  = $arg->{in_pod} ? 1 : 0;
  my $current;

  LINE: while (my $line = $handle->getline) {
    if ($in_pod and $line =~ /^=cut(?:\s*)(.*?)(\n)\z/) {
      my $content = "$1$2";
      $in_pod = 0;
      $self->handle_event($current) if $current;
      undef $current;
      $self->handle_event({
        type       => 'command',
        command    => 'cut',
        content    => $content,
        start_line => $handle->input_line_number,
      });
      next LINE;
    }

    if ($line =~ /\A=[a-z]/i) {
      if ($current and not $in_pod) {
        $self->handle_nonpod($current);
        undef $current;
      }

      $in_pod = 1;
    }

    if (not $in_pod) {
      $current ||= {
        type       => 'nonpod',
        start_line => $handle->input_line_number,
        content    => '',
      };

      $current->{content} .= $line;
      next LINE;
    }

    if ($line =~ /^\s*$/) {
      if ($current and $current->{type} ne 'blank') {
        $self->handle_event($current);

        $current = {
          type       => 'blank',
          content    => '',
          start_line => $handle->input_line_number,
        };
      }
    } elsif ($current and $current->{type} eq 'blank') {
      $self->handle_blank($current);
      undef $current;
    }

    if ($current) {
      $current->{content} .= $line;
      next LINE;
    }

    if ($line =~ /^=([a-z]+\S*)(?:\s*)(.*?)(\n)\z/i) {
      my $command = $1;
      my $content = "$2$3";
      $current = {
        type       => 'command',
        command    => $command,
        content    => $content,
        start_line => $handle->input_line_number,
      };
      next LINE;
    }

    $current = {
      type       => 'text',
      content    => $line,
      start_line => $handle->input_line_number,
    };
  }

  if ($current) {
    my $method = $current->{type} eq 'blank'  ? 'handle_blank'
               : $current->{type} eq 'nonpod' ? 'handle_nonpod'
               :                                'handle_event';

    $self->$method($current) if $current;
  }

  return;
}

#pod =method handle_event
#pod
#pod This method is called each time Pod::Eventual finishes scanning for a new POD
#pod event.  It must be implemented by a subclass or it will raise an exception.
#pod
#pod =cut

sub handle_event {
  Carp::confess("handle_event not implemented by $_[0]");
}

#pod =method handle_nonpod
#pod
#pod This method is called each time a non-POD segment is seen -- that is, lines
#pod after C<=cut> and before another command.
#pod
#pod If unimplemented by a subclass, it does nothing by default.
#pod
#pod =cut

sub handle_nonpod { }

#pod =method handle_blank
#pod
#pod This method is called at the end of a sequence of one or more blank lines.
#pod
#pod If unimplemented by a subclass, it does nothing by default.
#pod
#pod =cut

sub handle_blank  { }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Eventual - read a POD document as a series of trivial events

=head1 VERSION

version 0.094003

=head1 SYNOPSIS

  package Your::Pod::Parser;
  use base 'Pod::Eventual';

  sub handle_event {
    my ($self, $event) = @_;

    print Dumper($event);
  }

=head1 DESCRIPTION

POD is a pretty simple format to write, but it can be a big pain to deal with
reading it and doing anything useful with it.  Most existing POD parsers care
about semantics, like whether a C<=item> occurred after an C<=over> but before
a C<back>, figuring out how to link a C<< LE<lt>E<gt> >>, and other things like
that.

Pod::Eventual is much less ambitious and much more stupid.  Fortunately, stupid
is often better.  (That's what I keep telling myself, anyway.)

Pod::Eventual reads line-based input and produces events describing each POD
paragraph or directive it finds.  Once complete events are immediately passed
to the C<handle_event> method.  This method should be implemented by
Pod::Eventual subclasses.  If it isn't, Pod::Eventual's own C<handle_event>
will be called, and will raise an exception.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 read_handle

  Pod::Eventual->read_handle($io_handle, \%arg);

This method iterates through the lines of a handle, producing events and
calling the C<handle_event> method.

The only valid argument in C<%arg> (for now) is C<in_pod>, which indicates
whether we should assume that we are parsing pod when we start parsing the
file.  By default, this is false.

This is useful to behave differently when reading a F<.pm> or F<.pod> file.

B<Important:> the handle is expected to have an encoding layer so that it will
return text, not bytes, on reads.

=head2 read_file

This behaves just like C<read_handle>, but expects a filename rather than a
handle.  The file will be assumed to be UTF-8 encoded.

=head2 read_string

This behaves just like C<read_handle>, but expects a string containing POD
text rather than a handle.

=head2 handle_event

This method is called each time Pod::Eventual finishes scanning for a new POD
event.  It must be implemented by a subclass or it will raise an exception.

=head2 handle_nonpod

This method is called each time a non-POD segment is seen -- that is, lines
after C<=cut> and before another command.

If unimplemented by a subclass, it does nothing by default.

=head2 handle_blank

This method is called at the end of a sequence of one or more blank lines.

If unimplemented by a subclass, it does nothing by default.

=head1 EVENTS

There are four kinds of events that Pod::Eventual will produce.  All are
represented as hash references.

=head2 Command Events

These events represent commands -- those things that start with an equals sign
in the first column.  Here are some examples of POD and the event that would be
produced.

A simple header:

  =head1 NAME

  { type => 'command', command => 'head1', content => "NAME\n", start_line => 4 }

Notice that the content includes the trailing newline.  That's to maintain
similarity with this possibly-surprising case:

  =for HTML
  We're actually still in the command event, here.

  {
    type    => 'command',
    command => 'for',
    content => "HTML\nWe're actually still in the command event, here.\n",
    start_line => 8,
  }

Pod::Eventual does not care what the command is.  It doesn't keep track of what
it's seen or whether you've used a command that isn't defined.  The only
special case is C<=cut>, which is never more than one line.

  =cut
  We are no longer parsing POD when this line is read.

  {
    type    => 'command',
    command => 'cut',
    content => "\n",
    start_line => 15,
  }

Waiving this special case may be an option in the future.

=head2 Text Events

A text event is just a paragraph of text, beginning after one or more empty
lines and running until the next empty line (or F<=cut>).  In Perl 5's standard
usage of Pod, text content that begins with whitespace is a "verbatim"
paragraph, and text content that begins with non-whitespace is an "ordinary"
paragraph.

Pod::Eventual doesn't care.

Text events look like this:

  {
    type    => 'text',
    content => "a string of text ending with a\n",
    start_line =>  16,
  }

=head2 Blank events

These events represent blank lines (or many blank lines) within a Pod section.

Blank events look like this:

  {
    type    => 'blank',
    content => "\n\n\n\n",
    start_line => 21,
  }

=head2 Non-Pod events

These events represent non-Pod segments of the input.

Non-Pod events look like this:

  {
    type    => 'nonpod',
    content => "#!/usr/bin/perl\nuse strict;\n\nuse Acme::ProgressBar\n\n",
    start_line => 1,
  }

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Hans Dieter Pearcey Philippe Bruhat (BooK) Ricardo Signes

=over 4

=item *

Hans Dieter Pearcey <hdp@weftsoar.net>

=item *

Philippe Bruhat (BooK) <book@cpan.org>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
