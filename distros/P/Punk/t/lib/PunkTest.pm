package PunkTest;

use 5.010;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw(hit);

# the environment in which a 500 says what died, as Punk::Test sets it
$ENV{PUNK_ENV} = 'test' unless defined $ENV{PUNK_ENV};

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
