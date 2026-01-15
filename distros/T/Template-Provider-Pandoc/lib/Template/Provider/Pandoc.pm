=head1 NAME

Template::Provider::Pandoc - pre-process templates with Pandoc

=head1 SYNOPSIS

    use Template;
    use Template::Provider::Pandoc;

    my $tt = Template->new(
      LOAD_TEMPLATES => [ Template::Provider::Pandoc->new ],
    );

    $tt->process('template.md', \%vars)

=head1 DESCRIPTION

Template::Provider::Pandoc is an extension to the Template Toolkit
which automatically processes templates using Pandoc before they are
processed by TT.

=head1 USAGE

Like any Template provider module, you will usually use this module by
creating an instance of the object and passing that in the
C<LOAD_TEMPLATES> parameter to the Template module's C<new> method.

This module accepts all of the standard parameters that can be passed
to any Template provider module. See L<Template::Provider> for the full
list.

This module accepts three extra parameters, C<EXTENSIONS>, which defines the
file extensions that is used to identify files that require conversion,
C<OUTPUT_FORMAT> which defines the the format that template will be converted
into and C<STRIP_FRONT_MATTER> which will remove Jekyll-style front matter
from the file content before returning it.

C<EXTENSIONS> is a hash reference. The default is to only handle Markdown
files (which are identified by the extension .md). You can get a full list
of the allowed input formats by running

    $ pandoc --list-input-formats

at a command line.

The C<EXTENSIONS> option supports one special option. If you use `*` as
an extenstion, then files with any extension will be converted using the
supplied format. So code like:

    my $provider = Template::Provider::Pandoc(
        EXTENSIONS => { '*' => 'markdown' },
    );

will lead to all files being pre-processed as Markdown files before being
handed to the Template Toolkit.

C<OUTPUT_FORMAT> is a single, scalar value containing the name of an output
format. The default value is C<html>. You can get a full list of the
allowed putput values by running

    $ pandoc --list-output-values

at a command line.

C<STRIP_FRONT_MATTER> is a flag that is either true or false. The default
value is false. If it is true then this module will remove any Jekyll-style
front matter from the file contents before returning them.

Jekyll-style front matter is a format used by Jekyll and other, similar,
static site builders. It is a fragmant of YAML that is inserted at the top
of the file between two lines that consist only of three dashes, like this:

    ---
    title: Title of the page
    author: Joe Author
    tags:
      - list
      - of
      -tags
    ---

The current implementation doesn't check that the front matter is actually
YAML. It simply removes everything from the first line of dashes to the
second.

=head1 Template::Provider::Markdown::Pandoc

This module is a successor to Template::Provider::Markdown::Pandoc. This
replacement module has all the functionality of the older module, and a lot
more besides. And, as a bonus, it has a shorter name!

=cut

package Template::Provider::Pandoc;

use strict;
use warnings;
use 5.010;

use Moose;
use MooseX::NonMoose;
extends 'Template::Provider';

use Pandoc ();

our $VERSION = '0.1.1';

has pandoc => (
  isa => 'Pandoc',
  is  => 'ro',
  lazy_build => 1,
  handles => [qw[convert]],
);

sub _build_pandoc {
  return Pandoc->new;
}

has default_extensions => (
  isa => 'HashRef',
  is  => 'ro',
  lazy_build => 1,
);

sub _build_default_extensions {
  return {
    md => 'markdown',
  };
}

has default_output_format => (
  isa => 'Str',
  is  => 'ro',
  lazy_build => 1,
);

sub _build_default_output_format {
  return 'html';
}

before _init  => sub {
  my $self = shift;
  my ($opts) = @_;

  my $exts = $self->default_extensions;

  if (exists $opts->{EXTENSIONS}) {
    $exts->{$_} = $opts->{EXTENSIONS}{$_} for keys %{$opts->{EXTENSIONS}};
    delete $opts->{EXTENSIONS};
  }

  $self->{EXTENSIONS} = $exts;

  $self->{OUTPUT_FORMAT} =
    $opts->{OUTPUT_FORMAT} // $self->default_output_format;

  $self->{STRIP_FRONT_MATTER} = $opts->{STRIP_FRONT_MATTER} // 0;
};

around _template_content => sub {
  my $orig = shift;
  my $self = shift;
  my ($path) = @_;

  my ($data, $error, $mod_date) = $self->$orig(@_);

  if ($self->{STRIP_FRONT_MATTER}) {
    $data =~ s/\A---\n.+?\n---\n//s;
  }

  my $done = 0;

  for (keys %{$self->{EXTENSIONS}}) {
    next if $_ eq '*';
    if ($path =~ /\.\Q$_\E$/) {
      if (defined $self->{EXTENSIONS}{$_}) {
        $data = $self->convert(
          $self->{EXTENSIONS}{$_} => $self->{OUTPUT_FORMAT}, $data
        );
      }
      $done = 1;
      last;
    }
  }

  if (not $done and exists $self->{EXTENSIONS}{'*'}) {
    $data = $self->convert(
      $self->{EXTENSIONS}{'*'} => $self->{OUTPUT_FORMAT}, $data
    );
  }

  return ($data, $error, $mod_date) if wantarray;
  return $data;
};

no Moose;
# no need to fiddle with inline_constructor here
__PACKAGE__->meta->make_immutable;

1;

=head1 AUTHOR

Dave Cross E<lt>dave@perlhacks.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2017 Magnum Solutions Ltd. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template>, L<Template::Provider>, L<Pandoc>.

=cut
