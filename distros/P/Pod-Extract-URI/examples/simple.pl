use strict;
use warnings;
use Pod::Extract::URI;

# This script demonstrates the behaviour of Pod::Extract::URI
# under a few different configurations. We'll extract the URIs
# from the POD at the bottom of this script

my @configs = (
    {},
    { strip_brackets => 0 },
    { want_verbatim => 0 },
    { exclude_schemes => [ 'mailto' ] },
);

for my $args ( @configs ) {
    # Create a Pod::Extract::URI object - takes a hash of arguments
    my $peu = Pod::Extract::URI->new( %$args );
    $peu->parse_from_file( $0 ); # parse this file

    # Print out some config information
    print "Arguments:\n";
    for my $a ( keys %$args ) {
        print "  $a => ";
        if ( ref $args->{ $a } ) {
            print "[ '" . join ( "', '", @{ $args->{ $a } } ) . "' ]";
        } else {
            print $args->{ $a };
        }
        print "\n";
    }

    # Print out the URIs we found
    print "\nURIS:\n";
    for my $uri ( $peu->uris ) {
        print "  $uri\n";
    }
    print "\n";
}

=pod

=head1 A heading

This is a general textblock, with a URI in it:
http://www.example.com/textblock

We can also pick up other URIs, like E<lt>mailto:ian@example.comE<gt>.
Note that by default, Pod::Extract::URI strips out the angled brackets.

     In a verbatim block, which we may choose to ignore
     http://www.example.com/verbatim


