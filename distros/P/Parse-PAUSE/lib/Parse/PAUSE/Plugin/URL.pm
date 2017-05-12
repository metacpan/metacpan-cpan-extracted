use strict;
use warnings;

package Parse::PAUSE::Plugin::URL;
our $VERSION = '1.001';


use Moose;

has '_regexp' => (
    is => 'ro',
    isa => 'RegexpRef',
    default => sub {qr{
        ^ The \s URL \r\n
        ^ \r\n
        ^ \s{4} (.+) \r\n
        ^ \r\n
        ^ has \s entered \s CPAN \s as \r\n
        ^ \r\n
        ^ \s{2} file: \s (.+) \r\n
        ^ \s{2} size: \s (\d+) \s bytes \r\n
        ^ \s{3} md5: \s (.+) \r\n
        ^ \r\n
        ^ No \s action \s is \s required \s on \s your \s part \r\n
        ^ Request \s entered \s by: \s (.+) \r\n
        ^ Request \s entered \s on: \s (.+) \r\n
        ^ Request \s completed: \s{2} (.+) \r\n
        ^ \r\n^ Thanks, \r\n
        ^ -- \s \r\n
        ^ paused, \s v (\d+) \r\n
    }xms},
);

with 'Parse::PAUSE::Plugin';

sub _parse {
    my ($self, $body) = @_;
    my $regexp = $self->_regexp();

    if (my (
        $upload, $pathname, $size, $md5, $entered_by, $entered_on,
        $set_completed, $set_paused_version,
    ) = $body =~ m{$regexp}xms) {
        $self->_set_upload($upload);
        $self->_set_pathname($pathname);
        $self->_set_size($size);
        $self->_set_md5($md5);
        $self->_set_entered_by($entered_by);
        $self->_set_entered_on($entered_on);
        $self->_set_completed($set_completed);
        $self->_set_paused_version($set_paused_version);

        return $self;
    }
    else {
        return;
    }
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;
