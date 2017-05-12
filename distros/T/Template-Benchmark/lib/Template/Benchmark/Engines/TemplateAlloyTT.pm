package Template::Benchmark::Engines::TemplateAlloyTT;

use warnings;
use strict;

use base qw/Template::Benchmark::Engine/;

use Template::Alloy;

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
# TODO: ordering?
    hash_loop_value           =>
        '[% FOREACH k IN hash_loop %][% k.key %]: ' .
        '[% k.value %][% END %]',
    records_loop_value        =>
        '[% FOREACH r IN records_loop %][% r.name %]: ' .
        '[% r.age %][% END %]',
    array_loop_template       =>
        '[% FOREACH i IN array_loop %][% i %][% END %]',
# TODO: ordering?
    hash_loop_template        =>
        '[% FOREACH k IN hash_loop %][% k.key %]: ' .
        '[% k.value %][% END %]',
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
#  TODO: Hmm, this doesn't work, ideas anyone?
#        q{[% 'this has a substring.'.substr( 11, 9 ) %]},
        undef,
    variable_function         =>
        '[% variable_function_arg.substr( 4, 2 ) %]',
    );

sub syntax_type { return( 'mini-language' ); }
sub pure_perl { return( 1 ); }

sub benchmark_descriptions
{
    return( {
        TATT    =>
            "Template::Alloy ($Template::Alloy::VERSION) in " .
            "Template::Toolkit mode",
        TATT_S  =>
            "Template::Alloy ($Template::Alloy::VERSION) in " .
            "Template::Toolkit mode (using process_simple())",
        TATT_P  =>
            "Template::Alloy ($Template::Alloy::VERSION) in " .
            "Template::Toolkit mode (compile to perl)",
        TATT_PS =>
            "Template::Alloy ($Template::Alloy::VERSION) in " .
            "Template::Toolkit mode (compile to perl, using process_simple())",
        } );
}

sub benchmark_functions_for_uncached_string
{
    my ( $self ) = @_;

    return( {
        TATT =>
            sub
            {
                my $t = Template::Alloy->new(
                    VARIABLES      => $_[ 1 ],
                    CACHE_STR_REFS => 0,
                    );
                my $out = '';
                $t->process( \$_[ 0 ], $_[ 2 ], \$out );
                \$out;
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
    my ( @template_dirs );

    @template_dirs = ( $template_dir );

    return( {
        TATT =>
            sub
            {
                my $t = Template::Alloy->new(
                    VARIABLES    => $_[ 1 ],
                    INCLUDE_PATH => \@template_dirs,
                    COMPILE_DIR  => $cache_dir,
                    );
                my $out = '';
                $t->process( $_[ 0 ], $_[ 2 ], \$out );
                \$out;
            },
        TATT_S =>
            sub
            {
                my $t = Template::Alloy->new(
                    INCLUDE_PATH => \@template_dirs,
                    COMPILE_DIR  => $cache_dir,
                    );
                my $out = '';
                $t->process_simple( $_[ 0 ], { %{$_[ 1 ]}, %{$_[ 2 ]} },
                    \$out );
                \$out;
            },
        TATT_P =>
            sub
            {
                my $t = Template::Alloy->new(
                    VARIABLES    => $_[ 1 ],
                    INCLUDE_PATH => \@template_dirs,
                    COMPILE_DIR  => $cache_dir,
                    COMPILE_PERL => 1,
                    );
                my $out = '';
                $t->process( $_[ 0 ], $_[ 2 ], \$out );
                \$out;
            },
        TATT_PS =>
            sub
            {
                my $t = Template::Alloy->new(
                    INCLUDE_PATH => \@template_dirs,
                    COMPILE_DIR  => $cache_dir,
                    COMPILE_PERL => 1,
                    );
                my $out = '';
                $t->process_simple( $_[ 0 ], { %{$_[ 1 ]}, %{$_[ 2 ]} },
                    \$out );
                \$out;
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
    my ( $ta, $ta_s, $ta_p, $ta_ps, @template_dirs );

    @template_dirs = ( $template_dir );

    $ta = Template::Alloy->new(
        INCLUDE_PATH => \@template_dirs,
        COMPILE_DIR  => $cache_dir,
        );
    $ta_s = Template::Alloy->new(
        INCLUDE_PATH => \@template_dirs,
        COMPILE_DIR  => $cache_dir,
        );
    $ta_p = Template::Alloy->new(
        INCLUDE_PATH => \@template_dirs,
        COMPILE_DIR  => $cache_dir,
        COMPILE_PERL => 1,
        );
    $ta_ps = Template::Alloy->new(
        INCLUDE_PATH => \@template_dirs,
        COMPILE_DIR  => $cache_dir,
        COMPILE_PERL => 1,
        );

    return( {
        TATT =>
            sub
            {
                my $out = '';
                $ta->process( $_[ 0 ], { %{$_[ 1 ]}, %{$_[ 2 ]} }, \$out );
                \$out;
            },
        TATT_S =>
            sub
            {
                my $out = '';
                $ta_s->process_simple( $_[ 0 ], { %{$_[ 1 ]}, %{$_[ 2 ]} },
                    \$out );
                \$out;
            },
        TATT_P =>
            sub
            {
                my $out = '';
                $ta_p->process( $_[ 0 ], { %{$_[ 1 ]}, %{$_[ 2 ]} }, \$out );
                \$out;
            },
        TATT_PS =>
            sub
            {
                my $out = '';
                $ta_ps->process_simple( $_[ 0 ], { %{$_[ 1 ]}, %{$_[ 2 ]} },
                    \$out );
                \$out;
            },
        } );
}

1;

__END__

=pod

=head1 NAME

Template::Benchmark::Engines::TemplateAlloyTT - Template::Benchmark plugin for Template::Alloy in Template::Toolkit mode.

=head1 SYNOPSIS

Provides benchmark functions and template feature syntaxes to allow
L<Template::Benchmark> to benchmark the L<Template::Alloy> template
engine running in L<Template::Toolkit> emulation mode.

=head1 AUTHOR

Sam Graham, C<< <libtemplate-benchmark-perl at illusori.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-benchmark at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Benchmark>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Benchmark::Engines::TemplateAlloyTT


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
