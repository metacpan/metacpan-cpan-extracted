package Plack::App::ServiceStatus::DBIC;

# ABSTRACT: Check DBIC connection

our $VERSION = '0.906'; # VERSION

use 5.018;
use strict;
use warnings;

sub check {
    my ( $class, $args ) = @_;
    $args = [$args] unless ref($args) eq 'ARRAY';

    my $dbic  = $args->[0];
    my $query = $args->[1] || 'select 1';
    my $sth   = $dbic->storage->dbh->prepare($query);
    $sth->execute;
    my $ok = $sth->fetchrow_array;
    return 'ok' if $ok == 1;
    return 'nok', "got: $ok";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::App::ServiceStatus::DBIC - Check DBIC connection

=head1 VERSION

version 0.906

=head1 SYNOPSIS

  my $schema     = YourApp::Schema->connect( ... );
  my $status_app = Plack::App::ServiceStatus->new(
      app  => 'your app',
      DBIC => $schema,
  );

=head1 CHECK

Gets C<dbh> from the schema object and executes a query, per default
C<select 1;>. This query has to return C<1> to indicate that
everything is ok.

You can pass another query when loading C<Plack::App::ServiceStatus>:

  my $status_app = Plack::App::ServiceStatus->new(
      app           => 'your app',
      DBIC          => [ $schema, '
        SELECT CASE
            WHEN count(*) > 0 THEN 1
            ELSE 0
        END
        FROM some_table'
      ],
  );

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 - 2022 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
