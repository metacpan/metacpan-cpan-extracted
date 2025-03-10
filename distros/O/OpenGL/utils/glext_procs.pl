$|++;
my $file = '../include/GL/glext.h';
die "Unable to read '$file'" if (!open(FILE,$file));

my $exts = '../glext_procs.h';
die "Unable to write to '$exts'" if (!open(EXTS,">$exts"));
binmode EXTS;

my $exts = '../glext_consts.h';
die "Unable to write to '$exts'" if (!open(CNST,">$exts"));
binmode CNST;

my $exts = '../glext_types.h';
die "Unable to write to '$exts'" if (!open(TYPE,">$exts"));
binmode TYPE;

my $exps = 'exports.txt';
die "Unable to read '$exps'" if (!open(EXPS,$exps));
my $exports = {};
foreach my $line (<EXPS>)
{
  $line =~ s|[\r\n]+||g;
  next if (!$line);
  $exports->{$line}++;
}
close(EXPS);

# Header
my $header = qq
{#ifndef %s
#define %s

#ifdef __cplusplus
extern "C" \{
#endif

/*
** This file is derived from glext.h and is subject to the same license
** restrictions as that file.
**
};

print EXTS sprintf $header, ("__glext_procs_h_") x 2;
print CNST sprintf $header, ("__glext_consts_h_") x 2;
print TYPE sprintf $header, ("__glext_types_h_") x 2;


# License
while (<FILE>)
{
  my $line = $_;
  next if ($line !~ m|^\*\* Copyright \(c\) 20\d\d-20\d\d The Khronos Group Inc\.|);
  print EXTS $line;
  print CNST $line;
  last;
}

# Handle extensions
while (<FILE>)
{
  my $line = $_;
  if ($line =~ m|^\#ifdef __cplusplus|)
  {
    print "Found end\n";
    print EXTS $line;
    print CNST $line;
    print TYPE $line;
    next;
  }
  elsif ($line =~ m|^\#ifndef GL_[^\s]+|)
  {
    my $next_line = <FILE>;

    if ($next_line !~ m|^\#define (GL_[^\s]+) 1|)
    {
      print EXTS $line.$next_line;
      print CNST $line.$next_line;
      next;
    }

    my $ext = $1;
    print "$ext\n";

    print EXTS qq
{#ifndef NO_$ext
#ifndef $ext
#define $ext 1
#endif
};
    print CNST "#ifndef NO_$ext\n";

    my @procs;
    my $in_PROTOTYPES;
    my $in_TYPES;
    my $proto_level;
    my $types_level;
    my $def_level = 1;
    while (<FILE>)
    {
      my $line2 = $_;

      if ($line2 =~ m/^#(if|ifdef|ifndef)/)
      {
        print EXTS $line2;
        if($line2 =~ /ifdef.*GL_GLEXT_PROTOTYPES/)
        {
          $proto_level = $def_level;
          $in_PROTOTYPES = 1;
        }
        if($line2 =~ /ifndef.*GLEXT_64_TYPES_DEFINED/)
        {
          $types_level = $def_level;
          $in_TYPES = 2;
        }
        print CNST $line2 if !$in_PROTOTYPES;
        print TYPE $line2 if $in_TYPES;
        $def_level++;
        next;
      }

      if ($line2 !~ m|^\#endif|)
      {
        print EXTS $line2;
        $in_TYPES-- if $in_TYPES == 1 and $line2 !~ m|^typedef|;
        print TYPE $line2 if $in_TYPES;
        print TYPE $line2 if !$in_TYPES and $line2 =~ m|^typedef \w+ \w+;|;

        if ($line2 =~ m|APIENTRY (gl[^\s]+)|)
        {
          my $export = $1;
          if ($exports->{$export})
          {
            print "  Not a wgl export: $export\n";
          }
          else
          {
            push(@procs,'static PFN'.uc($1).'PROC '.$1." = NULL;\n");
          }
          next;
        }
        
        if ($line2 =~ m|^\#define (GL_[^\s]+)|)
        {
          print CNST "    i($1)\n";
          next;
        }
        
        # the #define here blocks GLEXT_64_TYPES_DEFINED, might be needed though
        next if $line2 =~ /^(#define|typedef|struct|#include) /;
        print CNST $line2;
        next;
      }
      $def_level--;

      if($def_level>0)
      {
        print EXTS $line2;
        print CNST $line2 if !$in_PROTOTYPES;
        print TYPE $line2 if $in_TYPES;

        $in_PROTOTYPES = 0 if $in_PROTOTYPES and $proto_level == $def_level;
        $in_TYPES-- if $in_TYPES and $types_level == $def_level;

        next;
      }

      if(@procs)
      {
        print EXTS "\#ifdef GL_GLEXT_PROCS\n";
        foreach my $proc (@procs)
        {
          print EXTS $proc;
        }
        print EXTS "\#endif /* GL_GLEXT_PROCS */\n";
      }

      print EXTS $line2;
      print CNST $line2;
      last;
    }
  }
  else
  {
    print EXTS $line;
    next if $line =~ /^(#include|#define) /;
    print CNST $line;
    print TYPE $line;
  }
}

close(EXTS);
close(FILE);
