package Test::Net::SAML2;
use strict;
use warnings;
use namespace::autoclean ();

use Test::Lib;

# ABSTRACT: Test module for Net::SAML2

use Import::Into;

use Path::Tiny ();
use Sub::Override ();

use Test::Deep ();
use Test::Exception ();
use Test::Fatal ();
use Test::More ();
use Test::Net::SAML2::Util ();

sub import {

    my $caller_level = 1;

    my @imports = qw(
        Path::Tiny
        Sub::Override
        Test::Deep
        Test::Exception
        Test::Fatal
        Test::More
        Test::Net::SAML2::Util
        namespace::autoclean
        strict
        warnings
    );

    $_->import::into($caller_level) for @imports;
}

1;

__END__


=head1 DESCRIPTION

Main test module for Net::SAML2

=head1 SYNOPSIS

  use Test::Lib;
  use Test::Net::SAML2;

  # tests here

  ...;

  done_testing();
