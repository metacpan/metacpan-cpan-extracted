package Term::Caca::Event::Key::Release;
our $AUTHORITY = 'cpan:YANICK';
# abstract: event triggered by a key release
$Term::Caca::Event::Key::Release::VERSION = '3.1.0';

use strict;
use warnings;

use parent 'Term::Caca::Event::Key';

sub new { 
    my $class = shift;
    my $self = Term::Caca::Event::Key->new( @_ );
    return bless $self, $class;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::Caca::Event::Key::Release

=head1 VERSION

version 3.1.0

=head1 SYNOPSIS

    use Term::Caca qw/ :events /;

    my $t = Term::Caca->new;
    while ( 1 ) {
        my $event = $t->wait_for_event( 
            mask => $KEY_RELEASE,
        );  
        
        print "character typed: ", $event->char;
    }

=head1 DESCRIPTION

Generated when a key is released.

=head1 METHODS

=head2 char()

Returns the character released.

=head1 SEE ALSO

L<Term::Caca::Event::Key>, L<Term::Caca::Event::Key::Press>

=head1 AUTHORS

=over 4

=item *

John Beppu <beppu@cpan.org>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019, 2018, 2013, 2011 by John Beppu.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut
