package Plack::Debugger::Panel::Dancer2::Version;

#ABSTRACT: Plack Debugger Panel for displaying Dancer2 Version
use strict;
use warnings;

use parent 'Plack::Debugger::Panel';

sub new {
    my $class = shift;
    my %args = @_ == 1 && ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

    $args{title} = 'Dancer2::Version';

    $args{'after'} = sub {
        my $self = shift;

        my $version = '0.160001';
        $self->set_subtitle($Dancer2::VERSION);
    };
    $class->SUPER::new( \%args );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Debugger::Panel::Dancer2::Version - Plack Debugger Panel for displaying Dancer2 Version

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Display Dancer2's version in Plack::Debugger.

=head1 SEE ALSO

L<Plack::Debugger>, L<Dancer2> 

=head1 AUTHOR

=head1 AUTHOR

William Carr <bill@bottlenose-wine.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by William Carr.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
