package Pod::Weaver::Section::GenerateSection;
# ABSTRACT: add pod section from an interpolated piece of text
$Pod::Weaver::Section::GenerateSection::VERSION = '4.017';
use strict;
use warnings;
use utf8;

use Moose;

with 'Pod::Weaver::Role::Section';

use Pod::Elemental::Element::Nested;
use Pod::Elemental::Element::Pod5::Ordinary;
use Text::Template;

use namespace::autoclean;

#pod =head1 SYNOPSIS
#pod
#pod In your F<weaver.ini>
#pod
#pod   [GenerateSection]
#pod   title = HOMEPAGE
#pod   text  = This is the POD for distribution {{$name}}. Check out what we have
#pod   text  = been up to at {{$homepage}}
#pod
#pod The title value can be omited if passed as the plugin name:
#pod
#pod   [GenerateSection / HOMEPAGE]
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin allows the creation of simple text sections, with or without the
#pod use of Text::Template for templated text.
#pod
#pod The C<text> parameters become the lines of the template.
#pod
#pod The values of text are concatenated and variable names with matching values on
#pod the distribution are interpolated.  Specifying the heading level allows one to
#pod write down a rather long section of POD text without need for extra files. For
#pod example:
#pod
#pod   [GenerateSection / FEEDBACK]
#pod   head = 1
#pod   [GenerateSection / Reporting bugs]
#pod   head = 2
#pod   text = Please report bugs when you find them. While we do have a mailing
#pod   text = list, please use the bug tracker at {{$bugtracker_web}}
#pod   text = to report bugs
#pod   [GenerateSection / Homegape]
#pod   head = 2
#pod   text = Also, come check out our other projects at
#pod   text = {{$homepage}}
#pod
#pod =head1 TEMPLATE RENDERING
#pod
#pod When rendering as a template, the variables C<$plugin>, C<$dist>, and
#pod C<$distmeta> will be provided, set to the GenerateSection plugin,
#pod C<Dist::Zilla> object, and the distribution metadata hash respectively. For
#pod convenience, the following variables are also set:
#pod
#pod =for :list
#pod * C<< $name >>
#pod * C<< $version >>
#pod * C<< $homepage >>
#pod * C<< $repository_web >>
#pod * C<< $repository_url >>
#pod * C<< $bugtracker_web >>
#pod * C<< $bugtracker_email >>
#pod
#pod =attr text
#pod
#pod The text to be added to the section. Multiple values are allowed and will be
#pod concatenated. Certain sequences on the text will be replaced (see below).
#pod
#pod =cut

sub mvp_multivalue_args { return qw(text) }
has text => (
  is      => 'ro',
  isa     => 'ArrayRef',
  lazy    => 1,
  default => sub { [] },
);

#pod =attr head
#pod
#pod This is the I<X> to use in the C<=headX> that's created.  If it's C<0> then no
#pod heading is added.  It defaults to C<1>.
#pod
#pod =cut

has head => (
  is      => 'ro',
  isa     => 'Int',
  lazy    => 1,
  default => 1,
);

#pod =attr title
#pod
#pod The title for this section.  If none is given, the plugin's name is used.
#pod
#pod =cut

has title => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub { $_[0]->plugin_name },
);

#pod =attr main_module_only
#pod
#pod If true, this attribute indicates that only the main module's Pod should be
#pod altered.  By default, it is false.
#pod
#pod =cut

has main_module_only => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => 0,
);

#pod =attr
#pod
#pod If true, the text is treated as a L<Text::Template> template and rendered.
#pod This attribute B<is true by default>.
#pod
#pod =cut

has is_template => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => 1,
);

sub weave_section {
  my ($self, $document, $input) = @_;

  if ($self->main_module_only) {
    return if $input->{zilla}->main_module->name ne $input->{filename};
  }

  my $text = join ("\n", @{ $self->text });

  if ($self->is_template) {
    my %stash;

    if ($input->{zilla}) {
      %stash = (
        dist      => \($input->{zilla}),
        distmeta  => \($input->{distmeta}),
        plugin    => \($self),

        name        => $input->{distmeta}{name},
        version     => $input->{distmeta}{version},
        homepage    => $input->{distmeta}{resources}{homepage},
        repository_web   => $input->{distmeta}{resources}{repository}{web},
        repository_url   => $input->{distmeta}{resources}{repository}{url},
        bugtracker_web   => $input->{distmeta}{resources}{bugtracker}{web},
        bugtracker_email => $input->{distmeta}{resources}{bugtracker}{mailto},
      );
    }

    $text = $self->fill_in_string($text, \%stash);
  }

  my $element = Pod::Elemental::Element::Pod5::Ordinary->new({ content => $text });

  if ($self->head) {
    $element = Pod::Elemental::Element::Nested->new({
      command  => "head" . $self->head,
      content  => $self->title,
      children => [ $element ],
    });
  }

  push @{ $document->children }, $element;
}

