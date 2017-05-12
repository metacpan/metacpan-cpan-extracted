package Redmine::Stat;

use strict;
use warnings;
use utf8;

require Crypt::SSLeay;
require IO::Socket::SSL;
use Carp;
use LWP::UserAgent;
use XML::LibXML;


our $redmine_url;
our $xml_auth_key;
our $xml_query_id;
our $xml;
our $xml_type;
our %projects;
our %trackers;

our $total_issues;

our $VERSION = '0.01';

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Redmine::Stat - Perl extension for dealing with Redmine Rest api. 

=head1 SYNOPSIS

	use Redmine::Stat;
	my $redmine = new Redmine::Stat;

	$redmine->auth_key('your_secret_key_to_api');
	$redmine->url('https://your.redmine.url');
	$redmine->query_id(100500) #id of redmine query, which stats your are gathering


	use Redmine::Stat;
	my $redmine = new Redmine::Stat->new(
		auth_key	=> 'your_secret_key_to_api',
		url		=> 'https://your.redmine.url');
		query_id	=> 100500,
	);



	$redmine->query(); #this does all the work

	$issues_count	= $redmine->total_issues;
	$projects_count	= $redmine->total_projects;
	$trackers_count	= $redmine->total_trackers;

	foreach ($redmine->projects)
	{
		print "Project: ". $_->{name} . " ";
		print "Path: ". $_->{redmine_path} ." ";
		print "Descripttion: ". $_->{description} ." ";
		print "Issues count: ". $_->{issues_count} ." ";
		print "\r\n";
	}

	foreach ($redmine->trackers)
	{
		print "Tracker: ". $_->{name}  ." ";
		print "Issues count: ". $_->{issues_count} ." ";
		print "\r\n";
	}

	$trackers{bug} = $redmine->tracker('BUG'); #you can search trackers by name
	$trackers{feature} = $remdine->tracker(4); #or by redmine id

	$projects{test.com} = $redmine->project('test.com'); #projects by name
	$projects{test.org} = $redmine->project(15); #by id
	$projects{test.net} = $redmine->project('test_net') #by redmine project path



=head1 DESCRIPTION

This module is designed for statistic purposes only, it does not apply CRUD or any other operations. I have wrote this module because i wanted to combine RRDtool with my Redmine.

