package Template::Benchmark::Engines::NTSTemplate;

use warnings;
use strict;

use base qw/Template::Benchmark::Engine/;

use NTS::Template;

our $VERSION = '1.09';

our %feature_syntaxes = (
    literal_text              =>
        join( "\n", ( join( ' ', ( 'foo' ) x 12 ) ) x 5 ),
    scalar_variable           =>
        '[% scalar_variable %]',
    hash_variable_value       =>
        '[% hash_variable.hash_value_key %]',
    array_variable_value      =>
        undef,
    deep_data_structure_value =>
        '[% this.is.a.very.deep.hash.structure %]',
    array_loop_value          =>
        '[% FOREACH i = array_loop %][% i %][% END %]',
    hash_loop_value           =>
        undef,
    records_loop_value        =>
        '[% FOREACH r = records_loop %][% r.name %]: ' .
        '[% r.age %][% END %]',
    array_loop_template       =>
        '[% FOREACH i = array_loop %][% i %][% END %]',
    hash_loop_template        =>
        undef,
    records_loop_template     =>
        '[% FOREACH r = records_loop %][% r.name %]: ' .
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
sub pure_perl { return( 1 ); }

sub benchmark_descriptions
{
    return( {
        NT    =>
            "NTS::Template ($NTS::Template::VERSION)",
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

    return( {
        NT =>
            sub
            {
                my $t = NTS::Template->new();
                \$t->process( {
                    templ_dir   => $template_dir,
                    templ_file  => $_[ 0 ],
                    templ_vars  => { %{$_[ 1 ]} , %{$_[ 2 ]} },
                    templ_extra => {
#                        source => 1,
                        oreturn => 1,
                        },
                    } );
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

Template::Benchmark::Engines::NTSTemplate - Template::Benchmark plugin for NTS::Template.

=head1 SYNOPSIS

Provides benchmark functions and template feature syntaxes to allow
L<Template::Benchmark> to benchmark the L<NTS::Template> template
engine.

=head1 KNOWN ISSUES AND BUGS

=over

=item C<literal_text> can fail if only enabled feature

L<NTS::Template> appears to behave differently if there are no
I<template variables> to replace, compared to if there is only
literal-text.

The benchmark may not give the expected output in these
situations.

=back

=head1 AUTHOR

Sam Graham, C<< <libtemplate-benchmark-perl at illusori.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-benchmark at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Benchmark>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Benchmark::Engines::NTSTemplate


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
