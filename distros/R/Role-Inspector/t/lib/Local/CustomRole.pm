package Local::CustomRole;

our %INFO = (
	name  => __PACKAGE__,
	type  => 'Local::Implementation',
	api   => [qw/ meth req /],
);

sub meth { 42 }

package Local::Implementation;

push @Role::Inspector::SCANNERS, sub {
	my $role = shift;
	my $info = \%{"$role\::INFO"};
	return $info if $info->{type} eq __PACKAGE__;
	return;
};

1;
