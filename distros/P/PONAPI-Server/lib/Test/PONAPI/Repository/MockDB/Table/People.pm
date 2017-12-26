# ABSTRACT: mock repository - table - People
package Test::PONAPI::Repository::MockDB::Table::People;

use Moose;

extends 'Test::PONAPI::Repository::MockDB::Table';
use Test::PONAPI::Repository::MockDB::Table::Relationships;

sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 ? %{ $_[0] } : @_;

    my $to_articles =
        Test::PONAPI::Repository::MockDB::Table::Relationships->new(
            TYPE          => 'articles',
            TABLE         => 'rel_articles_people',
            ID_COLUMN     => 'id_people',
            REL_ID_COLUMN => 'id_articles',
            COLUMNS       => [qw/ id_articles id_people /],
            ONE_TO_ONE    => 0,
        );

    %args = (
        TYPE      => 'people',
        TABLE     => 'people',
        ID_COLUMN => 'id',
        COLUMNS   => [qw/ id name age gender /],
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

Test::PONAPI::Repository::MockDB::Table::People - mock repository - table - People

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
