package SM::Client;

use strict;
use warnings;

use SM::Simulator;
use overload '""' => sub { $_[0]->id };

my $Counter;

sub new {
    my $class = ref $_[0] ? ref shift : shift;
    my $self = bless {
        id => $Counter++,
    }, $class;
}

sub id {
    $_[0]->{id};
}

1;
__END__

=head1 NAME

SM::Client - Client entity in the supermarket

=head1 SYNOPSIS

    use SM::Client;
    my $client = SM::Client->new;

=head1 DESCRIPTION

This class implements the client entity in the supermarket problem space.
Every client has an ID which is guaranteed to be unique in the whole application.

=head1 METHODS

=over

=item C<< $obj->new() >>

Client instance constructor.

=item C<< $id = $obj->id() >>

Read the client's ID.

=back

=head1 AUTHOR

Agent Zhang E<lt>agentzh@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2006 by Agent Zhang. All rights reserved.

This library is free software; you can modify and/or modify it under the same terms as
Perl itself.

=head1 SEE ALSO

L<SM>, L<SM::Server>, L<SM::Simulator>.
