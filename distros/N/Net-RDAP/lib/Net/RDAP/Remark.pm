package Net::RDAP::Remark;
use base qw(Net::RDAP::Base);
use strict;
use warnings;

=pod

=head1 NAME

L<Net::RDAP::Remark> - a module representing an RDAP remark.

=head1 DESCRIPTION

This module represents a remark attached to an RDAP response.

Any object which inherits from L<Net::RDAP::Object> will have a
C<remarks()> method which will return an array of zero or more
L<Net::RDAP::Remark> objects.

=head1 METHODS

=head2 Remark Title

    $title = $remark->title;

Returns the textual description of the remark.

=cut

sub title { $_[0]->{'title'} }

=pod

=head2 Remark Type

    $type = $link->type;

Returns the "type" of the remark. The possible values are defined by
an IANA registry; see:

=over

=item * L<https://www.iana.org/assignments/rdap-json-values/rdap-json-values.xhtml>

=back

=cut

sub type { $_[0]->{'type'} }

=pod

=head2 Remark Description

    my @description = $link->description;

Returns an array containing lines of text.

=cut

sub description { $_[0]->{'description'} ? @{$_[0]->{'description'}} : () }

=pod

=head2 Remark Links

    $links = $remark->links;

Returns a (potentially empty) array of L<Net::RDAP::Link> objects.

=head1 COPYRIGHT

Copyright 2018-2023 CentralNic Ltd, 2024 Gavin Brown. For licensing information,
please see the C<LICENSE> file in the L<Net::RDAP> distribution.

=cut

1;
