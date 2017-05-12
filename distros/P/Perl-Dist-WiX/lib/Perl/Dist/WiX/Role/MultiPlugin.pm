package Perl::Dist::WiX::Role::MultiPlugin;

=pod

=head1 NAME

Perl::Dist::WiX::Role::MultiPlugin

=head1 VERSION

This document describes Perl::Dist::WiX::Role::MultiPlugin version 1.500.

=cut

use 5.010;
use Moose::Role;
use Perl::Dist::WiX::Exceptions;

our $VERSION = '1.500';
$VERSION =~ s/_//ms;

around '_role_from_plugin' => sub {
	my ( $orig, $self, $plugin ) = @_;

	if ( $plugin =~ /^[+](.*)/msx ) { return $1; }

	my $o = join q{::}, $self->_plugin_ns(), $plugin;

	# Father, please forgive me for I have sinned.
	my @roles = grep {/${o}$/ms} $self->_plugin_locator()->plugins();

	if ( not scalar @roles ) {
		PDWiX->throw("Unable to locate perl version '$plugin'");
	}
	return $roles[0] if @roles == 1;

	## no critic(ProhibitComplexMappings)
	my $i = 0;
	my %precedence_list =
	  map { $i++; ( "${_}::${o}", $i ) } $self->_plugin_app_ns;

	@roles =
	  reverse sort { $precedence_list{$a} <=> $precedence_list{$b} } @roles;

	return @roles;
};

around '_build_plugin_app_ns' => sub {
	my ( $orig, $self ) = @_;
	my @names = (
		grep   { $_ !~ /::Mixin::/msx }
		  grep { $_ !~ /^Moose::/msx }
		  $self->meta()->class_precedence_list() );
	return \@names;
};

around 'load_plugins' => sub {
	my ( $orig, $self, @plugins ) = @_;
	if ( not scalar @plugins ) {
		PDWiX->throw('You did not provide a perl version');
	}

	my $loaded = $self->_plugin_loaded();
	my @load   = grep { not exists $loaded->{$_} } @plugins;
	my @roles  = map { $self->_role_from_plugin($_) } @load;

	return if @roles == 0;

	if ( $self->_load_and_apply_role(@roles) ) {
		foreach my $plugin (@load) {
			@{$loaded}{$plugin} = [];
		}
		my $plugin_name;
		foreach my $role (@roles) {
			($plugin_name) = $role =~ m/::([[:alnum:]]*)\z/msx;
			push @{ @{$loaded}{$plugin_name} }, $role;
		}
		return 1;
	} else {
		return;
	}
};

no Moose::Role;

1;

__END__

=pod

=head1 DIAGNOSTICS

See L<Perl::Dist::WiX::Diagnostics|Perl::Dist::WiX::Diagnostics> for a list of
exceptions that this module can throw.

=head1 BUGS AND LIMITATIONS (SUPPORT)

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>
if you have an account there.

2) Email to E<lt>bug-Perl-Dist-WiX@rt.cpan.orgE<gt> if you do not.

For other issues, contact the topmost author.

=head1 AUTHORS

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<http://ali.as/>, L<http://csjewell.comyr.com/perl/>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this distribution.

=cut
