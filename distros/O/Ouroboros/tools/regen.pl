#!/usr/bin/env perl

use strict;
use warnings;
use autodie;
use File::Slurp;
use Data::Dumper;

use lib "tools/lib";
use SpecParser;

sub pthx {
    my $fn = shift;
    if (!$fn->{tags}{no_pthx}) {
        @{$fn->{params}} ? "pTHX_ ": "pTHX"
    } else {
        ""
    }
}

open my $spec_fh, "<", "libouroboros.txt";
my $spec = SpecParser::parse_fh($spec_fh);

foreach my $fn (@{$spec->{fn}}) {
    # ptr_name is a name of sub that returns pointer to the wrapper.
    $fn->{ptr_name} = "$fn->{name}_ptr";

    $fn->{c_decl} = sprintf(
        "OUROBOROS_STATIC %s %s(%s%s);",
        $fn->{type},
        $fn->{name},
        pthx($fn),
        join(", ", @{$fn->{params}}));

    chomp $fn->{tags}{apidoc} if defined $fn->{tags}{apidoc};
}

{
    open my $xs, ">", "fn-pointer-xs.inc";

    foreach my $fn (@{$spec->{fn}}) {
        $xs->print("void*\n$fn->{ptr_name}()\n");
        $xs->print("CODE:\n\tRETVAL = $fn->{name};\nOUTPUT:\n\tRETVAL\n\n");
    }
}

sub make_fn_doc {
    my $fn = shift;

    my $impl = $fn->{tags}{_autoimpl} ? $fn->{tags}{_autoimpl}[0] : "";
    my $decl = $fn->{c_decl};

    my $doc = "=item $fn->{ptr_name}\n\n";

    $doc .= "    $fn->{c_decl}\n\n";

    $doc .= "$fn->{tags}{apidoc}\n\n" if $fn->{tags}{apidoc};

    $doc .= "Perl macro: C<$impl>\n\n" if $impl;

    return $doc;
}

{
    my $package = "lib/Ouroboros.pm";
    my $pm = read_file($package);
    my $shims = join "", map "    $_->{ptr_name}\n", @{$spec->{fn}};
    $pm =~ s/(our\s+\@EXPORT_OK\s*=\s*qw\()[^\)]*(\);)/$1\n$shims$2/m or die;

    my $fn_doc = join "", map make_fn_doc($_), @{$spec->{fn}};
    $pm =~ s/(\n=head1 METHODS\n\n.*?\n\n=over\n\n).*?(\n\n=back\n\n)/$1$fn_doc$2/ms or die;

    my $consts = join "", map "=item C<$_->{name}>\n\n", @{$spec->{enum}}, @{$spec->{const}};
    $pm =~ s/(\n=head1 CONSTANTS\n\n.*?\n\n=over\n\n).*?(\n\n=back\n\n)/$1$consts$2/ms or die;

    write_file($package, $pm);
}

{
    my $source = "Ouroboros.xs";
    my $xs = read_file($source);
    my $sizes = join "", map "\t\tSS($_->{type});\n", @{$spec->{sizeof}};
    $xs =~ s!(/\*\s*sizeof\s*{\s*\*/)[^}]*(/\*\s*}\s*\*/)!$1\n$sizes$2!m or die;
    write_file($source, $xs);
}

{
    my $decls = do {
        local $" = ", ";
        join "", map "$_->{c_decl}\n", @{$spec->{fn}}
    };

    my $header = "libouroboros.h";
    my $ch = read_file($header);
    $ch =~ s!(/\*\s*functions\s*{\s*\*/)[^}]*(/\*\s*}\s*\*/)!$1\n$decls$2!m or die;
    write_file($header, $ch);
}

sub mk_impl {
    my $fn = shift;

    my $pname = "a";
    my $svn = "";

    my ($macro_name, @hints) = @{$fn->{tags}{_autoimpl}};

    my (@decl, @impl);

    # A couple of macros take an explicit SP argument, while most do not.  We
    # keep SP inside the stack object and thus this extra argument does not
    # leak into public API.
    push @impl, "SP" if $fn->{tags}{_needs_sp};

    foreach my $ptype (@{$fn->{params}}) {
        my $hint = shift @hints // "";
        my $is_stack = $ptype eq "ouroboros_stack_t*";
        my $name =
            $is_stack
            ? "stack"
            : $ptype eq "SV*"
            ? "sv" . $svn++
            : $pname++;
        push @decl, "$ptype $name";
        push @impl, "$hint$name" unless $is_stack;
    }

    return sprintf("%s %s(%s%s)\n{\n        %s%s%s;\n}\n",
        $fn->{type}, $fn->{name}, pthx($fn),
        join(", ", @decl),
        $fn->{type} eq "void" ? "" : "return ",
        $macro_name,
        @impl ? map("($_)", join ", ", @impl) : $fn->{tags}{_parens} ? "()" : ""
    );
}

{
    my $impls = join "\n", map mk_impl($_), grep $_->{tags}{_autoimpl}, @{$spec->{fn}};
    my $source = "libouroboros.c";
    my $cc = read_file($source);
    $cc =~ s!(/\*\s*functions\s*{\s*\*/).*?(/\*\s*}\s*\*/)!$1\n$impls$2!s or die;
    write_file($source, $cc);
}

{
    my $consts = join "",
        map("    $_,\n",
            map("{ name => '$_->{name}', type => '$_->{perl_type}', macro => 1 }", @{$spec->{enum}}),
            map("{ name => '$_->{name}', type => '$_->{perl_type}' }", @{$spec->{const}}));

    my $makefile = "Makefile.PL";
    my $mf = read_file($makefile);
    $mf =~ s/(my\s+\@consts\s*=\s*\()[^\)]*(\);)/$1\n$consts$2/m or die;
    write_file($makefile, $mf);
}

sub strip_private {
    my $self = shift;
    if (ref $self eq "ARRAY") {
        return [ map strip_private($_), @$self ];
    }
    if (ref $self eq "HASH") {
        return { map $_ !~ /^_/ ? ($_ => strip_private($self->{$_})) : (), keys %$self };
    }
    return $self;
}

{
    my $pub_spec = strip_private($spec);
    my $dump = Data::Dumper->new([$pub_spec], ["*SPEC"])
        ->Useqq(1)
        ->Indent(1)
        ->Sortkeys(1);
    my $text = $dump->Dump;

    my $package = "lib/Ouroboros/Spec.pm";
    my $pm = read_file($package);
    $pm =~ s/^(#\s*spec\s*{).*?(^#\s*})/$1\nour $text\n$2/ms or die;
    write_file($package, $pm);
}
