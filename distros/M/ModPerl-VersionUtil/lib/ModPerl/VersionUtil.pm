#$Id: VersionUtil.pm,v 1.3 2006/01/17 01:36:51 naoya Exp $
package ModPerl::VersionUtil;
use strict;
use warnings;
use base qw/Class::Data::Inheritable/;

our $VERSION = '0.03';

BEGIN {
    __PACKAGE__->mk_classdata($_)
        for qw/mp_version mp_version_string is_mp is_mp1 is_mp19 is_mp2/;

    if (my $version = $ENV{MOD_PERL}) {
        # Note: This environment variable could be set in an external script called from mod_perl,
        # so don't presume we are in mod_perl just yet.

        ($version) = $version =~ /^\S+\/(\d+(?:[\.\_]\d+)+)/;
        __PACKAGE__->mp_version_string($version);

        $version =~ s/_//g;
        $version =~ s/(\.[^.]+)\./$1/g;
        __PACKAGE__->mp_version($version);

        if ($ENV{MOD_PERL_API_VERSION} && $ENV{MOD_PERL_API_VERSION} == 2 && exists $INC{'Apache2/RequestRec.pm'}) {
            __PACKAGE__->is_mp(1);
            __PACKAGE__->is_mp2(1)
        } elsif (exists $INC{'Apache.pm'}) {
            __PACKAGE__->is_mp(1);
            if ( $version >= 1.9901 ) {
                __PACKAGE__->is_mp19(1);
            } elsif ( $version >= 1.24 ) {
                __PACKAGE__->is_mp1(1);
            }
        }
    }
}

1;

__END__

=head1 NAME

ModPerl::VersionUtil - Makes it easier to investigate your mod_perl
version.

=head1 SYNOPSIS

  use ModPerl::VersionUtil;

  if (ModPerl::VersionUtil->is_mp) {
    print "It's running under mod_perl.";
    print "mod_perl version: " . ModPerl::VersionUtil->mp_version_string;
  }

  if (ModPerl::VersionUtil->is_mp2) {
    require Apache2 ();
    require Apache2::RequestRec();
    require Apache2::RequestIO ();
  } elsif (ModPerl::VersionUtil->is_mp19) {
    require Apache2;
    require Apache::RequestRec();
    require Apache::RequestIO ();
  } elsif (ModPerl::VersionUtil->is_mp1) {
    require Apache;
  }

=head1 DESCRIPTION

This module helps you to investigate your mod_perl version easily.

=head1 METHODS

=over 4

=item is_mp

Returns true if your application is running under mod_perl.

=item is_mp1

Returns true if your mod_perl version is 1.0.

=item is_mp19

Returns true if your mod_perl version is 1.9 which is incompatible
with 2.0.

=item is_mp2

Returns true if your mod_perl version is 2.0 or higher.

=item mp_version

Returns your mod_perl version as number. (e.g. '1.99920')

=item mp_version_string

Returns your mod_perl version as string. (e.g. '1.999.20')

=head1 ACKNOWLEDGEMENTS

Craig Manley E<lt>CMANLEY@cpan.orgE<gt> gave me a code to handle an
external scripts correctly.

=head1 AUTHOR

Naoya Ito, E<lt>naoya@bloghackers.netE<gt>

Some codes are borrowed from the L<Catalyst> web application framework
which can handle any versions of mod_perl elegantly.

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
