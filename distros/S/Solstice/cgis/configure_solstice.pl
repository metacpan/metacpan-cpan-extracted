#!/usr/bin/perl

# This wraps around the installer for Solstice, and runs it through all the lifecycle functions.
# This runs when the infrastructure to do a proper state based app isn't in place... 

use strict;
use warnings;

use Solstice::Controller::Installer;
use Solstice::CGI;
use Solstice::Server;

my $server = Solstice::Server->new();
$server->setContentType('text/html');

# Go through the lifecycle functions (the controller will decide what it needs to do in each step)

my $controller = Solstice::Controller::Installer->new();

$controller->update();
if ($controller->validate()) {
    $controller->commit();
}

my $url = Solstice::Server->new()->getURI();

my $view = $controller->getView();
$view->setError($controller->getError());

# Print the painted view...

my $screen = '';
$view->paint(\$screen);
$server->printHeaders();
print $screen; 

0;

=back

=head2 Modules Used

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

Version $Revision: $

=head1 COPYRIGHT

Copyright 1998-2006, Catalyst Group, University of Washington, Seattle

=cut

