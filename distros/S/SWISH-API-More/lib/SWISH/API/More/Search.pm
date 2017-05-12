package SWISH::API::More::Search;
use strict;
use warnings;
use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( search base ));

our $VERSION = '0.07';

my $loaded = 0;
sub setup
{
    return if $loaded++;
    SWISH::API::More::native_wrappers(
        [
            qw(
              SetQuery SetStructure PhraseDelimiter
              SetSearchLimit ResetSearchLimit SetSort
              )
        ],
        __PACKAGE__,
        'search'
                                    );
}

sub Execute { shift->execute(@_) }

sub execute
{
    my $self = shift;
    my $r    = $self->search->Execute(@_);
    return $self->base->whichnew('Results')
      ->new({results => $r, base => $self->base});
}

1;

__END__

=head1 NAME

SWISH::API::More::Search - do more with SWISH::API::Search

=head1 SYNOPSIS

See SWISH::API::Search.

=head1 SEE ALSO

L<http://swish-e.org/>

L<SWISH::API>, L<SWISH::API::More>

=head1 AUTHOR

Peter Karman, E<lt>karman@cpan.orgE<gt>

Thanks to L<Atomic Learning|http://www.atomiclearning.com/> for supporting some
of the development of this module.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
