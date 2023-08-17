package MooX::Role::DBIConnection;
use Moo::Role;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';
use DBI;

our $VERSION = '0.05';

=head1 NAME

MooX::Role::DBIConnection - handy mixin for objects with a DB connection

=head1 SYNOPSIS

    { package My::Example;
      use Moo 2;
      with 'MooX::Role::DBIConnection';
    };

    # Lazily connect using the parameters
    my $writer = My::Example->new(
        dbh => {
            dsn  => '...',
            user => '...',
            password => '...',
            options => '...',
        },
    );

    # ... or alternatively if you have a connection already
    my $writer2 = My::Example->new(
        dbh => $dbh,
    );

This module enhances your class constructor by allowing you to pass in either
a premade C<dbh> or the parameters needed to create one.

The C<dbh> method will then return either the passed-in database handle or
try a connection to the database at the first use.

=head1 OPTIONS

The following options can be passed in the hashref to specify

=over 4

=item B<dsn>

L<DBI> dsn to connect to

=item B<user>

Database user to use when connecting to the database. This is the second
parameter used in the call to C<< DBI->connect(...) >>.

=item B<password>

Database password to use when connecting to the database. This is the third
parameter used in the call to C<< DBI->connect(...) >>.

=item B<options>

Database options to use when connecting to the database. This is the fourth
parameter used in the call to C<< DBI->connect(...) >>.

=item B<eager>

Whether to connect to the database immediately or upon the first call to the
the C<< ->dbh >>. The default is to make the connection lazily on first use.

=back

=cut

sub BUILD( $self, $args ) {
    if( my $_dbh = delete $args->{dbh}) {
        if(ref $_dbh eq 'HASH' && $_dbh->{eager}) {
            $_dbh = $self->_connect_db( $_dbh );
            $self->{_dbh} = $_dbh;
        } else {
            $self->{_dbh_options} = $_dbh;
        }
    }
};

sub _connect_db( $self, $dbh ) {
    if( ref($dbh) eq 'HASH' ) {
        $dbh = DBI->connect( @{$dbh}{qw{dsn user password options}});
    }
    return $dbh
}

sub dbh( $self ) {
    if( my $opt = delete $self->{_dbh_options}) {
        $self->{_dbh} = $self->_connect_db( $opt );
    }
    $self->{_dbh}
}

1;

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/MooX-Role-DBIConnection>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=MooX-Role-DBIConnection>
or via mail to L<MooX-Role-DBIConnection@rt.cpan.org|mailto:MooX-Role-DBIConnection@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2019-2023 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
