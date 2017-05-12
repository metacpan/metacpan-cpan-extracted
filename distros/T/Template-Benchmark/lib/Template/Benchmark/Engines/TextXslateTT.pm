package Template::Benchmark::Engines::TextXslateTT;

use warnings;
use strict;

use base qw/Template::Benchmark::Engine/;

use Text::Xslate 0.1053;
use Text::Xslate::Bridge::TT2 1.0002;

our $VERSION = '1.09';

our %feature_syntaxes = (
    literal_text              =>
        join( "\n", ( join( ' ', ( 'foo' ) x 12 ) ) x 5 ),
    scalar_variable           =>
        '[% scalar_variable %]',
    hash_variable_value       =>
        '[% hash_variable.hash_value_key %]',
    array_variable_value      =>
        '[% array_variable.2 %]',
    deep_data_structure_value =>
        '[% this.is.a.very.deep.hash.structure %]',
    array_loop_value          =>
        '[% FOREACH i IN array_loop %][% i %][% END %]',
    hash_loop_value           =>
        undef,
#        '[% FOREACH k IN hash_loop %][% k.key %]: ' .
#        '[% k.value %][% END %]',
    records_loop_value        =>
        '[% FOREACH r IN records_loop %][% r.name %]: ' .
        '[% r.age %][% END %]',
    array_loop_template       =>
        '[% FOREACH i IN array_loop %][% i %][% END %]',
    hash_loop_template        =>
        undef,
#        '[% FOREACH k IN hash_loop %][% k.key %]: ' .
#        '[% k.value %][% END %]',
    records_loop_template     =>
        '[% FOREACH r IN records_loop %][% r.name %]: ' .
        '[% r.age %][% END %]',
    constant_if_literal       =>
        '[% IF 1 %]true[% END %]',
    variable_if_literal       =>
        '[% IF variable_if %]true[% END %]',
    constant_if_else_literal  =>
        '[% IF 1 %]true[% ELSE %]false[% END %]',
    variable_if_else_literal  =>
        '[% IF variable_if_else %]true[% ELSE %]false[% END %]',
    constant_if_template      =>
        '[% IF 1 %][% template_if_true %][% END %]',
    variable_if_template      =>
        '[% IF variable_if %][% template_if_true %][% END %]',
    constant_if_else_template =>
        '[% IF 1 %][% template_if_true %][% ELSE %]' .
        '[% template_if_false %][% END %]',
    variable_if_else_template =>
        '[% IF variable_if_else %][% template_if_true %][% ELSE %]' .
        '[% template_if_false %][% END %]',
    constant_expression       =>
        '[% 10 + 12 %]',
    variable_expression       =>
        '[% variable_expression_a * variable_expression_b %]',
    complex_variable_expression =>
        '[% ( ( variable_expression_a * variable_expression_b ) + ' .
        'variable_expression_a - variable_expression_b ) / ' .
        'variable_expression_b %]',
    constant_function         =>
        q{[% 'this has a substring.'.substr( 11, 9 ) %]},
#        undef,
    variable_function         =>
        '[% variable_function_arg.substr( 4, 2 ) %]',
    );

sub syntax_type { return( 'mini-language' ); }
sub pure_perl
{
    return( 1 ) if $ENV{ XSLATE } and $ENV{ XSLATE } =~ / \b pp \b /xms;
    return( 0 );
}

sub benchmark_descriptions
{
    if( __PACKAGE__->pure_perl() )
    {
        return( {
            TeXsTTPP  =>
                "Text::Xslate::PP ($Text::Xslate::PP::VERSION) " .
                    "in Template::Toolkit mode",
            } );
    }
    return( {
        TeXsTT    =>
            "Text::Xslate ($Text::Xslate::VERSION) " .
                "in Template::Toolkit mode",
        } );
}

sub benchmark_functions_for_uncached_string
{
    my ( $self ) = @_;

    return( {
        ( __PACKAGE__->pure_perl() ? 'TeXsTTPP' : 'TeXsTT' ) =>
            sub
            {
                my $t = Text::Xslate->new(
                    syntax => 'TTerse',
                    module => [ qw/Text::Xslate::Bridge::TT2/ ],
                    cache  => 0,
                    );
                \$t->render_string( $_[ 0 ], { %{$_[ 1 ]}, %{$_[ 2 ]} } );
            },
        } );
}

sub benchmark_functions_for_uncached_disk
{
    my ( $self, $template_dir ) = @_;
    my ( @template_dirs );

    @template_dirs = ( $template_dir );

    return( {
        ( __PACKAGE__->pure_perl() ? 'TeXsTTPP' : 'TeXsTT' ) =>
            sub
            {
                my $t = Text::Xslate->new(
                    syntax => 'TTerse',
                    module => [ qw/Text::Xslate::Bridge::TT2/ ],
                    path   => \@template_dirs,
                    cache  => 0,
                    );
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
        ( __PACKAGE__->pure_perl() ? 'TeXsTTPP' : 'TeXsTT' ) =>
            sub
            {
                my $t = Text::Xslate->new(
                    syntax    => 'TTerse',
                    module    => [ qw/Text::Xslate::Bridge::TT2/ ],
                    path      => \@template_dirs,
                    cache_dir => $cache_dir,
                    cache     => 2,
                    );
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

sub benchmark_functions_for_instance_reuse
{
    my ( $self, $template_dir, $cache_dir ) = @_;
    my ( @template_dirs, $t );

    @template_dirs = ( $template_dir );

    return( {
        ( __PACKAGE__->pure_perl() ? 'TeXsTTPP' : 'TeXsTT' ) =>
            sub
            {
                $t = Text::Xslate->new(
                    syntax    => 'TTerse',
                    module    => [ qw/Text::Xslate::Bridge::TT2/ ],
                    path      => \@template_dirs,
                    cache_dir => $cache_dir,
                    cache     => 2,
                    ) unless $t;
                \$t->render( $_[ 0 ], { %{$_[ 1 ]}, %{$_[ 2 ]} } );
            },
        } );
}

1;

__END__

=pod

=head1 NAME

Template::Benchmark::Engines::TextXslateTT - Template::Benchmark plugin for Text::Xslate in Template::Toolkit mode.

=head1 SYNOPSIS

Provides benchmark functions and template feature syntaxes to allow
L<Template::Benchmark> to benchmark the L<Text::Xslate> template
engine using the L<Text::Xslate::Syntax::TTerse> dialect and
L<Text::Xslate::Bridge::TT2> for L<Template::Toolkit> compatability.

Because L<Text::Xslate> and L<Text::Xslate::PP> trample over each other
if they're used in the same program there's no way to safely provide a
C<TextXslateTTPP> plugin, however if you set the XSLATE environment variable
to C<pp> as documented in L<Text::Xslate::PP>, this plugin will detect
that you're using the pure-perl backend.

=head1 AUTHORS

Sam Graham, C<< <libtemplate-benchmark-perl at illusori.co.uk> >>

Patches contributed by: Goro Fuji.

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-benchmark at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Benchmark>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Benchmark::Engines::TextXslateTT


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
