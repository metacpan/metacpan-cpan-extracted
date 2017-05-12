package OAuthomatic::Internal::UsageGuard;
# ABSTRACT: support for RAII for some roles


use Moose;
use namespace::sweep;

has 'obj' => (is => 'ro', isa=>'Object');
has '_active' => (is=>'rw', isa=>'Bool');

sub prepare {
    my $self = shift;
    return if $self->_active;
    $self->obj->prepare_to_work;
    $self->_active(1);
    return;
}

sub finish {
    my $self = shift;
    return unless $self->_active;
    $self->obj->cleanup_after_work;
    $self->_active(0);
    return;
}

sub DEMOLISH {
    my $self = shift;
    $self->finish;
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OAuthomatic::Internal::UsageGuard - support for RAII for some roles

=head1 VERSION

version 0.0201

=head1 DESCRIPTION

Internally used by L<OAuthomatic>

=head1 AUTHOR

Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Marcin Kasperski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
