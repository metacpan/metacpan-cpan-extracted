#
# Copyright (C) 1997 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: GroveBuilder.pm,v 1.1.1.1 1998/01/02 21:31:15 ken Exp $
#

package Pod::GroveBuilder;

use strict;
use vars qw($VERSION @ISA);

use SGML::SPGrove;

@ISA = qw(Pod::Parser);
$VERSION = '0.01';

sub new {
    my $type = shift;
    my $sysid = shift;

    my $parser = $type->SUPER::new();

    if (ref $sysid) {
	$parser->parse_from_filehandle ($sysid);
    } else {
	$parser->parse_from_file ($sysid);
    }

    return $parser->{_grove};
}

sub command {
    my ($parser, $command, $paragraph, $attributes) = @_;

}

sub verbatim {
    my ($parser, $paragraph) = @_;
}

sub textblock {
    my ($parser, $paragraph) = @_;
}

sub interior_sequence {
    my ($parser, $sequence, $seq_argument, $attributes) = @_;
}

1;
__END__
=head1 NAME

Pod::GroveBuilder - use Pod::Parser to create SGML::Grove objects

=head1 SYNOPSIS

  use Pod::GroveBuilder;
  $grove = Pod::GroveBuilder->new ($sysid);

=head1 DESCRIPTION

C<Pod::GroveBuilder> uses Pod::Parser to create SGML::Grove objects.
The resulting SGML::Grove objects can then be used by any module that
supports them, including writing SGML/XML output (SGML::Writer),
formatting the POD to Ascii or HTML (Quilt), or using SGML::Grove
iterators to perform multiple passes over the POD or working with
multiple PODs at the same time.

C<Pod::GroveBuilder-E<gt>new ($sysid)> creates a grove from a
C<$sysid>, a C<$sysid> may be a file name or a C<FileHandle> object.

GroveBuilder will build a grove that is hierarchical, for example,
`head2' sections will be contained inside of `head1' sections, and
`item' paragraphs will be contained within lists, etc.

  HEAD1
    "text"
    HEAD2
      LIST
        ITEM
          "text"
        ITEM
          "text"
    HEAD2
     "text"

See C<SGML::Grove> for details on using the grove returned by
C<Pod::GroveBuilder>.

=head1 AUTHOR

Ken MacLeod, ken@bitsko.slc.ut.us

=head1 SEE ALSO

perl(1), Pod::Parser(3), SGML::Grove(3), SGML::Writer(3), Quilt(3).

=cut
