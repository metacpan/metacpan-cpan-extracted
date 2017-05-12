#---------------------------------------------------------------------
package Pod::Loom::Parser;
#
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created:  6 Oct 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Subclass Pod::Eventual for Pod::Loom
#---------------------------------------------------------------------

use 5.008;
our $VERSION = '0.05';
# This file is part of Pod-Loom 0.08 (March 23, 2014)

use strict;
use warnings;

use Encode qw(find_encoding);
use Pod::Eventual ();
our @ISA = qw(Pod::Eventual);
#---------------------------------------------------------------------


sub new
{
  my ($class, $collectCommands) = @_;

  my %collect = map { $_ => [] } @$collectCommands;
  my %groups  = map { $_ => {} } @$collectCommands;

  bless {
    collect => \%collect,
    dest    => undef,
    groups  => \%groups,
  }, $class;
} # end new

#---------------------------------------------------------------------
sub _handle_encoding
{
  my ($self, $event) = @_;

  my $encoding = $event->{content};

  $encoding =~ s/^\s+//;
  $encoding =~ s/\s+\z//;

  my $e = find_encoding($encoding)
      or die "Invalid =encoding $encoding at line $event->{start_line}\n";

  if (defined $self->{encoding}) {
    return if $e->name eq $self->{encoding}->name;
    die "Conflicting =encoding directive at line $event->{start_line}\n";
  }

  $self->{encoding} = $e;
} # end _handle_encoding

#---------------------------------------------------------------------
sub handle_event
{
  my ($self, $event) = @_;

  my $dest = $self->{dest};

  if ($event->{type} eq 'command') {
    my $cmd = $event->{command};
    return if $cmd eq 'cut';

    return $self->_handle_encoding($event) if $cmd eq 'encoding';

    # See if this changes the output location:
    my $collector = $self->{collect}{ $cmd };

    if (not $collector and $cmd =~ /^(\w+)-(\S+)/ and $self->{collect}{$1}) {
      $collector = $self->{collect}{$cmd} = [];
      $self->{groups}{$1}{$2} = 1;
    } # end if new group

    # Special handling for Pod::Loom sections:
    if ($cmd =~ /^(begin|for)$/ and
        $event->{content} =~ s/^\s*(Pod::Loom\b\S*)\s*//) {
      $collector = ($self->{collect}{$1} ||= []);
      if ($cmd eq 'for') {
        push @$collector, $event->{content};
        return;
      }
      undef $cmd;
    } elsif ($cmd eq 'end' and
             $event->{content} =~ /^\s*Pod::Loom\b/) {
      # Handle =end Pod::Loom:
      $self->{dest} = undef;
      return;
    }

    # Either set output location, or make sure we have one:
    if ($collector) {
      push @$collector, '';
      $dest = $self->{dest} = \$collector->[-1];
    } else {
      die "=$cmd used too soon at line $event->{start_line}\n" unless $dest;
    }

    if ($cmd) {
      $$dest .= "=$cmd";
      $$dest .= ' ' unless $event->{content} =~ /^\n/;
    }
  } # end if command event

  $$dest .= $event->{content};
} # end handle_event

#---------------------------------------------------------------------
sub handle_blank
{
  my ($self, $event) = @_;

  if ($self->{dest}) {
    $event->{type} = 'text';
    $self->handle_event($event);
  }
} # end handle_blank
#---------------------------------------------------------------------


sub collected
{
  my ($self) = @_;

  my $collected = $self->{collect};
  my $encoding  = $self->{encoding} ||= find_encoding('iso-8859-1');

  unless ($self->{collect_decoded}++) {
    for my $array (values %$collected) {
      for my $value (@$array) {
        $value = $encoding->decode($value);
      }
    }
  }

  $collected;
} # end collected

#---------------------------------------------------------------------


sub encoding { shift->{encoding} ||= find_encoding('iso-8859-1') }
#---------------------------------------------------------------------


sub groups { shift->{groups} }

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

Pod::Loom::Parser - Subclass Pod::Eventual for Pod::Loom

=head1 VERSION

This document describes version 0.05 of
Pod::Loom::Parser, released March 23, 2014
as part of Pod-Loom version 0.08.

=head1 SYNOPSIS

  use Pod::Loom::Parser;

  my $parser = Pod::Loom::Parser->new( ['head1'] );
  $parser->read_file('lib/Foo/Bar.pm');
  my $collectedHash = $parser->collected;

  foreach my $block (@{ $collectedHash->{head1} }) {
    printf "---\n%s\n", $block;
  }

=head1 DESCRIPTION

Pod::Loom::Parser is a subclass of L<Pod::Eventual> intended for use
by L<Pod::Loom::Template>.  It breaks the POD into chunks based on a
list of POD commands.  Each chunk begins with one of the commands, and
contains all the POD up until the next selected command.

The commands do not need to be valid POD commands.  You can invent
commands like C<=attr> or C<=method>.

=head1 METHODS

See L<Pod::Eventual> for the C<read_handle>, C<read_file>, and
C<read_string> methods, which you use to feed POD into the parser.

=head2 new

  $parser = Pod::Loom::Parser->new(\@collect_commands);

Constructs a new Pod::Loom::Parser.  You pass it an arrayref of the
POD commands at which the POD should be chopped.


=head2 collected

  $hashRef = $parser->collected;

This returns the POD chunks that the document was chopped into.  There
is one entry for each of the C<@collect_commands> that were passed to
the constructor.  The value is an arrayref of strings, one for each
time that command appeared in the document.  Each chunk contains all
the text from the command up to (but not including) the command that
started the next chunk.  Chunks appear in document order.

If one of the commands did not appear in the document, its value will
be an empty arrayref.

In addition, any POD targeted to a format matching C</^Pod::Loom\b/>
will be collected under the format name.


=head2 encoding

  $encoding = $parser->encoding;

This returns the encoding that was used for the document as an
L<Encode> object.  If no encoding was explicitly defined, then the
default Latin-1 encoding is returned.


=head2 groups

  $hashRef = $parser->groups;

This returns a hashref with one entry for each of the
C<@collect_commands>.  Each value is a hashref whose keys are the
categories used with that command.  For example, if C<attr> was a
collected command, and the document contained these entries:

  =attr-foo attr1
  =attr-bar attr2
  =attr-foo attr3
  =attr attr4

then C<< keys %{ $parser->groups->{attr} } >> would return C<bar> and
C<foo>.  (The C<=attr> without a category does not get an entry in
this hash.)

=head1 CONFIGURATION AND ENVIRONMENT

Pod::Loom::Parser requires no configuration files or environment variables.

=head1 DEPENDENCIES

Pod::Loom::Parser requires L<Pod::Eventual>, which can be found on CPAN.

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
