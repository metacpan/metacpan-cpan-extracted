use strict;
use warnings;

package Template::Plugin::Transformator;

# ABSTRACT: TemplateToolkit plugin for Net::NodeTransformator

use Net::NodeTransformator;
use Template::Plugin::Filter;
use base qw( Template::Plugin::Filter );

our $VERSION = '0.001';    # VERSION

sub init {
    my $self = shift;

    $self->{config} =
      $self->{_CONTEXT}->{CONFIG}->{PLUGIN_CONFIG}->{Transformator} || {};

    my %config = %{ $self->{_CONFIG} };
    my @args   = @{ $self->{_ARGS} };

    my $name = $config{name} || 'Transformator';

    $self->{_DYNAMIC} = 1;

    $self->install_filter($name);

    $self->{nnt} =
      $self->{config}->{connect}
      ? Net::NodeTransformator->new( $self->{config}->{connect} )
      : Net::NodeTransformator->standalone;

    $self->{engine} = $config{engine} || $args[0];

    return $self;
}

sub filter {
    my ( $self, $text, $args, $conf ) = @_;

    my %config = %$conf;

    my $nnt =
      $config{connect}
      ? Net::NodeTransformator->new( $config{connect} )
      : $self->{nnt};

    my $engine = $self->{engine};
    $engine ||= shift @$args;

    $text = $nnt->transform( $engine, $text, $conf );
}

1;

__END__

=pod

=head1 NAME

Template::Plugin::Transformator - TemplateToolkit plugin for Net::NodeTransformator

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    [% USE Transformator %]
    
    [% FILTER Transformator 'jade' %]
    
    span
		| Hi!
    
    [% END %]

=head1 DESCRIPTION

This module is a filter for L<Net::NodeTransformator>.

=head1 CONFIGURATION

	Template->new({
		PLUGIN_CONFIG => {
			Transformator => {
				connect => 'hostname:port'
			}
		}
	});

=head1 USAGE EXAMPLES

=over 4

=item * Generic object, name engine each invocation

	[% USE Transformator %]
	[% FILTER Transformator 'engine_name' %]
		Lorem Ipsum
	[% END %]

=item * Specialized object, engine named as construction argument

	[% USE some_engine = Transformator 'engine_name' %]
	[% FILTER $some_engine %]
		Dolorem Sit Amet
	[% END %]

=item * Specialized object, using configuration override

	[% USE other_transformator = Transformator connect = 'some.other.hostname' %]
	[% FILTER $other_transformator 'engine_name' %]
	[% END %]

=item * Specialized object, using configuration override with engine name

	[% USE special_transformator = Transformator
	       connect = 'some.other.hostname'
		   engine = 'engine_name'
	%]
	[% FILTER $special_transformator %]
	[% END %]

=item * Parameterized engine invocation

	[% USE Transformator %]
	[% FILTER Transformator 'jade', name = 'Peter' %]
	| Hi #{name}!
	[% END %]

	[% vars = { name = 'Peter' } %]
	[% FILTER Transformator 'jade', vars %]
	| Hi #{name}!
	[% END %]

	[% USE jade = Transformator 'jade' %]
	[% FILTER $jade name = 'Peter' %]
	| Hi #{name}!
	[% END %]

	[% FILTER $jade vars %]
	| Hi #{name}!
	[% END %]

=back

=for Pod::Coverage init

=for Pod::Coverage filter

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/zurborg/libtemplate-plugin-transformator-perl/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

David Zurborg <zurborg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by David Zurborg.

This is free software, licensed under:

  The ISC License

=cut
