package String::Normal;
use strict;
use warnings;
our $VERSION = '0.08';

use String::Normal::Type;

sub new {
    my $package = shift;
    my $self = {@_};

    if (!$self->{type} or $self->{type} eq 'business') {
        $self->{normalizer} = String::Normal::Type::Business->new( @_ );
    } elsif ($self->{type} eq 'address') {
        $self->{normalizer} = String::Normal::Type::Address->new( @_ );
    } elsif ($self->{type} eq 'phone') {
        $self->{normalizer} = String::Normal::Type::Phone->new( @_ );
    } elsif ($self->{type} eq 'state') {
        $self->{normalizer} = String::Normal::Type::State->new( @_ );
    } elsif ($self->{type} eq 'city') {
        $self->{normalizer} = String::Normal::Type::City->new( @_ );
    } elsif ($self->{type} eq 'zip') {
        $self->{normalizer} = String::Normal::Type::Zip->new( @_ );
    } elsif ($self->{type} eq 'title') {
        $self->{normalizer} = String::Normal::Type::Title->new( @_ );
    } else {
        die "type $self->{type} is not implemented\n";
    }

    return bless $self, $package;
}

# currently only handles business types
sub transform {
    my ($self,$value,$type) = @_;

    $value = lc( $value );      # lowercase
    $value =~ tr/  //s;         # squeeze multiple spaces to one
    $value =~ s/^ //;           # trim leading space
    $value =~ s/ $//;           # trim trailing space

    # strip out control chars except tabs, lf's, cr's, r single quote, mdash and ndash
    $value =~ s/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x91\x93-\x95\x98-\x9F]//g;

    return $self->{normalizer}->transform( $value );
}

1;

__END__
=head1 NAME

String::Normal - Just another normal form string transformer.

=head1 SYNOPSIS

  use String::Normal;

  my $normalizer = String::Normal->new( type => 'business' );
  print $normalizer->transform( 'Jones & Sons Bakeries' );     # bakeri jone son

  $normalizer = String::Normal->new( type => 'address' );
  print $normalizer->transform( '123 Main Street Suite A47' ); # 123 main st

  $normalizer = String::Normal->new( type => 'phone' );
  print $normalizer->transform( '(818) 423-7750' );            # 8184237750

  $normalizer = String::Normal->new( type => 'city' );
  print $normalizer->transform( 'Los Angeles' );               # los angeles

  $normalizer = String::Normal->new( type => 'state' );
  print $normalizer->transform( 'California' );                # ca

  $normalizer = String::Normal->new( type => 'zip' );
  print $normalizer->transform( '90292' );                     # 90292

=head1 DESCRIPTION

THIS MODULE IS AN ALPHA RELEASE!

Transform strings into a normal form. Performs tokenization, snowball stemming,
stop word removal and complex name compression.

=head1 METHODS

=over 4

=item C<new( %params )>

  my $normalizer = String::Normal->new( %params );

Constructs object. Accepts the following named parameters:

=back

=over 8

=item * C<type>

Available types: business, address, phone, city, state, zip and title.
Defaults to C<business>.

  my $normalizer = String::Normal->new( type => 'title' );

=item * various configuration overides

See L<TYPE CLASSES> for more information.

=back

=over 4

=item C<transform( $word )>

  my $scalar = $normalizer->transform( 'Alien 1979 1080p.avi' );

Normalizes word based on given type.

=back

=head1 TYPE CLASSES

Consider the following values:

    Bary & Sons' Bakery
    Bary's & Sons Bakeries
    Bary's and Sons' Bakeries

These are business names as potentialy found in business listings. 
When each of these values is passed to C<transform()> the return value
will be "bakeri bari son." This is accomplished by a number of transformation
rules, found in the respective C<Type> class.

=over 4

=item * L<String::Normal::Type::Business>

Rules for business name listings, such as "Bary's Bakery".
Provides C<business_stem>, C<business_stop> and C<business_compress> data overides:

  my $normalizer = String::Normal->new( business_stem => '/path/to/stem.txt' );

=item * L<String::Normal::Type::Address>

