package Search::Tools::Object;
use Moo;
use namespace::autoclean;

has 'debug' => (
    is      => 'rw',
    default => sub { $ENV{PERL_DEBUG} || 0 },
    coerce  => sub {
        return 0 if !$_[0];    # allow for undef or zero
        return $_[0];
    }
);

our $VERSION = '1.007';

1;

=pod

=head1 NAME

Search::Tools::Object - base class for Search::Tools objects

=head1 SYNOPSIS

 package MyClass;
 use Moo;
 extends 'Search::Tools::Object';
 has 'foo' => ( is => 'rw' );
 has 'bar' => ( is => 'rw' );
 
 1;
 
 # elsewhere
 
 use MyClass;
 my $object = MyClass->new;
 $object->foo(123);
 print $object->bar . "\n";

=head1 DESCRIPTION

Search::Tools::Object is a simple Moo subclass. 

Prior to version 1.00 STO was a subclass of Rose::ObjectX::CAF.

Prior to version 0.24 STO was a subclass of Class::Accessor::Fast. 

=head1 METHODS

=head2 debug( I<n> )

Get/set the debug value for the object. All objects inherit this attribute.
You can use the C<PERL_DEBUG> env var to set this value as well.

=head1 AUTHOR

Peter Karman C<< <karman@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-tools at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-Tools>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::Tools


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-Tools>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-Tools>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-Tools>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-Tools/>

=back

=head1 COPYRIGHT

Copyright 2009 by Peter Karman.

This package is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself.

=head1 SEE ALSO

Search::QueryParser
