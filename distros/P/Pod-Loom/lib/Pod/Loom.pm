#---------------------------------------------------------------------
package Pod::Loom;
#
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: October 6, 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Weave pseudo-POD into real POD
#---------------------------------------------------------------------

use 5.008;
our $VERSION = '0.08';
# This file is part of Pod-Loom 0.08 (March 23, 2014)

use Moose 0.65; # attr fulfills requires
use Carp qw(croak);
use PPI ();
use String::RewritePrefix ();

#=====================================================================
{
  package Pod::Loom::_EventCounter;
  our @ISA = 'Pod::Eventual';
  sub new {
    require Pod::Eventual;
    my $events = 0;
    bless \$events => shift;
  }

  sub handle_event { ++${$_[0]} }
  sub events { ${ +shift } }
}

#=====================================================================
# Package Pod::Loom:

has template => (
  is      => 'rw',
  isa     => 'Str',
  default => 'Default',
);
#=====================================================================


sub weave
{
  my ($self, $docRef, $filename, $data) = @_;

  my $ppi = PPI::Document->new($docRef);

  my $sourcePod = join("\n", @{ $ppi->find('PPI::Token::Pod') || [] });

  $ppi->prune('PPI::Token::Pod');

  croak "Can't use Pod::Loom on $filename: there is POD inside string literals"
      if $self->_has_pod_events("$ppi");


  # Determine the template to use:
  my $templateClass = $self->template;

  if ($sourcePod =~ /^=for \s+ Pod::Loom-template \s+ (\S+)/mx) {
    $templateClass = $1;
  }

  $templateClass = String::RewritePrefix->rewrite(
    {'=' => q{},  q{} => 'Pod::Loom::Template::'},
    $templateClass
  );

  # Instantiate the template and let it weave the new POD:
  croak "Invalid class name $templateClass"
      unless $templateClass =~ /^[:_A-Z0-9]+$/i;
  eval "require $templateClass;" or croak "Unable to load $templateClass: $@";


  my $template = $templateClass->new($data);

  my $newPod = $template->weave(\$sourcePod, $filename);
  $newPod =~ s/(?:\s*\n=cut)*\s*\z/\n\n=cut\n/; # ensure it ends with =cut
  $newPod = '' if $newPod =~ /^\s*=cut$/;       # if it's blank, ignore it

  # Plug the new POD back into the code:

  my $end = do {
    my $end_elem = $ppi->find('PPI::Statement::Data');

    unless ($end_elem) {
      $end_elem = $ppi->find('PPI::Statement::End');

      # If there's nothing after __END__, we can put the POD there:
      if (not $end_elem or (@$end_elem == 1 and
                            $end_elem->[0] =~ /^__END__\s*\z/)) {
        $end_elem = [];
      } # end if no significant text after __END__
    } # end unless found __DATA__

    @$end_elem ? join q{}, @$end_elem : undef;
  };

  $ppi->prune('PPI::Statement::End');
  $ppi->prune('PPI::Statement::Data');

  my $docstr = $ppi->serialize;
  $docstr =~ s/\n*\z/\n/;       # ensure it ends with one LF

  return $newPod if $docstr eq "\n" and not defined $end; # Pure POD file

  return defined $end
      ? "$docstr\n$newPod\n$end"
      : "$docstr\n__END__\n\n$newPod";
} # end weave_document

#---------------------------------------------------------------------
sub _has_pod_events
{
  my $pe = Pod::Loom::_EventCounter->new;
  # We can't use read_string, because that treats the string as
  # encoded in UTF-8, for which some byte sequences aren't valid.
  open my $handle, '<:encoding(iso-8859-1)', \$_[1]
      or die "error opening string for reading: $!";
  $pe->read_handle($handle);

  $pe->events;
} # end _has_pod_events

#=====================================================================
# Package Return Value:

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Pod::Loom - Weave pseudo-POD into real POD

=head1 VERSION

This document describes version 0.08 of
Pod::Loom, released March 23, 2014
as part of Pod-Loom version 0.08.

