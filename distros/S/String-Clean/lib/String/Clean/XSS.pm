package String::Clean::XSS;
BEGIN {
  $String::Clean::XSS::VERSION = '0.031';
}

#use base qw{Exporter String::Class};
use Exporter qw{import};
our @EXPORT = qw{clean_XSS convert_XSS};

use strict;
use warnings;
use String::Clean;
use Carp::Assert::More;

=head1 NAME                                                                                                                                                             

String::Clean::XSS - Clean up for Cross Site Scripting (XSS)

=head1 SYNOPSIS

Clean strings to protect from XSS attacks.

=head2 EXAMPLES

   use String::Clean::XSS;
   
   my $stuff_from_user = '<script>bad stuff</script>';

   my $safe_login    = convert_XSS($stuff_from_user);
   # results in '&lt;script&gt;bad stuff&lt;/script&gt;'

   my $cleaned_login = clean_XSS($stuff_from_user);
   $ results in 'scriptbad stuff/script'

=head1 FUNCTIONS

=head2 clean_XSS

   clean_XSS( $string );

Removes angle brackets from the given string. 

=cut


sub clean_XSS {
   my ( $string ) = @_;
   assert_defined($string);
   my $yaml = q{
---
- '<'
- '>'
};
   return String::Clean->new()->clean_by_yaml( $yaml, $string );
}

=head2 convert_XSS

   convert_XSS( $string );

Converts angle brackets to there HTML entities. 

=cut
   
sub convert_XSS {
   my ( $string ) = @_;
   assert_defined($string);
   my $yaml = q{
---
'<' : '&lt;'
'>' : '&gt;'
};
   return String::Clean->new()->clean_by_yaml( $yaml, $string );
}

=head1 AUTHOR

ben hengst, C<< <notbenh at CPAN.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-string-clean at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-Clean>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc String::Clean


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=String-Clean>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/String-Clean>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/String-Clean>

=item * Search CPAN

L<http://search.cpan.org/dist/String-Clean>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2007 ben hengst, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of String::Clean::XSS
