package t::odea::ExtendsHasAttributes;

use Moo;
use MooX::LazierAttributes;

extends 't::odea::HasAttributes';

has '+one'   => ( default => sub { 20 } );
has '+two'   => ( default => sub { [qw/four five six/] } );
has '+three' => ( default => sub { { three => 'four' } } );
has '+four'  => ( default => sub { 'a different value' } );
has '+five'  => ( default => sub { bless {}, 'Okays' } );
has six   => ( is_ro, default => sub { 1 } );
has [qw/+eleven +twelve +thirteen/] => ( is_ro, default => sub { 'ahhhhhhhhhhhhh' } );

sub _build_fourteen {
    return 40000;
}

1;
