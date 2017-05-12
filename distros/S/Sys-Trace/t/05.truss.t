#!perl
use Test::More tests => 5;
use_ok "Sys::Trace::Impl::Truss";

# Try parsing some existing truss output
my $trace = Sys::Trace::Impl::Truss->new;
my $calls = $trace->parse(*DATA);

# Should have a call to execve
is 1, scalar grep { $_->{call} eq 'execve' } @$calls;

my($execve) = grep { $_->{call} eq 'execve' } @$calls;

is $execve->{name}, "/usr/bin/ls";
is $execve->{walltime}, "1277716460.858";

is 1, scalar grep { $_->{call} eq '_exit' } @$calls;

__DATA__
Base time stamp:  1277716460.8580  [ Mon Jun 28 09:14:20 GMT 2010 ]
6428:    0.0000 execve("/usr/bin/ls", 0x08047CF8, 0x08047D00)  argc = 1
6428:    0.0037 resolvepath("/usr/lib/ld.so.1", "/lib/ld.so.1", 1023) = 12
6428:    0.0040 resolvepath("/usr/bin/ls", "/usr/bin/ls", 1023) = 11
6428:    0.0042 xstat(2, "/usr/bin/ls", 0x08047AE8)             = 0
6428:    0.0044 open("/var/ld/ld.config", O_RDONLY)             Err#2 ENOENT
6428:    0.0046 sysconfig(_CONFIG_PAGESIZE)                     = 4096
6428:    0.0047 xstat(2, "/lib/libsec.so.1", 0x08047380)        = 0
6428:    0.0049 resolvepath("/lib/libsec.so.1", "/lib/libsec.so.1", 1023) = 16
6428:    0.0051 open("/lib/libsec.so.1", O_RDONLY)              = 3
6428:    0.0053 mmap(0x00010000, 4096, PROT_READ|PROT_EXEC, MAP_PRIVATE|MAP_ALIGN, 3, 0) = 0xFEFC0000
6428:    0.0055 mmap(0x00010000, 143360, PROT_NONE, MAP_PRIVATE|MAP_NORESERVE|MAP_ANON|MAP_ALIGN, -1, 0) = 0xFEF90000
6428:    0.0056 mmap(0xFEF90000, 49223, PROT_READ|PROT_EXEC, MAP_PRIVATE|MAP_FIXED|MAP_TEXT, 3, 0) = 0xFEF90000
6428:    0.0058 mmap(0xFEFAD000, 12169, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_INITDATA, 3, 53248) = 0xFEFAD000
6428:    0.0060 mmap(0xFEFB0000, 8536, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_ANON, -1, 0) = 0xFEFB0000
6428:    0.0062 munmap(0xFEF9D000, 65536)                       = 0
6428:    0.0064 memcntl(0xFEF90000, 8812, MC_ADVISE, MADV_WILLNEED, 0, 0) = 0
6428:    0.0065 close(3)                                        = 0
6428:    0.0067 mmap(0x00000000, 4096, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_PRIVATE|MAP_ANON, -1, 0) = 0xFEF80000
6428:    0.0069 xstat(2, "/lib/libc.so.1", 0x08047380)          = 0
6428:    0.0071 resolvepath("/lib/libc.so.1", "/lib/libc.so.1", 1023) = 14
6428:    0.0073 open("/lib/libc.so.1", O_RDONLY)                = 3
6428:    0.0074 mmap(0xFEFC0000, 4096, PROT_READ|PROT_EXEC, MAP_PRIVATE|MAP_FIXED, 3, 0) = 0xFEFC0000
6428:    0.0076 mmap(0x00010000, 856064, PROT_NONE, MAP_PRIVATE|MAP_NORESERVE|MAP_ANON|MAP_ALIGN, -1, 0) = 0xFEEA0000
6428:    0.0077 mmap(0xFEEA0000, 755413, PROT_READ|PROT_EXEC, MAP_PRIVATE|MAP_FIXED|MAP_TEXT, 3, 0) = 0xFEEA0000
6428:    0.0079 mmap(0xFEF69000, 24303, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_INITDATA, 3, 757760) = 0xFEF69000
6428:    0.0081 mmap(0xFEF6F000, 5720, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_ANON, -1, 0) = 0xFEF6F000
6428:    0.0082 munmap(0xFEF59000, 65536)                       = 0
6428:    0.0085 memcntl(0xFEEA0000, 120620, MC_ADVISE, MADV_WILLNEED, 0, 0) = 0
6428:    0.0087 close(3)                                        = 0
6428:    0.0089 xstat(2, "/lib/libavl.so.1", 0x08047380)        = 0
6428:    0.0091 resolvepath("/lib/libavl.so.1", "/lib/libavl.so.1", 1023) = 16
6428:    0.0093 open("/lib/libavl.so.1", O_RDONLY)              = 3
6428:    0.0095 mmap(0xFEFC0000, 4096, PROT_READ|PROT_EXEC, MAP_PRIVATE|MAP_FIXED, 3, 0) = 0xFEFC0000
6428:    0.0096 mmap(0x00010000, 73728, PROT_NONE, MAP_PRIVATE|MAP_NORESERVE|MAP_ANON|MAP_ALIGN, -1, 0) = 0xFEE80000
6428:    0.0098 mmap(0xFEE80000, 2788, PROT_READ|PROT_EXEC, MAP_PRIVATE|MAP_FIXED|MAP_TEXT, 3, 0) = 0xFEE80000
6428:    0.0100 mmap(0xFEE91000, 204, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_INITDATA, 3, 4096) = 0xFEE91000
6428:    0.0101 munmap(0xFEE81000, 65536)                       = 0
6428:    0.0103 memcntl(0xFEE80000, 1056, MC_ADVISE, MADV_WILLNEED, 0, 0) = 0
6428:    0.0105 close(3)                                        = 0
6428:    0.0111 munmap(0xFEFC0000, 4096)                        = 0
6428:    0.0114 mmap(0x00010000, 24576, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_PRIVATE|MAP_ANON|MAP_ALIGN, -1, 0) = 0xFEE70000
6428:    0.0116 getcontext(0x08047880)
6428:    0.0117 getrlimit(RLIMIT_STACK, 0x08047878)             = 0
6428:    0.0118 getpid()                                        = 6428 [6427]
6428:    0.0123 lwp_private(0, 1, 0xFEE72000)                   = 0x000001C3
6428:    0.0126 setustack(0xFEE72060)
6428:    0.0128 sysi86(SI86FPSTART, 0xFEF6FD18, 0x0000133F, 0x00001F80) = 0x00000001
6428:    0.0132 brk(0x080651E8)                                 = 0
6428:    0.0133 brk(0x080671E8)                                 = 0
6428:    0.0136 time()                                          = 1277716460
6428:    0.0138 ioctl(1, TCGETA, 0x08047A54)                    Err#6 ENXIO
6428:    0.0139 brk(0x080671E8)                                 = 0
6428:    0.0141 brk(0x080711E8)                                 = 0
6428:    0.0143 lstat64(".", 0x08046930)                        = 0
6428:    0.0145 openat(-3041965, ".", O_RDONLY|O_NDELAY|O_LARGEFILE) = 3
6428:    0.0147 fcntl(3, F_SETFD, 0x00000001)                   = 0
6428:    0.0149 fstat64(3, 0x08047970)                          = 0
6428:    0.0150 getdents64(3, 0xFEE74000, 8192)                 = 696
6428:    0.0152 getdents64(3, 0xFEE74000, 8192)                 = 0
6428:    0.0154 close(3)                                        = 0
6428:    0.0156 ioctl(1, TCGETA, 0x08045D04)                    Err#6 ENXIO
6428:    0.0158 fstat64(1, 0x08045D30)                          = 0
6428:    0.0160 brk(0x080711E8)                                 = 0
6428:    0.0161 brk(0x080731E8)                                 = 0
6428:    0.0163 fstat64(1, 0x08045C70)                          = 0
6428:    0.0165 write(1, " x x x x x x x x x x x x".., 192)     = 192
6428:    0.0166 _exit(0)
