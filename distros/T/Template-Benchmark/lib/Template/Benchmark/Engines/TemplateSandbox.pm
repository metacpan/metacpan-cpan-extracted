package Template::Benchmark::Engines::TemplateSandbox;

use warnings;
use strict;

use base qw/Template::Benchmark::Engine/;

use Template::Sandbox;
use Template::Sandbox::StringFunctions qw/substr/;

use Cache::CacheFactory;
use Cache::FastMmap;
use Cache::FastMemoryCache;
use Cache::Ref::FIFO;
use CHI;

our $VERSION = '1.09';

our %feature_syntaxes = (
    literal_text              =>
        join( "\n", ( join( ' ', ( 'foo' ) x 12 ) ) x 5 ),
    scalar_variable           =>
        '<: expr scalar_variable :>',
    hash_variable_value       =>
        '<: expr hash_variable.hash_value_key :>',
    array_variable_value      =>
        '<: expr array_variable[ 2 ] :>',
    deep_data_structure_value =>
        '<: expr this.is.a.very.deep.hash.structure :>',
    array_loop_value          =>
        '<: foreach i in array_loop :><: expr i :><: endfor :>',
    hash_loop_value           =>
        '<: foreach k in hash_loop :><: expr k :>: ' .
        '<: expr k.__value__ :><: endfor :>',
    records_loop_value        =>
        '<: foreach r in records_loop :><: expr r.name :>: ' .
        '<: expr r.age :><: endfor :>',
    array_loop_template       =>
        '<: foreach i in array_loop :><: expr i :><: endfor :>',
    hash_loop_template        =>
        '<: foreach k in hash_loop :><: expr k :>: ' .
        '<: expr k.__value__ :><: endfor :>',
    records_loop_template     =>
        '<: foreach r in records_loop :><: expr r.name :>: ' .
        '<: expr r.age :><: endfor :>',
    constant_if_literal       =>
        '<: if 1 :>true<: endif :>',
    variable_if_literal       =>
        '<: if variable_if :>true<: endif :>',
    constant_if_else_literal  =>
        '<: if 1 :>true<: else :>false<: endif :>',
    variable_if_else_literal  =>
        '<: if variable_if_else :>true<: else :>false<: endif :>',
    constant_if_template      =>
        '<: if 1 :><: expr template_if_true :><: endif :>',
    variable_if_template      =>
        '<: if variable_if :><: expr template_if_true :><: endif :>',
    constant_if_else_template =>
        '<: if 1 :><: expr template_if_true :><: else :>' .
        '<: expr template_if_false :><: endif :>',
    variable_if_else_template =>
        '<: if variable_if_else :><: expr template_if_true :><: else :>' .
        '<: expr template_if_false :><: endif :>',
    constant_expression       =>
        '<: expr 10 + 12 :>',
    variable_expression       =>
        '<: expr variable_expression_a * variable_expression_b :>',
    complex_variable_expression =>
        '<: expr ( ( variable_expression_a * variable_expression_b ) + ' .
        'variable_expression_a - variable_expression_b ) / ' .
        'variable_expression_b :>',
    constant_function         =>
        q{<: expr substr( 'this has a substring.', 11, 9 ) :>},
    variable_function         =>
        '<: expr substr( variable_function_arg, 4, 2 ) :>',
    );

sub syntax_type { return( 'mini-language' ); }
sub pure_perl { return( 1 ); }

sub benchmark_descriptions
{
    return( {
        TS    =>
            "Template::Sandbox ($Template::Sandbox::VERSION) without caching",
        TS_CF =>
            "Template::Sandbox ($Template::Sandbox::VERSION) with " .
            "Cache::CacheFactory ($Cache::CacheFactory::VERSION) caching",
        TS_CHI =>
            "Template::Sandbox ($Template::Sandbox::VERSION) with " .
            "CHI ($CHI::VERSION) caching",
        TS_CFM =>
            "Template::Sandbox ($Template::Sandbox::VERSION) with " .
            "Cache::FastMemoryCache ($Cache::FastMemoryCache::VERSION) caching",
        TS_CRF =>
            "Template::Sandbox ($Template::Sandbox::VERSION) with " .
            "Cache::Ref::FIFO ($Cache::Ref::FIFO::VERSION) caching",
        TS_FMM =>
            "Template::Sandbox ($Template::Sandbox::VERSION) with " .
            "Cache::FastMmap ($Cache::FastMmap::VERSION) caching",
        } );
}

sub benchmark_functions_for_uncached_string
{
    my ( $self ) = @_;

    return( {
        TS =>
            sub
            {
                my $t = Template::Sandbox->new();
                $t->set_template_string( $_[ 0 ] );
                $t->add_vars( $_[ 1 ] );
                $t->add_vars( $_[ 2 ] );
                $t->run();
            },
        } );
}

sub benchmark_functions_for_uncached_disk
{
    my ( $self, $template_dir ) = @_;

    return( {
        TS =>
            sub
            {
                my $t = Template::Sandbox->new(
                    template_root => $template_dir,
                    template      => $_[ 0 ],
                    );
                $t->add_vars( $_[ 1 ] );
                $t->add_vars( $_[ 2 ] );
                $t->run();
            },
        } );
}

