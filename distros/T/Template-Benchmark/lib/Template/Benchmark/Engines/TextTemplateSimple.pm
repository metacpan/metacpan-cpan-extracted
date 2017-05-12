package Template::Benchmark::Engines::TextTemplateSimple;

use warnings;
use strict;

use base qw/Template::Benchmark::Engine/;

use Text::Template::Simple;

our $VERSION = '1.09';

our %feature_syntaxes = (
    literal_text              =>
        join( "\n", ( join( ' ', ( 'foo' ) x 12 ) ) x 5 ),
    scalar_variable           =>
        '<%= $p{scalar_variable} %>',
    hash_variable_value       =>
        '<%= $p{hash_variable}{hash_value_key} %>',
    array_variable_value      =>
        '<%= $p{array_variable}[ 2 ] %>',
    deep_data_structure_value =>
        '<%= $p{this}{is}{a}{very}{deep}{hash}{structure} %>',
    array_loop_value          =>
        '<% foreach ( @{$p{array_loop}} ) { %><%= $_ %><% } %>',
    hash_loop_value           =>
        '<% foreach ( sort( keys( %{$p{hash_loop}} ) ) ) { %>' .
        '<%= $_ %>: <%= $p{hash_loop}{$_} %>' .
        '<% } %>',
    records_loop_value        =>
        '<% foreach ( @{$p{records_loop}} ) { %>' .
        '<%= $_->{name} %>: <%= $_->{age} %>' .
        '<% } %>',
    array_loop_template       =>
        '<% foreach ( @{$p{array_loop}} ) { %><%= $_ %><% } %>',
    hash_loop_template        =>
        '<% foreach ( sort( keys( %{$p{hash_loop}} ) ) ) { %>' .
        '<%= $_ %>: <%= $p{hash_loop}{$_} %>' .
        '<% } %>',
    records_loop_template     =>
        '<% foreach ( @{$p{records_loop}} ) { %>' .
        '<%= $_->{name} %>: <%= $_->{age} %>' .
        '<% } %>',
    constant_if_literal       =>
        '<% if( 1 ) { %>true<% } %>',
    variable_if_literal       =>
        '<% if( $p{variable_if} ) { %>true<% } %>',
    constant_if_else_literal  =>
        '<% if( 1 ) { %>true<% } else { %>false<% } %>',
    variable_if_else_literal  =>
        '<% if( $p{variable_if_else} ) { %>true<% } else { %>' .
        'false<% } %>',
    constant_if_template      =>
        '<% if( 1 ) { %><%= $p{template_if_true} %><% } %>',
    variable_if_template      =>
        '<% if( $p{variable_if} ) { %><%= $p{template_if_true} %>' .
        '<% } %>',
    constant_if_else_template =>
        '<% if( 1 ) { %><%= $p{template_if_true} %><% } else { %>' .
        '<%= $p{template_if_false} %><% } %>',
    variable_if_else_template =>
        '<% if( $p{variable_if_else} ) { %>' .
        '<%= $p{template_if_true} %><% } else { %>' .
        '<%= $p{template_if_false} %><% } %>',
    constant_expression       =>
        '<%= 10 + 12 %>',
    variable_expression       =>
        '<%= $p{variable_expression_a} * ' .
        '$p{variable_expression_b} %>',
    complex_variable_expression =>
        '<%= ( ( $p{variable_expression_a} * ' .
        '$p{variable_expression_b} ) + ' .
        '$p{variable_expression_a} - ' .
        '$p{variable_expression_b} ) / ' .
        '$p{variable_expression_b} %>',
    constant_function         =>
        q{<%= substr( 'this has a substring.', 11, 9 ) %>},
    variable_function         =>
        '<%= substr( $p{variable_function_arg}, 4, 2 ) %>',
    );

sub syntax_type { return( 'embedded-perl' ); }
sub pure_perl { return( 1 ); }

sub benchmark_descriptions
{
    return( {
        TeTeSimp =>
            "Text::Template::Simple ($Text::Template::Simple::VERSION)",
        } );
}

sub benchmark_functions_for_uncached_string
{
    my ( $self ) = @_;

    return( {
        TeTeSimp =>
            sub
            {
                my $t = Text::Template::Simple->new(
                    header => 'my %p = @_;',
                    );
                \$t->compile( [ STRING => $_[ 0 ] ],
                    [ %{$_[ 1 ]}, %{$_[ 2 ]} ] );
            },
        } );
}

sub benchmark_functions_for_uncached_disk
{
    my ( $self, $template_dir ) = @_;
    my ( @template_dirs );

    @template_dirs = ( $template_dir );

    return( {
        TeTeSimp =>
            sub
            {
                my $t = Text::Template::Simple->new(
                    header        => 'my %p = @_;',
                    include_paths => \@template_dirs,
                    );
                \$t->compile( [ FILE => $_[ 0 ] ],
                    [ %{$_[ 1 ]}, %{$_[ 2 ]} ] );
            },
        } );
}

sub benchmark_functions_for_disk_cache
{
    my ( $self, $template_dir, $cache_dir ) = @_;
    my ( @template_dirs );

    @template_dirs = ( $template_dir );

    return( {
        TeTeSimp =>
            sub
            {
                my $t = Text::Template::Simple->new(
                    header        => 'my %p = @_;',
                    include_paths => \@template_dirs,
                    cache         => 1,
                    cache_dir     => $cache_dir,
                    );
                \$t->compile( [ FILE => $_[ 0 ] ],
                    [ %{$_[ 1 ]}, %{$_[ 2 ]} ] );
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
    my ( @template_dirs );

    @template_dirs = ( $template_dir );

    return( {
        TeTeSimp =>
            sub
            {
                my $t = Text::Template::Simple->new(
                    header        => 'my %p = @_;',
                    include_paths => \@template_dirs,
                    cache         => 1,
                    );
                \$t->compile( [ FILE => $_[ 0 ] ],
                    [ %{$_[ 1 ]}, %{$_[ 2 ]} ] );
            },
        } );
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

Template::Benchmark::Engines::TextTemplateSimple - Template::Benchmark plugin for Text::Template::Simple.

=head1 SYNOPSIS

Provides benchmark functions and template feature syntaxes to allow
L<Template::Benchmark> to benchmark the L<Text::Template::Simple> template
engine.

=head1 AUTHOR

Sam Graham, C<< <libtemplate-benchmark-perl at illusori.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-benchmark at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Benchmark>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Benchmark::Engines::TextTemplateSimple


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
