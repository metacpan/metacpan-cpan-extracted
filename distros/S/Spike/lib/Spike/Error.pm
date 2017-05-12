package Spike::Error;

use strict;
use warnings;

use base qw(Spike::Object);

sub throw { die ref $_[0] ? $_[0] : shift->new(@_) }

sub new {
    my ($proto, $text, $value) = splice @_, 0, 3;
    my $class = ref $proto || $proto;

    return $class->SUPER::new(@_, text => $text, value => $value);
}

__PACKAGE__->mk_ro_accessors(qw(text value));

package Spike::Error::HTTP;

use base qw(Spike::Error);

use HTTP::Status;

sub new {
    my ($proto, $status) = splice @_, 0, 2;
    my $class = ref $proto || $proto;

    return $class->SUPER::new(
        HTTP::Status::status_message($status),
        $status,
        headers => [ @_ ],
    );
}

__PACKAGE__->mk_ro_accessors(qw(headers));

package Spike::Error::HTTP_OK;

use base qw(Spike::Error);

1;
