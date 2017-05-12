package SFML;

use 5.008009;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use SFML ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
	'all' => [ qw(

		  ) ]);

our @EXPORT_OK = (@{ $EXPORT_TAGS{'all'} });

our @EXPORT = qw(

);

our $VERSION = '0.0102';    # Alpha!

require XSLoader;
XSLoader::load('SFML', $VERSION);

# Preloaded methods go here.

1;
#__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

SFML - Perl extension that enables the use of the SFML multimedia library.

=head1 SYNOPSIS

  use SFML::Window;
  
  my $window = new SFML::Window::Window(new SFML::Window::VideoMode(800, 600), "perl-sfml");
  
  my $event = new SFML::Window::Event;
  
  while ($window->isOpen) {
  
  	while ($window->pollEvent($event)) {
  
  		if ($event->type == SFML::Window::Event::Closed) {
  
  			$window->close;
  
  		}
  
  	}
  
  	$window->display;
  
  }

=head1 DESCRIPTION

SFML is a free multimedia C++ API that provides you low and high level access to graphics, input, audio, etc.
The SFML is that, but with Perl!

=head2 EXPORT

None by default.

=head1 SEE ALSO

www.sfml-dev.org

github.com/jakeanq/perl-sfml/

=head1 AUTHOR

Jake Bott, E<lt>jakeanq@gmail.comE<gt>
Georgiy Tugai E<lt>georgiy.tugai@gmail.comE<gt>

=head1 BUGS

Please report bugs related to the SFML bindings here:

https://github.com/jakeanq/perl-sfml/issues

Note that this is not for bugs in the Alien::SFML module or the SFML library.  For those,
see the module and library homepages:

https://github.com/jakeanq/perl-alien-sfml/

http://www.sfml-dev.org/

Note that I do not maintain SFML itself, only the SFML module and Alien::SFML.
For that, see the above website (the sfml-dev one, not the github one)

=head1 LICENSE

See the LICENCE file that should have been included with this 

=head1 COPYRIGHT

 ############################################
 # Copyright 2013 Jake Bott, Georgiy Tugai. #
 #=>--------------------------------------<=#
 #  All Rights Reserved. Part of perl-sfml  #
 ############################################

=cut
