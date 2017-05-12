package Template::Benchmark::Engines::Solution;

use warnings;
use strict;

use base qw/Template::Benchmark::Engine/;

#  Need 0.000000004 for sorted hash-looping.
use Solution 0.000000004;
use Solution::Template;

our $VERSION = '1.09';

our %feature_syntaxes = (
    literal_text              =>
        join( "\n", ( join( ' ', ( 'foo' ) x 12 ) ) x 5 ),
    scalar_variable           =>
        '{{ scalar_variable }}',
    hash_variable_value       =>
        '{{ hash_variable.hash_value_key }}',
    array_variable_value      =>
        '{{ array_variable.2 }}',
    deep_data_structure_value =>
        '{{ this.is.a.very.deep.hash.structure }}',
    array_loop_value          =>
        '{% for i in array_loop %}{{ i }}{% endfor %}',
    hash_loop_value           =>
        '{% for k in hash_loop sorted %}{{ k.key }}: ' .
        '{{ k.value }}{% endfor %}',
    records_loop_value        =>
        '{% for r in records_loop %}{{ r.name }}: ' .
        '{{ r.age }}{% endfor %}',
    array_loop_template       =>
        '{% for i in array_loop %}{{ i }}{% endfor %}',
    hash_loop_template        =>
        '{% for k in hash_loop sorted %}{{ k.key }}: ' .
        '{{ k.value }}{% endfor %}',
    records_loop_template     =>
        '{% for r in records_loop %}{{ r.name }}: ' .
        '{{ r.age }}{% endfor %}',
    constant_if_literal       =>
        '{% if 1 %}true{% endif %}',
    variable_if_literal       =>
        '{% if variable_if %}true{% endif %}',
    constant_if_else_literal  =>
        '{% if 1 %}true{% else %}false{% endif %}',
    variable_if_else_literal  =>
        '{% if variable_if_else %}true{% else %}false{% endif %}',
    constant_if_template      =>
        '{% if 1 %}{{ template_if_true }}{% endif %}',
    variable_if_template      =>
        '{% if variable_if %}{{ template_if_true }}{% endif %}',
    constant_if_else_template =>
        '{% if 1 %}{{ template_if_true }}{% else %}' .
        '{{ template_if_false }}{% endif %}',
    variable_if_else_template =>
        '{% if variable_if_else %}{{ template_if_true }}{% else %}' .
        '{{ template_if_false }}{% endif %}',
    constant_expression       =>
        undef,
#        '{{ 10 + 12 }}',
    variable_expression       =>
        undef,
#        '{{ variable_expression_a * variable_expression_b }}',
    complex_variable_expression =>
        undef,
#        '{{ ( ( variable_expression_a * variable_expression_b ) + ' .
#        'variable_expression_a - variable_expression_b ) / ' .
#        'variable_expression_b }}',
    constant_function         =>
        undef,
#        q{{{ substr( 'this has a substring.', 11, 9 ) }}},
    variable_function         =>
        undef,
#        '{{ substr( variable_function_arg, 4, 2 ) }}',
    );

sub syntax_type { return( 'mini-language' ); }
sub pure_perl { return( 1 ); }

sub benchmark_descriptions
{
    return( {
        Sol    =>
            "Solution ($Solution::VERSION)",
        } );
}

sub benchmark_functions_for_uncached_string
{
    my ( $self ) = @_;

    return( {
        Sol =>
            sub
            {
                my $t = Solution::Template->new();
                $t->parse( $_[ 0 ] );
                \$t->render( { %{$_[ 1 ]}, %{$_[ 2 ]} } );
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

    #  Grr, another template engine that doesn't support files.
    return( {
        Sol =>
            sub
            {
                unless( $t )
                {
                    my ( $fh, $template );

                    $t = Solution::Template->new();
                    $fh = IO::File->new(
                        File::Spec->catfile( $template_dir, $_[ 0 ] ), '<' );
                    {
                        local $/ = undef;
                        $template = <$fh>;
                    }
                    $fh->close();

                    $t->parse( $template );
                }
                \$t->render( { %{$_[ 1 ]}, %{$_[ 2 ]} } );
            },
        } );
}

1;

__END__

=pod

=head1 NAME

Template::Benchmark::Engines::Solution - Template::Benchmark plugin for Solution.

=head1 SYNOPSIS

Provides benchmark functions and template feature syntaxes to allow
L<Template::Benchmark> to benchmark the L<Solution> template
engine.

=head1 AUTHOR

Sam Graham, C<< <libtemplate-benchmark-perl at illusori.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-benchmark at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Benchmark>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Benchmark::Engines::Solution


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
