package RDF::DOAP::ChangeSets;

use 5.008;
use strict;

use File::Slurp qw(slurp);
use LWP::Simple;
use Perl::Version;
use RDF::Trine;
use RDF::Query;
use Text::Wrap;
use List::MoreUtils qw(uniq);

our $VERSION = '0.206';

sub new
{
	my $class = shift;
	my $inuri = shift;
	my $data  = shift;
	my $type  = shift || 'auto';

	my $model;
	if (ref $data and $data->isa('RDF::Trine::Model'))
	{
		$model = $data;
	}
	else
	{
		$model = RDF::Trine::Model->new( RDF::Trine::Store->temporary_store );
		
		unless (defined $data)
		{
			if (ref $inuri and $inuri->isa('URI::file'))
			{
				$data = slurp( $inuri->file );
			}
			elsif ($inuri =~ /^(http|file|https|ftp):/i)
			{
				$data = get($inuri);
			}
		}
		
		my $fmt    = shift || 'turtle';
		my $parser = RDF::Trine::Parser->new($fmt);
		$parser->parse_into_model("$inuri", $data, $model);
	}
	
	if (lc $type eq 'auto')
	{
		my $r = RDF::Query->new(
			"ASK WHERE { ?a <http://usefulinc.com/ns/doap#Version> ?b .}")
			->execute($model);
		if ($r->get_boolean)
		{
			$type = 'legacy';
		}
		else
		{
			$type = 'current';
		}
	}	
	
	my $self = { 'model' => $model , 'type' => $type , 'uri' => $inuri } ;
	
	bless $self, $class;
}

sub is_legacy
{
	my $self = shift;
	return (lc $self->{'type'} eq 'legacy');
}

sub is_current
{
	my $self = shift;
	return !$self->is_legacy(@_);
}

sub model
{
	my $self = shift;
	return $self->{'model'};
}

sub uri
{
	my $self = shift;
	return $self->{'uri'} . '';
}

