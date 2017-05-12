package RedisDB::Parser::Error;

use strict;
use warnings;
our $VERSION = "2.22";
$VERSION = eval $VERSION;

=head1 NAME

RedisDB::Parser::Error - default error class for RedisDB::Parser

=head1 SYNOPSIS

    use Scalar::Util qw(blessed);
    ...;
    sub callback {
        my ( $master, $reply ) = @_;
        die "$reply" if blessed $reply;    # it's more like damned
        ...;                               # do something with reply
    }

=head1 DESCRIPTION

Then RedisDB::Parser parses error response from server it creates an object of
this class and passes it to callback. In string context object returns the
error message from the server.

=head1 METHODS

=cut

use overload '""' => \&as_string;

=head2 $class->new($message)

Create new error object with specified error message.

=cut

sub new {
    my ( $class, $message ) = @_;
    if ( $message =~ /^MOVED / ) {
        return "${class}::MOVED"->new($message);
    }
    elsif ( $message =~ /^ASK / ) {
        return "${class}::ASK"->new($message);
    }
    return bless { message => $message }, $class;
}

=head2 $self->as_string

Return error message. Also you can just use object in string context.

=cut

sub as_string {
    return shift->{message};
}

package RedisDB::Parser::Error::MOVED;
use strict;
use warnings;
our @ISA = qw(RedisDB::Parser::Error);

sub new {
    my ( $class, $message ) = @_;
    my ( $type, $slot, $host, $port ) =
      ( $message =~ /^(MOVED|ASK) \s ([0-9]+) \s ([0-9.]+):([0-9]+)$/x );
    return bless {
        slot    => $slot,
        host    => $host,
        port    => $port,
        message => $message,
    }, $class;
}

package RedisDB::Parser::Error::ASK;
our @ISA = qw(RedisDB::Parser::Error::MOVED);

1;

__END__

=head1 SEE ALSO

L<RedisDB::Parser>

=head1 AUTHOR

Pavel Shaydo, C<< <zwon at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2015 Pavel Shaydo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
