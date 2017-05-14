
#
# vim:ts=2:sw=2
# Package: Orac::Shell::Do
# contains the database interaction commands.
#

package Shell::Do;

sub do_prepare {
	my $self = shift;
	my $statement = shift;
$self->{dbh}->prepare( $statement );
}
sub do_execute {
	my $self = shift;
	my $sth  = shift;
$sth->execute(@_);
}
sub do_finish {
	my $self = shift;
}
sub do_fetch {
	my $self = shift;
}
sub do_commit {
	my $self = shift;
}
sub do_rollback {
	my $self = shift;
}
sub do_do {
	my $self = shift;
$self->{dbh}->do( @_ );
}

1;
__END__
