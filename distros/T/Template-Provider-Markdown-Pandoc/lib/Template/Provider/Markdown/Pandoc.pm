=head1 NAME

Template::Provider::Markdown::Pandoc - expand Markdown templates to HTML

=head1 SYNOPSIS

    use Template;
    use Template::Provider::Markdown::Pandoc;

    my $tt = Template->new(
      LOAD_TEMPLATES = [ Template::Provider::Markdown::Pandoc->new ],
    );

    $tt->process('template.md', \%vars)

=head1 DESCRIPTION

Template::Provider::Markdown::Pandoc is an extension to the Template Toolkit
which automatically converts Markdown files into HTML before they are
processed by TT.

=head1 USAGE

Like any Template provider module, you will usually use this module by
creating an instance of the object and passing that in the
C<LOAD_TEMPLATES> parameter to the Template module's C<new> method.

This module can accept all of the standard parameters that can be passed
to any Template provider module. See L<Template::Provider> for the full
list.

This module accepts one extra parameter, C<EXTENSION>, which defines the
file extension that is used to identify Markdown files. Only template
files with this extension will be pre-processed by this module. The
default extension is 'md', so you don't need to pass an C<EXTENSION>
parameter if you're happy to use that extension.

If you want to pre-process all template files, then you need to explicitly
set the C<EXTENSION> parameter to C<undef>.

    y $tt = Template->new(
      LOAD_TEMPLATES = [
        Template::Provider::Markdown::Pandoc->new(
          EXTENSION => undef,
        },
      ],
    );

=head1 Template::Provider::Markdown

There is already a module called L<Template::Provider::Markdown> available
on CPAN, so why did I write another, very similar-sounding, module? There
are two reasons.

=over 4

=item 1

Template::Provider::Markdown uses L<Text::Markdown> to do the conversion and
I've found a few problems with the Markdown conversion in that module. This
module uses C<pandoc> (see L<http://pandoc.org/>) a very powerful and
flexible tool for converting between document formats.

=item 2

Template::Provider::Markdown assumes that all of your templates are in
Markdown and converts them all. That didn't fit with what I wanted to. I
only wanted to convert specific templates.

However, because I'm using file extensions to recognise the templates
that need conversion, this module can only be used to pre-process templates
that are stored in files. This isn't a restriction in my use cases.

=back

=cut

package Template::Provider::Markdown::Pandoc;

use strict;
use warnings;
use 5.010;

use parent 'Template::Provider';
use Pandoc;

our $VERSION = '0.0.2';

my $pandoc;

sub new {
  my $class = shift;
  my %opts  = @_;

  my $ext = 'md';
  $ext = delete $opts{EXTENSION} if exists $opts{EXTENSION};

  my $self = $class->SUPER::new(%opts);

  $self->{EXTENSION} = $ext;

  return bless $self, $class;
}

sub _template_content {
  my $self = shift;
  my ($path) = @_;

  my ($data, $error, $mod_date) = $self->SUPER::_template_content($path);

  if (! defined $self->{EXTENSION} or $path =~ /\.\Q$self->{EXTENSION}\E$/) {
    $pandoc //= pandoc;
    $data = $pandoc->convert(markdown => 'html', $data);
  }

  return ($data, $error, $mod_date) if wantarray;
  return $data;
}

1;

=head1 AUTHOR

Dave Cross E<lt>dave@perlhacks.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2017 Magnum Solutions Ltd. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template>, L<Template::Provider>, L<Pandoc>,
L<Template::Provider::Markdown>.

=cut