=head1 WARNING

This code is still in flux.  Use it at your own risk, and be prepared
to adapt to changes.  The POD syntax should be fairly stable, but if
you write your own templates, they might need to change.

=head1 SYNOPSIS

  use Pod::Loom;

  my $document = ...; # Text of Perl program including POD
  my $filename = "filename/of/document.pm"; # For messages
  my %data = ...; # Configuration required by template

  my $loom = Pod::Loom->new(template => 'Custom');
  my $new_doc = $loom->weave(\$document, $filename, \%data);

=head1 DESCRIPTION

Pod::Loom extracts all the POD sections from Perl code, passes the POD
to a template that may reformat it in various ways, and then returns a
copy of the code with the reformatted POD at the end.

A template may convert non-standard POD commands like C<=method> and
C<=attr> into standard POD, reorder sections, and generally do
whatever it likes to the POD.

The document being reformatted can specify the template to use with a
line like this:

  =for Pod::Loom-template TEMPLATE_NAME

Otherwise, you can specify the template in the Pod::Loom constructor:

  $loom = Pod::Loom->new(template => TEMPLATE_NAME);

TEMPLATE_NAME is automatically prefixed with C<Pod::Loom::Template::>
to form a class name.  If you want to use a template outside that
namespace, prefix the class name with C<=> to indicate that.

=head1 METHODS

=head2 new

  $loom = Pod::Loom->new(template => TEMPLATE_NAME);

Constructs a new Pod::Loom.  The C<template> parameter is optional; it
defaults to C<Default> (meaning L<Pod::Loom::Template::Default>).



=head2 weave

    $new_doc = $loom->weave(\$doc, $filename, $data);

This method does all the work (see L</"DESCRIPTION">).  You pass it a
reference to a string containing Perl code mixed with POD.  (This
string is not modified.)  It returns a new string containing the
reformatted POD moved to the end of the code.  C<$doc> should contain
raw bytes (i.e. UTF8 flag off).  If C<$doc> is encoded in something
other than Latin-1, it must contain an C<=encoding> directive
specifying the encoding.  C<$new_doc> will likewise contain raw bytes
in the same encoding as C<$doc>.

The C<$filename> is used for error messages.  It does not need to
actually exist on disk.

C<$data> is passed as the only argument to the template class's
constructor (which must be named C<new>).  Pod::Loom does not inspect
it, but for consistency and compatibility between templates it should
be a hashref.

=head1 REQUIREMENTS OF A TEMPLATE CLASS

A template class must have a constructor named C<new> and a method
named C<weave> that matches the one in L<Pod::Loom::Template>.  It
should be in the C<Pod::Loom::Template::> namespace (to make it easy
to specify the template name), but it does not need to be a subclass
of Pod::Loom::Template.

=head1 DIAGNOSTICS

Pod::Loom may generate the following error messages, in addition to
whatever errors the template class generates.



=over

=item C<< Can't use Pod::Loom on %s: there is POD inside string literals >>

You have POD commands inside a string literal (probably a here doc).
Since Pod::Loom moves all POD to the end of the file, running it on
your program would change its behavior.  Move the POD outside the
string, or quote any equals sign at the beginning of a line so it no
longer looks like POD.


=item C<< Invalid class name %s >>

A template name may only contain ASCII alphanumerics and underscore.


=item C<< Unable to load %s: %s >>

Pod::Loom got an error when it tried to C<require> your template class.



=back

=head1 CONFIGURATION AND ENVIRONMENT

Pod::Loom requires no configuration files or environment variables.

=head1 DEPENDENCIES

Pod::Loom depends on L<Moose>, L<Pod::Eventual>, L<PPI>, and
L<String::RewritePrefix>, which can be found on CPAN.  The template
class may have additional dependencies.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-Pod-Loom AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Pod-Loom >>.

You can follow or contribute to Pod-Loom's development at
L<< https://github.com/madsen/pod-loom >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
