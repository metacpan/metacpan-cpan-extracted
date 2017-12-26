# ABSTRACT: mock repository - table - Articles
package Test::PONAPI::Repository::MockDB::Table::Articles;

use Moose;
use Test::PONAPI::Repository::MockDB::Table::Relationships;

extends 'Test::PONAPI::Repository::MockDB::Table';

use constant COLUMNS => [qw[
    id
    title
    body
    created
    updated
    status
]];

sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 ? %{ $_[0] } : @_;

    # We could abstract these to their own objects, but no need currently
    my $to_comments =
        Test::PONAPI::Repository::MockDB::Table::Relationships->new(
            TYPE          => 'comments',
            TABLE         => 'rel_articles_comments',
            ID_COLUMN     => 'id_articles',
            REL_ID_COLUMN => 'id_comments',
            COLUMNS       => [qw/ id_articles id_comments /],
            ONE_TO_ONE    => 0,
        );
    my $to_authors =
        Test::PONAPI::Repository::MockDB::Table::Relationships->new(
            TYPE          => 'people',
            TABLE         => 'rel_articles_people',
            ID_COLUMN     => 'id_articles',
            REL_ID_COLUMN => 'id_people',
            COLUMNS       => [qw/ id_articles id_people /],
            ONE_TO_ONE    => 1,
        );

    %args = (
        TYPE      => 'articles',
        TABLE     => 'articles',
        ID_COLUMN => 'id',
        COLUMNS   => COLUMNS(),
        RELATIONS => {
            authors  => $to_authors,
            comments => $to_comments,
        },
        %args,
    );

    return \%args;
}

use PONAPI::Constants;
override update_stmt => sub {
    my ($self, %args) = @_;

    my $values   = $args{values} || {};
    my $copy = { %$values };
    $copy->{updated} = \'CURRENT_TIMESTAMP';

    my ($stmt, $ret, $msg) = $self->SUPER::update_stmt(%args, values => $copy);
    $ret ||= PONAPI_UPDATED_EXTENDED;
    return $stmt, $ret, $msg;
};

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::PONAPI::Repository::MockDB::Table::Articles - mock repository - table - Articles

=head1 VERSION

version 0.003002

=head1 AUTHORS

=over 4

=item *

Mickey Nasriachi <mickey@cpan.org>

=item *

Stevan Little <stevan@cpan.org>

=item *

Brian Fraser <hugmeir@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Mickey Nasriachi, Stevan Little, Brian Fraser.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
