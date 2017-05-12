package Sys::Protect;

our $VERSION;
use Carp qw(confess);

our %allowed;
BEGIN {
  for (qw(
         Time::HiRes
         version
         Cwd
         Data::Dumper
         Digest::MD5
         Digest::SHA
         Encode
         Hash::Util
         I18N::Langinfo
         List::Util
         Mime::Base64
         Math::BigInt::FastCalc
         Storable
        )) {

    $allowed{$_}++;
  }
# re?
};

BEGIN {
  require XSLoader;
  $VERSION = '0.02';
  XSLoader::load('Sys::Protect', $VERSION);
  no warnings 'redefine';
  my $xsloader_load_orig = \&XSLoader::load;
  my $dynaloder_bootstrap_orig = \&DynaLoader::bootstrap;


  *XSLoader::load = sub {
    if ( $allowed{$_[0]} ) {
      $xsloader_load_orig->(@_);
    } else {
      confess "Not allowed to load $_[0]";
    }
  };

  *DynaLoader::bootstrap = sub {
    if ( $allowed{$_[0]} ) {
      $dynaloder_bootstrap_orig->(@_);
    } else {
      confess "Not allowed to bootstrap $_[0]";
    }
  };
};

use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use 5.008;
use strict;
use warnings;

{
use Exporter ();
@ISA         = qw(Exporter);
}


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Sys::Protect - deny a bunch of opcodes

=head1 SYNOPSIS

  use Sys::Protect;

=head1 ABSTRACT

=head1 DESCRIPTION

=head1 AUTHOR

Artur Bergman, E<lt>sky@crucially.netE<gt>

Brad Fitzpatrick, E<lt>brad@danga.comE<gt>

Various other people at NPW 2004 helped with ideas and suggestions.

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Artur Bergman

Copyright 2008 by Artur Bergman, Brad Fitzpatrick

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
