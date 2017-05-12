#
# $Id: Intersplunk.pm,v 927d5bf7d37e 2015/10/03 12:57:38 gomor $
#
package Splunklib::Intersplunk;
use strict;
use warnings;

use base qw(Exporter);
our @EXPORT_OK = qw(readResults outputResults isGetInfo outputGetInfo);

use Data::Dumper;
use Text::CSV_XS;
use URI::Escape;

my $Debug = 0;

#
# Intersplunk format
#
# Converted from /opt/splunk/lib/python2.7/site-packages/splunk/Intersplunk.py
# readResults() and outputResults() function.
#

sub _csv_reader {
   my $csvr = Text::CSV_XS->new({
      binary => 1,
      sep_char => ',',
      #allow_loose_escapes => 1,
   });
   if (! defined($csvr)) {
      # XXX: error handler
      return;
   }

   return $csvr;
}

sub _csv_writer {
   my ($ary, $stdout) = @_;

   my $results = $ary->[0];
   my $header = $ary->[1];
   my $lookup = $ary->[2];

   my $output_debug;
   if ($Debug) {
      open(my $output_debug, '>>', '/tmp/output-ta-base64pl-debug.txt');
   }

   my $csv = Text::CSV_XS->new({
      binary => 1,
      sep_char => ',',
   }) or die "Cannot use CSV: ".Text::CSV->error_diag();

   # Header
   $csv->print($stdout, $header);
   print $stdout "\r\n";
   if ($Debug) {
      $csv->print($output_debug, $header);
      print $output_debug "\r\n";
   }

   # Content
   if ($Debug) {
      for my $result (@$results) {
         $csv->print($stdout, $result);
         print $stdout "\r\n";
         $csv->print($output_debug, $result);
         print $output_debug "\r\n";
      }
   }
   else {
      for my $result (@$results) {
         $csv->print($stdout, $result);
         print $stdout "\r\n";
      }
   }

   return 1;
}

sub getEncodedMV {
   my ($s) = @_;

   # XXX: TODO

   return 1;
}

sub decodeMV {
   my ($s, $vals) = @_;

   # XXX: TODO

   if (! length($s)) {
      return;
   }

   my $tok = '';
   my $inval = 0;

   # XXX: todo
   #my $i = 0;
   #while ($i < length($s)) {
      #if (! $inval) {
         #if (
      #}
   #}

   return 1;
}

#
# Raw intersplunk input example:
#
# splunkVersion:6.2.6
# allowStream:1
# keywords:%22%22%22index%3A%3Alocal_system%22%22%20%22
# search:search%20index%3Dlocal_system%20%7C%20fields%20_raw%20%7C%20base64pl%20field%3D_raw
# sid:1443870176.14
# realtime:0
# preview:0
# truncated:0
#
# "_bkt","_cd","_indextime","_raw","_serial","_si","_sourcetype","_time"
# "local_system~17~5004F7D1-06C9-44F3-A726-29190625C311","17:207",1443870169,"Oct  3 13:02:48 messiah sudo: pam_unix(sudo:session): session closed for user root",0,"messiah
# local_system",syslog,1443870168

sub readResults {
   my ($stdin, $settings, $has_header) = @_;

   $settings ||= {};   # No settings by default
   $has_header ||= 1;  # Header by default

   my $input_debug;
   if ($Debug) {
      open(my $input_debug, '>', '/tmp/input-intersplunk-debug.txt');
   }

   if ($has_header) {
      if ($Debug) {
         while (my $line = <$stdin>) {
            print $input_debug $line;
            chomp($line);
            last if $line =~ /^\s*$/;
            $line = URI::Escape::uri_unescape($line);
            my ($k, $v) = split(/:/, $line);
            $settings->{$k} = $v;
         }
      }
      else {
         while (my $line = <$stdin>) {
            chomp($line);
            last if $line =~ /^\s*$/;
            $line = URI::Escape::uri_unescape($line);
            my ($k, $v) = split(/:/, $line);
            $settings->{$k} = $v;
         }
      }
   }

   my $csvr = _csv_reader();

   my $csvw;
   if ($Debug) {
      $csvw = Text::CSV_XS->new({
         binary => 1,
         sep_char => ',',
      }) or die "Cannot use CSV: ".Text::CSV->error_diag();
   }

   my $results = [];
   my $header = [];
   my $first = 1;
   my @mv_fields = ();
   my $lookup = {};
   while (my $line = $csvr->getline($stdin)) {
      # Activate when $Debug=1
      # Off by default for perf issues.
      #$csvw->print($output_debug, $line);
      #print $output_debug "\r\n";
      if ($first) {
         $header = $line;
         $first = 0;

         # Check which fields are multivalued (for a field 'foo', '__mv_foo' also exists)
         my %h_header = map { $_ => 1 } @$header;
         for my $field (@$header) {
            if (exists($h_header{"__mv_$field"})) {
               push @mv_fields, $field;
            }
         }

         next;
      }

      # We must maintain field order
      my $pos = 0;
      for my $hdr (@$header) {
         $lookup->{$hdr} = $pos;
         $pos++;
      }
      my $result = $line;

      for my $key (@mv_fields) {
         my $mv_key = "__mv_$key";
         if (exists($result->[$lookup->{$key}]) && exists($result->[$lookup->{$mv_key}])) {
            # Expand the value of __mv_[key] to a list, store it in key, and delete __mv_[key]
            my $vals = [];
            if (decodeMV($result->[$lookup->{$mv_key}], $vals)) {
               #$result{$key} = $vals;
               #if (@{$result{$key}} == 1) {
                  #$result{$key} = $result{$key}->[0];
               #}
               #delete $result{$mv_key};
               # XXX: todo
            }
         }
      }

      push @$results, $result;
   }

   return [ $results, $header, $lookup ];
}

