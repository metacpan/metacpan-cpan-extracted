package My::Role::Handler::R0;

use strict;
use warnings;

use Sub::Name 'subname';

use Exporter qw( import );

our @EXPORT = qw( make_make_tag_handler );

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
