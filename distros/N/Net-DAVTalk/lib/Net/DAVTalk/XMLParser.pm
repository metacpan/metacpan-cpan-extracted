package Net::DAVTalk::XMLParser;

use base 'Exporter';

=head1 NAME

Net::DAVTalk - Interface to talk to DAV servers

=head1 SYNOPSIS

Net::DAVTalk::XMLParser is a simple wrapper around XML::Fast, returning
a more usable structure like that created by XML::Simple, but running
approximately 10 times faster in testing.

=head1 SUBROUTINES/METHODS

=head2 $hashref = xmlToHash($xmlstring);

Converts an XML string to a hashref of the content.

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 FastMail Pty. Ltd.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut


our @EXPORT = qw(xmlToHash);

use XML::Fast;
use Carp qw(confess);

sub _nsexpand {
  my $data = shift;
  my $ns = shift || {};

  if (ref($data) eq 'HASH') {
    my @keys;
    my %res;
    foreach my $key (keys %$data) {
      if ($key eq '@xmlns') {
        $ns->{''} = $data->{$key};
      }
      elsif ($key eq '#text') {
        $res{'content'} = $data->{$key};
      }
      elsif (substr($key, 0, 7) eq '@xmlns:') {
        my $namespace = substr($key, 7);
        $ns->{$namespace} = $data->{$key};
        # this is what XML::Simple does with existing namespaces
        $res{"{http://www.w3.org/2000/xmlns/}$namespace"} = $data->{$key};
      }
      else {
        push @keys, $key;
      }
    }
    foreach my $key (@keys) {
      my %ns = %$ns; # copy, woot
      my $sub = _nsexpand($data->{$key}, \%ns);
      my $pos = index($key, ':');
      if ($pos > 0) {
        my $namespace = substr($key, 0, $pos);
        my $rest = substr($key, $pos+1);
        # move attribute sigil from namespace to value
        $rest = "\@$rest" if $namespace =~ s/^\@//;
        my $expanded = $ns{$namespace};
        confess "Unknown namespace $namespace" unless $expanded;
        $key = "{$expanded}$rest";
      }
      elsif ($key =~ m/^\@/) {
        # Attributes are never subject to the default namespace.
        # An attribute without an explicit namespace prefix is
        # considered not to be in any namespace.
      }
      elsif ($ns{''}) {
        my $expanded = $ns{''};
        $key = "{$expanded}$key";
      }
      $res{$key} = $sub;
    }
    return \%res;
  }
  elsif (ref($data) eq 'ARRAY') {
    return [ map { _nsexpand($_, $ns) } @$data ];
  }
  else {
    # like XML::Simple's ExpandContent option
    return { content => $data };
  }
}

sub xmlToHash {
  my $text = shift;

  my $Raw = XML::Fast::xml2hash($text, attr => '@');
  # like XML::Simple's NSExpand option
  my $Xml = _nsexpand($Raw);

  # XML::Simple returns the content of the top level key
  # (there should only be one)
  my ($key) = keys %$Xml;

  return $Xml->{$key};
}

1;
