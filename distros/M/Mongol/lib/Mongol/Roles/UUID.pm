package Mongol::Roles::UUID;

use Moose::Role;

use Data::UUID;

requires '_build_id';

around '_build_id' => sub {
	return Data::UUID->new()
		->create_str();
};

no Moose::Role;

1;

__END__

=pod

=head1 NAME

Mongol::Roles::UUID - UUID as object identifier

=head1 SYNOPSIS

=head1 DESCRIPTION

Using UUID instead of Mongo OnjectID.

=head1 SEE ALSO

=over 4

=item *

L<Data::UUID>

=back

=cut
