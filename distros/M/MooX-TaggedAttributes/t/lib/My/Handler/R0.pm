package My::Handler::R0;

use Sub::Name 'subname';
use Moo::Role;

sub make_make_tag_handler {
    my ( $tag, $target ) = @_;
    my $class = caller;
    subname "${target}::tag_handler" => sub {
        my ( $orig, $attrs, %opt ) = @_;

        push @{ $opt{$tag} }, [ $class, $target ]
          if exists $opt{$tag};
        $orig->( $attrs, %opt );
    }
}

1;
