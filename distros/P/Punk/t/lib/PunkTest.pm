package PunkTest;

use 5.010;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw(hit);

# One hand-built PSGI env call against a compiled app.
sub hit {
    my ($app, %o) = @_;
    my $body = $o{body} // '';
    open my $in, '<', \$body or die $!;
    return $app->({
        REQUEST_METHOD => $o{method} // 'GET',
        PATH_INFO      => $o{path}   // '/',
        QUERY_STRING   => $o{query}  // '',
        CONTENT_TYPE   => $o{type}
            // ($body ne '' ? 'application/json' : ''),
        CONTENT_LENGTH => length $body,
        'psgi.input'   => $in,
        %{ $o{env} // {} },
    });
}

1;
