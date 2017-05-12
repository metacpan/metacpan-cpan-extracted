use warnings;
use strict;

package Module::Starter::Plugin::InlineStore;

our $VERSION = '0.144';

use Carp ();

=head1 NAME

Module::Starter::Plugin::InlineStore -- inline module template files

=head1 VERSION

version 0.144

=head1 SYNOPSIS

 use Module::Starter qw(
   Module::Starter::Simple
   Module::Starter::Plugin::Template
   Module::Starter::Plugin::InlineStore
   ...
 );

 Module::Starter->create_distro( ... );

=head1 DESCRIPTION

This Module::Starter plugin is intended to be loaded after
Module::Starter::Plugin::Template.  It implements the C<templates> method,
required by the Template plugin.  The C<InlineStore> plugin stores all the
required templates in a single file, delimited with filenames between
triple-underscores.  In other words, a very simple template file might look
like this:

 ___Module.pm___
 package {modulename};
 1;
 ___Makefile.PL___
 die "lousy template"

Originally, this module was to use Inline::Files, or at least standard
double-underscore indication of file names, but it's just simpler this way.
Patches welcome.

=cut

=head1 METHODS

=head2 C<< templates >>

This method reads in the template file (described above) and populates the
object's C<templates> attribute.  The module template file is found by checking
the MODULE_TEMPLATE_FILE environment variable and then the "template_file"
config option.

=cut

sub _template_filehandle {
    my $self = shift;

    my $template_filename =
      ($ENV{MODULE_TEMPLATE_FILE} || $self->{template_file})
      or Carp::croak "no template file defined";
    open my $template_file, '<', $template_filename
      or Carp::croak "couldn't open template file: $template_filename";

    return $template_file;
}

sub templates {
    my $self = shift;
    my %template;
     
    my $template_file = $self->_template_filehandle;

    my $fn = '_';
    while (<$template_file>) {
        if (/^___([-_.0-9A-Za-z]+)___$/) {
            $fn = $1;
            $template{$fn} = q{};
            next;
        }
        $template{$fn} .= $_;
    }

    return %template;
}

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs@cpan.org> >>

=head1 Bugs

Please report any bugs or feature requests to
C<bug-module-starter-plugin-inlinestore@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT

Copyright 2004 Ricardo SIGNES, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
