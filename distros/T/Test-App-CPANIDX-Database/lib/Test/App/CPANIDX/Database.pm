package Test::App::CPANIDX::Database;
$Test::App::CPANIDX::Database::VERSION = '0.06';
# ABSTRACT: generate a test database for App::CPANIDX

use strict;
use warnings;
use DBI;
use File::Spec;
use App::CPANIDX::Tables;

use constant CPANIDX => 'cpanidx.db';

sub new {
  my $package = shift;
  my %self = @_;
  $self{lc $_} = delete $self{$_} for keys %self;
  $self{unlink} = 1 unless defined $self{unlink} and !$self{unlink};
  die "Invalid dir specified\n" if
    defined $self{dir} and !( -d File::Spec->rel2abs($self{dir}) );
  $self{dir} = File::Spec->rel2abs($self{dir}) if defined $self{dir};
  my $db = $self{dir} ? File::Spec->catfile( $self{dir}, CPANIDX ) : CPANIDX;

  my $dbh = DBI->connect("dbi:SQLite:dbname=$db",'','') or die $DBI::errstr;

  foreach my $table ( App::CPANIDX::Tables->tables() ) {
    my $sql = App::CPANIDX::Tables->table( $table );
    $dbh->do($sql) or die $dbh->errstr;
    $dbh->do('DELETE FROM ' . $table) or die $dbh->errstr;
  }

  my $statements = {
    auths => qq{INSERT INTO auths values (?,?,?)},
    mods  => qq{INSERT INTO mods values (?,?,?,?,?)},
    dists => qq{INSERT INTO dists values (?,?,?,?)},
    timestamp => qq{INSERT INTO timestamp values(?,?)},
  };

  my $stamp = ( $self{time} || time() );
  my $data = [
    [ 'auths', 'FOOBAR', 'Foo Bar', 'foobar@cpan.org' ],
    [ 'mods',  'Foo::Bar','Foo-Bar','0.01','FOOBAR','0.01' ],
    [ 'dists', 'Foo-Bar','FOOBAR','F/FO/FOOBAR/Foo-Bar-0.01.tar.gz','0.01' ],
    [ 'timestamp', $stamp, $stamp  ],
  ];

  foreach my $datum ( @{ $data } ) {
    my $table = shift @{ $datum };
    my $sql = $statements->{ $table };
    my $sth = $dbh->prepare($sql) or die $dbh->errstr;
    $sth->execute( @{ $datum } );
  }

  return bless \%self, $package;
}

sub dbfile {
  my $self = shift;
  return
    $self->{dir} ? File::Spec->catfile( $self->{dir}, CPANIDX ) : CPANIDX;
}

sub DESTROY {
  my $self = shift;
  return unless $self->{unlink};
  my $db = $self->{dir} ? File::Spec->catfile( $self->{dir}, CPANIDX ) : CPANIDX;
  unlink $db;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::App::CPANIDX::Database - generate a test database for App::CPANIDX

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  use strict;
  use warnings;

  use Test::App::CPANIDX::Database;

  # Create a test database in the current working directory

  my $tdb = Test::App::CPANIDX::Database->new();

  # Get the name of the test database file generated

  my $dbfile = $tdb->dbfile;

  # The test database will be automagically removed when the 
  # object goes out of scope.

=head1 DESCRIPTION

Test::App::CPANIDX::Database will generate a test database for use with
L<App::CPANIDX> deriatives.

It generates a very simple L<DBD::SQLite> database which contains a single
CPAN author C<FOOBAR>, a single distribution C<Foo-Bar-0.01.tar.gz> and a
single module C<Foo::Bar>.

=head1 CONSTRUCTOR

=over

=item C<new>

Generates a test database called C<cpanidx.db> and returns an object reference.

Without any parameters this database file will be located in the current working
directory and will be automatically removed when the object falls out of scope.

You may provide parameters to affect this behaviour.

=over

=item C<unlink>

Set this to a false value to disable the automatic removal of the test database file.

  my $tdb = Test::App::CPANIDX::Database->new( unlink => 0 );

=item C<dir>

Set this to an existing directory path where the database file should be created.

  my $tdb = Test::App::CPANIDX::Database->new( dir => '/some/funky/path' );

=back

=back

=head1 METHODS

=over

=item C<dbfile>

Returns the name of the database file that was generated.

=back

=head1 SEE ALSO

L<App::CPANIDX>

L<App::CPANIDX::Tables>

L<DBD::SQLite>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