sub benchmark_functions_for_disk_cache
{
    my ( $self, $template_dir, $cache_dir ) = @_;
    my ( $cf, $chi );

    $cf = Cache::CacheFactory->new(
        storage    => { 'file' => { cache_root => $cache_dir, }, },
        );
    $chi = CHI->new(
        driver   => 'File',
        root_dir => $cache_dir,
        );

    return( {
        TS_CF =>
            sub
            {
                my $t = Template::Sandbox->new(
                    cache         => $cf,
                    template_root => $template_dir,
                    template      => $_[ 0 ],
                    ignore_module_dependencies => 1,
                    );
                $t->add_vars( $_[ 1 ] );
                $t->add_vars( $_[ 2 ] );
                $t->run();
            },
        TS_CHI =>
            sub
            {
                my $t = Template::Sandbox->new(
                    cache         => $chi,
                    template_root => $template_dir,
                    template      => $_[ 0 ],
                    ignore_module_dependencies => 1,
                    );
                $t->add_vars( $_[ 1 ] );
                $t->add_vars( $_[ 2 ] );
                $t->run();
            },
        } );
}

sub benchmark_functions_for_shared_memory_cache
{
    my ( $self, $template_dir, $cache_dir ) = @_;
    my ( $fmm, $chi );

    $fmm = Cache::FastMmap->new(
        share_file => "$cache_dir/cache_mmap",
        cache_size => '100k',
        );
    $chi = CHI->new(
        driver     => 'FastMmap',
        root_dir   => $cache_dir,
        cache_size => '100k',
        );

    return( {
        TS_FMM =>
            sub
            {
                my $t = Template::Sandbox->new(
                    cache         => $fmm,
                    template_root => $template_dir,
                    template      => $_[ 0 ],
                    ignore_module_dependencies => 1,
                    );
                $t->add_vars( $_[ 1 ] );
                $t->add_vars( $_[ 2 ] );
                $t->run();
            },
        TS_CHI =>
            sub
            {
                my $t = Template::Sandbox->new(
                    cache         => $chi,
                    template_root => $template_dir,
                    template      => $_[ 0 ],
                    ignore_module_dependencies => 1,
                    );
                $t->add_vars( $_[ 1 ] );
                $t->add_vars( $_[ 2 ] );
                $t->run();
            },
        } );
}

sub benchmark_functions_for_memory_cache
{
    my ( $self, $template_dir, $cache_dir ) = @_;
    my ( $cf, $chi, $cfm, $crf );

    $cf = Cache::CacheFactory->new(
        storage       => 'fastmemory',
        no_deep_clone => 1,
        );
    $chi = CHI->new(
        driver  => 'Memory',
        global  => 1,
        );
    $cfm = Cache::FastMemoryCache->new();
    $crf = Cache::Ref::FIFO->new(
        size    => 1024,
        );

    return( {
        TS_CF =>
            sub
            {
                my $t = Template::Sandbox->new(
                    cache         => $cf,
                    template_root => $template_dir,
                    template      => $_[ 0 ],
                    ignore_module_dependencies => 1,
                    );
                $t->add_vars( $_[ 1 ] );
                $t->add_vars( $_[ 2 ] );
                $t->run();
            },
        TS_CHI =>
            sub
            {
                my $t = Template::Sandbox->new(
                    cache         => $chi,
                    template_root => $template_dir,
                    template      => $_[ 0 ],
                    ignore_module_dependencies => 1,
                    );
                $t->add_vars( $_[ 1 ] );
                $t->add_vars( $_[ 2 ] );
                $t->run();
            },
        TS_CFM =>
            sub
            {
                my $t = Template::Sandbox->new(
                    cache         => $cfm,
                    template_root => $template_dir,
                    template      => $_[ 0 ],
                    ignore_module_dependencies => 1,
                    );
                $t->add_vars( $_[ 1 ] );
                $t->add_vars( $_[ 2 ] );
                $t->run();
            },
        TS_CRF =>
            sub
            {
                my $t = Template::Sandbox->new(
                    cache         => $crf,
                    template_root => $template_dir,
                    template      => $_[ 0 ],
                    ignore_module_dependencies => 1,
                    );
                $t->add_vars( $_[ 1 ] );
                $t->add_vars( $_[ 2 ] );
                $t->run();
            },
        } );
}

sub benchmark_functions_for_instance_reuse
{
    my ( $self, $template_dir, $cache_dir ) = @_;
    my ( $t );

    #  clear_vars() wasn't available in older Template::Sandbox versions.
    return( undef ) unless Template::Sandbox->can( 'clear_vars' );

    return( {
        TS =>
            sub
            {
                if( $t )
                {
                    $t->clear_vars();
                }
                else
                {
                    $t = Template::Sandbox->new(
                        template_root => $template_dir,
                        template      => $_[ 0 ],
                        );
                }
                $t->add_vars( $_[ 1 ] );
                $t->add_vars( $_[ 2 ] );
                $t->run();
            },
        } );
}

1;

__END__

=pod

=head1 NAME

Template::Benchmark::Engines::TemplateSandbox - Template::Benchmark plugin for Template::Sandbox.

=head1 SYNOPSIS

Provides benchmark functions and template feature syntaxes to allow
L<Template::Benchmark> to benchmark the L<Template::Sandbox> template
engine.

=head1 AUTHOR

Sam Graham, C<< <libtemplate-benchmark-perl at illusori.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-benchmark at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Benchmark>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Benchmark::Engines::TemplateSandbox


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