sub isGetInfo {
   my ($args) = @_;

   if (@$args >= 1 && $args->[0] eq '__GETINFO__') {
      shift @$args;  # Strip it
      return 1;
   }
   elsif (@$args >= 1 && $args->[0] eq '__EXECUTE__') {
      shift @$args;  # Strip it
      return 0;
   }
   else {
      # XXX: error handling
      exit(0);
   }

   return 0;
}

sub outputGetInfo {
   my ($settings, $stdout) = @_;

   # Below is the correct field order to use.
   # We currently don't follow on the output, but it seems to be ok.
   $settings ||= {
      changes_colorder => 1,
      clear_required_fields => 0,
      enableheader => 1,
      generating => 0,
      local => 0,
      maxinputs => 0,
      needs_empty_results => 1,
      outputheader => 1,
      overrides_timeorder => 0,
      passauth => 0,
      perf_warn_limit => 0,
      required_fields => '',
      requires_srinfo => 0,
      retainsevents => 1,
      run_in_preview => 1,
      stderr_dest => 'log',
      streaming => 1,
      supports_multivalues => 1,
      supports_rawargs => 1,
      __mv_changes_colorder => '',
      __mv_clear_required_fields => '',
      __mv_enableheader => '',
      __mv_generating => '',
      __mv_local => '',
      __mv_maxinputs => '',
      __mv_needs_empty_results => '',
      __mv_outputheader => '',
      __mv_overrides_timeorder => '',
      __mv_passauth => '',
      __mv_perf_warn_limit => '',
      __mv_required_fields => '',
      __mv_requires_srinfo => '',
      __mv_retainsevents => '',
      __mv_run_in_preview => '',
      __mv_stderr_dest => '',
      __mv_streaming => '',
      __mv_supports_multivalues => '',
      __mv_supports_rawargs => '',
   };

   my $header = '';
   my $values = '';
   for my $k (sort { $a cmp $b } keys %$settings) {
      $header .= "$k,";
      $values .= $settings->{$k}.",";
   }
   $header =~ s/,$//;
   $values =~ s/,$//;

   print $stdout "\r\n";
   print $stdout "$header\r\n";
   print $stdout "$values\r\n";

   return 1;
}

sub outputResults {
   my ($ary, $messages, $fields, $mvdelim, $stdout) = @_;

   $mvdelim ||= '\n';

   my $results = $ary->[0];
   my $header = $ary->[1];
   my $lookup = $ary->[2];

   #
   # Example message header
   #
   # $messages = {
   #    streaming_preop' => '0',
   #    streaming' => '0',
   #    generating' => '0',
   #    retainsevents' => '0',
   #    requires_preop' => '0',
   #    generates_timeorder' => '0',
   #    overrides_timeorder' => '0',
   #    clear_required_fields' => '0',
   # };

   if (defined($messages)) {
      # message header is everything before the first empty line, similar to the input
      # header format.  also key = value, with stripping of whitespace
      for my $level (sort { $a <=> $b } keys %$messages) {
         print $stdout $level."=".$messages->{$level}."\r\n";
      }
      print $stdout "\r\n";
   }

   if (@$results == 0) {
      return;
   }

   my $s = {};
   my $l = [];
   # Check each entry to see if it is a list (multivalued).
   # If so, set the multivalued key to the proper encoding.
   # Replace the list with a newline separated string of the values.
   for my $result (@$results) {
      #for my $key (keys %$result) {
      for my $key (@$result) {
         # XXX: todo
         #if (ref($result->{$key}) eq 'ARRAY') {
            #$result->{"__mv_$key"} = getEncodedMV($result->{$key});
            #$result->{$key} = join($mvdelim, @{$result->{$key}});
         #}

         #if (! exists($s->{$key})) {
            #$s->{$key} = 1;
            #push @$l, $key;
         #}
      }
   }

   my $h;
   if (! $fields) {
      $h = $header;
   }
   else {
      $h = $fields;
   }

   _csv_writer($ary, $stdout);

   return 1;
}

1;

__END__

=head1 NAME

Splunklib::Intersplunk - parse the Intersplunk format

=head1 SYNOPSIS

   use Splunklib::Intersplunk qw(readResults outputResults);

=head1 DESCRIPTION

Read and writes the Intersplunk format.

=head2 METHODS

=over 4

=item B<readResults>

=item B<outputResults>

=item B<decodeMV>

=item B<getEncodedMV>

=item B<isGetInfo>

=item B<outputGetInfo>

=back

=head1 SEE ALSO

L<Splunklib>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
