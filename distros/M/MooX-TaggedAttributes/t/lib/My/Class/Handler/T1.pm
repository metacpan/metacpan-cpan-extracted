package My::Class::Handler::T1;

use Moo::Role;

use My::Class::Handler::R0;

use constant TAG => __PACKAGE__ =~ /::([^:]+$)/;

sub make_tag_handler {
    # wrap this, 'cause caller().
    make_make_tag_handler( TAG, @_ );
}

use MooX::TaggedAttributes -tags => TAG, -handler => \&make_tag_handler;

has lc( TAG ) => ( is => 'ro', TAG => [] );

1;
