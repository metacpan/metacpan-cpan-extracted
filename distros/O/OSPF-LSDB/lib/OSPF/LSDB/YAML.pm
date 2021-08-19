##########################################################################
# Copyright (c) 2010-2021 Alexander Bluhm <alexander.bluhm@gmx.net>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
##########################################################################

use strict;
use warnings;

=pod

=head1 NAME

OSPF::LSDB::YAML - load or dump OSPF link state database as YAML

=head1 SYNOPSIS

use OSPF::LSDB;

use OSPF::LSDB::YAML;

my $ospf = OSPF::LSDB-E<gt>new();

my $yaml = OSPF::LSDB::YAML-E<gt>new($ospf);

$string = $yaml-E<gt>Dump();

$yaml-E<gt>DumpFile($filename);

$yaml-E<gt>Load($string);

$yaml-E<gt>LoadFile($filename);

=head1 DESCRIPTION

The OSPF::LSDB::YAML module allows to load or dump a L<OSPF::LSDB>
instance in YAML format.

=cut

package OSPF::LSDB::YAML;
use base qw(OSPF::LSDB);
use YAML::Syck qw();

=pod

=over 4

=item $self-E<gt>Dump()

Return the L<OSPF::LSDB> content as YAML string.

=cut

sub Dump {
    my OSPF::LSDB $self = shift;
    return YAML::Syck::Dump($self->{ospf});
}

=pod

=item $self-E<gt>DumpFile($filepath)

Write the L<OSPF::LSDB> content as YAML into a file.

=cut

sub DumpFile {
    my OSPF::LSDB $self = shift;
    my $filepath = shift;
    YAML::Syck::DumpFile($filepath, $self->{ospf});
}

=pod

=item $self-E<gt>Load($string)

Set the L<OSPF::LSDB> base object to the given YAML string.
The content is converted to the current version and is validated.

=cut

sub Load {
    my OSPF::LSDB $self = shift;
    my $string = shift;
    $self->{ospf} = YAML::Syck::Load($string);
    $self->convert();
    $self->validate();
}

=pod

=item $self-E<gt>LoadFile($filepath)

Set the L<OSPF::LSDB> base object to the given YAML file.
The content is converted to the current version and is validated.

=back

=cut

sub LoadFile {
    my OSPF::LSDB $self = shift;
    my $filepath = shift;
    $self->{ospf} = YAML::Syck::LoadFile($filepath);
    $self->convert();
    $self->validate();
}

=pod

=head1 ERRORS

The methods die if any error occures.

=head1 SEE ALSO

L<OSPF::LSDB>,

L<ospfconvert>

=head1 AUTHORS

Alexander Bluhm

=cut

1;
