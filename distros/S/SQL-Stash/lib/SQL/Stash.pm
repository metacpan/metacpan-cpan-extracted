package SQL::Stash;
use strict;
use warnings;

use v5.6;
use Carp qw(croak);
use version v0.77;

use constant CACHE_DEFAULT => 1;

our $VERSION = version->declare("v0.2.0");
my %STASH;

sub new {
	my ($class, %args) = @_;
	my $self = bless({}, $class);
	$self->{'dbh'} = $args{'dbh'} or croak("DBI handle missing");
	$self->{'stash'} = {};
	return $self;
}

sub stash {
	my ($class, $name, $sql, $should_cache) = @_;
	my $stash;
	$should_cache ||= CACHE_DEFAULT;

	if(ref($class)) {
		$stash = $class->{'stash'};
	} else {
		$STASH{$class} ||= {};
		$stash = $STASH{$class};
	}

	$stash->{$name} = {
		'sql' => $sql,
		'should_cache' => $should_cache || 1,
	};
	return;
}

sub retrieve {
	my $self = shift;
	my $name = shift;
	my $class = ref($self) || $self;
	my $sth;
	my $stashed;

	if(ref($self)) {
		$stashed = $self->{'stash'}->{$name};
	}
	$stashed ||= $STASH{$class}->{$name} or return;
	my $sql = $self->transform_sql($stashed->{'sql'}, @_);

	if($stashed->{'should_cache'}) {
		$sth = $self->{'dbh'}->prepare_cached($sql);
	} else {
		$sth = $self->{'dbh'}->prepare($sql);
	}
	return $sth;
}

sub transform_sql {
	my $self = shift;
	my $sql = shift;
	return sprintf($sql, @_);
}

1;

__END__

=head1 NAME

SQL::Stash - A stash for SQL queries

=head1 SYNOPSIS

	package SQL::Stash::Foo;
	use base qw(SQL::Stash);
	__PACKAGE__->stash('select_foo', 'SELECT * FROM Foo');
	1;

	package main;
	my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
	my $stash = SQL::Stash::Foo->new();
	my $sth = $stash->retrieve('select_foo');
	$sth->execute();
	while(my $row = $sth->fetchrow_arrayref()) {
		print("$_\n") for @$row;
	}

=head1 DESCRIPTION

L<SQL::Stash|SQL::Stash> is a simple query library for SQL statements.
SQL statements are populated at the class level. SQL::Stash objects
prepare these statements as late as possible (i.e. before they are
executed).

SQL::Stash is in concept very similar to L<Ima::DBI|Ima::DBI>, but
differs by having instance-specific database handles and statements, and
by supporting externally defined database handles.

=head1 METHODS

=head2 new

	SQL::Stash->new(%args);

Designated constructor. Instantiates a new L<SQL::Stash|SQL::Stash>
object. The C<dbh> argument, a L<DBI|DBI>-like object,  must be
provided.

	my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
	my $stash = SQL::Stash->new('dbh' => $dbh);

=head2 stash

	SQL::Stash::Foo->stash($name, $statement, $should_cache);
	$stash->stash($name, $statement, $should_cache);

Stash an SQL C<statement>. The method can be called both on the class
and instance. If the class method is called the C<statement> will be
added to the global stash. If the instance method is called the
C<statement> will only be added to the instance-specific C<stash>.

The C<name> is used as an identifier in order to later
L<retrieve|retrieve> it. The C<should_cache> parameter is optional and
specifies whether C<prepare()> or C<prepare_cached()> is used to prepare
the C<statement>. It defaults to C<true>.

	SQL::Stash::Foo->stash('select_foo', 'SELECT * FROM Foo');

=head2 retrieve

	$stash->retrieve($name, @_);

Prepare the statement stored via L<stash|stash>, identified by C<name>,
and return a prepared statement handle. The SQL statement may be
modified by L<transform_sql|transform_sql> before it is prepared.

=head2 transform_sql

	$stash->transform_sql($sql, @_)

Transform the SQL statement before it is prepared to enable dynamically
generated statements. The default implementation is to use
L<sprintf|sprintf>, but sub-classes may override this method to perform
any transformation.

	$stash->transform_sql("SELECT * FROM %s", "table");
	#=> SELECT * FROM table

=head1 SEE ALSO

L<Ima::DBI|Ima::DBI>
L<SQL::Bibliosoph|SQL::Bibliosoph>
L<SQL::Snippet|SQL::Snippet>

=head1 AUTHOR

Sebastian Nowicki <sebnow@gmail.com>

=cut

