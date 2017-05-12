package Regexp::Log::Bar;

use base qw( Regexp::Log );
use vars qw( $VERSION %DEFAULT %FORMAT %REGEXP );

$VERSION = 0.01;

# default values
%DEFAULT = (
    format  => '%d %c %b',
    capture => [],
    _test   => 13,
);

# predefined format strings
%FORMAT = ( ':default' => '%a %b %c', );

# the regexps that match the various fields
# this is the difficult part
%REGEXP = (
    '%a' => '(?#=a)\\d+(?#!a)',
    '%b' => '(?#=b)th(?:is|at)(?#!b)',
    '%c' => '(?#=c)(?#=cs)\\w+(?#!cs)/(?#=cn)\\d+(?#!cn)(?#!c)',
    '%d' => '(?#=d)(?:foo|bar|baz)(?#!d)',
);

sub _postprocess {
    my $self = shift;

    # some code here
    $self->{_test}++;
}

1;
