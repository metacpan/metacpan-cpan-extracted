=head1 NAME

Template::Provider::Pandoc - expand Markdown templates to HTML

=head1 SYNOPSIS

    use Template;
    use Template::Provider::Pandoc;

    my $tt = Template->new(
      LOAD_TEMPLATES = [ Template::Provider::Pandoc->new ],
    );

    $tt->process('template.md', \%vars)

=head1 DESCRIPTION

Template::Provider::Pandoc is an extension to the Template Toolkit
which automatically converts Markdown files into HTML before they are
processed by TT.

=head1 USAGE

Like any Template provider module, you will usually use this module by
creating an instance of the object and passing that in the
C<LOAD_TEMPLATES> parameter to the Template module's C<new> method.

This module can accept all of the standard parameters that can be passed
to any Template provider module. See L<Template::Provider> for the full
list.

This module accepts two extra parameters, C<EXTENSIONS>, which defines the
file extensions that is used to identify files that require conversion, and
C<OUTPUT_FORMAT> which defines the the format that template will be converted
into.

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

=head1 Template::Provider::Markdown::Pandoc

This module is a successor to Template::Provider::Markdown::Pandoc. This
replacement module has all the functionality of the older module, and a lot
more besides. And, as a bonus, it has a shorter name!

=cut

package Template::Provider::Pandoc;

use strict;
use warnings;
use 5.010;

use parent 'Template::Provider';
use Pandoc;

our $VERSION = '0.0.2';

my $pandoc;

my $default_extensions = {
  md   => 'markdown',
};
my $default_output_format = 'html';

sub _init {
  my $self = shift;
  my ($opts) = @_;

  my $exts = $default_extensions;
  if (exists $opts->{EXTENSIONS}) {
    $exts->{$_} = $opts->{EXTENSIONS}{$_} for keys %{$opts->{EXTENSIONS}};
    delete $opts->{EXTENSIONS};
  }

  $self->{EXTENSIONS} = $exts;

  $self->{OUTPUT_FORMAT} = $opts->{OUTPUT_FORMAT} // $default_output_format;

  return $self->SUPER::_init($opts);
}

sub _template_content {
  my $self = shift;
  my ($path) = @_;

  my ($data, $error, $mod_date) = $self->SUPER::_template_content($path);

  my $done = 0;

  for (keys %{$self->{EXTENSIONS}}) {
    next if $_ eq '*';
    if ($path =~ /\.\Q$_\E$/) {
      if (defined $self->{EXTENSIONS}{$_}) {
        $pandoc //= pandoc;
        $data = $pandoc->convert(
          $self->{EXTENSIONS}{$_} => $self->{OUTPUT_FORMAT}, $data
        );
      }
      $done = 1;
      last;
    }
  }

  if (!$done and exists $self->{EXTENSIONS}{'*'}) {
    $data = $pandoc->convert(
      $self->{EXTENSIONS}{'*'} => $self->{OUTPUT_FORMAT}, $data
    );
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
L<Template::Provider>.

=cut
