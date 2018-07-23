#
# $Id: Ubigraph.pm,v 008243d3e89a 2018/07/21 14:54:07 gomor $
#
package Net::SinFP3::Output::Ubigraph;
use strict;
use warnings;

use base qw(Net::SinFP3::Output);
our @AS = qw(
   file
   _data
   _ug
   _nodes
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Data::Dumper;
# Make it optional
eval("use Frontier::Client;");

sub new {
   my $self = shift->SUPER::new(
      @_,
   );

   my $global = $self->global;
   my $log    = $global->log;

   if (!defined($self->file)) {
      $log->fatal("You must provide file attribute");
   }

   return $self;
}

sub _parseCsvFile {
   my $self = shift;
   my ($fd) = @_;

   my $data = {};
   while (my $line = <$fd>) {
      chomp($line);
      my @toks   = split(';', $line);
      my $next   = $toks[0];
      my $ip     = $toks[1];
      my $port   = $toks[2];
      my $nOs    = $toks[3];
      my $osList = $toks[4];
      $data->{$ip}->{$port} = { ip => $ip, port => $port, nOs => $nOs, osList => $osList };
   }

   return $data;
}

my %Colors = (
   'Linux'   => "#00ff00",  # Green
   'Windows' => "#0000ff",  # Blue
   'FreeBSD' => "#ff0000",  # Red
   'OpenBSD' => "#ff0000",  # Red
   'NetBSD'  => "#ff0000",  # Red
   'Darwin'  => "#ffff00",  # Yellow
   'SunOS'   => "#ff00ff",  # Violet
);

sub run {
   my $self = shift->SUPER::run(@_) or return;

   my $global  = $self->global;
   my $log     = $global->log;
   my @results = $global->result;

   # Read file and create structure
   open(my $in, '<', $self->file)
      or $log->fatal("Cannot open file: ".$self->file);
   my $data = $self->_parseCsvFile($in);
   $self->_data($data);
   close($in);

   print Dumper($data),"\n";

   # Prepare Ubigraph API
   my $ug = Frontier::Client->new(url => 'http://127.0.0.1:20738/RPC2');

   # Clean env
   $ug->call('ubigraph.clear');

   # The scanning host
   my $me = $ug->call('ubigraph.new_vertex');
   $ug->call('ubigraph.set_vertex_attribute', $me, shape => "sphere");
   $ug->call('ubigraph.set_vertex_attribute', $me, color => "#ffffff");
   $ug->call('ubigraph.set_vertex_attribute', $me, label => "sinfp3");
   $ug->call('ubigraph.set_vertex_attribute', $me, size  => "1.0 ");

   my $count = -1;
   my $done  = 0;
   my $prevIp;
   my $firstIp;
   my $lastIp;
   for my $ip (keys %$data) {
      my $newIp = $ug->call('ubigraph.new_vertex');
      $ug->call('ubigraph.set_vertex_attribute', $newIp, shape    => "cube");
      $ug->call('ubigraph.set_vertex_attribute', $newIp, color    => "#ffffff");
      $ug->call('ubigraph.set_vertex_attribute', $newIp, label    => $ip);
      $ug->call('ubigraph.set_vertex_attribute', $newIp, fontsize => "6 ");
      $ug->call('ubigraph.set_vertex_attribute', $newIp, size     => "1.0 ");

      if (! $done) {
         $ug->call('ubigraph.new_edge', $me, $newIp);
         $done++;
      }

      if (! $prevIp) {
         $firstIp = $newIp;
      }
      if ($prevIp) {
         $ug->call('ubigraph.new_edge', $prevIp, $newIp);
      }
      $prevIp = $newIp;
      $lastIp = $newIp;

      for my $port (keys %{$data->{$ip}}) {
         my $os    = $data->{$ip}->{$port}->{osList};
         my $color = $Colors{$os};
         if ($data->{$ip}->{$port}->{nOs} > 1) {
            $os    = 'Unknown';
            $color = "#ffffff";
         }
         my $newPort = $ug->call('ubigraph.new_vertex');
         $ug->call('ubigraph.set_vertex_attribute', $newPort, shape    => "octahedron");
         $ug->call('ubigraph.set_vertex_attribute', $newPort, color    => $color);
         $ug->call('ubigraph.set_vertex_attribute', $newPort, label    => "$port/tcp");
         $ug->call('ubigraph.set_vertex_attribute', $newPort, fontsize => "3 ");
         $ug->call('ubigraph.set_vertex_attribute', $newPort, size     => "0.5 ");

         $ug->call('ubigraph.new_edge', $newIp, $newPort);
      }
   }

   $ug->call('ubigraph.new_edge', $firstIp, $lastIp);

   return 1;
}

1;

__END__

=head1 NAME

Net::SinFP3::Output::Ubigraph - plugin to display results using Ubigraph

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
