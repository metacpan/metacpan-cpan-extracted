package MockDBIxClass::Schema;
push @DBIx::Class::Schema::ISA, (); # make the class exist
our @ISA= qw( DBIx::Class::Schema );
use strict;
use warnings;

sub new {
	my $class= shift;
	my $self= shift || {};
	$self->{sources} ||= {};
	for (keys %{$self->{sources}}) {
		$self->{sources}{$_}= MockDBIxClass::ResultSource->new({
			schmea => $self,
			name => $_,
			%{$self->{sources}{$_}}
		})
	}
	bless $self, $class;
}

sub sources {
	my $self= shift;
	return keys @{ $self->{sources} };
}

sub source {
	my ($self, $name)= @_;
	return $self->{sources}{$name} || die "No such source $name";
}

package MockDBIxClass::ResultSource;
push @DBIx::Class::ResultSource::ISA, (); # make the class exist
our @ISA= qw( DBIx::Class::ResultSource );
use strict;
use warnings;
use Scalar::Util;

sub new {
	my ($class, $self)= @_;
	ref $self->{columns} eq 'ARRAY' or die 'columns should be an array of [name => $info, ...]';
	$self->{columns_info}= { @{ $self->{columns} } };
	$self->{columns}= [ grep !ref, @{$self->{columns}} ];
	$self->{keys} ||= {};
	$self->{relationships} ||= {};
	Scalar::Util::weaken($self->{schema}) if $self->{schema};
	bless $self, $class;
	$self;
}

sub name { $_[0]{name} }

sub has_column { defined $_[0]{columns_info}{$_[1]} }

sub column_info { $_[0]{columns_info}{$_[1]} }

sub columns_info {
	my ($self, $names)= @_;
	my %r;
	@r{@$names}= @{$self->{columns_info}}{@$names};
	\%r;
}

sub columns { @{$_[0]{columns}} }

sub primary_columns { @{$_[0]{keys}{primary}{cols}} }

sub unique_constraints {
	my $keys= $_[0]{keys};
	my %r;
	for (keys %$keys) {
		$r{$_}= $keys->{$_}{cols} if $keys->{unique};
	}
	\%r;
}

sub unique_constraint_names {
	my $keys= $_[0]{keys};
	grep $keys->{$_}{unique}, keys %$keys
}

sub relationships {
	return keys %{ $_[0]{relationships} };
}

sub relationship_info {
	my ($self, $name)= @_;
	$self->{relationships}{$name};
}

sub has_relationship {
	my ($self, $name)= @_;
	defined $self->{relationships}{$name};
}

1;
