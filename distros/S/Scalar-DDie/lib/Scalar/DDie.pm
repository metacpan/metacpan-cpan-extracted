package Scalar::DDie;
use strict;
use warnings;
use 5.008005;
our $VERSION = '0.0.2';
use parent qw/Exporter/;

our @EXPORT = qw(ddie);
use Carp ();

sub ddie($) {
    if (defined($_[0])) {
        return $_[0];
    } else {
        Carp::croak("The value is not defined."); 
    }
}

1;
__END__

=encoding utf8

=head1 NAME

Scalar::DDie - Defined or die.

=head1 SYNOPSIS

    use Scalar::DDie;

    say ddie($var);

=head1 DESCRIPTION

Scalar::DDie checks the scalar value. If the value is not defined then it throw exception.
Just return value otherwise.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
