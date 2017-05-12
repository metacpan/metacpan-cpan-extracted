package Miril::Util;

use strict;
use warnings;
use autodie;

use File::Spec::Functions        qw(catfile);
use List::Util                   qw(first);
use Miril::URL                   qw();
use Miril::DateTime              qw();

### ACCESSORS ###

use Object::Tiny qw(cfg);

### CONSTRUCTOR ###

sub new 
{
	my ($class, $cfg) = @_;
	my $self = bless {}, $class;
	$self->{cfg} = $cfg;
	return $self;
}

### PUBLIC METHODS ###

sub inflate_date_published 
{
	my ($self, $old_date, $new_status) = @_;
	
	if ($new_status eq 'published')
	{
		return $old_date 
			? Miril::DateTime->new($old_date) 
			: Miril::DateTime->new(time);
	}
	else
	{
		return undef;
	}
}

sub inflate_date_modified 
{
	my ($self, $filename) = @_;
	return time - ( (-M $filename) * 86400 );
}

sub inflate_in_path 
{
	my ($self, $id) = @_;
	return catfile($self->cfg->data_path, $id);
}

sub inflate_out_path 
{
	my ($self, $name, $type) = @_;
	return catfile($self->cfg->output_path, $type->location, $name . ".html");
}

sub inflate_type
{
	my ($self, $id) = @_;
	return first { $_->id eq $id } $self->cfg->types->list;
}

sub inflate_author
{
	my ($self, $author) = @_;
	return $author ? $author : undef;
}

sub inflate_topics
{
	my ($self, @topics) = @_;
	my %topics_lookup = map {$_ => 1} @topics;
	my @topic_objects = grep { $topics_lookup{$_->{id}} } $self->cfg->topics->list;
	return \@topic_objects;
}

sub inflate_post_url 
{
	my ($self, $name, $type, $date) = @_;
	my $cfg = $self->cfg;
	my $url = Miril::URL->new(
		abs => 'http://' . $cfg->domain . $cfg->http_dir . $type->location . $name . '.html',
		rel => $cfg->http_dir . $type->location . $name . '.html',
		tag => 'tag:' . $cfg->domain . ',' . $date->strftime('%Y-%m-%d') . ':/' . $name,
	);
	return $url;
}

sub inflate_list_url
{
	my ($self, $id, $location) = @_;
	my $cfg = $self->cfg;
	my $date = Miril::DateTime->new(time());
	return Miril::URL->new(
		abs => 'http://' . $cfg->domain . $cfg->http_dir . $location,
		rel => $cfg->http_dir . $location,
		tag => $id ? 'tag:' . $cfg->domain . ',' . $date->strftime('%Y-%m-%d') . ':/list/' . $id : undef,
	);
}

1;
