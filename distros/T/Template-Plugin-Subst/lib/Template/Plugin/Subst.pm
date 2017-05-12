package Template::Plugin::Subst;

# Copyright (c) 2005 Nik Clayton
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

use warnings;
use strict;

use Template::Plugin::Filter;
use base qw(Template::Plugin::Filter);

use Template::Stash;

$Template::Stash::SCALAR_OPS->{subst} = \&subst;

=head1 NAME

Template::Plugin::Subst - s/// functionality for Template Toolkit templates

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

sub init {
  my $self = shift;

  $self->{_DYNAMIC} = 1;

  return $self;
}

sub filter {
  my($self, $text, $args, $config) = @_;

  $config = $self->merge_config($config);

  my $pattern     = $config->{pattern};
  my $replacement = $config->{replacement};
  my $global      = defined $config->{global} ? $config->{global} : 1;

#  warn "pattern: $pattern, replacement: $replacement\n";
  $text = subst($text, $pattern, $replacement, $global);

  return $text;
}

sub subst {
  my($text, $pattern, $replacement, $global) = @_;

  $global = defined $global ? $global : 1;

#  warn "-> subst() ('$pattern', '$replacement')\n";
  if($text !~ m/$pattern/) {
#    warn "text does not match '$pattern', returning";
    return $text;
  }

  # If there are no subgroups then it's a simple search/replace
  if($#- == 0) {
#    warn "No subgroups found, doing simple search/replace\n";
    if($global) {
      $text =~ s/$pattern/$replacement/g;
    } else {
      $text =~ s/$pattern/$replacement/;
    }
    return $text;
  }

  # First, save the original text, and what was matched
  my $saved_text = $text;
  my $PREMATCH   = substr($saved_text, 0, $-[0]);
  my $MATCHED    = substr($saved_text, $-[0], $+[0] - $-[0]);
  my $POSTMATCH  = substr($saved_text, $+[0]);

  # Save the positions where we matched
  my @saved_match_start = @-;
  my @saved_match_end   = @+;
			
#  warn "PREMATCH : <<$PREMATCH>>";
#  warn "MATCHED  : <<$MATCHED>>";
#  warn "POSTMATCH: <<$POSTMATCH>>";

  # Now do the s///.  This will leave placeholders (literally, '$1', '$2',
  # etc, in the replaced text.
#  warn "Doing s///";
  $MATCHED =~ s/$pattern/$replacement/;
#  warn "MATCHED:  <<$MATCHED>>";

  foreach my $i (1..$#saved_match_start) {
    my $backref = substr($saved_text,
			 $saved_match_start[$i],
			 $saved_match_end[$i] - $saved_match_start[$i]);
    $MATCHED =~ s/\$$i/$backref/g;
  }

#  warn "Fixed up backrefs";
#  warn "MATCHED:  <<$MATCHED>>";

  if($global) {
    return $PREMATCH . $MATCHED . subst($POSTMATCH, $pattern, $replacement);
  } else {
    return $PREMATCH . $MATCHED . $POSTMATCH;
  }
}

=head1 SYNOPSIS

=head2 As a vemthod

  [% USE Subst %]

  [% str = 'foobar' %]

  [% str.subst('(foo)(bar)', '$2$1', 1) %]

=head2 As a filter

  [% USE filt = Subst
                pattern = '(foo)(bar)'
                replacement = '$2$1'
                global = 1 %]

Then

  [% text | $filt %]

or

  [% FILTER $filt %]
  foobar
  [% END %]

=head1 DESCRIPTION

Template::Plugin::Subst acts as a filter and a virtual method to carry
out regular expression substitutions with back references on text and
variables in the Template Toolkit.

That's the advantage of this approach over the built-in C<replace>
method.  C<replace> doesn't deal with backrefs, so code like this:

  [% str = 'foobar' %]
  [% str.replace('(foo)(bar)', '$2$1') %]

inserts a literal C<$2$1> in to your document.

But with Template::Plugin::Subst;

  [% USE Subst %]
  [% str = 'foobar' %]
  [% str.subst('(foo)(bar)', '$2$1') %]

you get the expected C<barfoo>.

It can also be used as a filter, in which case it's very useful for finding
information in text and augmenting it in a useful fashion.

For example, suppose you want all strings of the form C<rt#\d+>, which
reference RT ticket numbers, to be converted to links to your local
RT installation.

First, instatiate the filter:

  [% USE rt = Subst
                pattern = 'rt#(\d+)'
                replacement = '<a href="/rt.cgi?t=$1">rt#$1</a>' %]

and then use it to filter arbitrary text:

  [% text_variable | $rt %]

=head1 OPTIONS

=head2 vmethod

  .subst($pattern, $replacement[, $global])

As a vmethod the first two arguments are the pattern to search for and
the string to replace it with.  These arguments are mandatory.

The third argument is a boolean that specifies whether or the
search/replace should be global, and behaves in the same way as the C<g>
modifier on a C<s///> operation.  The default value is '1'.  Note that
this differs from the default setting on the C<s///> operator.

=head2 Filter

  [% USE filt = Subst
                  pattern = '...'
                  replacement = '...'
                  global = 1 %]

These three named arguments have the same semantics as the arguments to
the vmethod.  C<global> is optional, and defaults to 1.

=head1 AUTHOR

Nik Clayton, C<< <nik@FreeBSD.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-template-plugin-subst@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-Subst>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2005 Nik Clayton
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.

=cut

1; # End of Template::Plugin::Subst
