package Test::Chado::DBManager::Testpg;
{
  $Test::Chado::DBManager::Testpg::VERSION = 'v4.1.1';
}

use namespace::autoclean;
use Moo;
use DBI;
use Test::PostgreSQL;
extends qw/Test::Chado::DBManager::Pg/;

sub _build_dbh {
    my ($self) = @_;
    my $pg = Test::PostgreSQL->new or die $Test::PostgreSQL::errstr;
    $self->dsn( $pg->dsn );
    my $dbh = DBI->connect( $self->dsn, $self->user, $self->password,
        $self->dbi_attributes );
    $dbh->do(qq{SET client_min_messages=WARNING});
    return $dbh;
}

1;

__END__

=pod

=head1 NAME

Test::Chado::DBManager::Testpg

=head1 VERSION

version v4.1.1

=head1 AUTHOR

Siddhartha Basu <biosidd@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Siddhartha Basu.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
