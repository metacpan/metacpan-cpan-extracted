use strict;
use warnings;

=head1 PURPOSE

This script extracts the function signatures etc from include/GL/glew.h
and saves the info to lib/OpenGL/Modern/Registry.pm

Run it with:

  make && perl -Mblib utils/generate-registry.pl

=cut

require './utils/common.pl';
my %upper2data;
my %case_map;
my %alias;

my %constants;

for my $file ("include/GL/glew.h") {

    my $feature_name;

    print "Processing file $file\n";

    open my $fh, '<', $file
      or die "Couldn't read '$file': $!";

    while ( my $line = <$fh> ) {
        if ( $line =~ m|^#define (\w+) 1\r?$| and $1 ne 'GL_ONE' and $1 ne 'GL_TRUE' ) {
            $feature_name = $1;
            # #endif /* GL_FEATURE_NAME */
        }
        elsif ( defined( $feature_name ) and $line =~ m|^#endif /\* $feature_name \*/\s*| ) {

            # End of lines for this OpenGL feature
            $feature_name = undef;

            # typedef void* (GLAPIENTRY * PFNGLMAPBUFFERPROC) (GLenum target, GLenum access);
            # typedef void (GLAPIENTRY * PFNGLGETQUERYIVPROC) (GLenum target, GLenum pname, GLint* params);
        }
        elsif ( $line =~ m|^typedef (\w+(?:\s*\*)?) \(GLAPIENTRY \* PFN(\w+)PROC\)\s*\((.*)\);| ) {
            my ( $restype, $name, $sig ) = ( $1, $2, $3 );
            my $s =
              { signature => $sig, restype => $restype, name => $name, glewtype => 'fun' };
            $s->{feature} = $feature_name if $feature_name;
            $upper2data{$name} = $s;

            # GLAPI void GLAPIENTRY glClearColor (GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha);
        }
        elsif ( $line =~ m|^GLAPI ([\w* ]+?) GLAPIENTRY (\w+) \((.*)\);| ) {

            # Some external function, likely imported from libopengl / opengl32
            my ( $restype, $name, $sig ) = ( $1, $2, $3 );
            my $s =
              { signature => $sig, restype => $restype, name => $name, glewtype => 'fun' };
            $s->{feature} = $feature_name if $feature_name;
            $upper2data{ uc $name } = $s;
            $case_map{ uc $name }  = $name;

            # GLEW_FUN_EXPORT PFNGLACTIVETEXTUREPROC __glewActiveTexture;
        }
        elsif ( $line =~ m|^GLEW_FUN_EXPORT PFN(\w+)PROC __(\w+)| ) {
            my ( $name, $impl ) = ( $1, $2 );
            $case_map{$name} = $impl;

            # #define glCopyTexSubImage3D GLEW_GET_FUN(__glewCopyTexSubImage3D)
        }
        elsif ( $line =~ m|^#define (\w+) GLEW_GET_FUN\(__(\w+)\)| ) {
            my ( $name, $impl ) = ( $1, $2 );
            $alias{$impl} = $name;

            # #define GLEW_VERSION_1_1 GLEW_GET_VAR(__GLEW_VERSION_1_1)
        }
        elsif ( $line =~ m|^#define (\w+) GLEW_GET_VAR\(__(\w+)\)| ) {
            my ( $name, $impl ) = ( $1, $2 );
            $alias{$impl} = $name;

            # #define GL_CONSTANT_NAME ...
        }
        elsif ( $line =~ m|^#define (GL(?:EW)?_\w+)\s+\S| ) {
            my $c = $1;
            $constants{$c} = undef if $c !~ /_EXPORT$/;

            # GLEW_VAR_EXPORT GLboolean __GLEW_VERSION_1_1;
        }
        elsif ( $line =~ m|^GLEW_VAR_EXPORT (\w+) __(\w+)| ) {
            my ( $restype, $impl ) = ( $1, $2 );
            my $s = { signature => 'void', restype => $restype, glewtype => 'var' };
            $s->{feature} = $feature_name if $feature_name;
            my $name = $alias{$impl};
            $upper2data{$name} = $s;
            $case_map{$name} = $impl;

        }
    }
}

