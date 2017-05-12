#!perl
use Test::More tests => 12;
use_ok "Sys::Trace::Impl::Strace";

# Try parsing some existing strace output
my $trace = Sys::Trace::Impl::Strace->new;
my $calls = $trace->parse(*DATA);

# Should have a call to execve
is 1, scalar grep { $_->{call} eq 'execve' } @$calls;

my($execve) = grep { $_->{call} eq 'execve' } @$calls;

is $execve->{name}, "/bin/pwd";
is $execve->{systime}, "0.000351";
is $execve->{walltime}, "1277677148.516737";
is_deeply $execve->{args}, [qw(/bin/pwd ["pwd"]), "[/* 32 vars */]"];

is 1, scalar grep { $_->{call} eq 'exit_group' } @$calls;

my($fstat64) = grep { $_->{call} eq 'fstat64' } @$calls;
is $fstat64->{args}->[0], 3;
is $fstat64->{args}->[1], "{st_mode=S_IFREG|0644, st_size=72860, ...}";
is $fstat64->{return}, 0;

my($access) = grep { $_->{call} eq 'access' } @$calls;
is $access->{name}, "/etc/ld.so.nohwcap";
is $access->{errno}, "ENOENT";

__DATA__
25901 1277677148.516737 execve("/bin/pwd", ["pwd"], [/* 32 vars */]) = 0 <0.000351>
25901 1277677148.517468 brk(0)                = 0x81f1000 <0.000022>
25901 1277677148.517611 access("/etc/ld.so.nohwcap", F_OK) = -1 ENOENT (No such file or directory) <0.000032>
25901 1277677148.517789 mmap2(NULL, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0xb772f000 <0.000026>
25901 1277677148.517932 access("/etc/ld.so.preload", R_OK) = -1 ENOENT (No such file or directory) <0.000030>
25901 1277677148.518072 open("/etc/ld.so.cache", O_RDONLY) = 3 <0.000032>
25901 1277677148.518192 fstat64(3, {st_mode=S_IFREG|0644, st_size=72860, ...}) = 0 <0.000022>
25901 1277677148.518390 mmap2(NULL, 72860, PROT_READ, MAP_PRIVATE, 3, 0) = 0xb771d000 <0.000026>
25901 1277677148.518483 close(3)              = 0 <0.000021>
25901 1277677148.518572 access("/etc/ld.so.nohwcap", F_OK) = -1 ENOENT (No such file or directory) <0.000029>
25901 1277677148.518720 open("/lib/tls/i686/cmov/libc.so.6", O_RDONLY) = 3 <0.000035>
25901 1277677148.518851 read(3, "\177ELF\1\1\1\0\0\0\0\0\0\0\0\0\3\0\3\0\1\0\0\0\260l\1\0004\0\0\0"..., 512) = 512 <0.000023>
25901 1277677148.519009 fstat64(3, {st_mode=S_IFREG|0755, st_size=1319364, ...}) = 0 <0.000021>
25901 1277677148.521333 mmap2(NULL, 1329512, PROT_READ|PROT_EXEC, MAP_PRIVATE|MAP_DENYWRITE, 3, 0) = 0xda2000 <0.000022>
25901 1277677148.521401 mprotect(0xee0000, 4096, PROT_NONE) = 0 <0.000014>
25901 1277677148.521442 mmap2(0xee1000, 12288, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x13e) = 0xee1000 <0.000017>
25901 1277677148.521500 mmap2(0xee4000, 10600, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_ANONYMOUS, -1, 0) = 0xee4000 <0.000011>
25901 1277677148.521549 close(3)              = 0 <0.000008>
25901 1277677148.521601 mmap2(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0xb771c000 <0.000010>
25901 1277677148.521645 set_thread_area({entry_number:-1 -> 6, base_addr:0xb771c8d0, limit:1048575, seg_32bit:1, contents:0, read_exec_only:0, limit_in_pages:1, seg_not_present:0, useable:1}) = 0 <0.000008>
25901 1277677148.521783 mprotect(0xee1000, 8192, PROT_READ) = 0 <0.000011>
25901 1277677148.521822 mprotect(0x8051000, 4096, PROT_READ) = 0 <0.000011>
25901 1277677148.521863 mprotect(0xcab000, 4096, PROT_READ) = 0 <0.000011>
25901 1277677148.521897 munmap(0xb771d000, 72860) = 0 <0.000015>
25901 1277677148.522040 brk(0)                = 0x81f1000 <0.000008>
25901 1277677148.522073 brk(0x8212000)        = 0x8212000 <0.000010>
25901 1277677148.522120 open("/usr/lib/locale/locale-archive", O_RDONLY|O_LARGEFILE) = -1 ENOENT (No such file or directory) <0.000020>
25901 1277677148.522195 open("/usr/share/locale/locale.alias", O_RDONLY) = 3 <0.000020>
25901 1277677148.522261 fstat64(3, {st_mode=S_IFREG|0644, st_size=2570, ...}) = 0 <0.000008>
25901 1277677148.522330 mmap2(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0xb772e000 <0.000009>
25901 1277677148.522368 read(3, "# Locale name alias data base.\n#"..., 4096) = 2570 <0.000018>
25901 1277677148.522461 read(3, "", 4096)     = 0 <0.000009>
25901 1277677148.522496 close(3)              = 0 <0.000009>
25901 1277677148.522527 munmap(0xb772e000, 4096) = 0 <0.000013>
25901 1277677148.522663 open("/usr/lib/locale/en_GB.UTF-8/LC_IDENTIFICATION", O_RDONLY) = -1 ENOENT (No such file or directory) <0.000013>
25901 1277677148.522721 open("/usr/lib/locale/en_GB.utf8/LC_IDENTIFICATION", O_RDONLY) = 3 <0.000014>
25901 1277677148.522775 fstat64(3, {st_mode=S_IFREG|0644, st_size=366, ...}) = 0 <0.000008>
25901 1277677148.522840 mmap2(NULL, 366, PROT_READ, MAP_PRIVATE, 3, 0) = 0xb772e000 <0.000010>
25901 1277677148.522875 close(3)              = 0 <0.000007>
25901 1277677148.522913 open("/usr/lib/gconv/gconv-modules.cache", O_RDONLY) = 3 <0.000014>
25901 1277677148.522964 fstat64(3, {st_mode=S_IFREG|0644, st_size=26048, ...}) = 0 <0.000008>
25901 1277677148.523027 mmap2(NULL, 26048, PROT_READ, MAP_SHARED, 3, 0) = 0xb7727000 <0.000010>
25901 1277677148.523062 close(3)              = 0 <0.000008>
25901 1277677148.523172 open("/usr/lib/locale/en_GB.UTF-8/LC_MEASUREMENT", O_RDONLY) = -1 ENOENT (No such file or directory) <0.000012>
25901 1277677148.523228 open("/usr/lib/locale/en_GB.utf8/LC_MEASUREMENT", O_RDONLY) = 3 <0.000012>
25901 1277677148.523280 fstat64(3, {st_mode=S_IFREG|0644, st_size=23, ...}) = 0 <0.000007>
25901 1277677148.523344 mmap2(NULL, 23, PROT_READ, MAP_PRIVATE, 3, 0) = 0xb7726000 <0.000010>
25901 1277677148.523378 close(3)              = 0 <0.000008>
25901 1277677148.523488 open("/usr/lib/locale/en_GB.UTF-8/LC_TELEPHONE", O_RDONLY) = -1 ENOENT (No such file or directory) <0.000013>
25901 1277677148.523543 open("/usr/lib/locale/en_GB.utf8/LC_TELEPHONE", O_RDONLY) = 3 <0.000013>
25901 1277677148.523594 fstat64(3, {st_mode=S_IFREG|0644, st_size=56, ...}) = 0 <0.000008>
25901 1277677148.523657 mmap2(NULL, 56, PROT_READ, MAP_PRIVATE, 3, 0) = 0xb7725000 <0.000010>
25901 1277677148.523692 close(3)              = 0 <0.000008>
25901 1277677148.523795 open("/usr/lib/locale/en_GB.UTF-8/LC_ADDRESS", O_RDONLY) = -1 ENOENT (No such file or directory) <0.000012>
25901 1277677148.523848 open("/usr/lib/locale/en_GB.utf8/LC_ADDRESS", O_RDONLY) = 3 <0.000012>
25901 1277677148.523897 fstat64(3, {st_mode=S_IFREG|0644, st_size=127, ...}) = 0 <0.000008>
25901 1277677148.523961 mmap2(NULL, 127, PROT_READ, MAP_PRIVATE, 3, 0) = 0xb7724000 <0.000009>
25901 1277677148.523995 close(3)              = 0 <0.000008>
25901 1277677148.524096 open("/usr/lib/locale/en_GB.UTF-8/LC_NAME", O_RDONLY) = -1 ENOENT (No such file or directory) <0.000012>
25901 1277677148.524147 open("/usr/lib/locale/en_GB.utf8/LC_NAME", O_RDONLY) = 3 <0.000013>
25901 1277677148.524194 fstat64(3, {st_mode=S_IFREG|0644, st_size=77, ...}) = 0 <0.000008>
25901 1277677148.524259 mmap2(NULL, 77, PROT_READ, MAP_PRIVATE, 3, 0) = 0xb7723000 <0.000010>
25901 1277677148.524293 close(3)              = 0 <0.000008>
25901 1277677148.524398 open("/usr/lib/locale/en_GB.UTF-8/LC_PAPER", O_RDONLY) = -1 ENOENT (No such file or directory) <0.000011>
25901 1277677148.524450 open("/usr/lib/locale/en_GB.utf8/LC_PAPER", O_RDONLY) = 3 <0.000012>
25901 1277677148.524499 fstat64(3, {st_mode=S_IFREG|0644, st_size=34, ...}) = 0 <0.000008>
25901 1277677148.524563 mmap2(NULL, 34, PROT_READ, MAP_PRIVATE, 3, 0) = 0xb7722000 <0.000010>
25901 1277677148.524597 close(3)              = 0 <0.000007>
25901 1277677148.524734 open("/usr/lib/locale/en_GB.UTF-8/LC_MESSAGES", O_RDONLY) = -1 ENOENT (No such file or directory) <0.000013>
25901 1277677148.524788 open("/usr/lib/locale/en_GB.utf8/LC_MESSAGES", O_RDONLY) = 3 <0.000012>
25901 1277677148.524837 fstat64(3, {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0 <0.000008>
25901 1277677148.524898 close(3)              = 0 <0.000009>
25901 1277677148.524931 open("/usr/lib/locale/en_GB.utf8/LC_MESSAGES/SYS_LC_MESSAGES", O_RDONLY) = 3 <0.000013>
25901 1277677148.524985 fstat64(3, {st_mode=S_IFREG|0644, st_size=52, ...}) = 0 <0.000008>
25901 1277677148.525049 mmap2(NULL, 52, PROT_READ, MAP_PRIVATE, 3, 0) = 0xb7721000 <0.000010>
25901 1277677148.525084 close(3)              = 0 <0.000008>
25901 1277677148.525191 open("/usr/lib/locale/en_GB.UTF-8/LC_MONETARY", O_RDONLY) = -1 ENOENT (No such file or directory) <0.000012>
25901 1277677148.525245 open("/usr/lib/locale/en_GB.utf8/LC_MONETARY", O_RDONLY) = 3 <0.000012>
25901 1277677148.525294 fstat64(3, {st_mode=S_IFREG|0644, st_size=290, ...}) = 0 <0.000008>
25901 1277677148.525359 mmap2(NULL, 290, PROT_READ, MAP_PRIVATE, 3, 0) = 0xb7720000 <0.000009>
25901 1277677148.525393 close(3)              = 0 <0.000008>
25901 1277677148.525495 open("/usr/lib/locale/en_GB.UTF-8/LC_COLLATE", O_RDONLY) = -1 ENOENT (No such file or directory) <0.000012>
25901 1277677148.525550 open("/usr/lib/locale/en_GB.utf8/LC_COLLATE", O_RDONLY) = 3 <0.000012>
25901 1277677148.525599 fstat64(3, {st_mode=S_IFREG|0644, st_size=966938, ...}) = 0 <0.000008>
25901 1277677148.525663 mmap2(NULL, 966938, PROT_READ, MAP_PRIVATE, 3, 0) = 0xb762f000 <0.000010>
25901 1277677148.525697 close(3)              = 0 <0.000007>
25901 1277677148.525806 open("/usr/lib/locale/en_GB.UTF-8/LC_TIME", O_RDONLY) = -1 ENOENT (No such file or directory) <0.000012>
25901 1277677148.525859 open("/usr/lib/locale/en_GB.utf8/LC_TIME", O_RDONLY) = 3 <0.000013>
25901 1277677148.525908 fstat64(3, {st_mode=S_IFREG|0644, st_size=2470, ...}) = 0 <0.000008>
25901 1277677148.526580 mmap2(NULL, 2470, PROT_READ, MAP_PRIVATE, 3, 0) = 0xb771f000 <0.000012>
25901 1277677148.526618 close(3)              = 0 <0.000008>
25901 1277677148.526726 open("/usr/lib/locale/en_GB.UTF-8/LC_NUMERIC", O_RDONLY) = -1 ENOENT (No such file or directory) <0.000013>
25901 1277677148.526781 open("/usr/lib/locale/en_GB.utf8/LC_NUMERIC", O_RDONLY) = 3 <0.000013>
25901 1277677148.526831 fstat64(3, {st_mode=S_IFREG|0644, st_size=54, ...}) = 0 <0.000008>
25901 1277677148.526896 mmap2(NULL, 54, PROT_READ, MAP_PRIVATE, 3, 0) = 0xb771e000 <0.000010>
25901 1277677148.526931 close(3)              = 0 <0.000008>
25901 1277677148.527033 open("/usr/lib/locale/en_GB.UTF-8/LC_CTYPE", O_RDONLY) = -1 ENOENT (No such file or directory) <0.000012>
25901 1277677148.527086 open("/usr/lib/locale/en_GB.utf8/LC_CTYPE", O_RDONLY) = 3 <0.000012>
25901 1277677148.527134 fstat64(3, {st_mode=S_IFREG|0644, st_size=256316, ...}) = 0 <0.000008>
25901 1277677148.527198 mmap2(NULL, 256316, PROT_READ, MAP_PRIVATE, 3, 0) = 0xb75f0000 <0.000009>
25901 1277677148.527233 close(3)              = 0 <0.000008>
25901 1277677148.527303 getcwd("/tmp", 4096)  = 5 <0.000010>
25901 1277677148.527348 fstat64(1, {st_mode=S_IFCHR|0620, st_rdev=makedev(136, 5), ...}) = 0 <0.000008>
25901 1277677148.527413 mmap2(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0xb75ef000 <0.000010>
25901 1277677148.527455 write(1, "/tmp\n", 5/tmp
25901 ) = 5 <0.000011>
25901 1277677148.527502 close(1)              = 0 <0.000007>
25901 1277677148.527532 munmap(0xb75ef000, 4096) = 0 <0.000013>
25901 1277677148.527568 close(2)              = 0 <0.000008>
25901 1277677148.527605 exit_group(0)         = ?
