use strict;
use warnings;
use Config;
use Module::Build;

my $builder = Module::Build->new(
  module_name         => 'Sys::Sendfile',
    'build_requires' => {
    'Fcntl' => '0',
    'File::Spec' => '0',
    'IO::Handle' => '0',
    'IO::Socket::INET' => '0',
    'IPC::Open3' => '0',
    'Module::Build' => '0.28',
    'Test::More' => '0',
    'perl' => '5.006'
  },
  'configure_requires' => {
    'Module::Build' => '0.28'
  },
  'requires' => {
    'Exporter' => '5.57',
    'XSLoader' => '0',
    'perl' => '5.006',
    'strict' => '0',
    'warnings' => '0'
  },
  
);

if ($^O eq 'MSWin32') {
	my $cc = $Config{cc};
	my $type = ($cc =~ /cl(\.exe)?$/ ? 'MSVC' : $cc =~ /bcc32(\.exe)?$/ ? 'BCC' : 'GCC');
	$builder->extra_linker_flags('mswsock.lib') if $type eq 'MSVC';
	$builder->extra_linker_flags('-lmswsock') if $type eq 'GCC';
}
elsif ($^O eq 'solaris') {
	$builder->extra_linker_flags('-lsendfile');
}
elsif($^O eq 'gnukfreebsd') {
	$builder->extra_compiler_flags('-I/usr/include/freebsd');
	$builder->extra_linker_flags('-lfreebsd-glue');
}

$builder->create_build_script();
