# ABSTRACT: mock repository - table - Comments
package Test::PONAPI::Repository::MockDB::Table::Comments;

use Moose;
extends 'Test::PONAPI::Repository::MockDB::Table';

use Test::PONAPI::Repository::MockDB::Table::Relationships;

sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 ? %{ $_[0] } : @_;

    my $to_articles =
        Test::PONAPI::Repository::MockDB::Table::Relationships->new(
            TYPE          => 'articles',
            TABLE         => 'rel_articles_comments',
            ID_COLUMN     => 'id_comments',
            REL_ID_COLUMN => 'id_articles',
            COLUMNS       => [qw/ id_articles id_comments /],
            ONE_TO_ONE    => 1,
        );

    %args = (
        TYPE      => 'comments',
        TABLE     => 'comments',
        ID_COLUMN => 'id',
        COLUMNS   => [qw/ id body /],
        RELATIONS => { articles => $to_articles, },
        %args,
    );

    return \%args;
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::PONAPI::Repository::MockDB::Table::Comments - mock repository - table - Comments

=head1 VERSION

version 0.003003

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

This software is copyright (c) 2019 by Mickey Nasriachi, Stevan Little, Brian Fraser.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
