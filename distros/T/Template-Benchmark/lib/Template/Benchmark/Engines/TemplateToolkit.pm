package Template::Benchmark::Engines::TemplateToolkit;

use warnings;
use strict;

use base qw/Template::Benchmark::Engine/;

use Template;
use Template::Stash;
use Template::Stash::XS;
use Template::Parser::CET;

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
sub pure_perl
{
    return( {
        TT      => 1,
        TT_X    => 0,
        TT_XCET => 0,
        } );
}

sub benchmark_descriptions
{
    return( {
        TT    =>
            "Template::Toolkit ($Template::VERSION)",
        TT_X =>
            "Template::Toolkit ($Template::VERSION) with " .
            "Stash::XS (no version number)",
        TT_XCET =>
            "Template::Toolkit ($Template::VERSION) with " .
            "Stash::XS (no version number) and " .
            "Template::Parser::CET ($Template::Parser::CET::VERSION)",
        } );
}

sub benchmark_functions_for_uncached_string
{
    my ( $self ) = @_;

    return( {
        TT =>
            sub
            {
                my $t = Template->new(
                    STASH => Template::Stash->new( $_[ 1 ] ),
                    );
                my $out;
                $t->process( \$_[ 0 ], $_[ 2 ], \$out );
                \$out;
            },
        TT_X =>
            sub
            {
                my $t = Template->new(
                    STASH => Template::Stash::XS->new( $_[ 1 ] ),
                    );
                my $out;
                $t->process( \$_[ 0 ], $_[ 2 ], \$out );
                \$out;
            },
        TT_XCET =>
            sub
            {
                my $t = Template->new(
                    STASH  => Template::Stash::XS->new( $_[ 1 ] ),
                    PARSER => Template::Parser::CET->new(),
                    );
                my $out;
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
        TT =>
            sub
            {
                my $t = Template->new(
                    STASH        => Template::Stash->new( $_[ 1 ] ),
                    INCLUDE_PATH => \@template_dirs,
                    COMPILE_DIR  => $cache_dir,
                    );
                my $out;
                $t->process( $_[ 0 ], $_[ 2 ], \$out );
                \$out;
            },
        TT_X =>
            sub
            {
                my $t = Template->new(
                    STASH        => Template::Stash::XS->new( $_[ 1 ] ),
                    INCLUDE_PATH => \@template_dirs,
                    COMPILE_DIR  => $cache_dir,
                    );
                my $out;
                $t->process( $_[ 0 ], $_[ 2 ], \$out );
                \$out;
            },
        TT_XCET =>
            sub
            {
                my $t = Template->new(
                    STASH        => Template::Stash::XS->new( $_[ 1 ] ),
                    PARSER       => Template::Parser::CET->new(),
                    INCLUDE_PATH => \@template_dirs,
                    COMPILE_DIR  => $cache_dir,
                    );
                my $out;
                $t->process( $_[ 0 ], $_[ 2 ], \$out );
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
    my ( $tt, $tt_x, $tt_xcet, @template_dirs );

    @template_dirs = ( $template_dir );

    $tt     = Template->new(
        STASH        => Template::Stash->new(),
        INCLUDE_PATH => \@template_dirs,
        );
    $tt_x   = Template->new(
        STASH        => Template::Stash::XS->new(),
        INCLUDE_PATH => \@template_dirs,
        );
    $tt_xcet = Template->new(
        STASH        => Template::Stash::XS->new(),
        PARSER       => Template::Parser::CET->new(),
        INCLUDE_PATH => \@template_dirs,
        );
    return( {
        TT =>
            sub
            {
                my $out;
                $tt->process( $_[ 0 ], { %{$_[ 1 ]}, %{$_[ 2 ]} }, \$out );
                \$out;
            },
        TT_X =>
            sub
            {
                my $out;
                $tt_x->process( $_[ 0 ], { %{$_[ 1 ]}, %{$_[ 2 ]} }, \$out );
                \$out;
            },
        TT_XCET =>
            sub
            {
                my $out;
                $tt_xcet->process( $_[ 0 ], { %{$_[ 1 ]}, %{$_[ 2 ]} }, \$out );
                \$out;
            },
        } );
}

1;

__END__

=pod

=head1 NAME

Template::Benchmark::Engines::TemplateToolkit - Template::Benchmark plugin for Template::Toolkit.

=head1 SYNOPSIS

Provides benchmark functions and template feature syntaxes to allow
L<Template::Benchmark> to benchmark the L<Template::Toolkit> template
engine.

=head1 AUTHOR

Sam Graham, C<< <libtemplate-benchmark-perl at illusori.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-benchmark at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Benchmark>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Benchmark::Engines::TemplateToolkit


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
