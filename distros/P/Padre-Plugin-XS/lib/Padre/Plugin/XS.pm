package Padre::Plugin::XS;

use 5.010001;
use warnings;
use strict;

use Padre::Unload;
use Try::Tiny;

our $VERSION = '0.12';
use parent qw(Padre::Plugin);

# Child modules we need to unload when disabled
use constant CHILDREN => qw{
	Padre::Plugin::XS
	Padre::Plugin::XS::PerlXS
	Padre::Plugin::XS::Document
	Perl::APIReference
};

#######
# Called by padre to know the plugin name
#######
sub plugin_name {
	return Wx::gettext('XS Support');
}

#######
# Called by padre to check the required interface
#######
sub padre_interfaces {
	return (
		'Padre::Plugin'   => '0.98',
		'Padre::Document' => '0.98',
		'Padre::Wx'       => '0.98',
		'Padre::Logger'   => '0.98',
	);
}


#########
# We need plugin_enable
# as we have an external dependency
#########
sub plugin_enable {
	my $self         = shift;
	my $perl_api_ref = 0;

	# Tests for externals used
	try {
		if ( require Perl::APIReference ) {
			$perl_api_ref = 1;
		}
	};

	return $perl_api_ref;
}

#######
# Add Plugin to Padre Menu
#######
sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		Wx::gettext('About...') => sub { $self->plugin_about },
	];
}

#######
# Called by padre to know which document to register for this plugin
#######
sub registered_documents {
	return (
		'text/x-perlxs' => 'Padre::Plugin::XS::Document',
	);
}


#######
# Add icon to Plugin
#######
# Core plugins may reuse the page icon
sub plugin_icon {
	require Padre::Wx::Icon;
	Padre::Wx::Icon::find('logo');
	return;
}



#######
# plugin_about
#######
sub plugin_about {
	my $self = shift;

	# my $share = $self->plugin_directory_share or return;
	# my $file = File::Spec->catfile( $share, 'icons', '48x48', 'git.png' );
	# return unless -f $file;
	# return unless -r $file;

	my $info = Wx::AboutDialogInfo->new;

	# $info->SetIcon( Wx::Icon->new( $file, Wx::wxBITMAP_TYPE_PNG ) );
	$info->SetName('Padre::Plugin::XS');
	$info->SetVersion($VERSION);
	$info->SetDescription( Wx::gettext('Padre XS and perlapi support') );
	$info->SetCopyright('(c) 2008-2013 The Padre development team');
	$info->SetWebSite('http://padre.perlide.org/trac/wiki/PadrePluginXS');
	$info->AddDeveloper('Steffen Mueller <smueller@cpan.org>');
	$info->AddDeveloper('Ahmad M. Zawawi <ahmad.zawawi@gmail.com>');
	$info->AddDeveloper('Kevin Dawson <bowtie@cpan.org>');

	# $info->SetArtists(
	# [   'Scott Chacon <https://github.com/github/gitscm-next>',
	# 'Licence <http://creativecommons.org/licenses/by/3.0/>'
	# ]
	# );
	Wx::AboutBox($info);
	return;
}

########
# plugin_disable
########
sub plugin_disable {
	my $self = shift;

	# Close the dialog if it is hanging around
	$self->clean_dialog;

	# Unload all our child classes
	for my $package (CHILDREN) {
		require Padre::Unload;
		Padre::Unload->unload($package);
	}

	$self->SUPER::plugin_disable(@_);

	return 1;
}

########
# Composed Method clean_dialog
########
sub clean_dialog {
	my $self = shift;

	# Close the main dialog if it is hanging around
	if ( $self->{dialog} ) {
		$self->{dialog}->Hide;
		$self->{dialog}->Destroy;
		delete $self->{dialog};
	}

	return 1;
}

1;

__END__


=pod

=encoding UTF-8

=head1 NAME

Padre::Plugin::XS - Padre support for perl XS (and perlapi)

=head1 VERSION

version: 0.12

=head1 DESCRIPTION

This plugin is intended to extend Padre's support for editing XS
and C-using-perlapi.

=head1 SYNOPSIS

Currently the plugin implements limited syntax highlighting and
calltips using a configurable version of the perlapi. After installing
this plugin, you can enable XS calltips in the C<View> menu of Padre
and enjoy the full perlapi of various releases of perl while writing
XS code. You can configure the version of perlapi you write against in
the padre.yml of your project (key C<xs_calltips_perlapi_version>).
By default, the newest available perlapi will be used.

Once this plug-in is installed the user can switch the highlighting of
XS files to use the highlighter via the Preferences menu of L<Padre>.
The default XS syntax highlighting of Padre is abysmal. You're very
encouraged to enable the C<XS highlighter> feature.

To use this Plugin you need to make sure B<editor_calltips> is enabled in
Tools-Preferences-Advance

Also see the L<wiki|http://padre.perlide.org/trac/wiki/PadrePluginXS> page.

=head1 METHODS

=over 4

=item * clean_dialog

=item * menu_plugins_simple

=item * padre_interfaces

=item * plugin_about

=item * plugin_disable

=item * plugin_enable

=item * plugin_icon

=item * plugin_name

=item * registered_documents

=back


=head1 AUTHORS

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

=head1 CONTRIBUTORS

Ahmad M. Zawawi E<lt>ahmad.zawawi@gmail.comE<gt>
Kevin Dawson E<lt>bowtie@cpan.orgE<gt>

=head1 ACKNOWLEDGMENTS

Many thanks to Gabor Szabo, who wrote the Kate plugin upon this is based.
I'm grateful to Herbert Breunung for writing Kephra and getting STC syntax highlighting more
right that us. Looking at his code has helped me write this.

=head1 COPYRIGHT

Copyright E<copy> 2010-2013 the Padre::Plugin::XS
L</AUTHOR> and L</CONTRIBUTORS> as listed above.


=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
