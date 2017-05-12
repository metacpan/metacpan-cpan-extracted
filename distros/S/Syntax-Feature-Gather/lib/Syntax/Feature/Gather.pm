package Syntax::Feature::Gather;

use strict;
use warnings;

# ABSTRACT: Provide a gather keyword

our $VERSION = '1.002001'; # VERSION

use Syntax::Keyword::Gather ();

sub install {
  my ($class, %args) = @_;

  my $target  = $args{into};
  my $options = $args{options} || {};

  Syntax::Keyword::Gather->import({ into => $target }, %$options );

  return 1;
}

1;

__END__

=pod

=head1 NAME

Syntax::Feature::Gather - Provide a gather keyword

=head1 VERSION

version 1.002001

=head1 SYNOPSIS

 use syntax 'gather';

 my @list = gather {
    # Try to extract odd numbers and odd number names...
    for (@data) {
       if (/(one|three|five|seven|nine)$/) { take qq{'$_'} }
       elsif (/^\d+$/ && $_ %2)            { take $_ }
    }
    # But use the default set if there aren't any of either...
    take @defaults unless gathered;
 }

or to use the stuff that L<Sub::Exporter> gives us, try

 # this is a silly idea
 use syntax gather => {
   gather => { -as => 'bake' },
   take   => { -as => 'cake' },
 };

 my @vals = bake { cake (1...10) };

The full documentation for this module is in L<Syntax::Keyword::Gather>.  This
is just a way to use the sugar that L<syntax> gives us.

=head1 AUTHORS

=over 4

=item *

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=item *

Damian Conway

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
