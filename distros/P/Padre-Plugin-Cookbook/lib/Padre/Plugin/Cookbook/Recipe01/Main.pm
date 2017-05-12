package Padre::Plugin::Cookbook::Recipe01::Main;

use v5.10.1;
use strict;
use warnings;

# use diagnostics;
# use utf8;
# use autodie;

# Version required
our $VERSION = '0.24';
use parent qw( Padre::Plugin::Cookbook::Recipe01::FBP::MainFB );

#######
# Method new
#######
sub new {
	my $class = shift;

	# Padre main window integration
	my $main = shift;

	# Create the dialog
	my $self = $class->SUPER::new($main);

	# define where to display main dialog
	$self->CenterOnParent;
	return $self;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Padre::Plugin::Cookbook::Recipe01::Main

=head1 VERSION

version: 0.24

=head1 DESCRIPTION

Recipe01 - 'Hello World'

Main is the event handler for MainFB, it's parent class.
It displays a Main dialog with 'Hello World'.
It's a basic example of a Padre plug-in using a WxDialog.

=head1 SUBROUTINES/METHODS

=over 4

=item new ()

Constructor. Should be called with $main by CookBook->load_dialog_recipe01_main().

=back

=head1 DEPENDENCIES

Padre::Plugin::Cookbook, Padre::Plugin::Cookbook::Recipe01::FBP::MainFB

=head1 AUTHOR

BOWTIE E<lt>kevin.dawson@btclick.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008-2013 The Padre development team as listed in Padre.pm.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
