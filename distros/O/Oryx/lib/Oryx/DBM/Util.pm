package Oryx::DBM::Util;

use File::Spec;
use DBM::Deep;

sub new {
    my $class = shift;
    return bless { }, $class;
}

sub table_exists {
    my ($self, $dbm, $table) = @_;
    return -e File::Spec->catfile($dbm->datapath, $table);
}

sub table_create {
    my ($self, $dbm, $table) = @_;
    my $filename = File::Spec->catfile($dbm->datapath, $table);
    $dbm->catalog->put( $table, {
	file      => $filename,
	type      => DBM::Deep::TYPE_ARRAY,
        autoflush => 1,
	locking => 1,
    });
}

sub table_drop {
    my ($self, $dbm, $table) = @_;
    my $meta = $dbm->catalog->get( $table );
    return unless $meta; # not defined for link tables
    unlink $meta->{file};
    $dbm->catalog->delete( $table );
}

1;
__END__

=head1 NAME

Oryx::DBM::Util - Oryx DBM utilities

=head1 DESCRIPTION

The following methods are defined to manipulate a L<DBM::Deep> database schema.

=head1 METHODS

=over

=item B<table_exists( $dbm, $table )>

Returns a true value if the table named C<$table> exists within C<$dbm>.

=item B<table_create( $dbm, $table )>

Creates a table named C<$table> in C<$dbm>.

=item B<table_drop( $dbm, $table )>

Drops the table named C<$table> in C<$dbm>.

=back

=head1 AUTHORS

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 Richard Hundt.

This library is free software and may be used under the same terms as Perl
itself.

=cut
