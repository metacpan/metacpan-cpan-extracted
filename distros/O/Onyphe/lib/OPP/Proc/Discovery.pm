#
# $Id: Discovery.pm,v 69a3d7308875 2023/04/05 15:11:02 gomor $
#
package OPP::Proc::Discovery;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

use utf8;
use Onyphe::Api;
use File::Temp qw(tempfile);

our $VERSION = '1.00';

my $oa = Onyphe::Api->new->init or die("discovery: init failed");
$oa->silent(1);
$oa->verbose(0);

#
# NOTE: datascan category by default
#
# | discovery
# | discovery category:vulnscan
# | discovery category:datascan tag:open device.class:database
#
sub process {
   my $self = shift;
   my ($input) = @_;

   my $options = $self->options;
   my $category = $options->{category}[0] || 'datascan';
   my $oql;
   if (defined($options->{args})) {
      $oql = $options->{args};
      $oql =~ s{category\s*:\s*(\S+)\s*}{}g;  # Remove category if given
   }

   my ($fh, $filename) = tempfile();
   for my $field (keys %$input) {
      my $value = $input->{$field};
      $value =~ s{"}{\\"}g;
      my $print = "$field:\"$value\"";
      if (defined($oql)) {
         $print .= " $oql";
      }
      utf8::encode($print);
      print $fh "$print\n";
   }
   close($fh);

   #print STDERR "tempfile [$filename]\n";

   my $cb = sub {
      my ($results) = @_;
      for (@$results) {
         next if m{.\@category.\s*:\s*.none.};
         my $docs = $self->from_json($_);
         $docs = $self->flatten($docs);
         $self->output->add($docs);
      }
   };

   $oa->bulk_discovery($category, $filename, undef, { trackquery => 'true' }, $cb);

   unlink($filename) if -f $filename;

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Discovery - ONYPHE Discovery API processor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2023, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
