package TV::Anytime::Genre;
use strict;
use warnings;
use base 'Class::Accessor::Chained::Fast';
__PACKAGE__->mk_accessors(qw(name value));

1;

__END__

=head1 NAME

TV::Anytime::Genre - Represent a genre

=head1 SYNOPSIS

  my $name  = $genre->name;
  my $value = $genre->value;

=head1 DESCRIPTION

The L<TV::Anytime::Genre> represents a genre.

=head1 METHODS

=head2 name

Return the name of the genre:

  my $name  = $genre->name;
  
=head2 value

Returns the value of the genre:

  my $value = $genre->value;

=head1 SEE ALSO 

L<TV::Anytime>

=head1 BUGS                                                   
                                                                                
Please report any bugs or feature requests to                                   
C<bug-TV-Anytime@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  

=head1 AUTHOR

Leon Brocard C<acme@astray.com>

=head1 LICENCE AND COPYRIGHT                                                    
                                                                                
Copyright (c) 2005, Leon Brocard C<acme@astray.com>. All rights reserved.
                                                                                
This module is free software; you can redistribute it and/or                    
modify it under the same terms as Perl itself.  