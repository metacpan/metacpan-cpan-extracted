package SWISH::API::More::Results;
use strict;
use warnings;
use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( results base query ));

our $VERSION = '0.07';

my $loaded = 0;
sub setup
{
    return if $loaded++;
    SWISH::API::More::native_wrappers(
        [
            qw(
              Hits SeekResult RemovedStopwords ParsedWords
              )
        ],
        __PACKAGE__,
        'results'
                                    );
}

sub NextResult { shift->next_result(@_) }

sub next_result
{
    my $self = shift;
    my $n    = $self->results->NextResult(@_);
    return undef unless defined $n;
    return $self->base->whichnew('Result')
      ->new({result => $n, base => $self->base});
}

1;

__END__

=head1 NAME

SWISH::API::More::Results - do more with SWISH::API::Results

=head1 SYNOPSIS

See SWISH::API::Results.

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
