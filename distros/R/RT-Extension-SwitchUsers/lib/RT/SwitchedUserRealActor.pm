package RT::SwitchedUserRealActor;

use strict;
use warnings;

use base 'RT::Record';

sub Table {'SwitchedUserRealActors'}

=head2 Id

Returns the current value of id.
(In the database, id is stored as int(11).)


=head2 ObjectType

Returns the current value of ObjectType.
(In the database, ObjectType is stored as varchar(255).)


=head2 ObjectId

Returns the current value of ObjectId.
(In the database, ObjectId is stored as int(11).)

=head2 Creator

Returns the current value of Creator.
(In the database, Creator is stored as int(11).)

=head2 LastUpdatedBy

Returns the current value of LastUpdatedBy.
(In the database, LastUpdatedBy is stored as int(11).)


=cut



sub _CoreAccessible {
    {
        id =>
                {read => 1, sql_type => 4, length => 11,  is_blob => 0,  is_numeric => 1,  type => 'int(11)', default => ''},
        ObjectType =>
                {read => 1, write => 1, sql_type => 12, length => 255,  is_blob => 0,  is_numeric => 0,  type => 'varchar(255)', default => ''},
        ObjectId =>
                {read => 1, write => 1, sql_type => 4, length => 11,  is_blob => 0,  is_numeric => 1,  type => 'int(11)', default => '0'},
        Creator =>
                {read => 1, auto => 1, sql_type => 4, length => 11,  is_blob => 0,  is_numeric => 1,  type => 'int(11)', default => '0'},
        LastUpdatedBy =>
                {read => 1, auto => 1, sql_type => 4, length => 11,  is_blob => 0,  is_numeric => 1,  type => 'int(11)', default => '0'},
    }
};


RT::Base->_ImportOverlays();

1;
