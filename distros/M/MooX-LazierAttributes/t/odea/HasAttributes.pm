package t::odea::HasAttributes;

use Moo;
use MooX::LazierAttributes;

has one   => ( is_rw, default => sub { 10 } );
has two   => ( is_ro, default => sub { [qw/one two three/] } );
has three => ( is_ro, default => sub { { one => 'two' } } );
has four  => ( is_ro, default => sub { 'a default value' } );
has five  => ( is_ro, default => sub { bless {}, 'Thing' } );
has six   => ( is_ro, default => sub { 0 } );
has seven => ( is_ro, default => sub { undef } );
has eight => ( is_rw );
has nine  => ( is_ro, lzy, default => sub { { broken => 'thing' } } );
has ten   => ( is_rw, default => sub { {} } );
has [qw/eleven twelve thirteen/] => ( is_ro, default => sub { 'test this' } );
has fourteen => ( is_rw, bld, clr, lzy );

sub _build_fourteen {
    return 100;
}

1;
