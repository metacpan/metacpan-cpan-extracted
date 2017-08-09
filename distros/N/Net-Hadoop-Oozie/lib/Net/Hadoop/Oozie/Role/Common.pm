package Net::Hadoop::Oozie::Role::Common;
$Net::Hadoop::Oozie::Role::Common::VERSION = '0.111';
use 5.010;
use strict;
use warnings;

use Carp qw(
    confess
);

use Carp ();
use Regexp::Common qw( URI number );

use Moo::Role;

has 'oozie_uri' => (
    is => 'rw',

    # The very least we can do to check the URL; since we use -keep we could
    # run more checks on the hostname, port, etc
    isa => sub {
        my $thing = shift;
        if ( $thing !~ $RE{URI}{HTTP}{-keep}{ -scheme => 'https?' } ) {
            Carp::confess "'$thing' is not a valid Oozie URI";
        }
    },
    default => sub {
        my $self = shift;
        if ( my $env = $ENV{OOZIE_URL} ) {
            # TODO
            #if ( $env !~ m{ \A https?:// (.+?) [/] oozie \z }xms ) {
            #    die "OOZIE_URL=$env is a malformed value!";
            #}
            return $env;
        }
        Carp::confess "oozie_uri not specified and \$ENV{OOZIE_URL} is not set!";
    },
    lazy => 1,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Hadoop::Oozie::Role::Common

=head1 VERSION

version 0.111

=head1 SYNOPSIS

    with 'Net::Hadoop::Oozie::Role::Common';
    # TODO

=head1 DESCRIPTION

Part of the Perl Oozie interface.

=head1 NAME

Net::Hadoop::Oozie::Role::Common - Common methods for Oozie

=head1 SEE ALSO

L<Net::Hadoop::Oozie>.

=head1 AUTHOR

David Morel <david.morel@amakuru.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by David Morel & Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
