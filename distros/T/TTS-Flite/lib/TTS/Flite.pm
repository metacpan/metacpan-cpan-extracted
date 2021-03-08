package TTS::Flite;

use Mouse;
use utf8;
use Kavorka -all;
use FFI::Raw;

our $VERSION = '0.04';

my $flite = 'libflite.so.1';
my $kal16 = 'libflite_cmu_us_kal16.so.1';


my $flite_init = FFI::Raw->new( $flite, 'flite_init', FFI::Raw::void);
my $flite_tts = FFI::Raw->new( $flite, 'flite_text_to_speech', FFI::Raw::float, FFI::Raw::str, FFI::Raw::ptr,  FFI::Raw::str);
my $register_cmu_us_kal16 = FFI::Raw->new( $kal16, 'register_cmu_us_kal16', FFI::Raw::ptr);

method init() {
	$register_cmu_us_kal16->call();
	$flite_init->call();
}

method tts($string) {
	$flite_tts->call($string, $register_cmu_us_kal16->call(), 'play' );
}



1;
__END__

=head1 NAME

TTS::Flite - Perl extension for blah blah blah

=head1 SYNOPSIS

  use TTS::Flite;

  my $flite = TTS::Flite->new();

  $flite->init();  # call it only once, before calling tts.

  $flite->tts("Some string");
  $flite->tts("Some other string");

=head1 DESCRIPTION

  You need to install flite before using this module. on ubuntu you can do this by `sudo apt install libflite1`


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Rajkumar Reddy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