Redmine::Stat works with Redmine REST api (L<http://www.redmine.org/projects/redmine/wiki/Rest_api>). By default redmine forces clients to use pagination, and does not allow unlimited queries, what is a bad idea imho. You need some modifications in Redmine core for this module to work correctly. Otherwise, if you don't need by-project or by-tracker issue statistics, you may not modify Redmine - this module will deal with "meta" fields, such as total_count. Maximum limit (100) is located as a Magick number in B<app/controllers/application_controller.rb:415> as of my version B<1.4.2>.

You may get almost any statistics by creating your own queries in redmine, and parsing them through this module.


=head1 SEE ALSO

=over

=item Redmine REST api L<http://www.redmine.org/projects/redmine/wiki/Rest_api>

=item L<Net::Redmine|Net::Redmine>

=back

=head1 AUTHOR

Fedor A Borshev, E<lt>fedor@shogo.ruE<gt>



=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Fedor A Borshev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

sub new
{
	(my $self, my %p) = @_;

	$self->url ($p{url}) if exists $p{url} and length $p{url};
	$self->auth_key ($p{auth_key}) if exists $p{auth_key} and length $p{auth_key};
	$self->query_id ($p{query_id}) if exists $p{query_id} and length $p{query_id};
	$self;
}


sub query
{
	my $self = shift;

	$self->xml_type('issues');
	$self->_parse_xml(
		$self->_get_xml( $self->_get_query_url('issues') )
	) or confess 'Cannot parse issues xml:(';

	$self->_parse_projects();
	$self->_parse_trackers();

	$total_issues = $self->total_issues;

	$self->xml_type('projects');
	$self->_parse_xml(
		$self->_get_xml( $self->_get_query_url('projects') )
	) or confess 'Cannot parse projects xml:(';

	$self->_parse_projects();

	$self->xml_type('trackers');
	$self->_parse_xml(
		$self->_get_xml( $self->_get_query_url('trackers') )
	) or confess 'Cannot parse trackers xml:(';
	

	$self->_parse_trackers();

}

sub total_issues
{
	my $self=shift;

	return $self->_total if $self->xml_type eq 'issues';

	return $total_issues;
}

sub total_projects
{
	my $self=shift;
	
	if ( $self->xml_type eq 'projects' )
	{
		return $self->_total;
	}
	
	if( $self->xml_type eq 'issues' ) #count of projects in issues query
	{
		$self->_parse_projects;
		return scalar keys %projects;
	}

	return scalar keys %projects;

}	

sub total_trackers
{
	my $self = shift;

	if( $self->xml_type eq 'trackers' )
	{
		$self->_parse_trackers;
		return scalar keys %trackers;
	}
	return scalar keys %trackers;
}

sub issues_by_tracker
{
	(my $self, my $tracker) = @_;
	
	return $self->_count_issues('tracker', $tracker);
}	

sub issues_by_author
{
	(my $self, my $author) = @_;

	return $self->_count_issues('author', $author);

}

sub issues_by_status
{
	(my $self, my $status) = @_;
	
	return $self->_count_issues('status', $status);

}

sub issues_by_project
{
	(my $self, my $project) = @_;

	return $self->_count_issues('project', $project);
}



sub _parse_xml
{
		
	(my $self, my $data) = @_;

	confess "Bad XML data" if not $data or not length $data;

	$xml = XML::LibXML->load_xml( string => $data ) or confess "Cannot parse XML!";


}

sub xml_type
{
	(my $self, my $type) = @_;

	return $xml_type if ( not $type or not length $type );

	$xml_type = $type;
}

sub auth_key
{
	(my $self, my $auth_key) = @_;
	
	return $xml_auth_key if ( not $auth_key or not length $auth_key );

	$xml_auth_key = $auth_key;
}

sub query_id
{
	(my $self, my $query_id) = @_;

	return $xml_query_id if ( not $query_id or not length $query_id );

	$xml_query_id = $query_id;
}

sub url
{
	(my $self, my $url) = @_;

	return $redmine_url if ( not $url or not length $url );
	

	$url =~ s/\/$//;

	$redmine_url = $url;
}


sub raw_xml
{
	my $self = shift;
	
	return $xml;

}

sub project
{
	(my $self, my $prj) = @_;

	if( $prj =~ /^\d+$/ and exists $projects{$prj} )
	{

		return $projects{$prj};
	}

	chomp $prj;

	foreach (keys %projects)
	{
		return $projects{$_} if( exists $projects{$_} and $projects{$_}{name} eq $prj );
		return $projects{$_} if( exists $projects{$_} and exists $projects{$_}{redmine_path} and $projects{$_}{redmine_path} eq $prj );
	}
}

sub projects
{
	my $self = shift;

	return keys %projects;
}

sub tracker
{
	(my $self, my $tracker) = @_;
	
	if( $tracker =~ /^\d+$/ and exists $trackers{$tracker})
	{
		return $trackers{$tracker};
	}

	foreach (keys %trackers)
	{
		return $trackers{$_} if( exists $trackers{$_} and $trackers{$_}{name} eq $tracker );
	}
}

sub trackers
{
	my $self = shift;

	return keys %trackers;
}

sub _parse_projects
{
	my $self = shift;
	
	if($self->xml_type() eq 'projects')
	{
		foreach( $xml->findnodes('projects/project') )
		{
			my $id 			= $_->findvalue('id');

			$projects{$id}{name}		= $_->findvalue('name');
			$projects{$id}{redmine_path}	= $_->findvalue('identifier');
			$projects{$id}{description}	= $_->findvalue('description') ? $_->findvalue('description') : '';

			chomp $projects{$id}{description};
			
		}
	}
	if($self->xml_type() eq 'issues')
	{
		foreach( $xml->findnodes('issues/issue') )
		{
			(my $prj_node) = $_->findnodes ('project');

			my $id		= $prj_node->getAttribute('id');
			my $name	= $prj_node->getAttribute('name');

			$projects{$id}{name} = $name;
		}

		$self->_count_issues_by_project;
	}
}

sub _count_issues_by_project
{
	my $self=shift;

	if($self->xml_type() eq 'issues')
	{
		foreach( keys %projects)
		{
			$projects{$_}{issues_count}=$self->_count_issues('project',$_);
		}
	}
}

sub _count_issues_by_tracker
{
	my $self=shift;

	if($self->xml_type() eq 'issues')
	{
		foreach( keys %trackers)
		{
			$trackers{$_}{issues_count}=$self->_count_issues('tracker',$_);
		}
	}
}

sub _parse_trackers
{
	my $self = shift;

	if( $self->xml_type eq 'trackers')
	{
		foreach( $xml->findnodes('trackers/tracker') )
		{
			my $id = $_->findvalue('id');

			$trackers{$id}{name} = $_->findvalue('name');
		}
	}

	if( $self->xml_type eq 'issues')
	{
		foreach( $xml->findnodes('issues/issue') )
		{
			(my $tracker_node) = $_->findnodes ('tracker');

			my $id		= $tracker_node->getAttribute('id');
			my $name	= $tracker_node->getAttribute('name');

			$trackers{$id}{name} = $name;
		}
		$self->_count_issues_by_tracker;
	}

}
		
sub _count_issues
{
	(my $self, my $nodename, my $name_or_id) = @_;

	my $cnt=0;

	foreach( $xml->findnodes('issues/issue') )
	{
		(my $node) = $_->findnodes( $nodename );

		if( $name_or_id =~ /^\d+$/ )
		{
			$cnt++ if ( $node->getAttribute('id') == $name_or_id );
		}
		else
		{
			$cnt++ if ( $node->getAttribute('name') eq $name_or_id );
		}
	}
	return $cnt;
}

sub _total
{
	my $self = shift;

	my $rootNode=$xml->documentElement;

	return $rootNode->getAttribute('total_count');
}

sub _get_query_url
{
	(my $self, my $url_type) = @_;

	if( $url_type eq 'issues')
	{
		return $self->url.'/issues.xml?query_id='.$self->query_id if $self->query_id;
		return $self->url.'/issues.xml';
	}
	return $self->url.'/projects.xml' if( $url_type eq 'projects');
	return $self->url.'/trackers.xml' if( $url_type eq 'trackers');

	return $self->url;
}

sub _get_xml
{
	(my $self, my $url) = @_;

	my $ua=LWP::UserAgent->new();

	$ua->default_header(
		'X-Redmine-API-Key' => $self->auth_key,
	);

	my $response=$ua->get($url);
	confess "Cannot fetch xml data" if $response->is_error;
	
	return $response->content;

}
1;
