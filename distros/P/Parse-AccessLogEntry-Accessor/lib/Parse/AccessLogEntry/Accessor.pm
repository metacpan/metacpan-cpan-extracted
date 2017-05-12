package Parse::AccessLogEntry::Accessor;

use warnings;
use strict;

our $VERSION = '0.01';

use base qw( Parse::AccessLogEntry Class::Accessor::Fast );
__PACKAGE__->mk_ro_accessors(qw(
    host    user  date  time
    diffgmt rtype file  proto
    code    bytes refer agent
));


sub new {
    my $class = shift;
    my $self  = $class->SUPER::new;

    return bless $self;
}

sub parse {
    my $self = shift;
    my $line = shift or die;

    my $ref = $self->SUPER::parse($line);

    while (my ($key, $val) = each %{$ref}) {
        $self->{$key} = $val;
    }
    return $self;
}

1;
__END__

=head1 NAME

Parse::AccessLogEntry::Accessor - adds accessors to Parse::AccessLogEntry module.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Parse::AccessLogEntry::Accessor;
    my $parser = Parse::AccessLogEntry::Accessor->new();

    # $line is a string containing one line of an access log
    $parser->parse($line);
    print $parser->host(), "\n";

=head1 DESCRIPTION

This module is an Apache accesslog parser. It's based on Parse::AccessLogEntry module.

The key name of the hushref and the accessor of this name are offered.

=head1 CLASS METHODS

=head2 new

Create an instance of Parse::AccessLogEntry::Accessor

=head1 INSTANCE METHODS

=head2 parse

Parse one line of an Apache accesslog

=head2 host

Get client ip of the request

=head2 user

Get user logged in ("-" for none)

=head2 date

Get date of the request

=head2 time

Get server time of the request

=head2 diffgmt

Get server offset from GMT

=head2 rtype

Get type of request (GET, POST, etc)

=head2 file

Get file requested

=head2 proto

Get protocol used (HTTP/1.1, etc)

=head2 code

Get code returned by apache (200, 304, etc)

=head2 bytes

Get number of bytes returned to the client

=head2 refer

Get referrer

=head2 agent

Get user-agent

=head1 SEE ALSO

L<Parse::AccessLogEntry>

=head1 AUTHOR

Ryoji Tanida, C<< <amarisan@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Ryoji Tanida, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
