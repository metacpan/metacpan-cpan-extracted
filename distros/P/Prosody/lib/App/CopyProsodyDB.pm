package App::CopyProsodyDB;
BEGIN {
  $App::CopyProsodyDB::AUTHORITY = 'cpan:GETTY';
}
{
  $App::CopyProsodyDB::VERSION = '0.007';
}
# ABSTRACT: Class of the copy_prosody_db script

use Moose;
use Moose::Util::TypeConstraints;
use Prosody::Storage::SQL;

with qw(
	MooseX::Getopt
);

has src_driver => (
	is => 'ro',
	isa => enum(["SQLite3","MySQL","PostgreSQL"]),
	required => 1,
);

has src_database => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

has src_username => (
	is => 'ro',
	isa => 'Str',
	predicate => 'has_src_username',
);

has src_password => (
	is => 'ro',
	isa => 'Str',
	predicate => 'has_src_password',
);

has trg_driver => (
	is => 'ro',
	isa => enum(["SQLite3","MySQL","PostgreSQL"]),
	required => 1,
);

has trg_database => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

has trg_username => (
	is => 'ro',
	isa => 'Str',
	predicate => 'has_trg_username',
);

has trg_password => (
	is => 'ro',
	isa => 'Str',
	predicate => 'has_trg_password',
);

has _src => (
	is => 'ro',
	isa => 'Prosody::Storage::SQL',
	lazy_build => 1,
);

sub _build__src {
	my ( $self ) = @_;
	my %vars = (
		driver => $self->src_driver,
		database => $self->src_database,
	);
	$vars{username} = $self->src_username if $self->has_src_username;
	$vars{password} = $self->src_password if $self->has_src_password;
	return Prosody::Storage::SQL->new(%vars);
}

has _trg => (
	is => 'ro',
	isa => 'Prosody::Storage::SQL',
	lazy_build => 1,
);

sub _build__trg {
	my ( $self ) = @_;
	my %vars = (
		driver => $self->trg_driver,
		database => $self->trg_database,
	);
	$vars{username} = $self->trg_username if $self->has_trg_username;
	$vars{password} = $self->trg_password if $self->has_trg_password;
	return Prosody::Storage::SQL->new(%vars);
}

sub BUILD {
	my ( $self ) = @_;
	for ($self->_src->rs->search({})->all) {
		$self->_trg->rs->create({
			host => $_->host,
			key => $_->key,
			store => $_->store,
			type => $_->type,
			user => $_->user,
			value => $_->value,
		});
	}
}

1;
__END__
=pod

=head1 NAME

App::CopyProsodyDB - Class of the copy_prosody_db script

=head1 VERSION

version 0.007

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Raudssus Social Software & Prosody Distribution Authors.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