sub to_string
{
	my $self = shift;
	my $rv = '';
	
	# Get project data for all projects described in the model.
	$self->_project_data;
	
#	# Heading
#	$rv.= "#" x 76 . "\n";
#	$rv.= "## " . $self->{'doctitle'} . " " . ("#" x (72 - length $self->{'doctitle'})) . "\n";
#	$rv.= "#" x 76 . "\n\n";
	
	# Create a shortcut to the data.
	my $projects = $self->{'projects'};	

	# foreach project
	foreach my $project (sort keys %$projects)
	{
		# Subheading
		$rv.= $projects->{$project}->{'distname'} . "\n";
		$rv.= ('=' x length $projects->{$project}->{'distname'}) . "\n\n";
		
		# Various interesting data about the project.
		$rv.= sprintf("Created:      %s\n", $projects->{$project}->{'created'})
			if $projects->{$project}->{'created'};
		foreach my $u (sort keys %{ $projects->{$project}->{'homepage'} })
		{
			$rv.= sprintf("Home page:    <%s>\n", $u);
		}
		foreach my $u (sort keys %{ $projects->{$project}->{'bugdatabase'} })
		{
			$rv.= sprintf("Bug tracker:  <%s>\n", $u);
		}
		foreach my $m (sort keys %{ $projects->{$project}->{'maint'} })
		{
			my @mboxes = sort keys %{$projects->{$project}->{'maint'}->{$m}->{'mbox'}};
			my $mbox = shift @mboxes;
			
			if (defined $mbox) { $rv.= sprintf("Maintainer:   %s <%s>\n", $projects->{$project}->{'maint'}->{$m}->{'name'}, $mbox); }
			else               { $rv.= sprintf("Maintainer:   %s\n", $projects->{$project}->{'maint'}->{$m}->{'name'}, $mbox); }
		}
		$rv.= "\n";
		
		# Read in data about this project's releases.
		$self->_release_data($project);
		
		my @revisions = sort {
			if (exists $b->{'issued'} and exists $a->{'issued'})
				{ $b->{'issued'} cmp $a->{'issued'} or Perl::Version->new($b->{'revision'}) cmp Perl::Version->new($a->{'revision'}); }
			else
				{ Perl::Version->new($b->{'revision'}) cmp Perl::Version->new($a->{'revision'}); }
		} values %{$projects->{$project}->{'v'}};
		
		# foreach version
		foreach my $version (@revisions)
		{
			# Version number, release data and version name.
			$rv.= $version->{'revision'};
			$rv.= sprintf('  %s', $version->{'issued'} ? $version->{'issued'} : 'Unknown');
			$rv.= sprintf("  %s", $version->{'name'}) if $version->{'name'};
			$rv.= "\n\n";
			
			my @changes = map
				{
					my $change = $_;
					
					my $sigil = '';
					if (defined $change->{'type'} and ref($change->{'type'}) eq 'ARRAY')
					{
						$sigil = join ' ',
							uniq
							sort
							map { m!doap.changeset.(.+)$!; $1; }
							grep { m!doap.changeset.(.+)$! }
							@{ $change->{'type'} };
						$sigil = "(${sigil}) " if length $sigil;
					}
					# Bullet point
					my $ret = wrap(' - ', '   ', sprintf("%s%s", $sigil, $change->{'label'})) . "\n";
					
					for (sort keys %{ $change->{issue} || {}})
					{
						m{^http://purl\.org/NET/cpan-uri/rt/ticket/([0-9]+)$}
							? ($ret .= sprintf("   Fixes RT#%s\n", $1)) :
						m{^(?:tdb:.*)https://rt\.cpan\.org/Ticket/Display\.html\?id=([0-9]+)$}
							? ($ret .= sprintf("   Fixes RT#%s\n", $1)) :
						m{^(?:tdb:.*)https://github.com/.*/issues/([0-9]+)$}
							? ($ret .= sprintf("   Fixes GH#%s\n", $1)) :
						();
					}
					
					my %blame = %{ $change->{blame} || {}};
					foreach $b (values %blame)
					{
						if (defined $b->{nick})
							{ $ret .= sprintf("   ++\$%s\n", $b->{nick}) }
						elsif (defined $b->{name})
							{ $ret .= sprintf("   ++\"%s\"\n", $b->{name}) }
						elsif (defined $b->{uri})
							{ $ret .= sprintf("   ++q<%s>\n", $b->{uri}) }
					}
					
					$ret;
				}
				values %{$version->{'c'}};
			
			$rv.= join q{}, sort @changes;
			$rv.= "\n";
		}
		
	}
	
	return $rv;
}

sub to_file
{
	my $self = shift;
	my $file = shift;
	
	open OUT, ">$file";
	print OUT $self->to_string;
	close OUT;
}

sub _project_data
{
	my $self = shift;
	my $rv;
	
	if ($self->is_legacy)
	{
		$rv = $self->_project_data__legacy(@_);
	}
	else
	{
		$rv = $self->_project_data__current(@_);
	}

	unless (length $self->{'doctitle'})
	{
		foreach my $project (sort keys %{$self->{'projects'}})
		{
			if (length $self->{'doctitle'} == 0
			or  length $self->{'doctitle'} > $self->{'projects'}->{$project}->{'distname'})
			{
				$self->{'doctitle'} = $self->{'projects'}->{$project}->{'distname'};
			}
		}
		if (length $self->{'doctitle'})
		{
			$self->{'doctitle'} = "Changes for " . $self->{'doctitle'};
		}
		else
		{
			$self->{'doctitle'} = "Changes";
		}
	}
	
	return $rv;
}

sub _project_data__current
{
	my $self  = shift;
	my $model = $self->model;
	my $inuri = $self->uri;

	my $sparql = "
	PREFIX dc: <http://purl.org/dc/terms/>
	PREFIX dcs: <http://ontologi.es/doap-changeset#>
	PREFIX doap: <http://usefulinc.com/ns/doap#>
	PREFIX foaf: <http://xmlns.com/foaf/0.1/>
	PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
	SELECT *
	WHERE
	{
		?project	a doap:Project .
		OPTIONAL { <$inuri> dc:title ?title . }
		OPTIONAL { <$inuri> rdfs:label ?title . }
		OPTIONAL { ?project doap:name ?distname . }
		OPTIONAL { ?project rdfs:label ?distname . }
		OPTIONAL { ?project dc:title ?distname . }
		OPTIONAL { ?project doap:created ?created . }
		OPTIONAL { ?project doap:homepage ?homepage . }
		OPTIONAL { ?project doap:bug-database ?bugdatabase . }
		OPTIONAL
		{
			?project doap:maintainer ?maint .
			?maint foaf:name ?maintname .
			OPTIONAL { ?maint foaf:mbox ?maintmbox . }
		}
	}
	";
	
	my $query    = RDF::Query->new($sparql);
	my $results  = $query->execute($model);
	my $projects = {};
	my $doctitle = '';
	while (my $row = $results->next)
	{
		my $p = $row->{'project'}->as_ntriples;
		$projects->{$p}->{'EXISTS'}++;
		$projects->{$p}->{'distname'} = $row->{'distname'}->literal_value
			if UNIVERSAL::isa($row->{'distname'}, 'RDF::Trine::Node::Literal');
		$projects->{$p}->{'created'} = $row->{'created'}->literal_value
			if UNIVERSAL::isa($row->{'created'}, 'RDF::Trine::Node::Literal');
		$projects->{$p}->{'homepage'}->{ $row->{'homepage'}->uri }++
			if UNIVERSAL::isa($row->{'homepage'}, 'RDF::Trine::Node::Resource');
		$projects->{$p}->{'bugdatabase'}->{ $row->{'bugdatabase'}->uri }++
			if UNIVERSAL::isa($row->{'bugdatabase'}, 'RDF::Trine::Node::Resource');
		$projects->{$p}->{'maint'}->{ $row->{'maint'}->as_ntriples }->{'name'} = $row->{'maintname'}->literal_value
			if UNIVERSAL::isa($row->{'maintname'}, 'RDF::Trine::Node::Literal');
		$projects->{$p}->{'maint'}->{ $row->{'maint'}->as_ntriples }->{'mbox'}->{ $row->{'maintmbox'}->uri }++
			if UNIVERSAL::isa($row->{'maintmbox'}, 'RDF::Trine::Node::Resource');
		$doctitle = $row->{'title'}->literal_value
			if UNIVERSAL::isa($row->{'title'}, 'RDF::Trine::Node::Literal');
	}
	
	foreach my $k (keys %$projects)
	{
		$projects->{$k}->{'distname'} = $k
			unless defined $projects->{$k}->{'distname'};
	}
	
	$self->{'projects'}  = $projects;
	$self->{'doctitle'}  = $doctitle;
}

sub _project_data__legacy
{
	my $self  = shift;
	my $model = $self->model;
	my $inuri = $self->uri;

	my $sparql = "
	PREFIX dc: <http://purl.org/dc/terms/>
	PREFIX doap: <http://usefulinc.com/ns/doap#>
	PREFIX foaf: <http://xmlns.com/foaf/0.1/>
	PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
	SELECT *
	WHERE
	{
		?project	a doap:Project .
		OPTIONAL { <$inuri> dc:title ?title . }
		OPTIONAL { <$inuri> rdfs:label ?title . }
		OPTIONAL { ?project doap:name ?distname . }
		OPTIONAL { ?project rdfs:label ?distname . }
		OPTIONAL { ?project dc:title ?distname . }
		OPTIONAL { ?project doap:created ?created . }
		OPTIONAL { ?project doap:homepage ?homepage . }
		OPTIONAL { ?project doap:bug-database ?bugdatabase . }
		OPTIONAL
		{
			?project doap:maintainer ?maint .
			?maint foaf:name ?maintname .
			OPTIONAL { ?maint foaf:mbox ?maintmbox . }
		}
	}
	";
	
	my $query    = RDF::Query->new($sparql);
	my $results  = $query->execute($model);
	my $projects = {};
	my $doctitle = '';
	while (my $row = $results->next)
	{
		my $p = $row->{'project'}->as_ntriples;
		$projects->{$p}->{'EXISTS'}++;
		$projects->{$p}->{'distname'} = $row->{'distname'}->literal_value
			if UNIVERSAL::isa($row->{'distname'}, 'RDF::Trine::Node::Literal');
		$projects->{$p}->{'created'} = $row->{'created'}->literal_value
			if UNIVERSAL::isa($row->{'created'}, 'RDF::Trine::Node::Literal');
		$projects->{$p}->{'homepage'}->{ $row->{'homepage'}->uri }++
			if UNIVERSAL::isa($row->{'homepage'}, 'RDF::Trine::Node::Resource');
		$projects->{$p}->{'bugdatabase'}->{ $row->{'bugdatabase'}->uri }++
			if UNIVERSAL::isa($row->{'bugdatabase'}, 'RDF::Trine::Node::Resource');
		$projects->{$p}->{'maint'}->{ $row->{'maint'}->as_ntriples }->{'name'} = $row->{'maintname'}->literal_value
			if UNIVERSAL::isa($row->{'maintname'}, 'RDF::Trine::Node::Literal');
		$projects->{$p}->{'maint'}->{ $row->{'maint'}->as_ntriples }->{'mbox'}->{ $row->{'maintmbox'}->uri }++
			if UNIVERSAL::isa($row->{'maintmbox'}, 'RDF::Trine::Node::Resource');
		$doctitle = $row->{'title'}->literal_value
			if UNIVERSAL::isa($row->{'title'}, 'RDF::Trine::Node::Literal');
	}

	foreach my $k (keys %$projects)
	{
		$projects->{$k}->{'distname'} = $k
			unless defined $projects->{$k}->{'distname'};
	}

	$self->{'projects'}  = $projects;
	$self->{'doctitle'}  = $doctitle;
}

sub _release_data
{
	my $self = shift;

	if ($self->is_legacy)
	{
		return $self->_release_data__legacy(@_);
	}
	else
	{
		return $self->_release_data__current(@_);
	}
}

sub _release_data__current
{
	my $self     = shift;
	my $model    = $self->model;
	my $p        = shift;
	my $projects = $self->{'projects'};
	
	my $sparql = "
	PREFIX dbug: <http://ontologi.es/doap-bugs#>
	PREFIX dc: <http://purl.org/dc/terms/>
	PREFIX dcs: <http://ontologi.es/doap-changeset#>
	PREFIX doap: <http://usefulinc.com/ns/doap#>
	PREFIX foaf: <http://xmlns.com/foaf/0.1/>
	PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
	SELECT *
	WHERE
	{
		$p doap:release ?version .
		?version doap:revision ?revision .
		OPTIONAL { ?version dc:issued ?issued . }
		OPTIONAL { ?version rdfs:label ?vname . }
		OPTIONAL
		{
			?version dcs:changeset [ dcs:item ?item ] .
			OPTIONAL { ?item a ?itemtype . }
			OPTIONAL { ?item rdfs:label ?itemlabel . }
			OPTIONAL {
				?item dcs:blame|dcs:thanks ?blame .
				OPTIONAL { ?blame foaf:nick ?blamenick . }
				OPTIONAL { ?blame foaf:name ?blamename . }
				OPTIONAL { ?blame rdfs:label ?blamename . }
			}
			OPTIONAL { ?item dcs:fixes ?issue . }
		}
	}
	";

	my $query    = RDF::Query->new($sparql);
	my $results  = $query->execute($model);
	while (my $row = $results->next)
	{
		my $v = $row->{'version'}->as_ntriples;
		$projects->{$p}->{'v'}->{$v}->{'EXISTS'}++;
		
		$projects->{$p}->{'v'}->{$v}->{'revision'} = $row->{'revision'}->literal_value
			if UNIVERSAL::isa($row->{'revision'}, 'RDF::Trine::Node::Literal');
		$projects->{$p}->{'v'}->{$v}->{'issued'} = $row->{'issued'}->literal_value
			if UNIVERSAL::isa($row->{'issued'}, 'RDF::Trine::Node::Literal');
		$projects->{$p}->{'v'}->{$v}->{'name'} = $row->{'vname'}->literal_value
			if UNIVERSAL::isa($row->{'vname'}, 'RDF::Trine::Node::Literal');
		
		if (UNIVERSAL::isa($row->{'item'}, 'RDF::Trine::Node'))
		{
			my $c = $row->{'item'}->as_ntriples;
			$projects->{$p}->{'v'}->{$v}->{'c'}->{$c}->{'label'} = $row->{'itemlabel'}->literal_value
				if UNIVERSAL::isa($row->{'itemlabel'}, 'RDF::Trine::Node::Literal');
			push @{ $projects->{$p}->{'v'}->{$v}->{'c'}->{$c}->{'type'} }, $row->{'itemtype'}->uri
				if UNIVERSAL::isa($row->{'itemtype'}, 'RDF::Trine::Node::Resource')
				and $row->{'itemtype'}->uri ne 'http://ontologi.es/doap-changeset#Change';
			$projects->{$p}->{'v'}->{$v}->{'c'}->{$c}->{'blame'} = {};
			
			if (UNIVERSAL::isa($row->{'issue'}, 'RDF::Trine::Node::Resource'))
			{
				$projects->{$p}->{'v'}->{$v}->{'c'}->{$c}->{'issue'}->{ $row->{'issue'}->uri }++;
				push @{ $projects->{$p}->{'v'}->{$v}->{'c'}->{$c}->{'type'} },
					q[http://ontologi.es/doap-changeset#Bugfix];
			}
		
			if (UNIVERSAL::isa($row->{'blame'}, 'RDF::Trine::Node'))
			{
				my $b = $row->{'blame'}->as_ntriples;
				$projects->{$p}->{'v'}->{$v}->{'c'}->{$c}->{'blame'}->{$b} = {
						uri  => $row->{'blame'}->is_resource ? $row->{'blame'}->uri : undef,
						name => $row->{'blamename'}&&$row->{'blamename'}->is_literal ? $row->{'blamename'}->literal_value : undef,
						nick => $row->{'blamenick'}&&$row->{'blamenick'}->is_literal ? $row->{'blamenick'}->literal_value : undef,
					};
			}
		}		
	}
}

sub _release_data__legacy
{
	my $self     = shift;
	my $model    = $self->model;
	my $p        = shift;
	my $projects = $self->{'projects'};
	
	my $sparql = "
	PREFIX dc: <http://purl.org/dc/terms/>
	PREFIX asc: <http://aaronland.info/ns/changefile/>
	PREFIX doap: <http://usefulinc.com/ns/doap#>
	PREFIX foaf: <http://xmlns.com/foaf/0.1/>
	PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
	SELECT *
	WHERE
	{
		?version dc:isVersionOf $p .
		?version doap:Version [ doap:revision ?revision ] .
		OPTIONAL { ?version doap:Version [ doap:created ?issued ] . }
		OPTIONAL { ?version rdfs:label ?vname . }
		OPTIONAL { ?version asc:changes [ ?itemtype ?itemlabel ] . }
	}
	";

	my $query    = RDF::Query->new($sparql);
	my $results  = $query->execute($model);
	while (my $row = $results->next)
	{
		my $v = $row->{'version'}->as_ntriples;
		$projects->{$p}->{'v'}->{$v}->{'EXISTS'}++;
		
		$projects->{$p}->{'v'}->{$v}->{'revision'} = $row->{'revision'}->literal_value
			if UNIVERSAL::isa($row->{'revision'}, 'RDF::Trine::Node::Literal');
		$projects->{$p}->{'v'}->{$v}->{'issued'} = $row->{'issued'}->literal_value
			if UNIVERSAL::isa($row->{'issued'}, 'RDF::Trine::Node::Literal');
		$projects->{$p}->{'v'}->{$v}->{'name'} = $row->{'vname'}->literal_value
			if UNIVERSAL::isa($row->{'vname'}, 'RDF::Trine::Node::Literal');
		
		if (UNIVERSAL::isa($row->{'itemlabel'}, 'RDF::Trine::Node'))
		{
			my $c = $row->{'itemlabel'}->as_ntriples;
			$projects->{$p}->{'v'}->{$v}->{'c'}->{$c}->{'label'} = $row->{'itemlabel'}->literal_value
				if UNIVERSAL::isa($row->{'itemlabel'}, 'RDF::Trine::Node::Literal');
			$projects->{$p}->{'v'}->{$v}->{'c'}->{$c}->{'blame'} = {};
				
			if (UNIVERSAL::isa($row->{'itemtype'}, 'RDF::Trine::Node::Resource'))
			{
				my $u = $row->{'itemtype'}->uri;
				
				if ($u =~ m'^http://aaronland.info/ns/changefile/(addition|update|bugfix|removal)$')
				{
					push @{ $projects->{$p}->{'v'}->{$v}->{'c'}->{$c}->{'type'} },
						'http://ontologi.es/doap-changeset#'.(ucfirst $1);
				}
			}
		}
	}	
}

1;

__END__

=head1 NAME

RDF::DOAP::ChangeSets - create pretty ChangeLogs from RDF

=head1 SYNOPSIS

 use RDF::DOAP::ChangeSets;
 use URI::file;
 
 my $file     = 'path/to/changelog.rdf';
 my $file_uri = URI::file->new_abs($file);
 
 my $dcs = RDF::DOAP::ChangeSets->new(
             $file_uri, undef, undef, 'RDFXML');
 print $dcs->to_string;

=head1 DESCRIPTION

This module takes software changelogs written in the RDF DOAP
Change Sets vocabulary and produces human-readable changelogs.

=over

=item C<< RDF::DOAP::ChangeSets->new($uri, $data, $type, $fmt) >>

Creates and initialises an object.

$uri is a URL for the input data. The URL is used to query the
RDF data for the heading of the output changelog. It may be passed
as either a string, or a L<URI> object.

$data is the RDF data to use as input. It may be passed as a
string, or as an L<RDF::Trine::Model> object. If undefined,
this module will attempt to read data from the URL using
L<LWP::Simple>.

$type gives the constructor a hint as to the RDF vocabulary you
are using. For DOAP Change Sets, use 'current'; for Aaron Cope's
Changefile vocab, use 'legacy'; to autodetect, use 'auto'. By
default, performs autodetection. This module may crash and burn
if you try to mix both vocabs!!

$fmt provides a hint as to what RDF format you're using. By
default, Turtle is assumed. Valid values are whatever
RDF::Trine::Parser->new accepts.

=item C<< $changeset->is_legacy >>

Boolean, indicating if a legacy vocab is being used.

=item C<< $changeset->is_current >>

Boolean, indicating if the current vocab is being used.

=item C<< $changeset->model >>

RDF::Trine::Model object representing the changelog data.

=item C<< $changeset->uri >>

String representing the changelog URI.

=item C<< $changeset->to_string >>

Creates a human-readable representation of the changelog.

=item C<< $changeset->to_file($filename) >>

Same as C<to_string>, but outputs to a file.

=back

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<RDF::Trine>, L<CPAN::Changes::Spec>, L<Module::Install::DOAPChangeSets>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2010-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
