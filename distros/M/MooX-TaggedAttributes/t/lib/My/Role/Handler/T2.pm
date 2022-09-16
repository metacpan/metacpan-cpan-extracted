package My::Role::Handler::T2;

use Moo::Role;

use My::Role::Handler::R0;

use constant TAG => __PACKAGE__ =~ /::([^:]+$)/;

sub make_tag_handler {
    # wrap this, 'cause caller().
    make_make_tag_handler( TAG, @_ );
}

use MooX::TaggedAttributes
  -tags    => TAG,
  -handler => \&make_tag_handler,
  -propagate;

has lc( TAG ) => ( is => 'ro', TAG => [] );

1;
