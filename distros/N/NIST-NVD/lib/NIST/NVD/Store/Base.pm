package NIST::NVD::Store::Base;

use warnings;
use strict;

use Carp(qw(croak));

our $VERSION = '1.00.00';

=head2 get_cve_for_cpe

=cut

sub get_cve_for_cpe {

}

=head2 get_cve


=cut

sub get_cve {

}

=head2 put_cpe


=cut

sub put_cpe {

}

sub _get_default_args {

}

=head2 new

  The constructor for classes which inherit from
  NIST::NVD::Store::Base, if they don't implement it themselves

=cut

sub new {
	(my( $class, %args )) = @_;
	$class //= ref $class;

	my $self = bless {store => $args{store}}, $class;

	my $store = $args{store};

	carp('database argument is required, but was not passed')
		unless exists $args{database};

	$self->{$store} = $self->_connect_db( database => $args{database} );

	return $self;
}

sub _important_fields {
	return
            qw(
            vuln:cve-id
            vuln:cvss
            vuln:cwe
            vuln:discovered-datetime
            vuln:published-datetime
            vuln:discovered-datetime
            vuln:last-modified-datetime
            vuln:security-protection
						vuln:vulnerable-software-list
            );

}

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self)
        or croak "$self is not an object";

    my $name = $AUTOLOAD;

		$name =~ s/^.*://;

		return if $name eq 'DESTROY';

		croak "$type does not yet implement $name.  Don't call it."
			unless $type->can($name);
}

sub DESTROY {}

1;
