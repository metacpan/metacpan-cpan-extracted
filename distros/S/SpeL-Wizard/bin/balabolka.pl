#!/usr/bin/perl -w
# -*- cperl -*-
# PODNAME: balabolka.pl
# ABSTRACT: script converting textfile named $1
   #                               into file $2
#                          with engine:voice $3
#           using balabolka

use v5.32;
use IO::File;
use IPC::Run;

# Check arguments
die( "Usage: $0 <input_text_file> <output_audio_file> <voice>\n" )
  unless( 3 == @ARGV );

my ( $textfilename, $audiofilename, $voice ) = @ARGV;

# Run balabolka, run!
my $command = [ "balabolka.exe",
		"-mqs",
		$textfilename,
		$audiofilename,
		$voice ];
my $out;
IPC::Run::run( $command, '>', \$out );
exit( $? );

__END__

=pod

=encoding UTF-8

=head1 NAME

balabolka.pl - script converting textfile named $1

=head1 VERSION

version 20241023.0918

=head1 AUTHOR

Walter Daems <wdaems@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Walter Daems.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=head1 CONTRIBUTOR

=for stopwords Paul Levrie

Paul Levrie

=cut
