package Slick::DatabaseExecutor::MySQL;

use 5.036;

use Moo;
use Carp qw(croak);

with 'Slick::DatabaseExecutor';

sub BUILD {
    my $self = shift;

    my $db = split /\//x, $self->{connection}->path;

    my $dsn = defined $db ? "dbi:mysql:dbname=$db" : "dbi:Pg";
    if ( my $host = $self->{connection}->host ) { $dsn .= ";host=$host"; }
    if ( my $port = $self->{connection}->port ) { $dsn .= ";port=$port"; }

    my ( $username, $password ) =
      split /\:/x, [ split /\@/x, $self->{connection}->authority ]->[0];

    $self->{dbi} = DBI->connect( $dsn, $username // '', $password // '',
        $self->dbi_options );

    croak qq{Couldn't connect to database: } . $self->{connection}
      unless $self->dbi->ping;

    return $self;
}

1;

=encoding utf8

=head1 NAME

Slick::DatabaseExecutor::MySQL

=head1 SYNOPSIS

A child class of L<Slick::DatabaseExecutor>, handles all interactions with MySQL, mostly just configuring the connection.

=head1 See also

=over 2

=item * L<Slick>

=item * L<Slick::RouteManager>

=item * L<Slick::Context>

=item * L<Slick::Database>

=item * L<Slick::DatabaseExecutor>

=item * L<Slick::DatabaseExecutor::Pg>

=item * L<Slick::EventHandler>

=item * L<Slick::Events>

=item * L<Slick::Methods>

=item * L<Slick::RouteMap>

=item * L<Slick::Util>

=back

=cut
