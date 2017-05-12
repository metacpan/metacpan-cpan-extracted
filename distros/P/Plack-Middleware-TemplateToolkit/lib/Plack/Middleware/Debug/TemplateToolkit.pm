package Plack::Middleware::Debug::TemplateToolkit;
# ABSTRACT: Debug panel for Template Toolkit middleware
$Plack::Middleware::Debug::TemplateToolkit::VERSION = '0.28';
use strict;
use warnings;
use 5.008_001;

use parent 'Plack::Middleware::Debug::Base';

sub run {
    my ( $self, $env, $panel ) = @_;

    return sub {
        my $res = shift;

        $panel->nav_subtitle( $env->{'tt.template'} )
            if defined $env->{'tt.template'};

        my $ttvars = "";
        if ( defined $env->{'tt.vars'} ) {
            $ttvars = '<h4>Template variables (tt.vars)</h4>'
                . $self->render_hash( delete $env->{'tt.vars'} );
        }

        my @ttkeys = grep { $_ =~ /^tt\./ } keys %$env;

        $panel->content(
            $self->render_list_pairs(
                [ map { $_ => delete $env->{$_} } sort @ttkeys ]
                )
                . $ttvars
        );
        }
}



1;

__END__

=head1 NAME

  Plack::Middleware::Debug::TemplateToolkit - debug panel for TemplateToolkit

=head1 SYNOPSIS

    builder {
        enable 'Debug';                     # enable debug
        enable 'Debug::TemplateToolkit';    # enable debug panel

        enable 'TemplateToolkit',
            INCLUDE_PATH => '/path/to/htdocs/',
            pass_through => 1;

        $app;
    };

=head1 DESCRIPTION

This L<Plack::Middleware::Debug> Panel shows which template and template
variables have been processed, and possibly other C<tt.> PSGI environment
variables.

=head1 AUTHOR

Jakob Voss

=cut
