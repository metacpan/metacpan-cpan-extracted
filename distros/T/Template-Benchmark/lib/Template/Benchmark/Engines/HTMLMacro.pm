package Template::Benchmark::Engines::HTMLMacro;

use warnings;
use strict;

use base qw/Template::Benchmark::Engine/;

use HTML::Macro;

use File::Spec;

our $VERSION = '1.09';

our %feature_syntaxes = (
    literal_text              =>
        join( "\n", ( join( ' ', ( 'foo' ) x 12 ) ) x 5 ),
    scalar_variable           =>
        '#scalar_variable#',
    hash_variable_value       =>
        undef,
    array_variable_value      =>
        undef,
    deep_data_structure_value =>
        undef,
    array_loop_value          =>
        '<loop id="array_loop_value">#value#</loop>',
    hash_loop_value           =>
        '<loop id="hash_loop_value">#key#: #value#</loop>',
    records_loop_value        =>
        '<loop id="records_loop_value">#name#: #age#</loop>',
    array_loop_template       =>
        '<loop id="array_loop_template">#value#</loop>',
    hash_loop_template        =>
        '<loop id="hash_loop_template">#key#: #value#</loop>',
    records_loop_template     =>
        '<loop id="records_loop_template">#name#: #age#</loop>',
    constant_if_literal       =>
        '<if expr="1">true</if>',
    variable_if_literal       =>
        '<if expr="#variable_if#">true</if>',
    constant_if_else_literal  =>
        '<if expr="1">true<else/>false</if>',
    variable_if_else_literal  =>
        '<if expr="#variable_if_else#">true<else/>false</if>',
    constant_if_template      =>
        '<if expr="1">#template_if_true#</if>',
    variable_if_template      =>
        '<if expr="#variable_if#">#template_if_true#</if>',
    constant_if_else_template =>
        '<if expr="1">#template_if_true#<else/>' .
        '#template_if_false#</if>',
    variable_if_else_template =>
        '<if expr="#variable_if_else#">#template_if_true#<else/>' .
        '#template_if_false#</if>',
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
        HMac    =>
            "HTML::Macro ($HTML::Macro::VERSION)",
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
        HMac =>
            sub
            {
                my $file = File::Spec->catfile( $template_dir, $_[ 0 ] );

                my $t = HTML::Macro->new( $file );
                my $h = { %{$_[ 1 ]}, %{$_[ 2 ]} };
                #  Somewhat unfair since we cause the transform hit even
                #  if we're not benchmarking this feature, then again, everyone
                #  else has to store it in their stash too.
                foreach my $id ( qw/value template/ )
                {
                    my $array_loop  = $t->new_loop( "array_loop_$id",
                        'value' );
                    foreach my $value ( @{$h->{ array_loop }} )
                    {
                        $array_loop->push_array( $value );
                    }
                }
                foreach my $id ( qw/value template/ )
                {
                    my $hash_loop   = $t->new_loop( "hash_loop_$id",
                        'key', 'value' );
                    foreach my $key ( sort( keys( %{$h->{ hash_loop }} ) ) )
                    {
                        $hash_loop->push_array( $key,
                            $h->{ hash_loop }{ $key } );
                    }
                }
                foreach my $id ( qw/value template/ )
                {
                    my $records_loop = $t->new_loop( "records_loop_$id" );
                    foreach my $record ( @{$h->{ records_loop }} )
                    {
                        $records_loop->push_hash( $record );
                    }
                }
                $t->set_hash( $h );
                \$t->process();
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
        HMac =>
            sub
            {
                unless( $t )
                {
                    my $file = File::Spec->catfile( $template_dir, $_[ 0 ] );
                    $t = HTML::Macro->new( $file,
                        {
                            cache_files => 1,
                        } );
                }

                my $h = { %{$_[ 1 ]}, %{$_[ 2 ]} };
                #  Somewhat unfair since we cause the transform hit even
                #  if we're not benchmarking this feature, then again, everyone
                #  else has to store it in their stash too.
                foreach my $id ( qw/value template/ )
                {
                    my $array_loop  = $t->new_loop( "array_loop_$id",
                        'value' );
                    foreach my $value ( @{$h->{ array_loop }} )
                    {
                        $array_loop->push_array( $value );
                    }
                }
                foreach my $id ( qw/value template/ )
                {
                    my $hash_loop   = $t->new_loop( "hash_loop_$id",
                        'key', 'value' );
                    foreach my $key ( sort( keys( %{$h->{ hash_loop }} ) ) )
                    {
                        $hash_loop->push_array( $key,
                            $h->{ hash_loop }{ $key } );
                    }
                }
                foreach my $id ( qw/value template/ )
                {
                    my $records_loop = $t->new_loop( "records_loop_$id" );
                    foreach my $record ( @{$h->{ records_loop }} )
                    {
                        $records_loop->push_hash( $record );
                    }
                }
                $t->set_hash( $h );
                \$t->process();
            },
        } );
}

1;

__END__

=pod

=head1 NAME

Template::Benchmark::Engines::HTMLMacro - Template::Benchmark plugin for HTML::Macro.

=head1 SYNOPSIS

Provides benchmark functions and template feature syntaxes to allow
L<Template::Benchmark> to benchmark the L<HTML::Macro> template
engine.

=head1 KNOWN ISSUES

Benchmark runs of L<Template::Benchmark::Engines::HTMLMacro> are likely
to take a lot longer time to run than expected.

L<HTML::Macro> makes heavy use of L<Cwd> and spends approximately 75% of
its runtime waiting on system as given by these example figures:

  real    0m35.237s
  user    0m8.685s
  sys     0m26.062s

Since L<Template::Benchmark> runs benchmarks for a duration based on
user time, this causes the wallclock/realtime to be much greater than
anticipated, currently by about a factor of 4.

=head1 AUTHOR

Sam Graham, C<< <libtemplate-benchmark-perl at illusori.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-benchmark at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Benchmark>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Benchmark::Engines::HTMLMacro


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
