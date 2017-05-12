package Plack::Middleware::Profiler::KYTProf::Profile::TemplateEngine;
use strict;
use warnings;

sub load {
    my $class = shift;
    $class->_add_template_engine_profs;
}

sub _add_template_engine_profs {
    my $class = shift;
    $class->_add_xslate_prof;
    $class->_add_tt2_prof;
    $class->_add_template_pro_prof;
    $class->_add_mojo_template_prof;
}

sub _add_xslate_prof {
    my $class = shift;

    Devel::KYTProf->add_prof(
        "Text::Xslate",
        "render",
        sub {
            my ( $orig, $self, $file, $args ) = @_;
            return [
                '%s %s',
                ["render_method", "file"],
                {  
                    "render_method" => "render",
                    "file" => $file 
                },
            ];
        }
    );
}

sub _add_tt2_prof {
    my $class = shift;
    Devel::KYTProf->add_prof(
        "Template",
        "process",
        sub {
            my ( $orig, $class, $file, $args ) = @_;
            return [
                '%s %s',
                ["render_method", "file"],
                {  
                    "render_method" => "process",
                    "file" => $file 
                },
            ];
        }
    );
}

sub _add_mojo_template_prof {
    Devel::KYTProf->add_prof(
        "Mojo::Template",
        "render_file",
        sub {
            my ( $orig, $class, $file, $args ) = @_;
            return [
                '%s %s',
                ["render_method", "file"],
                {  
                    "render_method" => "render_file",
                    "file" => $file 
                },
            ];

        }
    );

    Devel::KYTProf->add_prof(
        "Mojo::Template",
        "render",
        sub {
            my ( $orig, $class, $args ) = @_;

            return [
                '%s',
                ["render_method"],
                {  
                    "render_method" => "render",
                },
            ];
        }
    );

}

sub _add_template_pro_prof {
    my $class = shift;
    Devel::KYTProf->add_prof(
        "HTML::Template::Pro",
        "output",
        sub {
            my ( $orig, $class, $args ) = @_;
            return sprintf '%s', "output";

            return [
                '%s',
                ["render_method"],
                {  
                    "render_method" => "output",
                },
            ]
        }
    );
}

1;
