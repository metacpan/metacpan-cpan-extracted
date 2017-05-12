#! /usr/bin/perl
#---------------------------------------------------------------------
# 10-basic.t
# Copyright 2013 Christopher J. Madsen
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Test Pod::Weaver::Section::AllowOverride
#---------------------------------------------------------------------

use 5.010;
use strict;
use warnings;

use Test::More 0.88;            # done_testing

plan tests => 9;

use File::Temp 0.19;            # newdir
use File::Spec::Functions qw(catfile);

use PPI;
use Pod::Elemental::Document;
use Pod::Weaver;

my $tmpdir = File::Temp->newdir;

my $perl_document = <<'END PERL';
package Module_Name;
# ABSTRACT: abstract text
END PERL

#---------------------------------------------------------------------
sub open_ini_for_writing
{
  open(my $out, '>', catfile($tmpdir->dirname, 'weaver.ini')) or die $!;
  return $out;
} # end open_ini_for_writing

#---------------------------------------------------------------------
sub write_ini
{
  my $out = open_ini_for_writing;

  local $" = "\n";

  print $out <<"END CONFIG";
[\@CorePrep]
[Name]
[Version]
[AllowOverride / VERSION]
@_
[Authors]
END CONFIG

  close $out;
} # end write_ini

#---------------------------------------------------------------------
sub write_ini2
{
  my $out = open_ini_for_writing;

  local $" = "\n";

  print $out <<"END CONFIG";
[\@CorePrep]
[Name]
[Version]
[Authors]
[AllowOverride / VERSION]
@_
END CONFIG

  close $out;
} # end write_ini2

#---------------------------------------------------------------------
sub weave_pod
{
  my ($pod) = @_;

  my $ppi_document = PPI::Document->new(\$perl_document);

  my $document = Pod::Elemental->read_string($pod);

  my $weaver = Pod::Weaver->new_from_config({root => $tmpdir->dirname});

  return $weaver->weave_document({
    pod_document => $document,
    ppi_document => $ppi_document,

    version  => '1.234',
    authors  => [
      'E. Xavier Ample <example@example.org>',
    ],
  })->as_pod_string;
} # end weave_pod

#=====================================================================
write_ini();

my $pod = weave_pod('');

my ($header, $default_version, $footer) =
    ($pod =~ /\A(.*)^=head1 VERSION\n+(.+?)\s*^(=.+)\z/ms)
    or die "VERSION not found";

my $hRE = qr/\A\Q$header\E\s*/;
my $fRE = qr/\s*\Q$footer\E\z/;

my $input_body = "This section is overridden.\n";
my $input_head = "=head1 VERSION\n";
my $input      = "$input_head\n$input_body";

#---------------------------------------------------------------------
$pod = weave_pod($input);

like($pod, qr/$hRE\Q$input\E$fRE/, "VERSION overridden");

#---------------------------------------------------------------------
write_ini('match_anywhere = 1');

$pod = weave_pod($input);

like($pod, qr/$hRE\Q$input\E$fRE/, "VERSION overridden (match_anywhere)");

#---------------------------------------------------------------------
write_ini('action = append');

$pod = weave_pod($input);

like($pod, qr/$hRE \Q$input_head\E \s+
              \Q$default_version\E \s+ \Q$input_body\E $fRE/x,
     "VERSION appended");

#---------------------------------------------------------------------
write_ini('action = append', 'match_anywhere = 1');

$pod = weave_pod($input);

like($pod, qr/$hRE \Q$input_head\E \s+
              \Q$default_version\E \s+ \Q$input_body\E $fRE/x,
     "VERSION appended (match_anywhere)");

#---------------------------------------------------------------------
write_ini('action = prepend');

$pod = weave_pod($input);

like($pod, qr/$hRE \Q$input_head\E \s+
              \Q$input_body\E \s+ \Q$default_version\E $fRE/x,
     "VERSION prepended");

#---------------------------------------------------------------------
write_ini('action = prepend', 'match_anywhere = 1');

$pod = weave_pod($input);

like($pod, qr/$hRE \Q$input_head\E \s+
              \Q$input_body\E \s+ \Q$default_version\E $fRE/x,
     "VERSION prepended (match_anywhere)");

#---------------------------------------------------------------------
write_ini2('match_anywhere = 1');

$pod = weave_pod($input);

like($pod, qr/$hRE\Q$input\E$fRE/, "VERSION overridden (not previous)");

#---------------------------------------------------------------------
write_ini2('action = append', 'match_anywhere = 1');

$pod = weave_pod($input);

like($pod, qr/$hRE \Q$input_head\E \s+
              \Q$default_version\E \s+ \Q$input_body\E $fRE/x,
     "VERSION appended (not previous)");

#---------------------------------------------------------------------
write_ini2('action = prepend', 'match_anywhere = 1');

$pod = weave_pod($input);

like($pod, qr/$hRE \Q$input_head\E \s+
              \Q$input_body\E \s+ \Q$default_version\E $fRE/x,
     "VERSION prepended (not previous)");

#---------------------------------------------------------------------
done_testing;
