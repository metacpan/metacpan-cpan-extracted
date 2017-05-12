package Net::MythWeb::Channel;
use Moose;
use MooseX::StrictConstructor;

has 'id' => ( is => 'ro', isa => 'Int' );

has 'number' => ( is => 'ro', isa => 'Int' );

has 'name' => ( is => 'ro', isa => 'Str' );

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::MythWeb::Channel - A MythWeb channel

=head1 SEE ALSO

L<Net::MythWeb>, L<Net::MythWeb::Programme>.

=head1 AUTHOR

Leon Brocard <acme@astray.com>.

=head1 COPYRIGHT

Copyright (C) 2009, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
