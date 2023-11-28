##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN/Mirrors.pm
## Version v0.1.0
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/07/25
## Modified 2023/11/24
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
# This module file has been automatically generated. Any change made here will be lost.
# Edit the script in ./build/build_modules.pl instead
package Net::API::CPAN::Mirrors;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::CPAN::Generic );
    use vars qw( $VERSION );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{mirrors} = [] unless( CORE::exists( $self->{mirrors} ) );
    $self->{object}  = 'mirrors';
    $self->{took}    = undef unless( CORE::exists( $self->{took} ) );
    $self->{total}   = undef unless( CORE::exists( $self->{total} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'Net::API::CPAN::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{fields} = [qw( mirrors took total )];
    return( $self );
}

sub mirrors { return( shift->_set_get_object_array_object( 'mirrors', 'Net::API::CPAN::Mirror', @_ ) ); }

sub object { return( shift->_set_get_scalar_as_object( 'object', @_ ) ); }

sub took { return( shift->_set_get_number( 'took', @_ ) ); }

sub total { return( shift->_set_get_number( 'total', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::CPAN::Mirrors - Meta CPAN API Mirrors Class

=head1 SYNOPSIS

    use Net::API::CPAN::Mirrors;
    my $obj = Net::API::CPAN::Mirrors->new( {
      mirrors => [
        {
          ccode => "zz",
          city => "Everywhere",
          contact => [
            {
              contact_site => "perl.org",
              contact_user => "cpan",
            },
          ],
          continent => "Global",
          country => "Global",
          distance => undef,
          dnsrr => "N",
          freq => "instant",
          http => "http://www.cpan.org/",
          inceptdate => "2021-04-09T00:00:00",
          location => [
            0,
            0,
          ],
          name => "www.cpan.org",
          org => "Global CPAN CDN",
          src => "rsync://cpan-rsync.perl.org/CPAN/",
          tz => 0,
        },
      ],
      took => 2,
      total => 1,
    } ) || die( Net::API::CPAN::Mirrors->error );
    
    my $array = $obj->mirrors;
    my $str = $obj->object;
    my $num = $obj->took;
    my $num = $obj->total;

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class serves to retrieve and manipulate mirrors.

It inherits from L<Net::API::CPAN::Generic>

=head1 CONSTRUCTOR

=head2 new

Provided with an hash or hash reference of parameters, and this instantiates a new C<Net::API::CPAN::Mirrors> object.

The parameters that can be provided bear the same name and supports the same values as the methods below.

=head1 METHODS

=head2 mirrors

    $obj->mirrors( [
      {
        ccode => "zz",
        city => "Everywhere",
        contact => [
          {
            contact_site => "perl.org",
            contact_user => "cpan",
          },
        ],
        continent => "Global",
        country => "Global",
        distance => undef,
        dnsrr => "N",
        freq => "instant",
        http => "http://www.cpan.org/",
        inceptdate => "2021-04-09T00:00:00",
        location => [
          0,
          0,
        ],
        name => "www.cpan.org",
        org => "Global CPAN CDN",
        src => "rsync://cpan-rsync.perl.org/CPAN/",
        tz => 0,
      },
    ] );
    my $array = $obj->mirrors;

Sets or gets an array of L<Net::API::CPAN::Mirror> objects, or creates an L<Net::API::CPAN::Mirror> instance for each mirrors provided in the array, and returns an L<array object|Module::Generic::Array>, even if no value was provided.

=head2 object

Returns the object type for this class, which is C<mirrors>

=head2 took

    $obj->took(2);
    my $number = $obj->took;

Sets or gets an integer value, and returns a L<number object|Module::Generic::Number> or C<undef> if no value is set.

=head2 total

    $obj->total(1);
    my $number = $obj->total;

Sets or gets an integer value, and returns a L<number object|Module::Generic::Number> or C<undef> if no value is set.

=head1 API SAMPLE

    {
       "mirrors" : [
          {
             "ccode" : "zz",
             "city" : "Everywhere",
             "contact" : [
                {
                   "contact_site" : "perl.org",
                   "contact_user" : "cpan"
                }
             ],
             "continent" : "Global",
             "country" : "Global",
             "distance" : null,
             "dnsrr" : "N",
             "freq" : "instant",
             "http" : "http://www.cpan.org/",
             "inceptdate" : "2021-04-09T00:00:00",
             "location" : [
                0,
                0
             ],
             "name" : "www.cpan.org",
             "org" : "Global CPAN CDN",
             "src" : "rsync://cpan-rsync.perl.org/CPAN/",
             "tz" : "0"
          }
       ],
       "took" : 2,
       "total" : 1
    }

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Net::API::CPAN>, L<Net::API::CPAN::Activity>, L<Net::API::CPAN::Author>, L<Net::API::CPAN::Changes>, L<Net::API::CPAN::Changes::Release>, L<Net::API::CPAN::Contributor>, L<Net::API::CPAN::Cover>, L<Net::API::CPAN::Diff>, L<Net::API::CPAN::Distribution>, L<Net::API::CPAN::DownloadUrl>, L<Net::API::CPAN::Favorite>, L<Net::API::CPAN::File>, L<Net::API::CPAN::Module>, L<Net::API::CPAN::Package>, L<Net::API::CPAN::Permission>, L<Net::API::CPAN::Rating>, L<Net::API::CPAN::Release>

L<MetaCPAN::API>, L<MetaCPAN::Client>

L<https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2023 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