my %signature;
# Now rewrite the names to proper case when we only have their uppercase alias
for my $name ( keys %upper2data ) {
  my $impl      = $case_map{$name} || $name;
  my $real_name = $alias{$impl}    || $impl;
  my $s = $upper2data{$name};
  $signature{$real_name} = $s;
  delete $s->{name};
}

for my $name (@ARGV ? @ARGV : sort keys %signature) {
  my $item = $signature{$name};
  my $args = delete $item->{signature};
  die "No args for $name" unless $args;
  my @argdata;
  $args = '' if $args eq 'void';
  for (split /\s*,\s*/, $args) {
    s/\s+$//;
    s!\bGLsync(\s+)GLsync!GLsync$1myGLsync!g; # rewrite
    # Rewrite `const GLwhatever foo[]` into `const GLwhatever* foo`
    s!^const (\w+)\s+(\**)(\w+)\[\d*\]$!const $1 * $2$3!;
    s!^(\w+)\s+(\**)(\w+)\[\d*\]$!$1 * $2$3!;
    my ($type, $arg) = /(.*?)(\w+)$/;
    if (!$type) { $type = "$arg "; $arg = 'param'.(@argdata+1); }
    push @argdata, [$arg,$type];
  }
  $item->{argdata} = \@argdata if @argdata;
  my $glewImpl;
  if ( ($item->{feature}//'') ne "GL_VERSION_1_1" ) {
      ( $glewImpl = $name ) =~ s!^gl!__glew!;
  }
  $item->{glewImpl} = $glewImpl if defined $glewImpl;
  my $type = $item->{restype};
  my ($i, @ptr_args) = -1;
  for ([$i++,$type], map [$i++,$_->[1]], @argdata) {
    my ($ind, $type) = @$_;
    next if $type !~ /\*/;
    next if is_stringtype($type, 1);
    next if ($name !~ /v[A-Z]*$/ || $argdata[$ind][0] eq 'name') and $type =~ /^\s*const\s+GLubyte(?:ARB)?\s*\*\s*$/;
    push @ptr_args, $ind;
  }
  $item->{ptr_args} = \@ptr_args if @ptr_args;
}

my %counts;
for (grep $_, split /\n/, slurp('utils/paramcounts.txt')) {
  my ($enum, $count) = split /\s+/;
  $counts{$enum} = $count;
}

for (grep $_, split /\n/, slurp('utils/args-len.txt')) {
  my ($func, @args) = split ' ';
  next unless my $s = $signature{$func};
  my ($argind, $argdata, $found_compsize) = (0, $s->{argdata});
  for (@args) {
    my ($name, $len) = split /=/;
    my $arginfo = $argdata->[$argind++];
    $arginfo->[0] = $name;
    next if !$len;
    $found_compsize = 1 if $len =~ /COMPSIZE/;
    push @$arginfo, $len;
  }
  next if !$found_compsize;
  my %name2data = map +($_->[0] => $_), @$argdata;
  for (0..$#$argdata) {
    next if !$argdata->[$_][2] or $argdata->[$_][2] !~ /^COMPSIZE\((\w+)\)/;
    my $compsize_from = $1;
    my $fromdata = $name2data{$compsize_from};
    next if $fromdata->[1] !~ /^\s*GLsizei\s*$/;
    $argdata->[$_][2] = $compsize_from;
  }
}

for (grep $_, split /\n/, slurp('utils/args-group.txt')) {
  my ($func, @args) = split ' ';
  next unless my $s = $signature{$func};
  my $argind = 0;
  for (@args) {
    my ($name, $group) = split /=/;
    my $arginfo = $s->{argdata}[$argind++];
    $arginfo->[0] = $name;
    next if !$group;
    $arginfo->[3] = $group; # undef in slot 2 is OK
  }
}

for (grep $_, split /\n/, slurp('utils/dynlang.txt')) {
  my ($func, @args) = split ' ';
  $signature{$func}{dynlang} = { map split('=', $_, 2), @args };
}

my (%groups, %enums);
for (grep $_, split /\n/, slurp('utils/enums-group.txt')) {
  my ($enum, $value, @groups) = split ' ';
  $enums{$enum} = $value;
  push @{ $groups{$_} }, $enum for @groups;
}
my $g2c2s = assemble_enum_groups(\%groups, \%counts);

for my $name (@ARGV ? @ARGV : sort keys %signature) {
  my $s = $signature{$name};
  next if $s->{dynlang};
  my @argdata = @{$s->{argdata} || []};
  next unless my @ptr_arg_inds = @{$s->{ptr_args} || []};
  next unless @ptr_arg_inds = grep $_ >= 0, @ptr_arg_inds;
  my %name2data = map +($_->[0] => $_), @argdata;
  my @ptr_args = @argdata[@ptr_arg_inds];
  my @ptr_types = map parse_ptr($_), @ptr_args;
  my @constargs = @ptr_args[ grep $ptr_types[$_][1], 0..$#ptr_args ];
  my @outargs = @ptr_args[ grep !$ptr_types[$_][1], 0..$#ptr_args ];
  die "$name: undef ptr_type" if grep !$_->[0], @ptr_types;
  my %arg2len = map @$_, grep defined($_->[1]) && $_->[1] !~ /COMPSIZE/, map [@$_[0,2]], @argdata;
  my %dynlang;
  for my $arg (@ptr_args) {
    next unless my ($compsize_from) = ($arg->[2]//'') =~ /COMPSIZE\(([^,]+)\)/;
    next unless my $compsize_data = $name2data{$compsize_from};
    next unless my $compsize_group = $compsize_data->[3];
    next unless $g2c2s->{$compsize_group};
    $arg2len{$arg->[0]} = "${compsize_from}_count";
    $dynlang{$arg->[0]} = "SIZE:$compsize_group:$compsize_from";
  }
  if (@outargs == 1 and
    typefunc(parse_ptr($outargs[0])->[0]) and
    $s->{restype} eq 'void' and
    (my $len = $arg2len{$outargs[0][0]})
  ) {
    if ($len eq '1') {
      $dynlang{RETVAL} = $outargs[0][0];
    } else {
      $dynlang{$outargs[0][0]} = join ',', grep $_, $dynlang{$outargs[0][0]}, "OUTASLIST:$len";
    }
  } elsif (
    ((($s->{restype} ne 'void') + @outargs) > 1) and
    !(grep !$arg2len{$_->[0]} || !(is_stringtype($_->[1]) || typefunc(parse_ptr($_)->[0])), @outargs)
  ) {
    for (@outargs) {
      my $len = $arg2len{$_->[0]};
      my $outas = (is_stringtype($_->[1]) || ($len =~ /^\d+$/ && $len == 1))
        ? "OUTSCALAR" : "OUTARRAY:$arg2len{$_->[0]}";
      $dynlang{$_->[0]} = join ',', grep $_, $dynlang{$_->[0]}, $outas;
    }
  }
  if (@constargs == 1 and
    typefunc(parse_ptr($constargs[0])->[0]) and
    $arg2len{$constargs[0][0]}
  ) {
    my $len = $arg2len{$constargs[0][0]};
    my $startfrom = grep !$dynlang{$_} && $_ ne $len && $_ ne $constargs[0][0], keys %name2data;
    $dynlang{$len} = 'items'.($startfrom ? "-$startfrom" : '') if $len =~ /^[a-zA-Z]+$/;
    $dynlang{$constargs[0][0]} = join ',', grep $_, $dynlang{$constargs[0][0]}, "VARARGS:$startfrom:$len";
  } elsif (
    @constargs > 1 and
    !(grep !$arg2len{$_->[0]} || !typefunc(parse_ptr($_)->[0]), @constargs)
  ) {
    my %len_done;
    for (@constargs) {
      my $len = $arg2len{$_->[0]};
      if ($len =~ /\D/ and !$len_done{$len}) {
        $len_done{$len} = 1;
        $dynlang{$len} = "LEN:$_->[0]";
      }
      $dynlang{$_->[0]} = join ',', grep $_, $dynlang{$_->[0]}, "INARRAY:$arg2len{$_->[0]}";
    }
  }
  $s->{dynlang} = \%dynlang if %dynlang;
}

my %feature2version;
for (grep $_, split /\n/, slurp('utils/feature-reuse.txt')) {
  my ($v, $f) = split /\s+/;
  $feature2version{$f}{$v} = undef;
}
@feature2version{keys %feature2version} = map +(keys %$_)[0], values %feature2version;
$signature{$_}{core_removed} = 1 for grep $_, split /\s+/, slurp('utils/removed.txt');
my %features;
for my $name (sort {uc$a cmp uc$b} keys %signature) {
  my $s = $signature{$name};
  next if !$s->{feature};
  for ($s->{feature}, grep defined, $feature2version{$s->{feature}}) {
    $features{$_}{$name} = undef;
  }
}
@features{keys %features} = map [sort keys %$_], values %features;

{
my (%alias2real, %real2aliases);
for (grep $_, split /\n/, slurp('utils/aliases.txt')) {
  my ($to, $from) = split ' ';
  $alias2real{$from} = $to;
  push @{ $real2aliases{$to} }, $from;
}
for my $alias (grep !exists $signature{$alias2real{$_}}, sort keys %alias2real) {
  next unless my $real = $alias2real{$alias};
  next if !$real2aliases{$real}; # already done
  die "non-existent alias '$alias' to non-existent '$real'" if !$signature{$alias};
  my ($actual_real, $actual_alias) = ($alias, $real);
  my @bad_aliases = grep $_ ne $actual_real, @{ delete $real2aliases{$real} };
  delete @alias2real{$actual_real, @bad_aliases};
  $alias2real{$_} = $actual_real for $actual_alias, @bad_aliases;
}
for (sort keys %alias2real) {
  my ($to, $from) = ($alias2real{$_}, $_);
  my ($from_sig, $to_sig) = @signature{$from, $to};
  die "no sig for '$to'" if !$to_sig;
  if ($from_sig && $from_sig != $to_sig) {
    my ($from_data, $to_data) = map $_->{argdata}, $from_sig, $to_sig;
    if ($from_data && $to_data) {
      next if @$from_data != @$to_data;
      my ($from_types, $to_types) = map [map {
        my $type = $_->[1] =~ s#(?: |ARB|EXT|GL|const)##gr;
        $type eq 'enum' ? 'int' : $type
      } @$_], $from_data, $to_data;
      my @difftypeind = grep $from_types->[$_] ne $to_types->[$_], 0..$#$from_types;
      if (@difftypeind) {
        # print "$from diff $to at (@difftypeind) = (@{[map qq{'$from_types->[$_]' ne '$to_types->[$_]'}, @difftypeind]})\n";
        if (my $to_dyn = $to_sig->{dynlang}) {
          # relying on only difference being GLhandleARB vs GLuint, non-"pointer" args
          $from_sig->{dynlang} = { %$to_dyn };
          my $new_from_data = $from_sig->{argdata} = [ map [@$_], @$to_data ];
          $new_from_data->[$_][1] = $from_data->[$_][1] for 0..$#$new_from_data;
        }
        next;
      }
    }
  }
  $to_sig->{aliases}{$from} = $from_sig->{feature};
  delete $signature{$from};
}
}

my @version_features = grep /^GL_VERSION/, keys %features;
my (@version_31, @version_core);
for my $f (@version_features) {
  die "Error parsing '$f'" unless my ($maj, $min) = $f =~ /(\d)/g;
  my $arr = (10*$maj + $min) < 32 ? \@version_31 : \@version_core;
  push @$arr, $f;
}
my %gltags;
my @exported_functions; # names the module exports
for my $name (sort {uc$a cmp uc$b} keys %signature) {
  my $s = $signature{$name};
  my @bindings = bindings($name, $s, $g2c2s, \%signature);
  my @binding_names = map $_->{binding_name}, @bindings;
  my @binding_aliases = map @{ $_->{aliases} }, @bindings;
  push @exported_functions, @binding_names, @binding_aliases;
  next if !$s->{feature};
  for ($s->{feature}, grep defined, $feature2version{$s->{feature}}) {
    @{ $gltags{$_} }{ @binding_names } = ();
  }
  next if !$s->{aliases};
  my %aliases = %{ $s->{aliases} };
  for my $from (keys %aliases) {
    next unless my $feature = $aliases{$from};
    my @these_bindings = grep /^$from/, @binding_aliases;
    @{ $gltags{$feature} }{ @these_bindings } = ();
  }
}
@gltags{keys %gltags} = map [sort keys %$_], values %gltags;
my %glcompat_c = map +($_=>undef), map @{$gltags{$_}}, @version_31;

use Data::Dumper;
$Data::Dumper::Indent = $Data::Dumper::Sortkeys = $Data::Dumper::Terse = 1;
sub dump_strip {
  my $vdump = Dumper $_[0];
  $vdump =~ s!^\{!!;
  $vdump =~ s!\s+\}$!!s;
  $vdump;
}

# Now rewrite registry if we need to:
my $new = <<"END";
package OpenGL::Modern::Registry;\n
=head1 NAME\n\nOpenGL::Modern::Registry - info about OpenGL\n
=head1 SYNOPSIS\n\n # example use of information to see how many GL 1.1
 # functions were removed in "core"
 perl -MOpenGL::Modern::Registry -E '%r = %OpenGL::Modern::Registry::registry;
  say "\$_,\$r{\$_}{feature},\$r{\$_}{core_removed}"
    for sort grep /^gl[A-Z]/, keys %r'|grep GL_VERSION_1_1,1|wc -l
 # answer: of 336, 275 were removed\n
=cut\n
# ATTENTION: This file is automatically generated by utils/generate-registry.pl
#            Manual changes will be lost.
use strict;
use warnings;\n
END
$new .= "our %registry = (@{[dump_strip(\%signature)]});\n\n";
my $glconstants = join '', "\n", map "  $_\n", sort keys %constants;
$new .= "our \@glconstants = qw($glconstants);\n\n";
$new .= "our %features = (@{[dump_strip(\%features)]});\n\n";
$new .= "our %counts = (@{[dump_strip(\%counts)]});\n\n";
$new .= "our %groups = (@{[dump_strip(\%groups)]});\n\n";
$new .= "our %enums = (@{[dump_strip(\%enums)]});\n\n";
$new .= "1;\n";
save_file( "lib/OpenGL/Modern/Registry.pm", $new );

my $orig = slurp("lib/OpenGL/Modern.pm");
my $sep = "# OGLM INSERT SEPARATOR\n";
my ($start, undef, $end) = split $sep, $orig;
my $middle = "# BEGIN code generated by utils/generate-registry.pl\n";
my $gl_functionscompat = join '', "\n", map "  $_\n", sort grep exists $glcompat_c{$_}, @exported_functions;
$middle .= "our \@gl_functionscompat = qw($gl_functionscompat);\n";
my $gl_functionsrest = join '', "\n", map "  $_\n", sort {uc$a cmp uc$b} grep !exists $glcompat_c{$_}, @exported_functions;
$middle .= "our \@gl_functionsrest = qw($gl_functionsrest);\n";
$middle .= "our %EXPORT_TAGS_GL = (@{[dump_strip(\%gltags)]});\n";
$middle .= "our \@gl_constants = qw($glconstants);\n\n";
$middle .= "# END code generated by utils/generate-registry.pl\n";
$new = join $sep, $start, $middle, $end;
save_file( "lib/OpenGL/Modern.pm", $new );

$orig = slurp("lib/OpenGL/Modern.pod");
$sep = "=for OGLM INSERT SEPARATOR\n\n";
($start, undef, my $p1, undef, $end) = split $sep, $orig;
$middle = "=for OGLM BEGIN docs generated by utils/generate-registry.pl\n\n";
$middle .= "=item $_\n\n" for sort keys %gltags;
$middle .= "=for OGLM END docs generated by utils/generate-registry.pl\n\n";
my $middle1 = '';
for my $name (sort grep !/^GL/, keys %signature) {
  $middle1 .= "=head2 $name\n\n";
  my $s = $signature{$name};
  my %dynlang = %{ $s->{dynlang} || {} };
  for my $bind (sort {$a->{binding_name} cmp $b->{binding_name}} bindings($name, $s, $g2c2s, \%signature)) {
    die "$name: $bind->{binding_name} has no xs_rettype" if !defined $bind->{xs_rettype};
    my $prefix = " ";
    if (my @retnames = @{ $bind->{retnames} }) {
      $prefix .= @retnames == 1 ? "$retnames[0] = " : "(@{[join ', ', @retnames]}) = ";
    }
    my $suffix .= "(";
    $suffix .= join ', ', @{ $bind->{innames} };
    $suffix .= ");\n";
    $middle1 .= "$prefix$_$suffix" for $bind->{binding_name}, @{ $bind->{aliases} };
  }
  $middle1 .= "\n";
  my $descrip = '';
  $descrip .= "Exported under tag C<:$s->{feature}>.\n" if $s->{feature};
  $descrip .= "Not available in a 'future-compatible' profile as removed in 3.2.\n" if $s->{core_removed};
  if ($s->{feature} =~ /^GL_VERSION/ and $name !~ /\d[a-z]{1,2}v?$/) {
    $descrip .= "See L<https://registry.khronos.org/OpenGL-Refpages/gl";
    $descrip .= ($s->{core_removed} ? "2.1/xhtml/$name.xml" : "4/html/$name.xhtml") . ">\n";
  }
  $descrip .= "\n" if $descrip;
  $middle1 .= $descrip;
}
$new = join $sep, $start, $middle, $p1, $middle1, $end;
save_file( "lib/OpenGL/Modern.pod", $new );

$new = <<"END";
/* This file is automatically generated by utils/generate-registry.pl
   Manual changes will be lost. */\n
END
for my $group (sort keys %$g2c2s) {
  my $c2syms = $g2c2s->{$group};
  my ($max) = sort { $b <=> $a } keys %$c2syms;
  $new .= "int oglm_count_$group(int param);\n";
}
save_file( "lib/OpenGL/Modern/gl_counts.h", $new );

$new = <<"END";
/* This file is automatically generated by utils/generate-registry.pl
   Manual changes will be lost. */\n
#include <GL/glew.h>\n
END
for my $group (sort keys %$g2c2s) {
  my $c2syms = $g2c2s->{$group};
  my @counts = sort { $a <=> $b } keys %$c2syms;
  $new .= "int oglm_count_$group(int param) {\n  switch (param) {\n";
  for my $c (@counts) {
    my $syms = $c2syms->{$c};
    $new .= join '', map "    case $_:\n", @$syms;
    $new .= "      return $c;\n";
  }
  $new .= "  }\n  return -1;\n}\n";
}
save_file( "lib/OpenGL/Modern/gl_counts.c", $new );
