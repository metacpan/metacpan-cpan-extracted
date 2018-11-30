package Perl::Critic::RENEEB;

use warnings;
use strict;

# ABSTRACT: A collection of handy Perl::Critic policies

our $VERSION = '2.00';


1; # End of Perl::Critic::RENEEB

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::RENEEB - A collection of handy Perl::Critic policies

=head1 VERSION

version 2.00

=head1 SYNOPSIS

Perl::Critic::RENEEB is a collection of Perl::Critic policies that
is used in my programming environment

=head1 DESCRIPTION

The rules included with the Perl::Critic::RENEEB group include:

=head2 L<Perl::Critic::Policy::RegularExpressions::RequireExtendedFormattingExceptForSplit>

I use split with regular expressions regularly, but I don't want to use the x-modifier there. So
I wrote this policy to check all regular expressions in my programs but those used as a parameter to split.

=head2 L<Perl::Critic::Policy::Reneeb::ProhibitBlockEval>

Use C<try{...}> from L<Try::Tiny|https://metacpan.org/pod/Try::Tiny> instead of C<eval{...}>.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
