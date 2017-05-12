package TL1ng;

use 5.008000;

use strict;
use warnings;

use Carp;


our $VERSION = '0.08';


sub new {
    my ($class, $params) = @_;
	
	croak "Parameter list must be an anonymous hash!\n" 
	   if $params && ref $params ne "HASH";
	$params = {} if ! $params;
	
	
	# Since this class is just an abstract factory (kinda), 
	# determine the conrete TL1ng class to instantiate... 
	# Use TL1ng::Base as a default if none is provided.
	my $inst_class = defined $params->{Type} 
		? "${class}::" . $params->{Type} : "${class}::Base";
	
	
	# Clean up parameters we've used here - anything left over will 
	# be passed to the class we're instantiating.
	$params->{Type} and delete $params->{Type};
	
	
	# Instantiate the apropriate TL1 object
	eval "require $inst_class" || croak "Couldn't load $inst_class!";
	
	my $tl1_obj = $inst_class->new($params)
		|| return; #croak "Couldn't instantiate $inst_class!\n";

    return $tl1_obj;
}


1;
__END__

=head1 NAME

TL1ng - A simple, flexible, OO way to work with TL1.

=head1 SYNOPSIS

To get started, if you want *basic* no-frills TL1 functionality over Telnet:

  use TL1ng;
  my $tl1_obj = TL1ng->new();

Which, currently, is the same as:

  use TL1ng;
  my $tl1_obj = TL1ng->new({
  	Source => 'Telnet'
  	Type => 'Base',
  });

And that produces an object of the type L<TL1ng::Base>, configured to communicate 
with the NE/GNE via Telnet by use of the L<TL1ng::Source::Telnet> module.

But that's just the default right now. This is even better, and may become
the default in later versions:

  use TL1ng;
  my $tl1_obj = TL1ng->new({
  	Type => 'Generic',
  }); 
 
That produces an object of the type L<TL1ng::Generic>, (which is a subclass of
L<TL1ng::Base>,) also configured to communicate with the NE/GNE via Telnet 
(again, by use of the L<TL1ng::Source::Telnet> module.)

L<TL1ng::Generic> has methods for login, logout, and managing multiple sessions
through a single 'source' conection, and once I've vetted it's functionality
against a wider variety of equipment it will probably be merged with TL1ng::Base.

Coming soon will also be sub-classes to provide device or vendor-specicic TL1
functionality.

B<< BTW, I see nothing wrong with simply C<use>-ing and instantiating your 
desired sub-class module directly... >>

 use TL1ng::Generic;
 my $tl1_obj = TL1ng::Generic->new({ Various => Params, Go => Here });

Perhaps the factory idea behind this module is bird-brained and the example 
above is better. I'm not sure, but welcome suggestions! As always, TMTOWTDI.

=head1 DESCRIPTION

The module TL1ng is just a factory for getting instances of L<TL1ng::Base> 
and it's sub-classes. The best way to learn about how this all works right now is
to read the perldoc for L<TL1ng::Base>, then read the perldoc for any specific
sub-class(es) you may be using.


=head1 METHODS

=head2 new

Returns an object of the type L<TL1ng::Base>, or some sub-class. The only 
parameter this method truly cares about is C<Type>, and it's value is used to
determine which class to instantiate.

B<< All additional parameters are passed through to the C<new> method of the 
instantiated class. >>

For example, C<< Type => Foo >> will cause the module to load and create an 
object from TL1ng::Foo. All additional parameters are passed to 
C<< TL1ng::Foo->new() >>. It's simplistic, and I already see the limitations, 
but it works for my needs and I simply don't have the time to do it a better 
way right now.

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<Net::TL1>
L<Net::Telnet>


=head1 AUTHOR

Steve Scaffidi, E<lt>L<mailto:sscaffidi@cpan.net|sscaffidi@cpan.net>E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Steve Scaffidi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
