package Template::Benchmark::Engines::ParseTemplate;

use warnings;
use strict;

use base qw/Template::Benchmark::Engine/;

use Parse::Template;

our $VERSION = '1.09';

our %feature_syntaxes = (
    literal_text              =>
        join( "\n", ( join( ' ', ( 'foo' ) x 12 ) ) x 5 ),
    scalar_variable           =>
        '%% $scalar_variable %%',
    hash_variable_value       =>
        '%% $hash_variable{hash_value_key} %%',
    array_variable_value      =>
        '%% $array_variable[ 2 ] %%',
    deep_data_structure_value =>
        '%% $this{is}{a}{very}{deep}{hash}{structure} %%',
    array_loop_value          =>
        q|%% join( '', @array_loop ) %%|,
    hash_loop_value           =>
        q|%% join( '', map { $_ . ': ' . $hash_loop{$_} } | .
        q|sort( keys( %hash_loop ) ) ) %%|,
    records_loop_value        =>
        q|%% join( '', map { $_->{ name } . ': ' . $_->{ age } } | .
        q|@records_loop ) %%|,
    array_loop_template       =>
        #  Can't be done under the paradigm of Template::Benchmark,
        #  each content block needs to a separate template.
        undef,
    hash_loop_template        =>
        #  Can't be done under the paradigm of Template::Benchmark,
        #  each content block needs to a separate template.
        undef,
    records_loop_template     =>
        #  Can't be done under the paradigm of Template::Benchmark,
        #  each content block needs to a separate template.
        undef,
    constant_if_literal       =>
        q|%% if( 1 ) { 'true' } %%|,
    variable_if_literal       =>
        q|%% if( $variable_if ) { 'true' } %%|,
    constant_if_else_literal  =>
        q|%% if( 1 ) { 'true' } else { 'false' } %%|,
    variable_if_else_literal  =>
        q|%% if( $variable_if_else ) { 'true' } else { | .
        q|'false' } %%|,
    constant_if_template      =>
        #  Can't be done under the paradigm of Template::Benchmark,
        #  each content block needs to a separate template.
        undef,
    variable_if_template      =>
        #  Can't be done under the paradigm of Template::Benchmark,
        #  each content block needs to a separate template.
        undef,
    constant_if_else_template =>
        #  Can't be done under the paradigm of Template::Benchmark,
        #  each content block needs to a separate template.
        undef,
    variable_if_else_template =>
        #  Can't be done under the paradigm of Template::Benchmark,
        #  each content block needs to a separate template.
        undef,
    constant_expression       =>
        '%% 10 + 12 %%',
    variable_expression       =>
        '%% $variable_expression_a * ' .
        '$variable_expression_b %%',
    complex_variable_expression =>
        '%% ( ( $variable_expression_a * ' .
        '$variable_expression_b ) + ' .
        '$variable_expression_a - ' .
        '$variable_expression_b ) / ' .
        '$variable_expression_b %%',
    constant_function         =>
        q{%% substr( 'this has a substring.', 11, 9 ) %%},
    variable_function         =>
        '%% substr( $variable_function_arg, 4, 2 ) %%',
    );

sub syntax_type { return( 'embedded-perl' ); }
sub pure_perl { return( 1 ); }

sub benchmark_descriptions
{
    return( {
        PT    =>
            "Parse::Template ($Parse::Template::VERSION)",
        } );
}

sub benchmark_functions_for_uncached_string
{
    my ( $self ) = @_;

    return( {
        PT =>
            sub
            {
                my $t = Parse::Template->new(
                    TOP => $_[ 0 ],
                    );
                $t->env( %{$_[ 1 ]} );
                $t->env( %{$_[ 2 ]} );
                \$t->eval( 'TOP' );
            },
        } );
}

sub benchmark_functions_for_uncached_disk
{
    my ( $self, $template_dir ) = @_;

    return( undef );
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
    my ( $t );

    #  Ew ick, I was almost templated to leave this as "unsupported"
    #  given how much crud I need to wrap around the template engine
    #  to get it to do this basic task.
    return( {
        PT =>
            sub
            {
                unless( $t )
                {
                    my ( $fh, $template );

                    $fh = IO::File->new(
                        File::Spec->catfile( $template_dir, $_[ 0 ] ), '<' );
                    {
                        local $/ = undef;
                        $template = <$fh>;
                    }
                    $fh->close();

                    $t = Parse::Template->new(
                        TOP => $template,
                        );
                }
                $t->env( %{$_[ 1 ]} );
                $t->env( %{$_[ 2 ]} );
                \$t->eval( 'TOP' );
            },
        } );
}

1;

__END__

=pod

=head1 NAME

Template::Benchmark::Engines::ParseTemplate - Template::Benchmark plugin for Parse::Template.

=head1 SYNOPSIS

Provides benchmark functions and template feature syntaxes to allow
L<Template::Benchmark> to benchmark the L<Parse::Template> template
engine.

=head1 AUTHOR

Sam Graham, C<< <libtemplate-benchmark-perl at illusori.co.uk> >>

=head1 KNOWN BUGS AND ISSUES

Because of the paradigm of L<Parse::Template> to define sub-blocks of
the template separately from the main template, it isn't possible to
provide support for the C<_template> forms of the block and if features
under L<Template::Benchmark>, which expects them to be inline within
the main template.

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-benchmark at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Benchmark>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Benchmark::Engines::ParseTemplate


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
