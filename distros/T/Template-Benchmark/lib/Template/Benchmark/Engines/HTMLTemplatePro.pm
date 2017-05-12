package Template::Benchmark::Engines::HTMLTemplatePro;

use warnings;
use strict;

use base qw/Template::Benchmark::Engine/;

#  Need to use both these modules to prevent HTP from clobbering
#  their ISA and screwing up their use by other modules if it loads first.
use HTML::Template;
use HTML::Template::Expr;
use HTML::Template::Pro;

our $VERSION = '1.09';

our %feature_syntaxes = (
    literal_text              =>
        join( "\n", ( join( ' ', ( 'foo' ) x 12 ) ) x 5 ),
    scalar_variable           =>
        '<TMPL_VAR NAME=scalar_variable>',
    hash_variable_value       =>
        undef,
    array_variable_value      =>
        undef,
    deep_data_structure_value =>
        undef,
    array_loop_value          =>
        undef,
    hash_loop_value           =>
        undef,
    records_loop_value        =>
        '<TMPL_LOOP NAME=records_loop><TMPL_VAR NAME=name>: ' .
        '<TMPL_VAR NAME=age></TMPL_LOOP>',
    array_loop_template       =>
        undef,
    hash_loop_template        =>
        undef,
    records_loop_template     =>
        '<TMPL_LOOP NAME=records_loop><TMPL_VAR NAME=name>: ' .
        '<TMPL_VAR NAME=age></TMPL_LOOP>',
    constant_if_literal       =>
        '<TMPL_IF EXPR="1">true</TMPL_IF>',
    variable_if_literal       =>
        '<TMPL_IF NAME=variable_if>true</TMPL_IF>',
    constant_if_else_literal  =>
        '<TMPL_IF EXPR="1">true<TMPL_ELSE>false</TMPL_IF>',
    variable_if_else_literal  =>
        '<TMPL_IF NAME=variable_if_else>true<TMPL_ELSE>false</TMPL_IF>',
    constant_if_template      =>
        '<TMPL_IF EXPR="1"><TMPL_VAR NAME=template_if_true></TMPL_IF>',
    variable_if_template      =>
        '<TMPL_IF NAME=variable_if><TMPL_VAR NAME=template_if_true></TMPL_IF>',
    constant_if_else_template =>
        '<TMPL_IF EXPR="1"><TMPL_VAR NAME=template_if_true>' .
        '<TMPL_ELSE><TMPL_VAR NAME=template_if_false></TMPL_IF>',
    variable_if_else_template =>
        '<TMPL_IF NAME=variable_if_else><TMPL_VAR NAME=template_if_true>' .
        '<TMPL_ELSE><TMPL_VAR NAME=template_if_false></TMPL_IF>',
    constant_expression       =>
        '<TMPL_VAR EXPR="10 + 12">',
    variable_expression       =>
        '<TMPL_VAR EXPR="variable_expression_a * variable_expression_b">',
    complex_variable_expression =>
        '<TMPL_VAR EXPR="' .
        '( ( variable_expression_a * variable_expression_b ) + ' .
        'variable_expression_a - variable_expression_b ) / ' .
        'variable_expression_b">',
    constant_function         =>
        q{<TMPL_VAR EXPR="substr( 'this has a substring', 11, 9 )">},
    variable_function         =>
        '<TMPL_VAR EXPR="substr( variable_function_arg, 4, 2 )">',
    );

sub syntax_type { return( 'mini-language' ); }
sub pure_perl { return( 0 ); }

sub benchmark_descriptions
{
    return( {
        HTP    =>
            "HTML::Template::Pro ($HTML::Template::Pro::VERSION)",
        } );
}

sub benchmark_functions_for_uncached_string
{
    my ( $self ) = @_;

    return( {
        HTP =>
            sub
            {
                my $t = HTML::Template::Pro->new(
                    scalarref         => \$_[ 0 ],
                    case_sensitive    => 1,
                    die_on_bad_params => 0,
                    );
                $t->param( $_[ 1 ] );
                $t->param( $_[ 2 ] );
                my $out = $t->output();
                \$out;
            },
        } );
}

sub benchmark_functions_for_uncached_disk
{
    my ( $self, $template_dir ) = @_;
    my ( @template_dirs );

    @template_dirs = ( $template_dir );

    return( {
        HTP =>
            sub
            {
                my $t = HTML::Template::Pro->new(
                    path              => \@template_dirs,
                    filename          => $_[ 0 ],
                    case_sensitive    => 1,
                    die_on_bad_params => 0,
                    );
                $t->param( $_[ 1 ] );
                $t->param( $_[ 2 ] );
                my $out = $t->output();
                \$out;
            },
        } );
}

sub benchmark_functions_for_disk_cache
{
    my ( $self, $template_dir, $cache_dir ) = @_;

    return( undef );
}

sub benchmark_functions_for_shared_memory_cache
{
    my ( $self, $template_dir, $cache_dir ) = @_;

    return( undef );
}

sub benchmark_functions_for_memory_cache
{
    my ( $self, $template_dir, $cache_dir ) = @_;

    return( undef );
}

sub benchmark_functions_for_instance_reuse
{
    my ( $self, $template_dir, $cache_dir ) = @_;

    return( undef );
}

1;

__END__

=pod

=head1 NAME

Template::Benchmark::Engines::HTMLTemplatePro - Template::Benchmark plugin for HTML::Template::Pro.

=head1 SYNOPSIS

Provides benchmark functions and template feature syntaxes to allow
L<Template::Benchmark> to benchmark the L<HTML::Template::Pro> template
engine.

=head1 KNOWN ISSUES AND BUGS

Despite not using L<HTML::Template> or L<HTML::Template::Expr> directly,
this module needs to load them to prevent L<HTML::Template::Pro> from
clobbering their ISA and breaking other benchmark modules using them if
it is loaded first: in the event that you do not have either of those
modules installed, this benchmark will fail to load.

=head1 AUTHOR

Sam Graham, C<< <libtemplate-benchmark-perl at illusori.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-benchmark at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Benchmark>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Benchmark::Engines::HTMLTemplatePro


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Benchmark>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Benchmark>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Benchmark>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Benchmark/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Paul Seamons for creating the the bench_various_templaters.pl
script distributed with L<Template::Alloy>, which was the ultimate
inspiration for this module.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Sam Graham.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
