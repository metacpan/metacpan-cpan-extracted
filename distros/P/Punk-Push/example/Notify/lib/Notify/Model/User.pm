package Notify::Model::User;

use strict;
use warnings;
use Punk::Model;

our $VERSION = '0.01';

table 'users';

field id            => { type => 'integer', primary => 1 };
field email         => { type => 'string' };
field password_hash => { type => 'string' };
field verified      => { type => 'integer' };

1;

__END__
