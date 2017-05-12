#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Endpoint::HTTP::Interface::System::Windows;
   
use strict;
use warnings;

use Rex::Endpoint::HTTP::Interface::System::Base;
use base qw(Rex::Endpoint::HTTP::Interface::System::Base);

use Win32::API;

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = $proto->SUPER::new(@_);

   bless($self, $proto);

   return $self;
}

sub get_memory_statistics {
   my ($self) = @_;

   Win32::API::Struct->typedef(
      PPERFORMANCE_INFORMATION => qw{
         DWORD  cb;
         SIZE_T CommitTotal;
         SIZE_T CommitLimit;
         SIZE_T CommitPeak;
         SIZE_T PhysicalTotal;
         SIZE_T PhysicalAvailable;
         SIZE_T SystemCache;
         SIZE_T KernelTotal;
         SIZE_T KernelPaged;
         SIZE_T KernelNonpaged;
         SIZE_T PageSize;
         DWORD  HandleCount;
         DWORD  ProcessCount;
         DWORD  ThreadCount;
      }
   );

   Win32::API->Import( 'psapi',
      'BOOL GetPerformanceInfo(PPERFORMANCE_INFORMATION pPerformanceInformation, DWORD cb)');

   my $pi = Win32::API::Struct->new('PPERFORMANCE_INFORMATION');

   my $mem_info = {};

   if(GetPerformanceInfo($pi, $pi->sizeof)) {
      $mem_info = {
         swap_size => $pi->{CommitLimit} * $pi->{PageSize},
         swap_used => $pi->{CommitTotal} * $pi->{PageSize},
         swap_free => ($pi->{CommitLimit} - $pi->{CommitTotal}) * $pi->{PageSize},
      };
   }
   else {
      die(Win32::FormatMessage(Win32::GetLastError()));
   }


   Win32::API::Struct->typedef(
      MEMORYSTATUSEX => qw{
         DWORD     dwLength;
         DWORD     dwMemoryLoad;
         ULONGLONG ullTotalPhys;
         ULONGLONG ullAvailPhys;
         ULONGLONG ullTotalPageFile;
         ULONGLONG ullAvailPageFile;
         ULONGLONG ullTotalVirtual;
         ULONGLONG ullAvailVirtual;
         ULONGLONG ullAvailExtendedVirtual;
      }
   );

   Win32::API->Import( 'kernel32',
      'BOOL GlobalMemoryStatusEx(LPMEMORYSTATUSEX lpBuffer)' );

   my $ms = Win32::API::Struct->new('MEMORYSTATUSEX');
   $ms->{dwLength} = $ms->sizeof;


   if(GlobalMemoryStatusEx($ms)) {
      $mem_info->{memory_load} = $ms->{dwMemoryLoad};
      $mem_info->{total_memory} = $ms->{ullTotalPhys};
      $mem_info->{avail_memory} = $ms->{ullAvailPhys};
   } else {
      die(Win32::FormatMessage(Win32::GetLastError()));
   }

   return $mem_info;
}

sub set_routes {
   my ($self, $r) = @_;

   $r->post("/os/memory/free")->to("os-windows-memory#free");
   $r->post("/os/memory/max")->to("os-windows-memory#max");
   $r->post("/os/memory/used")->to("os-windows-memory#used");

   $r->post("/os/swap/free")->to("os-windows-swap#free");
   $r->post("/os/swap/max")->to("os-windows-swap#max");
   $r->post("/os/swap/used")->to("os-windows-swap#used");

}

1;
