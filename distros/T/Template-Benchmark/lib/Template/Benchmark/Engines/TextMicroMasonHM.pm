package Template::Benchmark::Engines::TextMicroMasonHM;

use warnings;
use strict;

use base qw/Template::Benchmark::Engine/;

use Text::MicroMason;

use File::Spec;

our $VERSION = '1.09';

our %feature_syntaxes = (
    literal_text              =>
        join( "\n", ( join( ' ', ( 'foo' ) x 12 ) ) x 5 ),
    scalar_variable           =>
        '<% $ARGS{scalar_variable} %>',
    hash_variable_value       =>
        '<% $ARGS{hash_variable}->{hash_value_key} %>',
    array_variable_value      =>
        '<% $ARGS{array_variable}->[ 2 ] %>',
    deep_data_structure_value =>
        '<% $ARGS{this}->{is}{a}{very}{deep}{hash}{structure} %>',
    array_loop_value          =>
        '% $_out->( $_ ) foreach @{$ARGS{array_loop}};' . "\n",
    hash_loop_value           =>
        '% $_out->( "$_: $ARGS{hash_loop}->{$_}" ) foreach sort( keys( %{$ARGS{hash_loop}} ) );' . "\n",
    records_loop_value        =>
        '% $_out->( "$_->{name}: $_->{age}" ) foreach @{$ARGS{records_loop}};' . "\n",
    array_loop_template       =>
        '<%perl>foreach ( @{$ARGS{array_loop}} ) {</%perl>' .
        '<% $_ %>' .
        '<%perl>}</%perl>' . "\n",
    hash_loop_template        =>
        '<%perl>foreach ( sort( keys( %{$ARGS{hash_loop}} ) ) ) {</%perl>' .
        '<% $_ %>: <% $ARGS{hash_loop}->{$_} %>' .
        '<%perl>}</%perl>' . "\n",
    records_loop_template     =>
        '<%perl>foreach ( @{$ARGS{records_loop}} ) {</%perl>' .
        '<% $_->{ name } %>: <% $_->{ age } %>' .
        '<%perl>}</%perl>' . "\n",
    constant_if_literal       =>
        '<%perl>if( 1 ) {</%perl>true<%perl>}</%perl>' . "\n",
    variable_if_literal       =>
        '<%perl>if( $ARGS{variable_if} ) {</%perl>true<%perl>}</%perl>' . "\n",
    constant_if_else_literal  =>
        '<%perl>if( 1 ) {</%perl>true<%perl>} else {</%perl>' .
        'false<%perl>}</%perl>' . "\n",
    variable_if_else_literal  =>
        '<%perl>if( $ARGS{variable_if_else} ) {</%perl>true<%perl>} ' .
        'else {</%perl>false<%perl>}</%perl>' . "\n",
    constant_if_template      =>
        '<%perl>if( 1 ) {</%perl>' .
        '<% $ARGS{template_if_true} %><%perl>}</%perl>' . "\n",
    variable_if_template      =>
        '<%perl>if( $ARGS{variable_if} ) {</%perl>' .
        '<% $ARGS{template_if_true} %><%perl>}</%perl>' . "\n",
    constant_if_else_template =>
        '<%perl>if( 1 ) {</%perl>' .
        '<% $ARGS{template_if_true} %><%perl>} ' .
        'else {</%perl>' .
        '<% $ARGS{template_if_false} %><%perl>}</%perl>' . "\n",
    variable_if_else_template =>
        '<%perl>if( $ARGS{variable_if_else} ) {</%perl>' .
        '<% $ARGS{template_if_true} %><%perl>} ' .
        'else {</%perl>' .
        '<% $ARGS{template_if_false} %><%perl>}</%perl>' . "\n",
    constant_expression       =>
        '<% 10 + 12 %>',
    variable_expression       =>
        '<% $ARGS{variable_expression_a} * $ARGS{variable_expression_b} %>',
    complex_variable_expression =>
        '<% ( ( $ARGS{variable_expression_a} * $ARGS{variable_expression_b} ) + ' .
        '$ARGS{variable_expression_a} - $ARGS{variable_expression_b} ) / ' .
        '$ARGS{variable_expression_b} %>',
    constant_function         =>
        q[<% substr( 'this has a substring.', 11, 9 ) %>],
    variable_function         =>
        '<% substr( $ARGS{variable_function_arg}, 4, 2 ) %>',
    );

sub syntax_type { return( 'embedded-perl' ); }
sub pure_perl { return( 1 ); }

sub benchmark_descriptions
{
    return( {
        TeMMHM    =>
            "Text::MicroMason ($Text::MicroMason::VERSION) using " .
                "Text::MicroMason::HTMLMason (no version number)",
        } );
}

sub benchmark_functions_for_uncached_string
{
    my ( $self ) = @_;

    return( {
        TeMMHM =>
            sub
            {
                my $t = Text::MicroMason->new();
                \$t->execute(
                    text => $_[ 0 ],
                    ( %{$_[ 1 ]}, %{$_[ 2 ]} ) );
            },
        } );
}

sub benchmark_functions_for_uncached_disk
{
    my ( $self, $template_dir ) = @_;

    return( {
        TeMMHM =>
            sub
            {
                my $t = Text::MicroMason->new();
                \$t->execute(
                    file => File::Spec->catfile( $template_dir, $_[ 0 ] ),
                    ( %{$_[ 1 ]}, %{$_[ 2 ]} ) );
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
    my ( $t );

    return( {
        TeMMHM =>
            sub
            {
                $t = Text::MicroMason->new()->compile(
                    file => File::Spec->catfile( $template_dir, $_[ 0 ] )
                    )
                    unless $t;
                \$t->( ( %{$_[ 1 ]}, %{$_[ 2 ]} ) );
            },
        } );
}

1;

__END__

=pod

=head1 NAME

Template::Benchmark::Engines::TextMicroMasonHM - Template::Benchmark plugin for Text::MicroMason in HTML::Mason mode.

=head1 SYNOPSIS

Provides benchmark functions and template feature syntaxes to allow
L<Template::Benchmark> to benchmark the L<Text::MicroMason> template
engine running in L<HTML::Mason> mode.

=head1 AUTHOR

Sam Graham, C<< <libtemplate-benchmark-perl at illusori.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-benchmark at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Benchmark>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Benchmark::Engines::TextMicroMasonHM


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
