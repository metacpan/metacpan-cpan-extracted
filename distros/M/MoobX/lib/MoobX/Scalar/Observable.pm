package MoobX::Scalar::Observable;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Observable role for MobX scalars
$MoobX::Scalar::Observable::VERSION = '0.1.0';

use 5.20.0;

use Moose::Role;

use Scalar::Util 'refaddr';

before 'FETCH' => sub {
    my $self = shift;
    push @MoobX::DEPENDENCIES, $self if $MoobX::WATCHING;
};

after 'STORE' => sub {
    my $self = shift;
    
    MoobX::observable_ref($self->value) if ref $self->value;
    MoobX::observable_modified( $self );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MoobX::Scalar::Observable - Observable role for MobX scalars

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

Role applied to L<MoobX::Scalar> objects to make them observables.

Used internally by L<MoobX>.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
