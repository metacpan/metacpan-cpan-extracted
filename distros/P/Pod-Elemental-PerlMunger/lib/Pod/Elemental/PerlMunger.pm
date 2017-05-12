package Pod::Elemental::PerlMunger;
# ABSTRACT: a thing that takes a string of Perl and rewrites its documentation
$Pod::Elemental::PerlMunger::VERSION = '0.200006';
use Moose::Role;

#pod =head1 OVERVIEW
#pod
#pod This role is to be included in classes that rewrite the documentation of a Perl
#pod document, stripping out all the Pod, munging it, and replacing it into the
#pod Perl.
#pod
#pod The only relevant method is C<munge_perl_string>, which must be implemented
#pod with a different interface than will be exposed.
#pod
#pod When calling the C<munge_perl_string> method, arguments should be passed like
#pod this:
#pod
#pod   $object->munge_perl_string($perl_string, \%arg);
#pod
#pod C<$perl_string> should be a character string containing Perl source code.
#pod
#pod C<%arg> may contain any input for the underlying procedure.  Defined keys for
#pod C<%arg> are:
#pod
#pod =for :list
#pod = filename
#pod the name of the file whose contents are being munged; optional, used for error
#pod messages
#pod = no_strip_bom
#pod If given, the BOM character (U+FEFF) won't be stripped from the input.
#pod Probably best to leave this one off.
#pod
#pod The method will return a character string containing the rewritten and combined
#pod document.
#pod
#pod Classes including this role must implement a C<munge_perl_string> that expects
#pod to be called like this:
#pod
#pod   $object->munge_perl_string(\%doc, \%arg);
#pod
#pod C<%doc> will have two entries:
#pod
#pod   ppi - a PPI::Document of the Perl document with all its Pod removed
#pod   pod - a Pod::Elemental::Document with no transformations yet performed
#pod
#pod This C<munge_perl_string> method should return a hashref in the same format as
#pod C<%doc>.
#pod
#pod =cut

use namespace::autoclean;

use Encode ();
use List::Util 1.33 qw(any max);
use Params::Util qw(_INSTANCE);
use PPI;

requires 'munge_perl_string';

