package SVN::TXN::Props;

use strict;
use warnings;
use Tie::Hash;
use SVN::Core;
use SVN::Fs;
use SVN::Repos;
use Carp;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter Tie::ExtraHash);

our @EXPORT_OK = qw( get_txn_props );
our @EXPORT = qw();
our $VERSION = '1.01';

sub get_txn_props ($;$) {
	my $txn = open_transaction(@_);
	my %hash;
	tie %hash, 'SVN::TXN::Props', $txn;
	return \%hash;
}

sub TIEHASH ($$;$) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $txn = open_transaction(@_);
	my $self = bless [ $txn->proplist(), $txn ];
	return $self;
}

sub STORE ($$$) {
	my $self = shift;
	my ($key, $value) = @_;
	$self->txn->change_prop($key, $value);
	$self->SUPER::STORE(@_);
}

sub DELETE ($$) {
	my $self = shift;
	my ($key) = @_;
	$self->txn->change_prop($key, undef);
	$self->SUPER::DELETE(@_);
}

sub CLEAR ($) {
	my $self = shift;
	foreach my $key (keys %{$self->[0]}) {
		$self->txn->change_prop($key, undef);
	}
	$self->SUPER::CLEAR(@_);
}

sub open_transaction ($;$) {
	my $first_arg = shift
		or croak "invalid arguments";
	if (ref($first_arg) and $first_arg->isa('_p_svn_fs_txn_t')) {
		# already have a transaction
		return $first_arg;
	}
	my $repos;
	if (ref($first_arg) and $first_arg->isa('_p_svn_repos_t')) {
		# already have an open repository
		$repos = $first_arg;
	} else {
		# probably a repository path
		$repos = SVN::Repos::open($first_arg);
	}
	my $txn_name = shift
		or croak "invalid arguments: transaction name not specified";
	return $repos->fs->open_txn($txn_name);
}

sub txn() {
	my $self = shift;
	return $self->[1];
}


1;
__END__
=head1 NAME

SVN::TXN::Props - Provides a hash interface to Subversion transaction properties

=head1 SYNOPSIS

  use SVN::TXN::Props qw(get_txn_props);

  my $repository_path = '/svnrepo';
  my $txn_name = '1-0';

  my $props = get_txn_props($repository_path, $txn_name);
  $props->{'svn:author'} = 'nobody';

  my %props;
  tie %props, 'SVN::TXN::Props', $repository_path, $txn_name;
  $props{'svn:author'} = 'nobody';

  my $txn = SVN::Repos::open($repository_path)->fs->open_txn($txn_name);
  $props = get_txn_props($txn);
  tie %props, 'SVN::TXN::Props', $txn;

  my @paths = keys %{tied(%props)->txn->root->paths_changed()};

=head1 DESCRIPTION

Maps properties from a subversion transaction to a hash.  This allows for
reading and manipulating properties of active subversion transactions before
the transaction is commited, for example during a pre-commit hook script.

This module provides a tied hash interface, allowing it to be used with the
perl tie function, eg:

  use SVN::TXN::Props;
  tie %props, 'SVN::TXN::Props', $repository_path, $txn_name;
  $props{'svn:author'} = 'nobody';

The arguments to the tie function can either be the path to a repository
and the name of a transaction, or an already open transaction object:

  my $txn = SVN::Repos::open($repository_path)->fs->open_txn($txn_name);
  tie %props, 'SVN::TXN::Props', $txn;

Alternatively, the function get_txn_props can be imported, which will
returned an already tied hash reference, eg:

  use SVN::TXN::Props qw(get_txn_props);
  my $props = get_txn_props($repository_path, $txn_name);
  $props->{'svn:author'} = 'nobody';

As with the tie call, a single open transaction object can be passed 
to get_txn_props instead of the repository_path and txn_name.

The underlying SVN::TXN::Props object is returned by the tie call, or
can be obtained from the tied hash using the perl tied() function.  This
provides a single method txn() that will return the underlying subversion
transaction object, eg:

  my $txn_props = tie %props, 'SVN::TXN::Props', $repository_path, $txn_name;
  my @paths = keys %{$txn_props->txn->root->paths_changed()};

=head1 SEE ALSO

SVN::Repo, SVN::Fs

=head1 AUTHOR

Chris Leishman, E<lt>chris@leishman.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Chris Leishman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
