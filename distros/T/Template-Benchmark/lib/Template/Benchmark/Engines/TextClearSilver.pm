package Template::Benchmark::Engines::TextClearSilver;

use warnings;
use strict;

use base qw/Template::Benchmark::Engine/;

use Text::ClearSilver;

our $VERSION = '1.09';

our %feature_syntaxes = (
    literal_text              =>
        join( "\n", ( join( ' ', ( 'foo' ) x 12 ) ) x 5 ),
    scalar_variable           =>
        '<?cs var:scalar_variable ?>',
    hash_variable_value       =>
        '<?cs var:hash_variable.hash_value_key ?>',
    array_variable_value      =>
        '<?cs var:array_variable[ 2 ] ?>',
    deep_data_structure_value =>
        '<?cs var:this.is.a.very.deep.hash.structure ?>',
    array_loop_value          =>
        '<?cs each:i = array_loop ?><?cs var:i ?><?cs /each ?>',
    hash_loop_value           =>
        undef,
#  This works but is unsorted, so we can't compare the output.
#        '<?cs each:k = hash_loop ?><?cs name:k ?>: ' .
#        '<?cs var:k ?><?cs /each ?>',
    records_loop_value        =>
        '<?cs each:r = records_loop ?><?cs var:r.name ?>: ' .
        '<?cs var:r.age ?><?cs /each ?>',
    array_loop_template       =>
        '<?cs each:i = array_loop ?><?cs var:i ?><?cs /each ?>',
    hash_loop_template        =>
        undef,
#  This works but is unsorted, so we can't compare the output.
#        '<?cs each:k = hash_loop ?><?cs name:k ?>: ' .
#        '<?cs var:k ?><?cs /each ?>',
    records_loop_template     =>
        '<?cs each:r = records_loop ?><?cs var:r.name ?>: ' .
        '<?cs var:r.age ?><?cs /each ?>',
    constant_if_literal       =>
        '<?cs if 1 ?>true<?cs /if ?>',
    variable_if_literal       =>
        '<?cs if variable_if ?>true<?cs /if ?>',
    constant_if_else_literal  =>
        '<?cs if 1 ?>true<?cs else ?>false<?cs /if ?>',
    variable_if_else_literal  =>
        '<?cs if variable_if_else ?>true<?cs else ?>false<?cs /if ?>',
    constant_if_template      =>
        '<?cs if 1 ?><?cs var:template_if_true ?><?cs /if ?>',
    variable_if_template      =>
        '<?cs if variable_if ?><?cs var:template_if_true ?><?cs /if ?>',
    constant_if_else_template =>
        '<?cs if 1 ?><?cs var:template_if_true ?><?cs else ?>' .
        '<?cs var:template_if_false ?><?cs /if ?>',
    variable_if_else_template =>
        '<?cs if variable_if_else ?><?cs var:template_if_true ?><?cs else ?>' .
        '<?cs var:template_if_false ?><?cs /if ?>',
    constant_expression       =>
        '<?cs var:10 + 12 ?>',
    variable_expression       =>
        '<?cs var:variable_expression_a * variable_expression_b ?>',
    complex_variable_expression =>
        '<?cs var:( ( variable_expression_a * variable_expression_b ) + ' .
        'variable_expression_a - variable_expression_b ) / ' .
        'variable_expression_b ?>',
    constant_function         =>
        q{<?cs var:string.slice( 'this has a substring.', 11, 20 ) ?>},
    variable_function         =>
        '<?cs var:string.slice( variable_function_arg, 4, 6 ) ?>',
    );

sub syntax_type { return( 'mini-language' ); }
sub pure_perl { return( 0 ); }

sub benchmark_descriptions
{
    return( {
        TeCS   =>
            "Text::ClearSilver ($Text::ClearSilver::VERSION)",
        } );
}

sub benchmark_functions_for_uncached_string
{
    my ( $self ) = @_;

    return( {
      TeCS =>
            sub
            {
                my $t = Text::ClearSilver->new();
                my $out = '';
                $t->process( \$_[ 0 ], { %{$_[ 1 ]}, %{$_[ 2 ]} }, \$out );
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
      TeCS =>
            sub
            {
                my $t = Text::ClearSilver->new(
                    load_path => \@template_dirs,
                    );
                my $out = '';
                $t->process( $_[ 0 ], { %{$_[ 1 ]}, %{$_[ 2 ]} }, \$out );
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
    my ( $t, @template_dirs );

    @template_dirs = ( $template_dir );

    $t = Text::ClearSilver->new(
        load_path => \@template_dirs,
        );

    return( {
      TeCS =>
            sub
            {
                my $out = '';
                $t->process( $_[ 0 ], { %{$_[ 1 ]}, %{$_[ 2 ]} }, \$out );
                \$out;
            },
        } );
}

1;

__END__

=pod

=head1 NAME

Template::Benchmark::Engines::TextClearSilver - Template::Benchmark plugin for Text::ClearSilver.

=head1 SYNOPSIS

Provides benchmark functions and template feature syntaxes to allow
L<Template::Benchmark> to benchmark the L<Text::ClearSilver> template
engine.

C<hash_loop_variable> and C<hash_loop_template> are not currently
supported, although the underlying L<Text::ClearSilver> engine supports
them.
Their output is unsorted, making it impossible to compare
template output with other template engines to check for accuracy of
output.
This may be possible to correct in a future release.

=head1 AUTHOR

Sam Graham, C<< <libtemplate-benchmark-perl at illusori.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-benchmark at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Benchmark>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Benchmark::Engines::TextClearSilver


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
