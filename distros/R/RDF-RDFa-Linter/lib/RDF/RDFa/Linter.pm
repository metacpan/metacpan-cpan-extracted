package RDF::RDFa::Linter;

use 5.008;
use strict;
use RDF::RDFa::Linter::Error;
use RDF::RDFa::Linter::Service::CreativeCommons;
use RDF::RDFa::Linter::Service::Facebook;
use RDF::RDFa::Linter::Service::Google;
use RDF::RDFa::Linter::Service::SchemaOrg;
use RDF::RDFa::Parser;
use RDF::Trine;
use RDF::Query;

our $VERSION = '0.053';

sub new
{
	my ($class, $service, $thisuri, $parser) = @_;
	
	my $self = bless {
		service  => __PACKAGE__ . '::Service::' . $service,
		uri      => $thisuri,
		parser   => $parser,
		}, $class;

	$parser->{'__linter'} = $self;
	$parser->set_callbacks({
		onprefix => \&cb_onprefix,
		oncurie  => \&cb_oncurie,
		});
	$self->{'graph'} = $parser->graph;
	$self->{'lint'}  = $self->{'service'}->new($parser->graph, $thisuri);

	return $self;
}

sub info
{
	my ($self) = @_;
	return $self->{'lint'}->info;
}

sub filtered_graph
{
	my ($self) = @_;
	return $self->{'lint'}->filtered_graph;
}

sub find_errors
{
	my ($self) = @_;
	my @errs = @{ $self->{'parse_errors'} };
	push @errs, $self->{'lint'}->find_errors;
	
	return @errs;
}

sub cb_onprefix
{
	my ($parser, $node, $prefix, $uri) = @_;
	my $self = $parser->{'__linter'};
	
	my $preferred = $self->{'service'}->prefixes;
	
	if (defined $preferred->{$prefix}
	and $preferred->{$prefix} ne $uri)
	{
		push @{ $self->{'parse_errors'} },
			RDF::RDFa::Linter::Error->new(
				'subject' => RDF::Trine::Node::Resource->new($self->{'uri'}),
				'text'    => "Prefix '$prefix' bound to <$uri>, instead of the usual <".$preferred->{$prefix}."> - this is allowed, but unusual.",
				'level'   => 1,
				);
	}
	elsif (!defined $preferred->{$prefix})
	{
		while (my ($p,$f) = each %$preferred)
		{
			if ($f eq $uri)
			{
				push @{ $self->{'parse_errors'} },
					RDF::RDFa::Linter::Error->new(
						'subject' => RDF::Trine::Node::Resource->new($self->{'uri'}),
						'text'    => "Prefix '$prefix' bound to <$uri>, instead of the usual prefix '$p' - this is allowed, but unusual.",
						'level'   => 1,
						);
			}
		}
	}
	
	return 0;
}

sub cb_oncurie
{
	my ($parser, $node, $curie, $uri) = @_;
	my $self = $parser->{'__linter'};

	return $uri unless $curie eq $uri || $uri eq '';

	my $preferred = $self->{'service'}->prefixes;
	
	if ($curie =~ m/^([^:]+):(.*)$/)
	{
		my ($pfx, $sfx) = ($1, $2);
		
		if (defined $preferred->{$pfx})
		{
			push @{ $self->{'parse_errors'} },
				RDF::RDFa::Linter::Error->new(
					'subject' => RDF::Trine::Node::Resource->new($self->{'uri'}),
					'text'    => "CURIE '$curie' used but '$pfx' is not bound - perhaps you forgot to specify xmlns:${pfx}=\"".$preferred->{$pfx}."\"",
					'level'   => 5,
					);
			
			return $preferred->{$pfx} . $sfx;
		}
		elsif ($pfx !~ m'^(http|https|file|ftp|urn|tag|mailto|acct|data|
			fax|tel|modem|gopher|info|news|sip|irc|javascript|sgn|ssh|xri|widget)$'ix)
		{
			push @{ $self->{'parse_errors'} },
				RDF::RDFa::Linter::Error->new(
					'subject' => RDF::Trine::Node::Resource->new($self->{'uri'}),
					'text'    => "CURIE '$curie' used but '$pfx' is not bound - perhaps you forgot to specify xmlns:${pfx}=\"SOMETHING\"",
					'level'   => 1,
					);
		}
	}

	return $uri;
}

sub __rdf_query
{
	my ($sparql, $model) = @_;
	my $result = RDF::Query->new($sparql)->execute($model);

	if ($result->is_boolean)
		{ return $result->get_boolean }
	elsif ($result->is_bindings)
		{ return $result }

	$result->is_graph or die;

	my $return = RDF::Trine::Model->new;
	$return->add_hashref( $result->as_hashref );
	return $return;
}

1;

__END__

=head1 NAME

RDF::RDFa::Linter - find common mistakes in RDFa files

=head1 SYNOPSIS

 my $parser = RDF::RDFa::Parser->new_from_url($input_url);
 my $linter = RDF::RDFa::Linter->new('Facebook', $input_url, $parser);
 my $model  = $linter->filtered_graph;
 my @errors = $linter->find_errors;

=head1 DESCRIPTION

In the above example, $model is an RDF::Trine::Model containing just the
statements from $input_url that the service (in this case, Facebook's
Open Graph) understands.

@errors is a list of RDF::RDFa::Linter::Error objects. RDF::RDFa::Linter::Error
is a subclass of RDF::RDFa::Generator::HTML::Pretty::Note, which comes in
handy if you want to generate a report of the errors and filtered graph
together.

TODO: proper documentation!!

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<XML::LibXML>, L<RDF::RDFa::Parser>, L<RDF::RDFa::Generator>.

L<http://www.perlrdf.org/>.

L<http://check.rdfa.info/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2010 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

