use strict;
use ExtUtils::MakeMaker;
use Config;

my @objects;

sub getFiles
{
  my $dir = shift;
  opendir(local *DIR, $dir) or return;
  foreach my $file (readdir(DIR))
  {
    if (-d "$dir/$file" && $file !~ /^\./)
    {
      getFiles("$dir/$file");
    }
    elsif (-f "$dir/$file" && $file =~ /(.*)\.c(?:pp)?$/)
    {
      push @objects, "$dir/$1.o";
    }
  }
  closedir(DIR);
}

push @objects, 'Universal.o', 'CachingHRCParser.o';

getFiles('colorer');

foreach (@ExtUtils::MakeMaker::MM_Sections)
{
  $_ = 'xs_cpp' if $_ eq 'xs_c';
}
foreach (@ExtUtils::MakeMaker::Overridable)
{
  $_ = 'xs_cpp' if $_ eq 'xs_c';
}

my %options = (
    NAME              => 'Syntax::Highlight::Universal',
    VERSION_FROM      => 'Universal.pm',
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'Universal.pm',
       AUTHOR         => 'Wladimir Palant <palant@cpan.org>') : ()),
    OBJECT            => join(' ', @objects),
    CCFLAGS           => '-w',
    OPTIMIZE          => '-O2',
    XS                => {'Universal.xs' => 'Universal.cpp'},
    INC               => '-Icolorer',
    clean             => {FILES => join(' ', @objects, 'precompiled.hrcc', 'vc60.pdb', 'Universal_def.old')},
);

if ($^O =~ /Win32/ && $Config{cc} =~ /cl/)
{
  $options{CCFLAGS} .= ' -DWIN32 /Fo$*.obj';
}
else
{
  $options{CCFLAGS} .= ' -o $*.o';
  $options{LIBS} = '-lstdc++';
}

WriteMakefile(%options);
