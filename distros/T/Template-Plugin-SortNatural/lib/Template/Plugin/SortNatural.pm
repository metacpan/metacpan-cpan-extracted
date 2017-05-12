package Template::Plugin::SortNatural;

use warnings;
use strict;
use base qw( Template::Plugin::VMethods );
use Carp;
use Sort::Naturally; 

our $VERSION = '0.001';

our @LIST_OPS =  qw( sortn );

=head1 NAME

Template::Plugin::SortNatural - Sort lists natural with Sort::Naturally

=head1 SYNOPSIS

 [% USE SortNatural;
    foo.nsort;
 %]
  

=head1 DESCRIPTION

sort lexically, but sort numeral parts numerically

=cut

=head2 sortn( )

Returns a new sorted arrayref.

=cut

sub sortn {
    my $list  = shift;
    if ( ref $list eq 'ARRAY' ) {
        return nsort(@{$list});
    } else {
        croak "sort_by only works with ARRAY references";
    }

}

1;

__END__

=head1 AUTHOR

Alexander Wirt, C<< <formorer@formorer.de> >>

=head1 BUGS

Please report any bugs or feature requests to github:
https://github.com/credativ/pkg-libtemplate-plugin-sortnatural-perl/issues

=head1 COPYRIGHT & LICENSE

Copyright 2014 by Alexander Wirt C<< <formorer@formorer.de> >>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

