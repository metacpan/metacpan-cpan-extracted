package Padre::Plugin::XS::Document;

use v5.10.1;
use strict;
use warnings;

use Padre::Logger;
use YAML::Tiny;

our $VERSION = '0.12';
use parent qw(Padre::Document);

#######
# Task Integration
#######
sub task_functions {
	return '';
}

sub task_outline {
	return '';
}

sub task_syntax {
#	return 'Padre::Plugin::YAML::Syntax';
	return '';
}

# sub comment_lines_str {
	# return '#';
# }



#######
# Padre-Document Overloading
#######

# TODO better highlighting. Can vim do better? Can we steal? Add an STC highlighter? ...

sub get_calltip_keywords {
	my $self = shift;
	TRACE("get_calltip_keywords called") if DEBUG;

	if ( not defined $self->{_perlapi_keywords} ) {
		$self->_load_perlapi_keywords();
	}
	return $self->{_perlapi_keywords};
}


# This loads the perlapi keywords for calltips
# It first tries to use the Perl::APIReference module which has perlapi references
# for many, many releases of perl. It fetches the desired perlapi version from the
# project configuration and uses the newest if not configured. Then, it asks the
# Perl::APIReference for the index of keywords. Since this can fail at various levels,
# we fall back to reading the perlapi keywords from an included YAML file if necessary
# --Steffen
sub _load_perlapi_keywords {
	my $self = shift;

	if ( not eval {use Perl::APIReference 0.03; 1;} ) {
		TRACE('Perl::APIReference failed') if DEBUG;
		$self->{_perlapi_keywords} =
			YAML::Tiny::LoadFile( Padre::Util::sharefile( 'languages', 'perl5', 'perl5.yml', 'perlapi_current.yml' ) );
		return;
	}

	my $perl_version = $self->{_perlapi_version};
# p $perl_version;
	if ( not defined $perl_version ) {
		my $project = $self->project;
		if ( defined $project ) {
			$perl_version = 'newest';
			my $cfg = $project->config;
			$perl_version = $cfg->xs_calltips_perlapi_version(); # this is = 'newest'
		} else {
			$perl_version = Padre->ide->config->xs_calltips_perlapi_version();
		}
		$self->{_perlapi_version} = $perl_version;
	}
# p $perl_version;
	my $apiref = eval { Perl::APIReference->new( perl_version => $perl_version ) };
# p $apiref;
	if ( not $apiref ) {

		# fallback...
		$self->{_perlapi_keywords} =
			YAML::Tiny::LoadFile( Padre::Util::sharefile( 'languages', 'perl5', 'perl5.yml', 'perlapi_current.yml' ) );
		return;
	}

	# TODO: Perl::APIReference also provides an "index" method, but that doesn't return the structure
	#       in exactly the way we want it. Easy way out: Add an accessor to Perl::APIReference that
	#       returns an API structure akin to what would be returned by loading the YAML.
#	require YAML::Tiny;
	$self->{_perlapi_keywords} = YAML::Tiny::Load( $apiref->as_yaml_calltips );
# p $self->{_perlapi_keywords};
	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Padre::Plugin::XS::Document - A Padre Document that understands XS

=head1 VERSION

version: 0.12

=head1 METHODS

=over 4

=item * task_functions

=item * task_outline

=item * task_syntax

=item * get_calltip_keywords

=back

=head1 AUTHOR

See L<Padre::Plugin::XS>

=head2 CONTRIBUTORS

See L<Padre::Plugin::XS>

=head1 COPYRIGHT

See L<Padre::Plugin::XS>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
