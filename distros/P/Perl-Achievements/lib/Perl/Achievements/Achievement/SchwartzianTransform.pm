package Perl::Achievements::Achievement::SchwartzianTransform;
BEGIN {
  $Perl::Achievements::Achievement::SchwartzianTransform::AUTHORITY = 'cpan:YANICK';
}
{
  $Perl::Achievements::Achievement::SchwartzianTransform::VERSION = '0.4.0';
}
# ABSTRACT: code uses schwartzian transformations

use 5.10.0;

use strict;
use warnings;

use Moose;
use MooseX::SemiAffordanceAccessor;

with 'Perl::Achievements::Achievement';

has transformations => (
    traits  => [qw/ Counter Perl::Achievements::Role::ConfigItem /],
    isa     => 'Num',
    is      => 'rw',
    default => 0,
    handles => {
        inc_transformations => 'inc',
    },
);

sub scan {
    my $self = shift;

    use List::MoreUtils 'uniq';

    # Living up to the name of...
    my $schwartzian_transformations =
            # Step 6) Superfluous but still nice to have a step 6 ;-)
      scalar 
            # Step 5) DIRRRTY! (but matches more complex statements than just a simple map sort map) 
      grep { /map.*?sort.*?map/g }                                                          
            # Step 4) Prune the statements gathered from Step 3)      
       map {                                                                                 
            $_->prune(sub {         #   (that is, remove everything from that statement)
                    !(              #   except
                            $_[1]->isa('PPI::Token::Word')                #   the tokens
                        and $_[1]->literal ~~ [ 'map', 'grep', 'sort' ]   #   'map' and 'sort' ('grep' doesn't hurt here and you could
                    )                                                     #   do some clever combination of Steps 1 + 4 + 5....)
            }                         #   Finally,
          ) => $_->content            #   don't forget to return the content
      }                               #   (since prune only returns the number it has pruned)
      uniq                      # Step 3) uniq-ify them
      map { $_->statement }     # Step 2) Get the statements in which these tokens occur
      @{                        # Step 1) Generate the list to work on...
        $self->ppi->find(       #   all places where 'map' or 'sort' occurs
            sub {               #   of course...
                $_[1]->isa('PPI::Token::Word')             #   you could watch out for more
                  and $_[1]->literal ~~ [ 'map', 'sort' ]  #   'grep', 'uniq', ...
            }
        )
      } or return;

    $self->inc_transformations($schwartzian_transformations);

    return unless $self->transformations >= 2**$self->level;

    $self->inc_level;

    $self->unlock(
        sprintf "used the schwartzian transformations %d times",
                $self->transformations
    );
}

1;



=pod

=head1 NAME

Perl::Achievements::Achievement::SchwartzianTransform - code uses schwartzian transformations

=head1 VERSION

version 0.4.0

=head1 AUTHORS

=over

=item Daniel Bruder <dbr@cpan.org>

=item Yanick Champoux <yanick@cpan.org>

=back

=head1 SEE ALSO

Wikipedia entry on the Schwartzian Transform -
L<http://en.wikipedia.org/wiki/Schwartzian_transform>

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

