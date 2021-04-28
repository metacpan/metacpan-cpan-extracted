#!perl
#PODNAME: Raisin::Logger
#ABSTRACT: Default logger for Raisin.

use strict;
use warnings;

package Raisin::Logger;
$Raisin::Logger::VERSION = '0.91';
my $FH = *STDERR;

sub new { bless {}, shift }

sub log {
    my ($self, %args) = @_;
    printf $FH '%s %s', uc($args{level}), $args{message};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Raisin::Logger - Default logger for Raisin.

=head1 VERSION

version 0.91

=head1 SYNOPSIS

    my $logger = Raisin::Logger->new;
    $logger->log(info => 'Hello, world!');

=head1 DESCRIPTION

Simple logger for Raisin.

=head1 METHODS

=head2 log

Accept's two parameters: C<level> and C<message>.

=head1 AUTHOR

Artur Khabibullin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Artur Khabibullin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
