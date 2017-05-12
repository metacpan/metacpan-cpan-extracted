
package CD;

our $c;

use base "Class::Accessor::Assert";
__PACKAGE__->mk_accessors(qw(
   artist=CD::Artist title publishdate=Time::Piece songs=ARRAY
));

package CD::Compilation;
use base 'CD';


package CD::Song;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors("name");

package CD::Artist;
use base 'Class::Accessor::Assert';
__PACKAGE__->mk_accessors(qw( name popularity cds=Set::Object ));

package CD::Person;
use base 'CD::Artist';
__PACKAGE__->mk_accessors(qw(gender haircolor birthdate=Time::Piece));

package CD::Band;
use base 'CD::Artist';
__PACKAGE__->mk_accessors( qw( members=Set::Object
                               creationdate=Time::Piece
                               enddate=Time::Piece ));

# for running tests, we keep a count of objects created
BEGIN {
    for my $package ( qw(CD CD::Song CD::Artist CD::Person CD::Band) ) {
	sub new { $CD::c++; my $invocant = shift; $invocant->SUPER::new(@_); }
	sub DESTROY { --$CD::c; }
    }
}

# This dispatching isn't necessary because we use inheritance

# # Dispatch "band" accessors if it's a band
# for my $accessor (qw(members creationdate breakupdate)) {
#     *$accessor = sub {
#        my $self = shift;
#        return $self->band->$accessor(@_) if $self->band
#     };
# }

# # And dispatch "person" accessors if it's a person
# for my $accessor (qw(gender haircolor birthdate)) {
#     *$accessor = sub {
#        my $self = shift;
#        return $self->person->$accessor(@_) if $self->person
#     };
# }

1;
