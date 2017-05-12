package Oryx::DBI::Association;
use base qw(Oryx::Association);
1;

__END__

=head1 NAME

Oryx::DBI::Association - Abstract base class for DBI association implementations

=head1 SYNOPSIS

See L<Oryx::Association>.

=head1 DESCRIPTION

This is an abstract base class inheriting from L<Oryx::Association> and is implemented by the Oryx DBI association implementations.

=head1 SEE ALSO

L<Oryx>, L<Oryx::DBI>, L<Oryx::DBI::Association::Array>, L<Oryx::DBI::Association::Hash>, L<Oryx::DBI::Association::Reference>

=head1 AUTHOR

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 Richard Hundt.

This library is free software and may be used under the same terms as Perl itself.

=cut
