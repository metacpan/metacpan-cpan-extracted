package DerivedUser;
use strict;

our $db;
use base qw(BaseUser);

use Rose::DBx::Object::MakeMethods::EKSBlowfish(
  eksblowfish => [
    type => {
      cost => 8,
      key_nul => 0,
    },
  ],
);

# Change the "password" column into a eksblowfish column.
__PACKAGE__->meta->replace_column('password' => {type => 'eksblowfish'});
__PACKAGE__->meta->initialize(replace_existing => 1);

1;
