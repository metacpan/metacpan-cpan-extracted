package Padre::Plugin::YAML;

use v5.10.1;
use strict;
use warnings;

use English qw( -no_match_vars ); # Avoids reg-ex performance penalty
use Padre::Plugin ();
use Padre::Wx     ();
use Try::Tiny;

our $VERSION = '0.10';
use parent qw(Padre::Plugin);

# Child modules we need to unload when disabled
use constant CHILDREN => qw{
	Padre::Plugin::YAML
	Padre::Plugin::YAML::Document
	Padre::Plugin::YAML::Syntax
};

#######
# Called by padre to know the plugin name
#######
sub plugin_name {
	return Wx::gettext('YAML');
}

#######
# Called by padre to check the required interface
#######
sub padre_interfaces {
	return (
		'Padre::Plugin'       => '0.94',
		'Padre::Document'     => '0.94',
		'Padre::Wx'           => '0.94',
		'Padre::Task::Syntax' => '0.94',
		'Padre::Logger'       => '0.94',
	);
}

#########
# We need plugin_enable
# as we have an external dependency
#########
sub plugin_enable {
	my $self                 = shift;
	my $correct_yaml_install = 0;

	# Tests for externals used by Preference's

	if ( $OSNAME =~ /Win32/i ) {
		try {
			if ( require YAML ) {
				$correct_yaml_install = 1;
			}
		};
	} else {
		try {
			if ( require YAML::XS ) {
				$correct_yaml_install = 1;
			}
		};
	}

	return $correct_yaml_install;
}


#######
# Called by padre to know which document to register for this plugin
#######
sub registered_documents {
	return (
		'text/x-yaml' => 'Padre::Plugin::YAML::Document',
	);
}

#######
# Called by padre to build the menu in a simple way
#######
sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		Wx::gettext('About...') => sub {
			$self->plugin_about;
		},
	];
}

#######
# plugin_about
#######
sub plugin_about {
	my $self = shift;

	#	my $share = $self->plugin_directory_share or return;
	#	my $file = File::Spec->catfile( $share, 'icons', '48x48', 'git.png' );
	#	return unless -f $file;
	#	return unless -r $file;

	my $info = Wx::AboutDialogInfo->new;

	#	$info->SetIcon( Wx::Icon->new( $file, Wx::wxBITMAP_TYPE_PNG ) );
	$info->SetName('Padre::Plugin::YAML');
	$info->SetVersion($VERSION);
	$info->SetDescription( Wx::gettext('A Simple YAML syntax checker for Padre') );
	$info->SetCopyright('(c) 2008-2013 The Padre development team');
	$info->SetWebSite('http://padre.perlide.org/trac/wiki/PadrePluginYAML');
	$info->AddDeveloper('Zeno Gantner <zenog@cpan.org>');
	$info->AddDeveloper('Kevin Dawson <bowtie@cpan.org>');
	$info->AddDeveloper('Ahmad M. Zawawi <ahmad.zawawi@gmail.com>');

	#	$info->SetArtists(
	#		[   'Scott Chacon <https://github.com/github/gitscm-next>',
	#			'Licence <http://creativecommons.org/licenses/by/3.0/>'
	#		]
	#	);
	Wx::AboutBox($info);
	return;
}


#######
# Called by Padre when this plugin is disabled
#######
sub plugin_disable {
	my $self = shift;

	# Unload all our child classes
	# TODO: Switch to Padre::Unload once Padre 0.96 is released
	for my $package (CHILDREN) {
		require Padre::Unload;
		Padre::Unload->unload($package);
	}

	$self->SUPER::plugin_disable(@_);

	return 1;
}

1;

__END__

=pod

=head1 NAME

Padre::Plugin::YAML - YAML support for Padre, The Perl IDE.


=head1 VERSION

version: 0.10


=head1 DESCRIPTION

YAML support for Padre, the Perl Application Development and Re-factoring
Environment.

Syntax highlighting for YAML is supported by Padre out of the box.
This plug-in adds some more features to deal with YAML files.

=head2 Example

Example is not relevant as this is a Padre::Plugin

=head1 BUGS AND LIMITATIONS

No bugs have been reported.


=head1 METHODS

=over 4

=item * menu_plugins_simple

=item * padre_interfaces

=item * plugin_enable

=item * plugin_disable

=item * plugin_name

=item * registered_documents

=item * plugin_about

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Padre::Plugin::YAML

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Padre-Plugin-YAML>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Padre-Plugin-YAML>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Padre-Plugin-YAML>

=item * Search CPAN

L<http://search.cpan.org/dist/Padre-Plugin-YAML/>

=back


=head1 AUTHOR

Zeno Gantner E<lt>zenog@cpan.orgE<gt>

=head2 CONTRIBUTORS

Kevin Dawson  E<lt>bowtie@cpan.orgE<gt>

Ahmad M. Zawawi E<lt>ahmad.zawawi@gmail.comE<gt>

=head1 COPYRIGHT

Copyright E<copy> 2009-2013 the Padre::Plugin::YAML  L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

=cut
