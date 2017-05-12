package Provision::Unix::Web::Lighttpd;
# ABSTRACT: provision www virtual hosts on lighttpd
$Provision::Unix::Web::Lighttpd::VERSION = '1.08';
use strict;
use warnings;

use Params::Validate qw( :all );

use lib "lib";

use Provision::Unix;
my $prov = Provision::Unix->new;

sub new {
    my $class = shift;
    my $self  = {};
    bless( $self, $class );
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Provision::Unix::Web::Lighttpd - provision www virtual hosts on lighttpd

=head1 VERSION

version 1.08

=head1 AUTHOR

Matt Simerson <msimerson@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by The Network People, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
