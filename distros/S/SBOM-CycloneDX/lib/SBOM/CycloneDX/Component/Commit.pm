package SBOM::CycloneDX::Component::Commit;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::List;

use Types::Standard qw(Str InstanceOf);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has uid       => (is => 'rw', isa => Str);
has url       => (is => 'rw', isa => Str);
has author    => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::IdentifiableAction']);
has committer => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::IdentifiableAction']);
has message   => (is => 'rw', isa => Str);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{uid}       = $self->uid       if $self->uid;
    $json->{url}       = $self->url       if $self->url;
    $json->{author}    = $self->author    if $self->author;
    $json->{committer} = $self->committer if $self->committer;
    $json->{message}   = $self->message   if $self->message;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Component::Commit - Commit

=head1 SYNOPSIS

    SBOM::CycloneDX::Component::Commit->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Component::Commit> specifies an individual commit.

=head2 METHODS

L<SBOM::CycloneDX::Component::Commit> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Component::Commit->new( %PARAMS )

Properties:

=over

=item C<author>, The author who created the changes in the commit

=item C<committer>, The person who committed or pushed the commit

=item C<message>, The text description of the contents of the commit

=item C<uid>, A unique identifier of the commit. This may be version
control specific. For example, Subversion uses revision numbers whereas git
uses commit hashes.

=item C<url>, The URL to the commit. This URL will typically point to a
commit in a version control system.

=back

=item $commit->author

=item $commit->committer

=item $commit->message

=item $commit->uid

=item $commit->url

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-SBOM-CycloneDX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-SBOM-CycloneDX>

    git clone https://github.com/giterlizzi/perl-SBOM-CycloneDX.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025-2026 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
