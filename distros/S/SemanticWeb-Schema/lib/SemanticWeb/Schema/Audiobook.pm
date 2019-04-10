use utf8;

package SemanticWeb::Schema::Audiobook;

# ABSTRACT: An audiobook.

use Moo;

extends qw/ SemanticWeb::Schema::AudioObject SemanticWeb::Schema::Book /;


use MooX::JSON_LD 'Audiobook';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


has duration => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'duration',
);



has read_by => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'readBy',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Audiobook - An audiobook.

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

An audiobook.

=head1 ATTRIBUTES

=head2 C<duration>

=for html The duration of the item (movie, audio recording, event, etc.) in <a
href="http://en.wikipedia.org/wiki/ISO_8601">ISO 8601 date format</a>.

A duration should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Duration']>

=back

=head2 C<read_by>

C<readBy>

A person who reads (performs) the audiobook.

A read_by should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Book>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
