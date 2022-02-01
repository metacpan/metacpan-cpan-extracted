package Podman::Exception;

##! Simple generic exception class.
##!
##!     Podman::Exception->new( Code => 404 );
##!
##! Exception is thrown on API request failure.

use strict;
use warnings;
use utf8;

use Moose;
with qw(Throwable);

use overload '""' => 'AsString';

### API error description.
has 'Message' => (
    is => 'rw',
    isa => 'Str',
    default => '',
);

### API (HTTP) code.
has 'Code' => (
    is => 'ro',
    isa => 'Int',
    required => 1,
);

### #[ignore(item)]
sub BUILD {
    my $Self = shift;

    my %Messages = (
        0   => 'Connection failed.',
        304 => 'Action already processing.',
        400 => 'Bad parameter in request.',
        404 => 'No such item.',
        409 => 'Conflict error in operation.',
        500 => 'Internal server error.',
    );

    $Self->Message($Messages{$Self->Code} || 'Unknown error.');

    return;
}

### #[ignore(item)]
sub AsString {
    my $Self = shift;

    return sprintf "%s (%d)", $Self->Message, $Self->Code;
}

__PACKAGE__->meta->make_immutable;

1;
