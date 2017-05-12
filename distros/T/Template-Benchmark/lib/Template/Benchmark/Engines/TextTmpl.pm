package Template::Benchmark::Engines::TextTmpl;

use warnings;
use strict;

use base qw/Template::Benchmark::Engine/;

use Text::Tmpl;

use File::Spec;

our $VERSION = '1.09';

our %feature_syntaxes = (
    literal_text              =>
        join( "\n", ( join( ' ', ( 'foo' ) x 12 ) ) x 5 ),
    scalar_variable           =>
        '<!-- echo $scalar_variable -->',
    hash_variable_value       =>
        undef,
    array_variable_value      =>
        undef,
    deep_data_structure_value =>
        undef,
    array_loop_value          =>
        '<!-- loop "array_loop" --><!-- echo $value --><!-- endloop -->',
    hash_loop_value           =>
        '<!-- loop "hash_loop" --><!-- echo $key -->: <!-- echo $value --><!-- endloop -->',
    records_loop_value        =>
        '<!-- loop "records_loop" --><!-- echo $name -->: <!-- echo $age --><!-- endloop -->',
    array_loop_template       =>
        '<!-- loop "array_loop" --><!-- echo $value --><!-- endloop -->',
    hash_loop_template        =>
        '<!-- loop "hash_loop" --><!-- echo $key -->: <!-- echo $value --><!-- endloop -->',
    records_loop_template     =>
        '<!-- loop "records_loop" --><!-- echo $name -->: <!-- echo $age --><!-- endloop -->',
    constant_if_literal       =>
        undef,
    variable_if_literal       =>
        '<!-- if $variable_if -->true<!-- endif -->',
    constant_if_else_literal  =>
        undef,
    variable_if_else_literal  =>
        '<!-- if $variable_if_else -->true<!-- endif -->' .
        '<!-- ifn $variable_if_else -->false<!-- endifn -->',
    constant_if_template      =>
        undef,
    variable_if_template      =>
        '<!-- if $variable_if -->' .
            '<!-- echo $template_if_true -->' .
        '<!-- endif -->',
    constant_if_else_template =>
        undef,
    variable_if_else_template =>
        '<!-- if $variable_if_else -->' .
            '<!-- echo $template_if_true -->' .
        '<!-- endif -->' .
        '<!-- ifn $variable_if_else -->' .
            '<!-- echo $template_if_false-->' .
        '<!-- endifn -->',
    constant_expression       =>
        undef,
    variable_expression       =>
        undef,
    complex_variable_expression =>
        undef,
    constant_function         =>
        undef,
    variable_function         =>
        undef,
    );

sub syntax_type { return( 'mini-language' ); }
sub pure_perl { return( 0 ); }

sub benchmark_descriptions
{
    return( {
        TeTmpl    =>
            "Text::Tmpl ($Text::Tmpl::VERSION)",
        } );
}

sub benchmark_functions_for_uncached_string
{
    my ( $self ) = @_;

    return( {
        TeTmpl =>
            sub
            {
                my $t = Text::Tmpl->new();
                my $h = { %{$_[ 1 ]}, %{$_[ 2 ]} };
                #  Somewhat unfair since we cause the transform hit even
                #  if we're not benchmarking this feature, then again, everyone
                #  else has to store it in their stash too.
                foreach my $value ( @{$h->{ array_loop }} )
                {
                    $t->loop_iteration( 'array_loop' )->set_values(
                        { value => $value } );
                }
                foreach my $key ( sort( keys( %{$h->{ hash_loop }} ) ) )
                {
                    $t->loop_iteration( 'hash_loop' )->set_values(
                        { key => $key, value => $h->{ hash_loop }{ $key } } );
                }
                foreach my $record ( @{$h->{ records_loop }} )
                {
                    $t->loop_iteration( 'records_loop' )->set_values(
                        $record );
                }
                $t->set_values( $h );
                $t->set_delimiters( '<!--', '-->' );
                $t->set_strip( 0 );
                \$t->parse_string( $_[ 0 ] );
            },
        } );
}

sub benchmark_functions_for_uncached_disk
{
    my ( $self, $template_dir ) = @_;

    $template_dir .= '/';

    return( {
        TeTmpl =>
            sub
            {
                my $t = Text::Tmpl->new();
                my $h = { %{$_[ 1 ]}, %{$_[ 2 ]} };
                #  Somewhat unfair since we cause the transform hit even
                #  if we're not benchmarking this feature, then again, everyone
                #  else has to store it in their stash too.
                foreach my $value ( @{$h->{ array_loop }} )
                {
                    $t->loop_iteration( 'array_loop' )->set_values(
                        { value => $value } );
                }
                foreach my $key ( sort( keys( %{$h->{ hash_loop }} ) ) )
                {
                    $t->loop_iteration( 'hash_loop' )->set_values(
                        { key => $key, value => $h->{ hash_loop }{ $key } } );
                }
                foreach my $record ( @{$h->{ records_loop }} )
                {
                    $t->loop_iteration( 'records_loop' )->set_values(
                        $record );
                }
                $t->set_values( $h );
                $t->set_delimiters( '<!--', '-->' );
                $t->set_strip( 0 );
                $t->set_dir( $template_dir );
                \$t->parse_file( $_[ 0 ] );
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

Template::Benchmark::Engines::TextTmpl - Template::Benchmark plugin for Text::Tmpl.

=head1 SYNOPSIS

Provides benchmark functions and template feature syntaxes to allow
L<Template::Benchmark> to benchmark the L<Text::Tmpl> template
engine.

=head1 AUTHOR

Sam Graham, C<< <libtemplate-benchmark-perl at illusori.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-benchmark at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Benchmark>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Benchmark::Engines::TextTmpl


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
