
package Paper::Specs::base::brand;
use strict;

use vars qw($VERSION);
$VERSION=0.02;

=head1 Paper::base::brand

Base class for brand information

=head1

$things = Paper::Brand->find( '1234');

Returns things that match the supplied code. Typical code name normalization is applied

=cut

sub find {

    my $self = shift;

    my $code  = $self->normalize( shift ); 
    return "We need a code to search for\n" unless $code;

    eval "use ${self}::$code";
    return "${self}::$code"->new unless $@;
    
    if ($Paper::Specs::debug) {
      warn $@;
    }

    return ();

}

=over

=item Class->normalize( code )

Returnes a normalized code name for consistent searching.

 - strip leading zeros from the code name
 - strip leading spaces
 - switch to all lower case
 - switch spaces to "_"

=back

=cut

sub normalize {

    my $code=$_[1];

    $code =~ s/^0+//;
    $code =~ s/^\s+//;
    $code =~ s/\s+/_/;
    $code =~ tr/A-Z/a-z/;

    return $code;

}

1;

