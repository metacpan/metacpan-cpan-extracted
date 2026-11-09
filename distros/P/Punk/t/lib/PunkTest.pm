package PunkTest;

use 5.010;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw(hit loop_pool_error);

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

# The async backend forks its pool at the first statement. Where that fork
# fails there is no backend to test - on Cygwin a child can be refused
# because a DLL's address is already taken in it - and every statement
# would fail the same way. Returns the spawn error, one line, so a test can
# skip and say why. Any other failure is a real one and dies as it would
# have. The model needs its table: the probe is a count on it.
sub loop_pool_error {
    my ($model) = @_;
    return '' if eval { $model->count({})->get; 1 };
    my $err = $@;
    return $err =~ /could not spawn pool worker/ ? (split /\n/, $err)[0] : die $err;
}

1;
