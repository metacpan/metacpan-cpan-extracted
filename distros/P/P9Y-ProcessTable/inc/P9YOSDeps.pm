package inc::P9YOSDeps;
use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_WriteMakefile_dump => sub {
   my ($self) = @_;
   my $txt = super();

   $txt =~ s/([\'\"]?PREREQ_PM[\'\"]? => \{)/$1\n    &os_deps,/g;

   return $txt;
};

override _build_MakeFile_PL_template => sub {
   my ($self) = @_;
   my $template = super();

   $template .= <<'TEMPLATE';
sub os_deps {
   if ( $^O eq 'MSWin32' or $^O eq 'cygwin' ) {
      return (
         'Win32::Process'       => 0,
         'Win32::Process::Info' => 1.020,  # WMI on Cygwin
         'Path::Class'          => 0.32,   # fixes Cygwin path issue
      );
   }
   elsif ( $^O eq 'freebsd' ) {
      return ( 'BSD::Process' => 0 );
   }
   elsif ( $^O eq 'os2' ) {
      return ( 'OS2::Process' => 0 );
   }
   elsif ( $^O eq 'VMS' ) {
      return ( 'VMS::Process' => 0 );
   }
   else {
      # let's hope they have /proc
      if ( -d '/proc' and @{[ glob('/proc/*') ]} ) {
         return ();
      }
      # ...or that Proc::ProcessTable can handle it
      else {
         return ( 'Proc::ProcessTable' => 0.48 );  # ie: the one that ain't broke
      }
   }
   return ();
}
TEMPLATE

   return $template;
};

__PACKAGE__->meta->make_immutable;

42;
