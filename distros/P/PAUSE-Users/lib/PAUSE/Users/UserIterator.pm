package PAUSE::Users::UserIterator;
$PAUSE::Users::UserIterator::VERSION = '0.07';
use strict;
use warnings;
use 5.14.0;

use Moo;
use PAUSE::Users::User;
use autodie;
use feature 'unicode_strings';

has 'users' => ( is => 'ro' );
has _fh     => ( is => 'rw' );

sub next_user
{
    my $self = shift;
    my @fields;
    my $inuser;
    my $fh;
    local $_;

    if (not defined $self->_fh) {
        $fh = $self->users->open_file();
        $self->_fh($fh);
    }
    else {
        $fh = $self->_fh;
    }

    $inuser = 0;
    LINE:
    while (<$fh>) {

        if (m!<cpanid>!) {
            $inuser = 1;
            next LINE;
        }

        next LINE unless $inuser;

        if (m!<([a-zA-Z0-6_]+)>(.*?)</\1>!) {
            my ($field, $value) = ($1, $2);

            # <type>author</type> specified a user account
            # <type>list</type> is a mailing list; we skip those
            if ($field eq 'type') {
                $inuser = 0 if $value eq 'list';
                next LINE;
            }

            push(@fields, $field => $value);
        }

        if (m!</cpanid>!) {
            my $user = PAUSE::Users::User->new(@fields);
            @fields  = ();
            return $user;
        }

    }
    close($fh);
    return undef;
}

1;
