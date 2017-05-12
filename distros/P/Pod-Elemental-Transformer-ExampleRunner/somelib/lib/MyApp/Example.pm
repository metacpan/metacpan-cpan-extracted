package MyApp::Example;

=head1 MyApp::Example - a crappy example

=cut

use base qw[ SomeLib ];

sub AUTOLOAD {
    my $self = shift;
    print "Oh my! $AUTOLOAD is happening!\n" unless $AUTOLOAD =~ 'DESTROY';
}

"i love the smell of patches in the moring"
