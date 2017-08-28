# Copyright 2016 The Michael Song. All rights rberved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

package Spp::Tools;

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(to_json from_json error count
  start_with end_with rev_str first tail rest subarray
  trim read_file write_file len to_trace_str);

use 5.012;
no warnings "experimental";
use JSON::XS qw(encode_json decode_json);
use Spp::IsAtom;

sub to_json { 
  my $data = shift;
  if (is_chars($data)) {
    my $json_str = encode_json([$data]);
    return substr($json_str, 1, -1);
  } 
  return encode_json($data);
}

sub from_json { return decode_json(shift) }

sub error { say @_; exit() }

sub first {
  my $data = shift;
  if (is_chars($data)) { return substr($data, 0, 1) }
  if (is_array($data)) { return $data->[0] }
  error("could not first($data)");
}

sub tail {
  my $data = shift;
  if (is_chars($data)) { return substr($data, -1) }
  if (is_array($data)) { return $data->[-1] }
  error("Could not tail($data)");
}

sub rest {
   my $data = shift;
   return substr($data, 1) if is_chars($data);
   if (is_array($data)) {
     my $len_data = len($data);
     # copy $data, splice would change array
     my @array = @{$data};
     return [ splice(@array, 1, $len_data) ];
   }
   error("rest only could do str or array");
}

sub subarray {
  my ($array, $from, $to) = @_;
  # make copy of $array, splice would change it
  my @array = @{$array};
  if (is_array($array)) {
    if ($to < 0) {
      my $len = len($array) + $to - $from + 1;
      my $sub_array = [ splice @array, $from, $len ];
      return $sub_array;
    }
    return [ splice @array, $from, $to ];
  }
  error("subarray only could process array");
}

sub count {
   my ($str, $char) = @_;
   my @array = ($str =~ /$char/g);
   return scalar(@array);
}

sub start_with {
   my ($str, $start) = @_;
   return 1 if index($str, $start) == 0;
   return 0;
}

sub end_with {
   my ($str, $end) = @_;
   return start_with(rev_str($str), rev_str($end));
}

sub rev_str {
   my $str = shift;
   return scalar(reverse($str));
}

sub trim {
   my $str = shift;
   if (is_chars($str)) {
      $str =~ s/^\s+|\s+$//g;
      return $str;
   }
   my $str_json = str($str);
   error("! trim only make string: $str_json");
}

sub read_file {
   my $file = shift;
   error("file: $file not exists") if not -e $file;
   local $/;
   open my ($fh), '<:utf8', $file or die $!;
   return <$fh>;
}

sub write_file {
   my ($file, $str) = @_;
   open my ($fh), '>:utf8', $file or die $!;
   print {$fh} $str;
   return $file;
}

sub len {
   my $data = shift;
   return scalar(@{$data}) if is_array($data);
   return length($data) if is_chars($data);
}

sub to_trace_str {
   my ($str, $n) = @_;
   $str = rev_str($str);
   my @buf = ();
   for my $ch (split('', $str)) {
      given ($ch) {
         when ("\n") { push @buf, 'n\\' }
         when ("\r") { push @buf, 'r\\' }
         when ("\t") { push @buf, 't\\' }
         default     { push @buf, $ch }
      }
   }
   $str = join('', @buf);
   my $len = len($str);
   if ($len > $n) {
      $str = substr($str, 0, $n);
   }
   elsif ($len < $n) {
      $str = (' ' x ($n - $len)) . $str;
   }
   return rev_str($str);
}

=head1 AUTHOR

Michael Song, C<< <10435916 at qq.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-spp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Spp>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Spp::Tools

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Spp>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Spp>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Spp>

=item * Search CPAN

L<http://search.cpan.org/dist/Spp/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Michael Song.

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

1;
