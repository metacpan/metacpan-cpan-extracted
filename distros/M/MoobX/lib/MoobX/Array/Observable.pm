package MoobX::Array::Observable;
our $AUTHORITY = 'cpan:YANICK';
$MoobX::Array::Observable::VERSION = '0.1.2';
use Moose::Role;

use experimental 'postderef', 'signatures';

use Scalar::Util 'refaddr';

before [ qw/ FETCH FETCHSIZE /] => sub {
    my $self = shift;
    push @MoobX::DEPENDENCIES, $self if $MoobX::WATCHING;
};


after [ qw/ STORE PUSH CLEAR /] => sub {
    my $self = shift;
    for my $i ( 0.. $self->value->$#* ) {
        next if tied $self->value->[$i];
        next unless ref $self->value->[$i];
        MoobX::observable_ref( $self->value->[$i] );
    }
    MoobX::observable_modified( $self );
};



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MoobX::Array::Observable

=head1 VERSION

version 0.1.2

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2017 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
