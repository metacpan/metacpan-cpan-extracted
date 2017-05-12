package Oryx::Value::Oid;

# This is here to eventually support multi-column primary keys, if,
# indeed they're needed... something I can't guess at this stage.

use base qw(Oryx::Value);

sub primitive { 'Oid' }

1;
__END__

=head1 NAME

Oryx::Value::Oid - Internal type for identifying rows

=head1 SYNOPSIS

Do not use this value type directly.

=head1 DESCRIPTION

This value type is used internally by the ID fields of each record. Do not use this type for anything else.

=head1 SEE ALSO

L<Oryx::Value>

=head1 AUTHOR

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software and may be used under the same terms as Perl itself.

=cut
