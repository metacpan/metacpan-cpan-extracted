#!perl
#PODNAME: Raisin::Encoder::Text
#ABSTRACT: Data::Dumper serialization plugin for Raisin.

use strict;
use warnings;

package Raisin::Encoder::Text;
$Raisin::Encoder::Text::VERSION = '0.90';
use Data::Dumper;
use Encode 'encode';

sub detectable_by { [qw(text/plain txt)] }
sub content_type { 'text/plain; charset=utf-8' }

sub serialize {
    my ($self, $data) = @_;

    $data = Data::Dumper->new([$data], ['data'])
        ->Sortkeys(1)
        ->Purity(1)
        ->Terse(1)
        ->Deepcopy(1)
        ->Dump;
    $data = encode('UTF-8', $data);
    $data;
}

sub deserialize {
    Raisin::log(error => 'Raisin:Encoder::Text doesn\'t support deserialization');
    die;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Raisin::Encoder::Text - Data::Dumper serialization plugin for Raisin.

=head1 VERSION

version 0.90

=head1 DESCRIPTION

Provides C<content_type>, C<serialize> methods.

=head1 AUTHOR

Artur Khabibullin <rtkh@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Artur Khabibullin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