around munge_perl_string => sub {
  my ($orig, $self, $perl, $arg) = @_;

  $perl =~ s/^\x{FEFF}// unless $arg->{no_strip_bom};

  my $ppi_document = PPI::Document->new(\$perl);
  confess(PPI::Document->errstr) unless $ppi_document;

  my $last_code_elem;
  my $code_elems = $ppi_document->find(sub {
    return if grep { $_[1]->isa("PPI::Token::$_") }
                    qw(Comment Pod Whitespace Separator Data End);
    return 1;
  });

  $code_elems ||= [];
  for my $elem (@$code_elems) {
    # Really, we might get two elements on the same line, and one could be
    # later in position because it could have a later column — but we don't
    # care, because we're only thinking about Pod, which is linewise.
    next if $last_code_elem
        and $elem->line_number <= $last_code_elem->line_number;

    $last_code_elem = $elem;
  }

  my @pod_tokens;

  {
    my @queue = $ppi_document->children;
    while (my $element = shift @queue) {
      if ($element->isa('PPI::Token::Pod')) {
        my $after_last = $last_code_elem
                      && $last_code_elem->line_number > $element->line_number;
        my @replacements = $self->_replacements_for($element, $after_last);

        # save the text for use in building the Pod-only document
        push @pod_tokens, "$element";

        my $last = $element;
        while (my $next = shift @replacements) {
          my $ok = $last->insert_after($next);
          confess("error inserting replacement!") unless $ok;
          $last = $next;
        }

        $element->delete;

        next;
      }

      if ( _INSTANCE($element, 'PPI::Node') ) {
        # Depth-first keeps the queue size down
        unshift @queue, $element->children;
      }
    }
  }

  my $finder = sub {
    my $node = $_[1];
    return 0 unless any { $node->isa($_) }
       qw( PPI::Token::Quote PPI::Token::QuoteLike PPI::Token::HereDoc );
    return 1 if $node->content =~ /^=[a-z]/m;
    return 0;
  };

  if ($ppi_document->find_first($finder)) {
    $self->log(
      sprintf "can't invoke %s on %s: there is POD inside string literals",
        $self->plugin_name,
        (defined $arg->{filename} ? $arg->{filename} : 'input')
    );
  }

  # TODO: I should add a $weaver->weave_* like the Linewise methods to take the
  # input, get a Document, perform the stock transformations, and then weave.
  # -- rjbs, 2009-10-24
  my $pod_str  = join "\n", @pod_tokens;
  my $pod_utf8 = Encode::encode('utf-8', $pod_str, Encode::FB_CROAK);
  my $pod_document = Pod::Elemental->read_string($pod_utf8);

  my $doc = $self->$orig(
    {
      ppi => $ppi_document,
      pod => $pod_document,
    },
    $arg,
  );

  my $new_pod = $doc->{pod}->as_pod_string;

  my $end_finder = sub {
    return 1 if $_[1]->isa('PPI::Statement::End')
             || $_[1]->isa('PPI::Statement::Data');
    return 0;
  };

  my $end = do {
    my $end_elem = $doc->{ppi}->find($end_finder);

    # If there's nothing after __END__, we can put the POD there:
    if (not $end_elem or (@$end_elem == 1 and
                          $end_elem->[0]->isa('PPI::Statement::End') and
                          $end_elem->[0] =~ /^__END__\s*\z/)) {
      $end_elem = [];
    }

    @$end_elem ? join q{}, @$end_elem : undef;
  };

  $doc->{ppi}->prune($end_finder);

  my $new_perl = $doc->{ppi}->serialize;

  s/\n\s*\z// for $new_perl, $new_pod;

  return defined $end
         ? "$new_perl\n\n$new_pod\n\n$end"
         : "$new_perl\n\n__END__\n\n$new_pod\n";
};

#pod =attr replacer
#pod
#pod The replacer is either a method name or code reference used to produces PPI
#pod elements used to replace removed Pod.  By default, it is
#pod C<L</replace_with_nothing>>, which just removes Pod tokens entirely.  This
#pod means that the line numbers of the code in the newly-produced document are
#pod changed, if the Pod had been interleaved with the code.
#pod
#pod See also C<L</replace_with_comment>> and C<L</replace_with_blank>>.
#pod
#pod If no further code follows the Pod being replaced, C<L</post_code_replacer>> is
#pod used instead.
#pod
#pod =attr post_code_replacer
#pod
#pod This attribute is used just like C<L</replacer>>, and defaults to its value,
#pod but is used for building replacements for Pod removed after the last hunk of
#pod code.  The idea is that if you're only concerned about altering your code's
#pod line numbers, you can stop replacing stuff after there's no more code to be
#pod affected.
#pod
#pod =cut

has replacer => (
  is  => 'ro',
  default => 'replace_with_nothing',
);

has post_code_replacer => (
  is   => 'ro',
  lazy => 1,
  default => sub { $_[0]->replacer },
);

sub _replacements_for {
  my ($self, $element, $after_last) = @_;

  my $replacer = $after_last ? $self->replacer : $self->post_code_replacer;
  return $self->$replacer($element);
}

#pod =method replace_with_nothing
#pod
#pod This method returns nothing.  It's the default C<L</replacer>>.  It's not very
#pod interesting.
#pod
#pod =cut

sub replace_with_nothing { return }

#pod =method replace_with_comment
#pod
#pod This replacer replaces removed Pod elements with a comment containing their
#pod text.  In other words:
#pod
#pod   =head1 A header!
#pod
#pod   This is great!
#pod
#pod   =cut
#pod
#pod ...is replaced with:
#pod
#pod   # =head1 A header!
#pod   #
#pod   # This is great!
#pod   #
#pod   # =cut
#pod
#pod =cut

