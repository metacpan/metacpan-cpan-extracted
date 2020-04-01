package main;

use 5.006;

use strict;
use warnings;

use PPIx::QuoteLike::Utils qw{ __normalize_interpolation_for_ppi };
use Test::More 0.88;	# Because of done_testing();

sub norm ($$;$);

norm '$foo', '$foo';

norm '$ foo', '$foo';

norm '${foo}', '$foo';

norm '${ foo }', '$foo';

norm '$ { foo }', '$foo';

# NOTE this is a warning, and so (for now) not supported
# norm '${foo{bar}}', '$foo{bar}';

# NOTE this is a warning, and so (for now) not supported
# norm '@{foo{bar}}', '@foo{bar}';

norm '@{$x[$i]}', '@{$x[$i]}';

norm '@{ [ foo() ] }', 'foo()';

norm '${ \\ ( foo() ) }', 'foo()';

done_testing;

sub norm ($$;$) {
    my ( $norm, $want, $title ) = @_;
    defined $title
	or $title = "'$norm' normalizes to '$want'";
    my $got = __normalize_interpolation_for_ppi( $norm );
    @_ = ( $got, $want, $title );
    goto &is;
}

1;

# ex: set textwidth=72 :