# BEGIN CODE IMPORTED FROM Dist::Zilla::Role::TextTemplate
#pod =attr delim
#pod
#pod If given, this must be an arrayref with two elements.  These will be the
#pod opening and closing delimiters of template variable sections.  By default they
#pod are C<{{> and C<}}>.
#pod
#pod =cut

has delim => (
  is   => 'ro',
  isa  => 'ArrayRef',
  lazy => 1,
  init_arg => undef,
  default  => sub { [ qw(  {{  }}  ) ] },
);

sub fill_in_string {
  my ($self, $string, $stash, $arg) = @_;

  $self->log_fatal("Cannot use undef as a template string")
    unless defined $string;

  my $tmpl = Text::Template->new(
    TYPE       => 'STRING',
    SOURCE     => $string,
    DELIMITERS => $self->delim,
    BROKEN     => sub { my %hash = @_; die $hash{error}; },
    %$arg,
  );

  $self->log_fatal("Could not create a Text::Template object from:\n$string")
    unless $tmpl;

  my $content = $tmpl->fill_in(%$arg, HASH => $stash);

  $self->log_fatal("Filling in the template returned undef for:\n$string")
    unless defined $content;

  return $content;
}
# END CODE IMPORTED FROM Dist::Zilla::Role::TextTemplate

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::GenerateSection - add pod section from an interpolated piece of text

=head1 VERSION

version 4.017

=head1 SYNOPSIS

In your F<weaver.ini>

  [GenerateSection]
  title = HOMEPAGE
  text  = This is the POD for distribution {{$name}}. Check out what we have
  text  = been up to at {{$homepage}}

The title value can be omited if passed as the plugin name:

  [GenerateSection / HOMEPAGE]

=head1 DESCRIPTION

This plugin allows the creation of simple text sections, with or without the
use of Text::Template for templated text.

The C<text> parameters become the lines of the template.

The values of text are concatenated and variable names with matching values on
the distribution are interpolated.  Specifying the heading level allows one to
write down a rather long section of POD text without need for extra files. For
example:

  [GenerateSection / FEEDBACK]
  head = 1
  [GenerateSection / Reporting bugs]
  head = 2
  text = Please report bugs when you find them. While we do have a mailing
  text = list, please use the bug tracker at {{$bugtracker_web}}
  text = to report bugs
  [GenerateSection / Homegape]
  head = 2
  text = Also, come check out our other projects at
  text = {{$homepage}}

=head1 ATTRIBUTES

=head2 text

The text to be added to the section. Multiple values are allowed and will be
concatenated. Certain sequences on the text will be replaced (see below).

=head2 head

This is the I<X> to use in the C<=headX> that's created.  If it's C<0> then no
heading is added.  It defaults to C<1>.

=head2 title

The title for this section.  If none is given, the plugin's name is used.

=head2 main_module_only

If true, this attribute indicates that only the main module's Pod should be
altered.  By default, it is false.

=head2

If true, the text is treated as a L<Text::Template> template and rendered.
This attribute B<is true by default>.

=head2 delim

If given, this must be an arrayref with two elements.  These will be the
opening and closing delimiters of template variable sections.  By default they
are C<{{> and C<}}>.

=head1 TEMPLATE RENDERING

When rendering as a template, the variables C<$plugin>, C<$dist>, and
C<$distmeta> will be provided, set to the GenerateSection plugin,
C<Dist::Zilla> object, and the distribution metadata hash respectively. For
convenience, the following variables are also set:

=over 4

=item *

C<< $name >>

=item *

C<< $version >>

=item *

C<< $homepage >>

=item *

C<< $repository_web >>

=item *

C<< $repository_url >>

=item *

C<< $bugtracker_web >>

=item *

C<< $bugtracker_email >>

=back

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
