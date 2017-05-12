package SWISH::API::More::Result;
use strict;
use warnings;
use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( result base ));

our $VERSION = '0.07';

my $loaded = 0;
sub setup
{
    return if $loaded++;
    SWISH::API::More::native_wrappers(
        [
            qw(
              Property ResultPropertyStr ResultIndexValue
              FuzzyMode PropertyList MetaList
              )
        ],
        __PACKAGE__,
        'result'
                                    );
}

sub fuzzy_word { shift->fw(@_) }
sub FuzzyWord  { shift->fw(@_) }

sub fw
{
    my $self = shift;
    my $fw   = $self->result->FuzzyWord(@_);
    return $self->base->whichnew('FuzzyWord')
      ->new({fw => $fw, base => $self->base});
}


1;

__END__

=head1 NAME

SWISH::API::More::Result - do more with SWISH::API::Result

=head1 SYNOPSIS

See SWISH::API::Result.

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
