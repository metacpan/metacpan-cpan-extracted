package OpenTracing::Process;

use strict;
use warnings;

our $VERSION = '1.001'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

use parent qw(OpenTracing::Common);

no indirect;
use utf8;

=encoding utf8

=head1 NAME

OpenTracing::Process - information about a single process

=head1 DESCRIPTION

Each batch of spans is linked to a process. This can either be a Unix-style process or a more abstract "service"
concept.

=cut

=head1 METHODS

=head2 name

The process name. Freeform text string.

=cut

sub name { shift->{name} //= "$0" }

=head2 tags

Arrayref of tags relating to the process.

=cut

sub tags { shift->{tags} }

=head2 tag_list

List of tags for this process.

=cut

sub tag_list {
    (shift->{tags} //= [])->@*
}

sub tag : method {
    my ($self, %args) = @_;
    @{$self->{tags}}{keys %args} = values %args;
    return $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2018-2020. Licensed under the same terms as Perl itself.

