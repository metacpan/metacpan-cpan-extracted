package Template::Benchmark::Engines::TextTemplet;

use warnings;
use strict;

use base qw/Template::Benchmark::Engine/;

use Text::Templet;

our $VERSION = '1.09';

use vars qw/$args $loop_counter @sorted_keys/;

our %feature_syntaxes = (
    literal_text              =>
        join( "\n", ( join( ' ', ( 'foo' ) x 12 ) ) x 5 ),
    scalar_variable           =>
        '$args->{scalar_variable}',
    hash_variable_value       =>
        '$args->{hash_variable}->{hash_value_key}',
    array_variable_value      =>
        '$args->{array_variable}->[ 2 ]',
    deep_data_structure_value =>
        '$args->{this}->{is}{a}{very}{deep}{hash}{structure}',
    array_loop_value          =>
        #  Oh good lord...
        '<% $loop_counter = -1 %>' .
        '<%LOOP%>' .
        '<% $loop_counter++; ' .
           'return "*LOOP" ' .
               'if $loop_counter >= scalar( @{$args->{array_loop}} ); "" %>' .
        '$args->{array_loop}->[$loop_counter]' .
        '<%*LOOP%>',
    hash_loop_value           =>
        #  Argh!
        '<% $loop_counter = -1 %>' .
        '<% @sorted_keys = sort( keys( %{$args->{hash_loop}} ) ) %>' .
        '<%LOOP%>' .
        '<% $loop_counter++; ' .
           'return "*LOOP" ' .
               'if $loop_counter >= scalar( @sorted_keys ); "" %>' .
        '$sorted_keys[$loop_counter]: ' .
        '$args->{hash_loop}->{$sorted_keys[$loop_counter]}' .
        '<%*LOOP%>',
    records_loop_value        =>
        '<% $loop_counter = -1 %>' .
        '<%LOOP%>' .
        '<% $loop_counter++; ' .
           'return "*LOOP" ' .
               'if $loop_counter >= scalar( @{$args->{records_loop}} ); "" %>' .
        '$args->{records_loop}->[$loop_counter]->{name}: ' .
        '$args->{records_loop}->[$loop_counter]->{age}' .
        '<%*LOOP%>',
    array_loop_template       =>
        '<% $loop_counter = -1 %>' .
        '<%LOOP%>' .
        '<% $loop_counter++; ' .
           'return "*LOOP" ' .
               'if $loop_counter >= scalar( @{$args->{array_loop}} ); "" %>' .
        '$args->{array_loop}->[$loop_counter]' .
        '<%*LOOP%>',
    hash_loop_template        =>
        #  Argh!
        '<% $loop_counter = -1 %>' .
        '<% @sorted_keys = sort( keys( %{$args->{hash_loop}} ) ) %>' .
        '<%LOOP%>' .
        '<% $loop_counter++; ' .
           'return "*LOOP" ' .
               'if $loop_counter >= scalar( @sorted_keys ); "" %>' .
        '$sorted_keys[$loop_counter]: ' .
        '$args->{hash_loop}->{$sorted_keys[$loop_counter]}' .
        '<%*LOOP%>',
    records_loop_template     =>
        '<% $loop_counter = -1 %>' .
        '<%LOOP%>' .
        '<% $loop_counter++; ' .
           'return "*LOOP" ' .
               'if $loop_counter >= scalar( @{$args->{records_loop}} ); "" %>' .
        '$args->{records_loop}->[$loop_counter]->{name}: ' .
        '$args->{records_loop}->[$loop_counter]->{age}' .
        '<%*LOOP%>',
    constant_if_literal       =>
        '<% "IF" unless 1 %>true<%IF%>',
    variable_if_literal       =>
        '<% "IF" unless $args->{variable_if} %>true<%IF%>',
    constant_if_else_literal  =>
        '<% "*ELSE" unless 1 %>true<%*ELSE%>false<%ELSE%>',
    variable_if_else_literal  =>
        '<% "*ELSE" unless $args->{variable_if_else} %>true<%*ELSE%>' .
        'false<%ELSE%>',
    constant_if_template      =>
        '<% "IF" unless 1 %>$args->{template_if_true}<%IF%>',
    variable_if_template      =>
        '<% "IF" unless $args->{variable_if} %>$args->{template_if_true}<%IF%>',
    constant_if_else_template =>
        '<% "*ELSE" unless 1 %>$args->{template_if_true}<%*ELSE%>' .
        '$args->{template_if_false}<%ELSE%>',
    variable_if_else_template =>
        '<% "*ELSE" unless $args->{variable_if_else} %>' .
        '$args->{template_if_true}<%*ELSE%>' .
        '$args->{template_if_false}<%ELSE%>',
    constant_expression       =>
        '<% &$_outf( 10 + 12 ) %>',
    variable_expression       =>
        '<% &$_outf( $args->{variable_expression_a} * ' .
        '$args->{variable_expression_b} ) %>',
    complex_variable_expression =>
        '<% &$_outf( ( ( $args->{variable_expression_a} * ' .
        '$args->{variable_expression_b} ) + ' .
        '$args->{variable_expression_a} - ' .
        '$args->{variable_expression_b} ) / ' .
        '$args->{variable_expression_b} ) %>',
    constant_function         =>
        q{<% &$_outf( substr( 'this has a substring.', 11, 9 ) ) %>},
    variable_function         =>
        '<% &$_outf( substr( $args->{variable_function_arg}, 4, 2 ) ) %>',
    );

sub syntax_type { return( 'embedded-perl' ); }
sub pure_perl { return( 1 ); }

sub benchmark_descriptions
{
    return( {
        TeTemplet    =>
            "Text::Templet ($Text::Templet::VERSION)",
        } );
}

#  Labels need to be unique, so we have to fudge them to work
#  with template_repeats.
sub preprocess_template
{
    my ( $self, $template ) = @_;
    my ( $label_id );

    #  Replace label pairs first.
    $label_id = 0;
    $template =~ s~IF~'IF' . ( int( $label_id++ / 2 ) )~geo;

    #  Replace label triplets next.
    $label_id = 0;
    $template =~ s~(\*?(?:LOOP|ELSE))~$1 . ( int( $label_id++ / 3 ) )~geo;

    return( $template );
}

sub benchmark_functions_for_uncached_string
{
    my ( $self ) = @_;

    return( {
        TeTemplet =>
            sub
            {
                local $args = { %{$_[ 1 ]}, %{$_[ 2 ]} };
                my $t = Templet( $_[ 0 ] );
                \$t;
            },
        } );

    return( undef );
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

    return( undef );
}

1;

__END__

=pod

=head1 NAME

Template::Benchmark::Engines::TextTemplet - Template::Benchmark plugin for Text::Templet.

=head1 SYNOPSIS

Provides benchmark functions and template feature syntaxes to allow
L<Template::Benchmark> to benchmark the L<Text::Templet> template
engine.

=head1 AUTHOR

Sam Graham, C<< <libtemplate-benchmark-perl at illusori.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-benchmark at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Benchmark>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Benchmark::Engines::TextTemplet


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
