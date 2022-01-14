package OpenTracing::Reference;

use strict;
use warnings;

our $VERSION = '1.005'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

use parent qw(OpenTracing::Common);

no indirect;
use utf8;

use constant {
    CHILD_OF => 0,
    FOLLOWS_FROM => 1,
};

=encoding utf8

=head1 NAME

OpenTracing::Reference - represents a span Reference

=head1 DESCRIPTION

=cut

=head2 ref_type

The type of reference

=cut

sub ref_type { shift->{ref_type} }

=head2 span

The context for this reference.

=cut

sub context { shift->{context} }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2018-2021. Licensed under the same terms as Perl itself.