Rules for business address listings, such as "123 Main Street Suite A".
Provides C<address_stem> and C<address_stop> data overides:

  my $normalizer = String::Normal->new(
      type          => 'address',
      business_stem => '/path/to/stem.txt',
  );

=item * L<String::Normal::Type::City>

Rules for names of cities.

=item * L<String::Normal::Type::State>

Rules for US and Canadian state codes.

=item * L<String::Normal::Type::Zip>

Rules for US and Canadian zip codes.

=item * L<String::Normal::Type::Phone>

Rules for US area and exchange phone codes.
Provides C<area_codes> data overides:

  my $normalizer = String::Normal->new(
      type       => 'phone',
      area_codes => '/path/to/codes.txt',
  );

=item * L<String::Normal::Type::Title>

Rules for movie, film and television show titles.
Provides C<title_stem> and C<title_stop> data overides:

  my $normalizer = String::Normal->new(
      type       => 'title',
      title_stop => '/path/to/stop-words.txt',
  );

=back

The movitation for such transformation is to identify duplicates when combining
multiple digest feeds into a master feed. This transformation (called normalization
here) was designed with the need to identify and match duplicate business listings,
but can be used to match duplicated from other sources as well, such as movie, film
and television show titles.

Each type uses data found in a respective Config class.

=head1 CONFIG CLASSES

=head3 Business

Business values are first compressed, then stemmed via L<Lingua::Stem>
(with customizations) and finally stop worded.

=over 4

=item * L<String::Normal::Config::BusinessStop>

Contains stop words to be removed from business names.

=item * L<String::Normal::Config::BusinessStem>

Stem words are transformed into some normal form, business types
use L<Lingua::Stem> with some customizations.

=item * L<String::Normal::Config::BusinessCompress>

Compress words are combined into one word. Consider:

    Box*Mart
    Box-Mart
    Box Mart
    BoxMart

These are all "compressed" into the value C<boxmart> by specifying
the value C<box-mart> in the compression list.

=back

=head3 Address

Address values are first stemmed with a simple substitution and then finally stop worded.

=over 4

=item * L<String::Normal::Config::AddressStop>

Contains stop words to be removed from addresses.

=item * L<String::Normal::Config::AddressStem>

Transforms into some normal form, but does not use L<Lingua::Stem>.

=back

=head3 Title

Title values are stop worded first, then stemmed via L<Lingua::Stem>.

=over 4

=item * L<String::Normal::Config::TitleStop>

Contains stop words to be removed from titles.

=item * L<String::Normal::Config::TitleStem>

Transforms into some normal form, via L<Lingua::Stem> with no customizations.

=back

=head3 State

=over 4

=item * L<String::Normal::Config::State>

Valide US and Canadian state codes.

=back

=head3 Phone

=over 4

=item * L<String::Normal::Config::AreaCodes>

Valid US area codes.

=back

All Config classes can be overriden by specifying your own
custom text files.

=head1 CLI TOOLS

=over 4

=item * C<normalizer>

Quickly transform values without writing a script:

  $ normalizer --value='Jones & Sons Bakeries'

  $ normalizer --value='Los Angeles' --type='city'

  $ normalizer --file=addresses.txt --type=address

=back

=head1 AUTHOR

Jeff Anderson, C<< <jeffa at cpan.org> >>

=head1 BUGS AND LIMITATIONS

Documentation is currently light and needs to be expanded.

Please report any bugs or feature requests to either:

=over 4

=item * Email: C<bug-string-normal at rt.cpan.org>

=item * Web: L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-Normal>

=back

I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc String::Normal

The Github project is L<https://github.com/jeffa/String-Normal>

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here) L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=String-Normal>

=item * AnnoCPAN: Annotated CPAN documentation L<http://annocpan.org/dist/String-Normal>

=item * CPAN Ratings L<http://cpanratings.perl.org/d/String-Normal>

=item * Search CPAN L<http://search.cpan.org/dist/String-Normal/>

=back

=head1 ACKNOWLEDGEMENTS

The following people contributed algorithms and strategies in addition to the author. Thank you very much! :)

=over 4

=item * Gauthier Groult

=item * Christophe Louvion

=item * Virginie Louvion

=item * Ana Martinez

=item * Ray Toal

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2024 Jeff Anderson.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
