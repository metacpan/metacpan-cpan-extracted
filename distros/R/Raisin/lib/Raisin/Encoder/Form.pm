#!perl
#PODNAME: Raisin::Encoder::Form
#ABSTRACT: Form deserialization plugin for Raisin.

use strict;
use warnings;

package Raisin::Encoder::Form;
$Raisin::Encoder::Form::VERSION = '0.94';
use Encode qw(decode_utf8);

sub detectable_by { [qw(application/x-www-form-urlencoded multipart/form-data)] }
sub content_type { 'text/plain; charset=utf-8' }

sub serialize {
    Raisin::log(error => 'Raisin:Encoder::Form doesn\'t support serialization');
    die;
}

sub deserialize { $_[1]->body_parameters }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Raisin::Encoder::Form - Form deserialization plugin for Raisin.

=head1 VERSION

version 0.94

=head1 DESCRIPTION

Provides C<deserialize> method to decode HTML form data requests.

=head1 AUTHOR

Artur Khabibullin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Artur Khabibullin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
