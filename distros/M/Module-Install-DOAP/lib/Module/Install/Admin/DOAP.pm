package Module::Install::Admin::DOAP;

use 5.008;
use base qw(Module::Install::Base);
use strict;

use Module::Install::Admin::RDF 0.003;
use RDF::Trine;

our $VERSION = '0.006';

use RDF::Trine::Namespace qw[RDF RDFS OWL XSD];
my $CPAN = RDF::Trine::Namespace->new('http://purl.org/NET/cpan-uri/terms#');
my $DC   = RDF::Trine::Namespace->new('http://purl.org/dc/terms/');
my $DOAP = RDF::Trine::Namespace->new('http://usefulinc.com/ns/doap#');
my $DEPS = RDF::Trine::Namespace->new('http://ontologi.es/doap-deps#');
my $FOAF = RDF::Trine::Namespace->new('http://xmlns.com/foaf/0.1/');
my $NFO  = RDF::Trine::Namespace->new('http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#');
my $SKOS = RDF::Trine::Namespace->new('http://www.w3.org/2004/02/skos/core#');

sub doap_metadata
{
	my ($self, $uri) = @_;
	
	unless (defined $uri)
	{
		$uri = Module::Install::Admin::RDF::rdf_project_uri($self);
	}
	unless (ref $uri)
	{
		$uri = RDF::Trine::Node::Resource->new($uri);
	}

	my $metadata = sub {
		$self->_top->call(@_);
		};

	my $model = Module::Install::Admin::RDF::rdf_metadata($self);

	my $name;
	NAME: foreach ($model->objects_for_predicate_list($uri, $DOAP->name, $FOAF->name, $RDFS->label))
	{
		next NAME unless $_->is_literal;
		$name = $_->literal_value;
		$metadata->(name => $_->literal_value);
		last NAME;
	}

	my $mname;
	MNAME: foreach ($model->objects_for_predicate_list($uri, $CPAN->module_name))
	{
		next MNAME unless $_->is_literal;
		$mname = $_->literal_value;
		$metadata->(module_name => $_->literal_value);
		last MNAME;
	}
	if (defined $name and !defined $mname)
	{
		$mname = $name;
		$mname =~ s/-/::/g;
		$metadata->(module_name => $mname);
	}

	DESC: foreach ($model->objects_for_predicate_list($uri, $DOAP->shortdesc, $DC->abstract))
	{
		next DESC unless $_->is_literal;
		$metadata->(abstract => $_->literal_value);
		last DESC;
	}

	LICENSE: foreach ($model->objects_for_predicate_list($uri, $DOAP->license, $DC->license))
	{
		next LICENSE unless $_->is_resource;
		
		my $license_code = {
			'http://www.gnu.org/licenses/agpl-3.0.txt'              => 'open_source',
			'http://www.apache.org/licenses/LICENSE-1.1'            => 'apache_1_1',
			'http://www.apache.org/licenses/LICENSE-2.0'            => 'apache',
			'http://www.apache.org/licenses/LICENSE-2.0.txt'        => 'apache',
			'http://www.perlfoundation.org/artistic_license_1_0'    => 'artistic',
			'http://opensource.org/licenses/artistic-license.php'   => 'artistic',
			'http://www.perlfoundation.org/artistic_license_2_0'    => 'artistic_2',
			'http://opensource.org/licenses/artistic-license-2.0.php'  => 'artistic_2',
			'http://www.opensource.org/licenses/bsd-license.php'    => 'bsd',
			'http://creativecommons.org/publicdomain/zero/1.0/'     => 'unrestricted',
			'http://www.freebsd.org/copyright/freebsd-license.html' => 'open_source',
			'http://www.gnu.org/copyleft/fdl.html'                  => 'open_source',
			'http://www.opensource.org/licenses/gpl-license.php'    => 'gpl',
			'http://www.gnu.org/licenses/old-licenses/gpl-1.0.txt'  => 'gpl',
			'http://www.opensource.org/licenses/gpl-2.0.php'        => 'gpl2',
			'http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt'  => 'gpl2',
			'http://www.opensource.org/licenses/gpl-3.0.html'       => 'gpl3',
			'http://www.gnu.org/licenses/gpl-3.0.txt'               => 'gpl3',
			'http://www.opensource.org/licenses/lgpl-license.php'   => 'lgpl',
			'http://www.opensource.org/licenses/lgpl-2.1.php'       => 'lgpl2',
			'http://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt' => 'lgpl2',
			'http://www.opensource.org/licenses/lgpl-3.0.html'      => 'lgpl3',
			'http://www.gnu.org/licenses/lgpl-3.0.txt'              => 'lgpl3',
			'http://www.opensource.org/licenses/mit-license.php'    => 'mit',
			'http://www.mozilla.org/MPL/MPL-1.0.txt'                => 'mozilla',
			'http://www.mozilla.org/MPL/MPL-1.1.txt'                => 'mozilla',
			'http://opensource.org/licenses/mozilla1.1.php'         => 'mozilla',
			'http://www.openssl.org/source/license.html'            => 'open_source',
			'http://dev.perl.org/licenses/'                         => 'perl',
			'http://www.opensource.org/licenses/postgresql'         => 'open_source',
			'http://trolltech.com/products/qt/licenses/licensing/qpl'  => 'open_source',
			'http://h71000.www7.hp.com/doc/83final/BA554_90007/apcs02.html'  => 'unrestricted',
			'http://www.openoffice.org/licenses/sissl_license.html' => 'open_source',
			'http://www.zlib.net/zlib_license.html'                 => 'open_source',
			}->{ $_->uri } || undef;

		$metadata->(license => $license_code);
		last LICENSE;
	}
	
	my %resources;
	($resources{license}) = 
		map  { $_->uri }
		grep { $_->is_resource }
		$model->objects_for_predicate_list($uri, $DOAP->license, $DC->license);
	($resources{homepage}) = 
		map  { $_->uri }
		grep { $_->is_resource }
		$model->objects_for_predicate_list($uri, $DOAP->homepage, $FOAF->homepage, $FOAF->page);
	($resources{bugtracker}) = 
		map  { $_->uri }
		grep { $_->is_resource }
		$model->objects($uri, $DOAP->uri('bug-database'));
	REPO: foreach my $repo ($model->objects($uri, $DOAP->repository))
	{
		next REPO if $repo->is_literal;
		($resources{repository}) = 
			map  { $_->uri }
			grep { $_->is_resource }
			$model->objects($repo, $DOAP->uri('browse'));
		last REPO if $resources{repository};
	}
	($resources{MailingList}) = 
		map  { $_->uri }
		grep { $_->is_resource }
		$model->objects($uri, $DOAP->uri('mailing-list'));
	($resources{Wiki}) = 
		map  { $_->uri }
		grep { $_->is_resource }
		$model->objects($uri, $DOAP->uri('wiki'));
	$metadata->(resources => %resources);

	my %keywords;
	CATEGORY: foreach my $cat ($model->objects_for_predicate_list($uri, $DOAP->category, $DC->subject))
	{
		if ($cat->is_literal)
		{
			$keywords{ uc $cat->literal_value } = $cat->literal_value;
		}
		else
		{
			LABEL: foreach my $label ($model->objects_for_predicate_list($cat, $SKOS->prefLabel, $RDFS->label, $DOAP->name, $FOAF->name))
			{
				next LABEL unless $label->is_literal;
				$keywords{ uc $label->literal_value } = $label->literal_value;
				next CATEGORY;
			}
		}
	}
	$metadata->(keywords => sort values %keywords);
	
	my %authors;
	AUTHOR: foreach my $author ($model->objects_for_predicate_list($uri, $DOAP->developer, $DOAP->maintainer, $FOAF->maker, $DC->creator))
	{
		my ($name) =
			map  { $_->literal_value }
			grep { $_->is_literal }
			$model->objects_for_predicate_list($author, $FOAF->name, $RDFS->label);
		my ($mbox) =
			map  { my $x = $_->uri; $x =~ s/^mailto://i; $x; }
			grep { $_->is_resource }
			$model->objects_for_predicate_list($author, $FOAF->mbox);
		
		my $str = do
			{
				if ($name and $mbox)
					{ "$name <$mbox>"; }
				elsif ($name)
					{ $name; }
				elsif ($mbox)
					{ $mbox; }
				else
					{ "$author"; }
			};
		$authors{uc $str} = $str;
	}
	$metadata->(authors => sort values %authors);

	{
		my @terms = qw(requires build_requires configure_requires test_requires recommends provides);
		foreach my $term (@terms)
		{
			foreach my $dep ($model->objects($uri, $CPAN->$term))
			{
				warn "$term is deprecated in favour of http://ontologi.es/doap-deps#";
				if ($dep->is_literal)
				{
					my ($mod, $ver) = split /\s+/, $dep->literal_value;
					$ver ||= 0;
					$metadata->($term => $mod => $ver);
				}
				else
				{
					warn "Dunno what to do with ${dep}... we'll figure something out eventually.";
				}
			}
		}
	}

	foreach my $phase (qw/ configure build test runtime develop /)
	{
		foreach my $level (qw/ requirement recommendation suggestion /)
		{
			my $term = "${phase}-${level}";
			my $mi_term = {
				'configure-requirement'  => 'configure_requires',
				'build-requirement'      => 'build_requires',
				'test-requirement'       => 'test_requires',
				'runtime-requirement'    => 'requires',
				'build-recommendation'   => 'recommends',
				'test-recommendation'    => 'recommends',
				'runtime-recommendation' => 'recommends',
			}->{$term} or next;
			
			foreach my $dep ( $model->objects($uri, $DEPS->uri($term)) )
			{
				if ($dep->is_literal)
				{
					warn $DEPS->$term . " expects a resource, not literal $dep!";
					next;
				}
				
				foreach my $ident ( $model->objects($dep, $DEPS->on) )
				{
					unless ($ident->is_literal
					and     $ident->has_datatype
					and     $ident->literal_datatype eq $DEPS->CpanId->uri)
					{
						warn "Dunno what to do with ${ident}... we'll figure something out eventually.";
						next;
					}
					
					my ($mod, $ver) = split /\s+/, $ident->literal_value;
					$ver ||= 0;
					$metadata->($mi_term => $mod => $ver);
				}
			}
		}			
	}

	{
		my @terms = qw(abstract_from author_from license_from perl_version_from readme_from requires_from version_from
			no_index install_script requires_external_bin);
		TERM: foreach my $term (@terms)
		{
			foreach my $val ($model->objects($uri, $CPAN->$term))
			{
				if ($val->is_literal)
				{
					$metadata->($term => $val->literal_value);
					next TERM;
				}
				else
				{
					foreach my $name ($model->objects($val, $NFO->fileName))
					{
						if ($name->is_literal)
						{
							$metadata->($term => $name->literal_value);
							next TERM;
						}
					}
				}
			}
		}
	}
}

1;
