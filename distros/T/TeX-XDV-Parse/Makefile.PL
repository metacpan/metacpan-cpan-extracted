use 5.005;
use strict;
use warnings;
use File::Basename ();
use ExtUtils::MakeMaker;

my $config_mods = {
    'ExtUtils::MakeMaker' => 0,
};

my $build_mods = {
    'strict'     => 0,
    'warnings'   => 0,
    'Exporter'   => 0,
    'Test::More' => 0,
    'Text::Diff' => 0,
};

my $run_mods = {
    'strict'          => 0,
    'warnings'        => 0,
    'constant'        => 0,
    'Exporter'        => 0,
    'TeX::DVI::Parse' => 0,
};

WriteMakefile(
    NAME               => 'TeX::XDV::Parse',
    VERSION_FROM       => 'lib/TeX/XDV/Parse.pm',
    PREREQ_PM          => $run_mods,
    BUILD_REQUIRES     => $build_mods,
    CONFIGURE_REQUIRES => $config_mods,
    LICENSE            => 'perl',
    ABSTRACT_FROM      => 'lib/TeX/XDV/Parse.pm',
    AUTHOR             => 'Rick Myers <jrm@cpan.org>',
    clean => {
        FILES => join ' ', qw{
            MANIFEST.bak
            MANIFEST.SKIP.bak
            t/tex/*.out
        },
    },
    postamble => {
        TEX2XDV => [ qw{
            t/tex/color.tex
            t/tex/print.tex
        }],
        RUN_MODULES    => [ sort mysort keys %$run_mods ],
        BUILD_MODULES  => [ sort mysort keys %{{%$build_mods, %$config_mods}} ],
    },
);

sub mysort {
    length($a) <=> length($b)
    or
    index($a,':') <=> index($b,':')
    or
    $a cmp $b
}

package MY;

# make README and INSTALL at 'make manifest' time
sub dist_basics {
    my $o = shift->SUPER::dist_basics(@_);
    $o =~ s/(manifest :)/$1 INSTALL README/m;
    return $o;
}

# add -Ilib so we can use our Test modules without installing
sub test_via_harness {
    my $o = shift->SUPER::test_via_harness(@_);
    $o =~ s!,!, 'inc',!;
    return $o;
}

sub postamble {
    my $o = shift->SUPER::postamble(@_);
    my $opts = {@_};

    #
    # add targets for html, pdf, xdv, and cmp generation
    #
    my $perl  = qq{\$(PERL) -Iinc -Iblib/lib -Iblib/arch};
    my $lh    = q{blib/script/latexhtml};
    my @all_files;
    my @pdf_files;
    my @html_files;
    for my $tex_file ( @{$opts->{TEX2HTML}} ) {
        (my $html_file = $tex_file) =~ s/\.tex$/.html/;
        (my $css_file  = $tex_file) =~ s/\.tex$/.css/;
        (my $pdf_file  = $tex_file) =~ s/\.tex$/.pdf/;
        my $tex_base = File::Basename::fileparse( $tex_file, '.tex' );
        push @all_files, $html_file, $css_file;
        push @html_files, $html_file;
        push @pdf_files, $pdf_file;
        my $args = qq{};
        $o .= qq{$html_file $css_file : pure_all $tex_file\n};
        $o .= qq{\t$perl $lh $args $tex_file\n};
        $o .= qq{\n};
        $o .= qq{$pdf_file : pure_all $tex_file\n};
        $o .= qq{\tcd t/tex && xelatex $tex_base\n};
        $o .= qq{\t\$(RM_F) t/tex/${tex_base}.aux\n};
        $o .= qq{\t\$(RM_F) t/tex/${tex_base}.log\n};
        $o .= qq{\n};
    }
    my @cmp_files;
    my @xdv_files;
    for my $tex_file ( @{$opts->{TEX2XDV}} ) {
        (my $xdv_file  = $tex_file) =~ s/\.tex$/.xdv/;
        (my $cmp_file  = $tex_file) =~ s/\.tex$/.cmp/;
        my $tex_base = File::Basename::fileparse( $tex_file, '.tex' );
        push @xdv_files, $xdv_file;
        push @cmp_files, $cmp_file;
        $o .= qq{$xdv_file : pure_all $tex_file\n};
        $o .= qq{\tcd t/tex && xelatex -no-pdf $tex_base\n};
        $o .= qq{\tcd t/tex && \$(RM_F) ${tex_base}.aux ${tex_base}.log\n};
        $o .= qq{\n};
        $o .= qq{$cmp_file : pure_all $xdv_file\n};
        $o .= qq{\t\$(ABSPERLRUNINST) -Iinc -MTeX::XDV::Print };
        $o .= qq{-e'TeX::XDV::Print->new(q{t/tex/${tex_base}.xdv})->parse' };
        $o .= qq{> t/tex/${tex_base}.cmp\n};
        $o .= qq{\n};
    }
    $o .= 'html : '. join(' ', @html_files). "\n\n";
    $o .= 'pdf : '. join(' ', @pdf_files). "\n\n";
    $o .= 'xdv : '. join(' ', @xdv_files). "\n\n";
    $o .= 'cmp : '. join(' ', @cmp_files). "\n\n";
    $o .= "clean_html :\n";
    $o .= "\t\$(RM_F) $_\n" for @all_files;
    $o .= "\n";
    $o .= "clean_pdf :\n";
    $o .= "\t\$(RM_F) $_\n" for @pdf_files;
    $o .= "\n";
    $o .= "clean_xdv :\n";
    $o .= "\t\$(RM_F) $_\n" for @xdv_files;
    $o .= "\n";
    $o .= "clean_cmp :\n";
    $o .= "\t\$(RM_F) $_\n" for @cmp_files;
    $o .= "\n";

    #
    # targets for the README and INSTALL files
    #
    my $run_mods   = join qq{ \\\n}, @{ $opts->{RUN_MODULES} };
    my $build_mods = join qq{ \\\n}, @{ $opts->{BUILD_MODULES} };
    $o .= "README : Makefile.PL lib/TeX/XDV/Parse.pm\n";
    $o .= qq{\tREADME_TYPE='readme' };
    $o .= qq{VERSION='\$(VERSION)' };
    $o .= qq{RUN_MODULES='${run_mods}' };
    $o .= qq{BUILD_MODULES='${build_mods}' };
    $o .= qq{bin/readme\n};
    $o .= "\n";
    $o .= "INSTALL : Makefile.PL lib/TeX/XDV/Parse.pm\n";
    $o .= qq{\tREADME_TYPE='install' };
    $o .= qq{VERSION='\$(VERSION)' };
    $o .= qq{RUN_MODULES='${run_mods}' };
    $o .= qq{BUILD_MODULES='${build_mods}' };
    $o .= qq{bin/readme\n};

    return $o;
}

1;

