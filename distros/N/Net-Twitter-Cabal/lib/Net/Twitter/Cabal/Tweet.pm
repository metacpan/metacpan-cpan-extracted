package Net::Twitter::Cabal::Tweet;
#use Moose;

#has 'id'       => ( is => 'ro', isa => 'Int' );
#has 'content'  => ( is => 'rw', isa => 'Str', required => 1 );
#has 'poster'   => ( is => 'ro', isa => 'Str', required => 1 );
#has 'datetime' => ( is => 'ro', isa => 'DateTime' );
#has 'length'   => ( is => 'rw', isa => 'Int' );

use strict;
use warnings;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors( qw/
	content
	poster
	/
);
# id and datetime left for a future release (w/ store and forward)
# length left for a future release (w/ tweet splitting)

use Carp;

#use DateTime;

=head1 NAME

Net::Twitter::Cabal::Tweet - A tweet used by Net::Twitter::Cabal

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Inside a cabal-controlling program:

	my $tweet = Net::Twitter::Cabal::Tweet->new( {
		poster  => $nick,
		content => "I'm inhaling",
	} );

This should only be used internally.

=head1 FUNCTIONS

=head2 new

	my $tweet = Net::Twitter::Cabal::Tweet->new( {
		poster  => $nick,
		content => $text,
	} );

=cut

sub new {
	my $proto = shift;
	my $class = ref $proto || $proto;
	
	my $self  = $class->SUPER::new( @_ );
	croak unless ( $self->poster && $self->content );
	
	return $self;
}

=head2 poster

=head2 content

Set/get the poster/content of a tweet:

	$tweet->poster( $nick ); $tweet->poster;
	$tweet->content( $content ); $tweet->content;
	
=head1 AUTHOR

Pedro Figueiredo, C<< <me at pedrofigueiredo.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-twitter-cabal at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Twitter-Cabal>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Twitter::Cabal::Tweet


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Twitter-Cabal>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Twitter-Cabal>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Twitter-Cabal>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Twitter-Cabal/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Pedro Figueiredo, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

45; # End of Net::Twitter::Cabal::Tweet
