#
#   Sub::Contract::Pool - The pool of contracts
#
#   $Id: Pool.pm,v 1.15 2009/06/16 12:23:58 erwan_lemonnier Exp $
#

package Sub::Contract::Pool;

use strict;
use warnings;

use Carp qw(croak);

use vars qw($AUTOLOAD);
use accessors qw( _contract_index
		);

use base qw(Exporter);

our $VERSION = '0.12';

our @EXPORT = ();
our @EXPORT_OK = ('get_contract_pool');

#---------------------------------------------------------------
#
#   A singleton pattern with lazy initialization and embedded constructor
#

my $pool;

sub get_contract_pool {
    if (!defined $pool) {
	$pool = bless({},__PACKAGE__);
	$pool->_contract_index({});
    }
    return $pool;
}

#---------------------------------------------------------------
#
#   list_all_contracts - return all contracts registered in the pool
#

sub list_all_contracts {
    my $self = shift;
    return values %{$self->_contract_index};
}

#---------------------------------------------------------------
#
#   has_contract -
#

# TODO: should it be removed? to use find_contract instead? would it be too slow?

sub has_contract {
    my ($self, $contractor) = @_;

    croak "method has_contract() expects a fully qualified function name as argument"
	if ( scalar @_ != 2 ||
	     !defined $contractor ||
	     ref $contractor ne '' ||
	     $contractor !~ /::/
	);

    my $index = $self->_contract_index;
    return exists $index->{$contractor};
}

#---------------------------------------------------------------
#
#   _add_contract
#

sub _add_contract {
    my ($self, $contract) = @_;

    croak "method add_contract() expects only 1 argument"
	if (scalar @_ != 2);
    croak "method add_contract() expects an instance of Sub::contract as argument"
	if (!defined $contract || ref $contract ne 'Sub::Contract');

    my $index = $self->_contract_index;
    my $contractor = $contract->contractor;

    croak "trying to contract function [$contractor] twice"
	if ($self->has_contract($contractor));

    $index->{$contractor} = $contract;

    return $self;
}

################################################################
#
#
#   Operations on contracts during runtime
#
#
################################################################

sub enable_all_contracts {
    my $self = shift;
    map { $_->enable } $self->list_all_contracts;
}

sub disable_all_contracts {
    my $self = shift;
    map { $_->disable } $self->list_all_contracts;
}

sub enable_contracts_matching {
    my $self = shift;
    map { $_->enable } $self->find_contracts_matching(@_);
}

sub disable_contracts_matching {
    my $self = shift;
    map { $_->disable } $self->find_contracts_matching(@_);
}

sub find_contract {
    my ($self, $contractor) = @_;

    croak "method find_contract() expects a fully qualified function name as argument"
	if ( scalar @_ != 2 ||
	     !defined $contractor ||
	     ref $contractor ne '' ||
	     $contractor !~ /::/
	);

    my $index = $self->_contract_index;
    return $index->{$contractor};
}

sub find_contracts_matching {
    my $self = shift;
    my $match = shift;
    my @contracts;

# TODO: fix croak level when called from enable/disable_matching
#    local $Carp::CarpLevel = 2 if ((caller(1))[3] =~ /^Sub::Contract::Pool::(enable|disable)_contracts_matching$/);

    croak "method find_contracts_matching() expects a regular expression"
	if (scalar @_ != 0 || !defined $match || ref $match ne '');

    while ( my ($name,$contract) = each %{$self->_contract_index} ) {
	push @contracts, $contract if ($name =~ /^$match$/);
    }

    return @contracts;
}

1;

__END__

=head1 NAME

Sub::Contract::Pool - A pool of all subroutine contracts

=head1 SYNOPSIS

    use Sub::Contract::Pool qw(get_contract_pool);

    my $pool = get_contract_pool();

    # disable all contracts in package My::Test
    foreach my $contract ($pool->find_contracts_matching("My::Test::.*")) {
        $contract->disable;
    }

    # or simply
    $pool->disable_contracts_matching("My::Test::.*");

=head1 DESCRIPTION

Every subroutine contract created with Sub::Contract is
automatically added to a common pool of contracts.

Contracts are instances of Sub::Contract.

You can query this pool to retrieve contracts based on the
qualified name of the contractors (ie package name + subroutine name).
You can then modify, recompile, enable and disable contracts
that you fetch from the pool, at any time during runtime.

Sub::Contract::Pool uses a singleton pattern, giving you
access to the common contract pool.

=head1 API

=over 4

=item C<< my $pool = get_contract_pool() >>;

Return the contract pool.

=item C<< $pool->list_all_contracts >>

Return all contracts registered in the pool.

=item C<< $pool->has_contract($fully_qualified_name) >>

Return true if the subroutine identified by C<$fully_qualified_name>
has a contract.

=item C<< $pool->find_contract($fully_qualified_name) >>

Return the contract of the subroutine identified by C<$fully_qualified_name>
or C<undef> if this subroutine does not exist or has no contract. Example:

    my $c = get_contract_pool->find_contract("Foo::Bar::yaph") ||
        die "couldn't find contract";
    $c->clear_cache;    

=item C<< $pool->find_contracts_matching($regexp) >>

Find all the contracts registered in the pool and whose contractor's
fully qualified names matches the pattern C</^$regexp$/>. Example:

    foreach my $c (get_contract_pool->find_contract("Foo::Bar::*")) {
        $c->clear_cache;
    }

=item C<< $pool->enable_all_contracts >>

Enable all the contracts registered in the pool.

=item C<< $pool->disable_all_contracts >>

Disable all the contracts registered in the pool.

=item C<< $pool->enable_contracts_matching($regexp) >>

Enable all the contracts registered in the pool whose contractor's
fully qualified names matches the pattern C</^$regexp$/>.

=item C<< $pool->disable_contracts_matching($regexp) >>

Disable all the contracts registered in the pool whose contractor's
fully qualified names matches the pattern C</^$regexp$/>.

=back

=head1 SEE ALSO

See 'Sub::Contract'.

=head1 VERSION

$Id: Pool.pm,v 1.15 2009/06/16 12:23:58 erwan_lemonnier Exp $

=head1 AUTHOR

Erwan Lemonnier C<< <erwan@cpan.org> >>

=head1 LICENSE

See Sub::Contract.

=cut



