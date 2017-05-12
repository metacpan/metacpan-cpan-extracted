package Prosody::Storage::SQL;
BEGIN {
  $Prosody::Storage::SQL::AUTHORITY = 'cpan:GETTY';
}
{
  $Prosody::Storage::SQL::VERSION = '0.007';
}
# ABSTRACT: access a database of mod_storage_sql

use Moose;
use Moose::Util::TypeConstraints;
use Prosody::Storage::SQL::DB;
use JSON;
use Encode;

has driver => (
	is => 'ro',
	isa => enum(["SQLite3","MySQL","PostgreSQL"]),
	required => 1,
);

has database => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

has username => (
	is => 'ro',
	isa => 'Str',
	predicate => 'has_username',
);

has password => (
	is => 'ro',
	isa => 'Str',
	predicate => 'has_password',
);

has host => (
	is => 'ro',
	isa => 'Str',
	predicate => 'has_host',
);

has _db => (
	is => 'ro',
	isa => 'Prosody::Storage::SQL::DB',
	lazy => 1,
	default => sub {
		my ( $self ) = @_;
		my $vars = {
			quote_char              => '"',
			name_sep                => '.',
		};
		if ($self->driver eq 'SQLite3') {
			$vars->{sqlite_unicode} = 1;
		} elsif ($self->driver eq 'MySQL') {
			$vars->{mysql_enable_utf8} = 1,
		} elsif ($self->driver eq 'PostgreSQL') {
			$vars->{pg_enable_utf8} = 1,
		};
		Prosody::Storage::SQL::DB->connect($self->dsn, $self->username, $self->password, $vars);
	},
);

sub rs { shift->resultset(@_) }
sub resultset { shift->_db->resultset('Prosody') }

has dsn => (
	is => 'ro',
	lazy => 1,
	default => sub {
		my ( $self ) = @_;
		my $driver;
		$driver = 'SQLite' if $self->driver eq "SQLite3";
		$driver = 'mysql' if $self->driver eq "MySQL";
		$driver = 'Pg' if $self->driver eq "PostgreSQL";
		return 'dbi:'.$driver.':dbname='.$self->database.( $self->has_host ? ';host='.$self->host : '' )
	},
);

sub host_list {
	my ( $self ) = @_;	
	my @hosts = $self->rs->search({},{
		columns => [ qw/host/ ],
		distinct => 1,
    });
	my @hostlist;
	for (@hosts) { push @hostlist, $_->host }
	return @hostlist;
}

sub user_list {
	my ( $self, $host ) = @_;
	my %query;
	$query{host} = $host if $host;
	my @users = $self->rs->search(\%query,{
		columns => [ qw/user/ ],
		distinct => 1,
    });
	my @userlist;
	for (@users) { push @userlist, $_->user }
	return @userlist;
}

sub all_user {
	my ( $self, $host ) = @_;
	my %query;
	$query{host} = $host if $host;
	my @keys = $self->rs->search(\%query);
	my %v;
	for (@keys) {
		$v{$_->user.'@'.$_->host}->{$_->store}->{$_->key} = $self->get_value($_);
	}
	return \%v;
}

sub user {
	my ( $self, $jid ) = @_;
	my @jidparts = split(/@/,$jid);
	die __PACKAGE__.': user parameter needs to be user@host' unless (@jidparts == 2);
	my @keys = $self->rs->search({
		host => $jidparts[1],
		user => $jidparts[0],
	});
	my %v;
	for (@keys) {
		$v{$_->store}->{$_->key} = $self->get_value($_);
	}
	return \%v;
}

sub get_value {
	my ( $self, $row ) = @_;
	if ($row->type eq 'string') {
		return $row->value;
	} elsif ($row->type eq 'json') {
		return decode_json(encode('utf8', $row->value));
	}
}

1;
__END__
=pod

=head1 NAME

Prosody::Storage::SQL - access a database of mod_storage_sql

=head1 VERSION

version 0.007

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Raudssus Social Software & Prosody Distribution Authors.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

