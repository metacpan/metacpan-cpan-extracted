package Stencil::Source::Class;

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

inherits:
- MyApp::Parent

integrates:
- MyApp::Role::Doable

attributes:
- is: ro
  name: name
  type: Str
  required: 1

operations:
- from: class
  make: lib/MyApp.pm
- from: class-test
  make: t/MyApp.t

routines:
- name: execute
  args: "(Str $key) : Any"
  desc: executes something which triggers something else

=class

package [% data.name %];

use 5.014;

use strict;
use warnings;

use Moo;

[%- IF data.inherits %]
[%- FOR item IN data.inherits %]
extends '[% item %]';
[%- END %]
[% END -%]

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

=class-test

use 5.014;

use strict;
use warnings;

use Test::More;

use_ok '[% data.name %]';

[%- IF data.inherits %]
[%- FOR item IN data.inherits %]
isa_ok '[% data.name %]', '[% item %]';
[%- END %]
[% END -%]

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
