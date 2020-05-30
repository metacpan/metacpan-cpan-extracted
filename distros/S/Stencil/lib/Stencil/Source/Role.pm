package Stencil::Source::Role;

use 5.014;

use strict;
use warnings;
use routines;

use Data::Object::Class;

extends 'Stencil::Source';

our $VERSION = '0.01'; # VERSION

1;

__DATA__

=spec

name: MyApp

integrates:
- MyApp::Role::Doable

attributes:
- is: ro
  name: name
  type: Str
  required: 1

operations:
- from: role
  make: lib/MyApp.pm
- from: role-test
  make: t/MyApp.t

routines:
- name: execute
  args: "(Str $key) : Any"
  desc: executes something which triggers something else

=role

package [% data.name %];

use 5.014;

use strict;
use warnings;

use Moo;

[%- IF data.integrates %]
[%- FOR item IN data.integrates %]
with '[% item %]';
[%- END %]
[% END -%]

# VERSION

[%- IF data.attributes %]
# ATTRIBUTES
[% FOR item IN data.attributes %]
has '[% item.name %]' => (
  is => '[% item.is %]',
  isa => '[% item.type %]',
  required => [% item.required %],
);
[% END -%]
[% END -%]

[%- IF data.routines %]
# ROUTINES
[% FOR item IN data.routines %]
sub [% item.name %] {
  my ($self) = @_;

  # do something ...

  return $self;
}
[% END -%]
[% END -%]

1;

=role-test

use 5.014;

use strict;
use warnings;

use Test::More;

use_ok '[% data.name %]';

[%- IF data.integrates %]
[%- FOR item IN data.integrates %]
use_ok '[% item %]';
[%- END %]
[% END -%]

subtest 'synopsis', sub {

  # do something ...

};

[%- IF data.routines %]
[%- FOR item IN data.routines %]
subtest 'routine: [% item.name %]', sub {

  # do something ...

};
[% END -%]
[% END -%]

done_testing;