sub replace_with_comment {
  my ($self, $element) = @_;

  my $text = "$element";

  (my $pod = $text) =~ s/^(.)/#pod $1/mg;
  $pod =~ s/^$/#pod/mg;
  my $commented_out = PPI::Token::Comment->new($pod);

  return $commented_out;
}

#pod =method replace_with_blank
#pod
#pod This replacer replaces removed Pod elements with vertical whitespace of equal
#pod line count.  In other words:
#pod
#pod   =head1 A header!
#pod
#pod   This is great!
#pod
#pod   =cut
#pod
#pod ...is replaced with five blank lines.
#pod
#pod =cut

sub replace_with_blank {
  my ($self, $element) = @_;

  my $text = "$element";
  my @lines = split /\n/, $text;
  my $blank = PPI::Token::Whitespace->new("\n" x (@lines));

  return $blank;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::PerlMunger - a thing that takes a string of Perl and rewrites its documentation

=head1 VERSION

version 0.200006

=head1 OVERVIEW

This role is to be included in classes that rewrite the documentation of a Perl
document, stripping out all the Pod, munging it, and replacing it into the
Perl.

The only relevant method is C<munge_perl_string>, which must be implemented
with a different interface than will be exposed.

When calling the C<munge_perl_string> method, arguments should be passed like
this:

  $object->munge_perl_string($perl_string, \%arg);

C<$perl_string> should be a character string containing Perl source code.

C<%arg> may contain any input for the underlying procedure.  Defined keys for
C<%arg> are:

=over 4

=item filename

the name of the file whose contents are being munged; optional, used for error
messages

=item no_strip_bom

If given, the BOM character (U+FEFF) won't be stripped from the input.
Probably best to leave this one off.

=back

The method will return a character string containing the rewritten and combined
document.

Classes including this role must implement a C<munge_perl_string> that expects
to be called like this:

  $object->munge_perl_string(\%doc, \%arg);

C<%doc> will have two entries:

  ppi - a PPI::Document of the Perl document with all its Pod removed
  pod - a Pod::Elemental::Document with no transformations yet performed

This C<munge_perl_string> method should return a hashref in the same format as
C<%doc>.

=head1 ATTRIBUTES

=head2 replacer

The replacer is either a method name or code reference used to produces PPI
elements used to replace removed Pod.  By default, it is
C<L</replace_with_nothing>>, which just removes Pod tokens entirely.  This
means that the line numbers of the code in the newly-produced document are
changed, if the Pod had been interleaved with the code.

See also C<L</replace_with_comment>> and C<L</replace_with_blank>>.

If no further code follows the Pod being replaced, C<L</post_code_replacer>> is
used instead.

=head2 post_code_replacer

This attribute is used just like C<L</replacer>>, and defaults to its value,
but is used for building replacements for Pod removed after the last hunk of
code.  The idea is that if you're only concerned about altering your code's
line numbers, you can stop replacing stuff after there's no more code to be
affected.

=head1 METHODS

=head2 replace_with_nothing

This method returns nothing.  It's the default C<L</replacer>>.  It's not very
interesting.

=head2 replace_with_comment

This replacer replaces removed Pod elements with a comment containing their
text.  In other words:

  =head1 A header!

  This is great!

  =cut

...is replaced with:

  # =head1 A header!
  #
  # This is great!
  #
  # =cut

=head2 replace_with_blank

This replacer replaces removed Pod elements with vertical whitespace of equal
line count.  In other words:

  =head1 A header!

  This is great!

  =cut

...is replaced with five blank lines.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Christopher J. Madsen Dave Rolsky Karen Etheridge perlancar (on PC, Bandung)

=over 4

=item *

Christopher J. Madsen <perl@cjmweb.net>

=item *

Dave Rolsky <autarch@urth.org>

=item *

Karen Etheridge <ether@cpan.org>

=item *

perlancar (on PC, Bandung) <perlancar@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
