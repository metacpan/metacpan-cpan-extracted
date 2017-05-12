use strict;
use warnings;

package Parse::PAUSE::Plugin;
our $VERSION = '1.001';


use Moose::Role;
use Encode;
use Encode::Newlines;

requires '_regexp', '_parse';

has 'upload' => (
    is => 'ro', isa => 'Str', writer => '_set_upload', init_arg => undef,
);

has 'pathname' => (
    is => 'ro', isa => 'Str', writer => '_set_pathname', init_arg => undef,
);

has 'size' => (
    is => 'ro', isa => 'Int', writer => '_set_size', init_arg => undef,
);

has 'md5' => (
    is => 'ro', isa => 'Str', writer => '_set_md5', init_arg => undef,
);

has 'entered_by' => (
    is => 'ro', isa => 'Str', writer => '_set_entered_by', init_arg => undef,
);

has 'entered_on' => (
    is => 'ro', isa => 'Str', writer => '_set_entered_on', init_arg => undef,
);

has 'completed' => (
    is => 'ro', isa => 'Str', writer => '_set_completed', init_arg => undef,
);

has 'paused_version' => (
    is => 'ro', isa => 'Int', writer => '_set_paused_version', init_arg => undef,
);

sub _process {
    my ($class, $content) = @_;
    my $self = $class->new();
    my $normalized_content = decode(CRLF => $content);

    return $self->_parse($normalized_content);
}

1;
