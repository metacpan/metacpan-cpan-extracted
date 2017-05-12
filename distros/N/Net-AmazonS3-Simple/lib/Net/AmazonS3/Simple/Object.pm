package Net::AmazonS3::Simple::Object;
use strict;
use warnings;

use Class::Tiny qw(etag content_encoding content_length content_type last_modified),
  { validate => 1, };

=head1 NAME

Net::AmazonS3::Simple::Object - base class of Object

=head1 DESCRIPTION

base object of Object

=head1 METHODS

=head2 new(%attributes)

=head3 %attributes

=head4 etag

=head4 content_encoding

=head4 content_length

=head4 content_type

=head4 last_modified

=head4 validate

=cut

sub BUILD {
    my ($self) = @_;

    foreach my $req (qw/etag/) {
        die "$req attribute required" unless defined $self->$req;
    }
}

=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Seidl E<lt>seidl@avast.comE<gt>

=cut

1;
