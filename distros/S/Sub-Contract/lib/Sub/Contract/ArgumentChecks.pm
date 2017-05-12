#
#   Sub::Contract::ArgumentChecks - Conditions on input/return arguments
#
#   $Id: ArgumentChecks.pm,v 1.8 2009/06/16 12:23:58 erwan_lemonnier Exp $
#

package Sub::Contract::ArgumentChecks;

use strict;
use warnings;
use Carp qw(croak);
use Data::Dumper;

use accessors ('type',         # 'in' or 'out'
	       'list_checks',  # an anonymous array of checks on list-style passed arguments
	       'hash_checks',  # an anonymous hash of checks on hash-style passed arguments
	       );

our $VERSION = '0.12';

#---------------------------------------------------------------
#
#   new - constructor
#

sub new {
    my($class,$type) = @_;
    $class = ref $class || $class;

    croak "BUG: type must be in or out" if ($type !~ /^(in|out)$/);

    my $self = bless({},$class);
    $self->type($type);
    $self->list_checks([]);
    $self->hash_checks({});
}

sub add_list_check {
    my ($self,$check) = @_;
    push @{$self->list_checks}, $check;
}

sub add_hash_check {
    my ($self,$key,$check) = @_;
    $self->hash_checks->{$key} = $check;
}

sub has_list_args {
    return scalar @{$_[0]->list_checks};
}

sub has_hash_args {
    return scalar keys %{$_[0]->hash_checks};
}


1;

__END__

=head1 NAME

Sub::Contract::ArgumentChecks - Hold the constraints on input/return arguments

=head1 SYNOPSIS

See 'Sub::Contract'.

=head1 DESCRIPTION

An instance of Sub::Contract::ArgumentChecks holds the constraints for
either the input arguments or the return results of a given subroutine.

Subroutine arguments in perl can be passed as a list of values, or as a hash,
or as a list mixing both values and hash. In fact arguments are always passed
as a list but the elements of this list might have to be considered as members
of a hash after a given position in the list.

An instance of Sub::Contract::ArgumentChecks describe the contract conditions
on any optional heading list arguments and any optional trailing hash arguments
in a list of input or return values.

=head1 API

See 'Sub::Contract'.

=over 4

=item new()

=item add_list_check()

Add a check for an argument passed in list-style. The order of calling
C<add_list_check> defines the position of that argument in the list.

=item add_hash_check()

Add a check for an argument passed in hash-style. The number of calls
made to C<add_list_check> defines where the hash starts in the list
of arguments.

=item has_list_args()

Return true if there are conditions on arguments passed in list-style.

=item has_hash_args()

Return true if there are conditions on arguments passed in hash-style.

=back

=head1 SEE ALSO

See 'Sub::Contract'.

=head1 VERSION

$Id: ArgumentChecks.pm,v 1.8 2009/06/16 12:23:58 erwan_lemonnier Exp $

=head1 AUTHOR

Erwan Lemonnier C<< <erwan@cpan.org> >>

=head1 LICENSE

See Sub::Contract.

=cut

