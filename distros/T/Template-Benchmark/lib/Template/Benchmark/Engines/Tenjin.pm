package Template::Benchmark::Engines::Tenjin;

use warnings;
use strict;

use base qw/Template::Benchmark::Engine/;

use File::Spec;

#  0.05 has a different API to prior versions.
use Tenjin 0.05;

#  Governs how long cached files remain valid, given it can be ten
#  minutes or more after cache generation before it runs again, we
#  want to set this to a high value.
$Tenjin::TIMESTAMP_INTERVAL = 60 * 60 * 24;

use IO::File;

our $VERSION = '1.09';

our %feature_syntaxes = (
    literal_text              =>
        join( "\n", ( join( ' ', ( 'foo' ) x 12 ) ) x 5 ),
    scalar_variable           =>
        '[== $scalar_variable =]',
    hash_variable_value       =>
        '[== $hash_variable->{hash_value_key} =]',
    array_variable_value      =>
        '[== $array_variable->[ 2 ] =]',
    deep_data_structure_value =>
        '[== $this->{is}{a}{very}{deep}{hash}{structure} =]',
    array_loop_value          =>
        '<?pl foreach ( @{$array_loop} ) { ?>[== $_ =]<?pl } ?>' . "\n",
    hash_loop_value           =>
        '<?pl foreach ( sort( keys( %{$hash_loop} ) ) ) { ?>' .
        '[== $_ =]: [== $hash_loop->{$_} =]' .
        '<?pl } ?>' . "\n",
    records_loop_value        =>
        '<?pl foreach ( @{$records_loop} ) { ?>' .
        '[== $_->{name} =]: [== $_->{age} =]' .
        '<?pl } ?>' . "\n",
    array_loop_template       =>
        '<?pl foreach ( @{$array_loop} ) { ?>[== $_ =]<?pl } ?>' . "\n",
    hash_loop_template        =>
        '<?pl foreach ( sort( keys( %{$hash_loop} ) ) ) { ?>' .
        '[== $_ =]: [== $hash_loop->{$_} =]' .
        '<?pl } ?>' . "\n",
    records_loop_template     =>
        '<?pl foreach ( @{$records_loop} ) { ?>' .
        '[== $_->{name} =]: [== $_->{age} =]' .
        '<?pl } ?>' . "\n",
    constant_if_literal       =>
        '<?pl if( 1 ) { ?>true<?pl } ?>' . "\n",
    variable_if_literal       =>
        '<?pl if( $variable_if ) { ?>true<?pl } ?>' . "\n",
    constant_if_else_literal  =>
        '<?pl if( 1 ) { ?>true<?pl } else { ?>false<?pl } ?>' . "\n",
    variable_if_else_literal  =>
        '<?pl if( $variable_if_else ) { ?>true<?pl } else { ?>' .
        'false<?pl } ?>' . "\n",
    constant_if_template      =>
        '<?pl if( 1 ) { ?>[== $template_if_true =]<?pl } ?>' . "\n",
    variable_if_template      =>
        '<?pl if( ${variable_if} ) { ?>[== $template_if_true =]' .
        '<?pl } ?>' . "\n",
    constant_if_else_template =>
        '<?pl if( 1 ) { ?>[== $template_if_true =]<?pl } else { ?>' .
        '[== $template_if_false =]<?pl } ?>' . "\n",
    variable_if_else_template =>
        '<?pl if( $variable_if_else ) { ?>' .
        '[== $template_if_true =]<?pl } else { ?>' .
        '[== $template_if_false =]<?pl } ?>' . "\n",
    constant_expression       =>
        '[== 10 + 12 =]',
    variable_expression       =>
        '[== $variable_expression_a * ' .
        '$variable_expression_b =]',
    complex_variable_expression =>
        '[== ( ( $variable_expression_a * ' .
        '$variable_expression_b ) + ' .
        '$variable_expression_a - ' .
        '$variable_expression_b ) / ' .
        '$variable_expression_b =]',
    constant_function         =>
        q{[== substr( 'this has a substring.', 11, 9 ) =]},
    variable_function         =>
        '[== substr( $variable_function_arg, 4, 2 ) =]',
    );

sub syntax_type { return( 'embedded-perl' ); }
sub pure_perl { return( 1 ); }

sub benchmark_descriptions
{
    return( {
        Tenj    =>
            "Tenjin ($Tenjin::VERSION)",
        } );
}

sub benchmark_functions_for_uncached_string
{
    my ( $self ) = @_;

    return( undef );
}

sub benchmark_functions_for_uncached_disk
{
    my ( $self, $template_dir ) = @_;

    my ( @template_dirs );

    @template_dirs = ( $template_dir );

    return( {
        Tenj =>
            sub
            {
                my $t = Tenjin->new( {
                    path  => \@template_dirs,
                    cache => 0,
                    } );
                \$t->render( $_[ 0 ], { %{$_[ 1 ]}, %{$_[ 2 ]} } );
            },
        } );
}

sub benchmark_functions_for_disk_cache
{
    my ( $self, $template_dir, $cache_dir ) = @_;
    my ( @template_dirs );

    @template_dirs = ( $template_dir );

    return( {
        Tenj =>
            sub
            {
                my $t = Tenjin->new( {
                    path => \@template_dirs,
                    } );
                \$t->render( $_[ 0 ], { %{$_[ 1 ]}, %{$_[ 2 ]} } );
            },
        } );
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

#  TODO: this seems suspiciously slow, not sure it's caching.
sub benchmark_functions_for_instance_reuse
{
    my ( $self, $template_dir, $cache_dir ) = @_;
    my ( $t, @template_dirs );

    @template_dirs = ( $template_dir );

    return( {
        Tenj =>
            sub
            {
                $t = Tenjin->new( {
                    path => \@template_dirs,
                    } )
                    unless $t;
                \$t->render( $_[ 0 ], { %{$_[ 1 ]}, %{$_[ 2 ]} } );
            },
        } );
}

1;

__END__

=pod

=head1 NAME

Template::Benchmark::Engines::Tenjin - Template::Benchmark plugin for Tenjin.

=head1 SYNOPSIS

Provides benchmark functions and template feature syntaxes to allow
L<Template::Benchmark> to benchmark the L<Tenjin> template
engine.

=head1 AUTHOR

Sam Graham, C<< <libtemplate-benchmark-perl at illusori.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-benchmark at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Benchmark>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Benchmark::Engines::Tenjin


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
