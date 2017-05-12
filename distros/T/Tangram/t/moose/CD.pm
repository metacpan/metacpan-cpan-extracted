
package CD;
use Moose;
use Moose::Util::TypeConstraints;

has 'title' => ( is => 'rw', isa => 'Str' );
has 'artist' => ( is => 'rw', isa => 'CD::Artist' );
has 'publishdate' => ( is => 'rw', isa => 'Time::Piece' );

# we need proper generics!  this is silly
subtype "Array of CD::Song"
    => as ArrayRef
    => where {
	(blessed($_) && $_->isa('CD::Song') || return) for @$_; 1
    };

has 'songs' => ( is => 'rw', isa => 'Array of CD::Song' );

package CD::Compilation;

use Moose;
extends 'CD';

package CD::Song;
use Moose;

has 'name' => ( is => 'rw', isa => 'Str' );

package CD::Artist;
use Moose;
use Set::Object;

has 'name' => ( is => 'rw', isa => 'Str' );
has 'popularity' => ( is => 'rw', isa => 'Str' );
use Moose::Util::TypeConstraints;

subtype "Set of CD"
    => as Set::Object
    => where {
	($_->isa('CD') || return) for $_->members; 1
    };

has 'cds' => ( is => 'rw', isa => 'Set of CD' );

package CD::Person;
use Moose;
use Moose::Util::TypeConstraints;

extends 'CD::Artist';
enum "Gender" => qw(Male Female Asexual Hemaphrodite);
has 'gender' => ( is => 'rw', isa => "Gender" );
has 'haircolor' => ( is => 'rw', isa => "Str" );
has 'birthdate' => ( is => 'rw', isa => 'Time::Piece' );

package CD::Band;
use Moose;
use Moose::Util::TypeConstraints;

extents 'CD::Artist';

subtype "Set of CD::Person"
    => as Set::Object
    => where {
	($_->isa('CD::Artist') || return) for $_->members; 1
    };

has 'members' => ( is => 'rw', isa => 'Set of CD::Person' );
has 'creationdate' => ( is => 'rw', isa => 'Time::Piece' );
has 'enddate' => ( is => 'rw', isa => 'Time::Piece' );

sub CD::addone { $CD::c++ }
sub CD::delone { --$CD::c }

# for running tests, we keep a count of objects created
BEGIN {
    for my $package ( qw(CD CD::Song CD::Artist CD::Person CD::Band) ) {
	eval " package $package;
	before 'new' => \&CD::addone;
	after 'DESTROY' => \&CD::delone;";
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
