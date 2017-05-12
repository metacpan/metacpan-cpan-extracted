package MooseX::POE::Meta::Role;
{
  $MooseX::POE::Meta::Role::VERSION = '0.215';
}
# ABSTRACT: Pay no attention to this.
use Moose::Role;
with qw(MooseX::POE::Meta::Trait);

around default_events => sub {
    my ( $orig, $self ) = @_;
    my $events = $orig->($self);
    push @$events, grep { s/^on_(\w+)/$1/; } $self->get_method_list;
    return $events;
};

around get_state_method_name => sub {
    my ( $orig, $self, $name ) = @_;
    return 'on_' . $name if $self->has_method( 'on_' . $name );
    return $orig->( $self, $name );
};


no Moose::Role;

1;


__END__
=pod

=head1 NAME

MooseX::POE::Meta::Role - Pay no attention to this.

=head1 VERSION

version 0.215

=head1 AUTHORS

=over 4

=item *

Chris Prather <chris@prather.org>

=item *

Ash Berlin <ash@cpan.org>

=item *

Chris Williams <chris@bingosnet.co.uk>

=item *

Yuval (nothingmuch) Kogman

=item *

Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Chris Prather, Ash Berlin, Chris Williams, Yuval Kogman, Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

