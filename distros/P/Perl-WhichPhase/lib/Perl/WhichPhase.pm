package Perl::WhichPhase;

use strict;
use vars qw: $VERSION @ISA @EXPORT_OK %EXPORT_TAGS :;

$VERSION = "0.01";

@ISA = qw: Exporter :;

@EXPORT_OK = qw"
  block
  in_BEGIN
  in_INIT
  in_END
  in_CHECK
  in_CODE
";

%EXPORT_TAGS = (
  in => [ qw: in_BEGIN in_INIT in_END in_CHECK in_CODE : ],
);

sub block () {
  my($i, $b, $subroutine) = 1;
  while($subroutine = (caller($i++))[3]) {
    $b = (split(/::/, $subroutine))[-1];
    return $b if($b eq 'BEGIN' || $b eq 'END' || $b eq 'INIT' || $b eq 'CHECK');
  }
  return;
}

sub in_BEGIN () { return block eq 'BEGIN'; }
sub in_INIT  () { return block eq 'INIT'; }
sub in_END   () { return block eq 'END'; }
sub in_CHECK () { return block eq 'CHECK'; }
sub in_CODE  () { return !defined block; }

1;

__END__

=head1 NAME

Perl::WhichPhase

=head1 SYNOPSIS

 use Perl::WhichPhase qw- :in block -;

 if(block eq 'BEGIN') {
   print "We are in a BEGIN block\n";
 }

 if(in_END) {
   print "We are finishing up\n";
 }

=head1 DESCRIPTION

This module allows determination of the phase the Perl compiler and
interpreter are in, one of BEGIN, INIT, END, or CHECK, or C<undef>ined if
none of the four apply.

=head1 METHODS

All of the functions listed here are importable.  The import tag C<:in> may
be used to name all the functions beginning with C<in_>.

=over 4

=item block

This will return one of the four strings BEGIN, INIT, END, or CHECK if Perl
is current running that phase.  If Perl is not running one of those phases,
then this will return C<undef>.

=item in_BEGIN

This will return true of the code is being run in a BEGIN block.

=item in_CHECK

This will return true of the code is being run in a CHECK block.

=item in_CODE

This will return true if the code is not being run in any of the four phases.

=item in_END

This will return true of the code is being run in an END block.

=item in_INIT

This will return true of the code is being run in an INIT block.

=back 4

=head1 AUTHOR

James G. Smith <jsmith@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2002 Texas A&M University.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
