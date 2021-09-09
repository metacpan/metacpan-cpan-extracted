use v5.10;

use Moo;
say Moo->VERSION;

package My::Role {
    use Moo::Role;
    has '+p1' => (
        is      => 'rw',
        trigger => sub { say 'happy' },
    );
}

package My::Base {
    use Moo;
    has p1 => (
               is => 'rw',
              );
    with 'My::Role';
}

My::Base->new->p1('are we');
