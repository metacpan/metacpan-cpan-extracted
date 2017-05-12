package Regexp::Log::Foo;

use base qw( Regexp::Log );
use vars qw( $VERSION %DEFAULT %FORMAT %REGEXP );

$VERSION = 0.01;

# default values
%DEFAULT = (
    format  => '%d %c %b',
    capture => ['c'],
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

sub _preprocess {
    my $self = shift;

    # multiple consecutive spaces in the format are compressed
    # to a single space
    $self->{_regexp} =~ s/ +/ /g;
}

1;
