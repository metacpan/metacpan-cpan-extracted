package MsgPack::Raw::Ext;
$MsgPack::Raw::Ext::VERSION = '0.05';
use strict;
use warnings;
use overload
    '==' => sub { $_[0]->{type} == $_[1]->{type} && $_[0]->{data} eq $_[1]->{data} },
    fallback => 1 ;
use MsgPack::Raw;


sub new
{
    my ($this, $type, $data) = @_;

    my $class = ref ($this) || $this;
    my $self =
    {
        type => $type,
        data => $data,
    };

    return bless $self, $class;
}


=head1 NAME

MsgPack::Raw::Ext - msgpack Ext class

=head1 VERSION

version 0.05

=head1 DESCRIPTION

MessagePack Ext class

=head1 SYNOPSIS

	use MsgPack::Raw;

=head1 METHODS

=head2 new( $type, $data)

Create a new ext type.

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of MsgPack::Raw::Ext
