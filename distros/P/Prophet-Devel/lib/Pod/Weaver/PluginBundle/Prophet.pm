package Pod::Weaver::PluginBundle::Prophet;
{
  $Pod::Weaver::PluginBundle::Prophet::VERSION = '0.001';
}

# ABSTRACT: Weave Prophet's POD

use Moose;
use Pod::Weaver::Config::Assembler;

use Pod::Elemental::Transformer::List;
use Pod::Weaver::Section::BugsAndLimitations;
use Pod::Weaver::Section::Contributors;

sub _exp { Pod::Weaver::Config::Assembler->expand_package( $_[0] ) }
 
sub mvp_bundle_config
{
    my @plugins;
    push @plugins, (
        [ '@NRR/Encoding', _exp( 'Encoding' ),  {} ],
        [ '@NRR/CorePrep', _exp( '@CorePrep' ), {} ],
        [ '@NRR/Name',     _exp( 'Name' ),      {} ],
        [ '@NRR/Version',  _exp( 'Version' ),   {} ],
 
        [   '@NRR/Prelude',
            _exp( 'Region' ),
            { region_name => 'prelude' }
        ],
 
        [   '@NRR/Synopsis', _exp( 'Generic' ), { header => 'SYNOPSIS' }
        ],
        [   '@NRR/Description',
            _exp( 'Generic' ),
            { header => 'DESCRIPTION' }
        ],
        [   '@NRR/Overview', _exp( 'Generic' ), { header => 'OVERVIEW' }
        ],
        [ '@NRR/Usage', _exp( 'Generic' ), { header => 'USAGE' } ],
    );
 
    for my $plugin (
        [ 'Attributes', _exp( 'Collect' ), { command => 'attr' } ],
        [ 'Methods',    _exp( 'Collect' ), { command => 'method' } ],
        [ 'Functions',  _exp( 'Collect' ), { command => 'func' } ],
        )
    {
        $plugin->[2]{header} = uc $plugin->[0];
        push @plugins, $plugin;
    }
 
    push @plugins,
        (
        [ '@NRR/Leftovers', _exp( 'Leftovers' ), {} ],
        [   '@NRR/postlude',
            _exp( 'Region' ),
            { region_name => 'postlude' }
        ],
        [   '@NRR/Support',
            _exp( 'Support' ),
            {   websites =>
                    'search, ratings, testers, testmatrix, deps',
                bugs               => 'metadata',
                repository_link    => 'both',
                repository_content => '',
            }
        ],
        [ '@NRR/Authors', _exp( 'Authors' ), {} ],
        [ '@NRR/Legal',   _exp( 'Legal' ),   {} ],
        [   '@NRR/List',
            _exp( '-Transformer' ),
            { 'transformer' => 'List' }
        ],
        [ '@NRR/Stopwords', _exp( '-Stopwords' ), {} ],
        );
 
    return @plugins;
}
 
1;

__END__

=pod

=head1 NAME

Pod::Weaver::PluginBundle::Prophet - Weave Prophet's POD

=head1 VERSION

version 0.001

=head1 AUTHOR

Ioan Rogers <ioanr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Ioan Rogers.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
