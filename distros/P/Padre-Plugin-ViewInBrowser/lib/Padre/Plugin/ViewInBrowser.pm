package Padre::Plugin::ViewInBrowser;

use warnings;
use strict;

our $VERSION = '0.07';

use base 'Padre::Plugin';
use Padre::Wx ();

sub padre_interfaces {
	'Padre::Plugin' => '0.26',
}

sub menu_plugins_simple {
	my $self = shift;
	return ('ViewInBrowser' => [
		'View in Browser', sub { $self->view_in_browser },
	]);
}

sub view_in_browser {
	my ( $self ) = @_;
	my $main = $self->main;
	
	my $filename = $main->current->filename;
	unless ( $filename ) {
		Wx::MessageBox( 'What to open? God KNOWS!',
		'Error', Wx::wxOK | Wx::wxCENTRE, $main );
		return;
	}
	Wx::LaunchDefaultBrowser($filename);
}

1;
__END__

=head1 NAME

Padre::Plugin::ViewInBrowser - view selected doc in browser for L<Padre>

=head1 SYNOPSIS

    $>padre
    Plugins -> ViewInBrowser -> View in Browser

=head1 DESCRIPTION

basically it's a shortcut for Wx::LaunchDefaultBrowser( $main->current->filename );

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
