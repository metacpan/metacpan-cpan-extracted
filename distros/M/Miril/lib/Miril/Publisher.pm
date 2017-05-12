package Miril::Publisher;

use warnings;
use strict;
use autodie;

use Try::Tiny;
use Exception::Class;
use Carp;
use Module::Load;
use Miril::Warning;
use Miril::Exception;
use Miril::Config;
use Miril::List;
use Ref::List qw(list);
use File::Spec::Functions qw(catfile splitpath);
use Text::Sprintf::Named;
use Miril::URL;
use File::Path qw(make_path);


our $VERSION = '0.007';

sub publish {
	my ($class, $miril, $rebuild) = @_;

	my $cfg = $miril->cfg;

	my (@to_create, @to_update);

	my @posts = $miril->store->get_posts;

	foreach my $post (@posts) 
	{
		if (-x $post->out_path) {
			# TODO - check if this is correct!
			if ( $rebuild or ($post->modified->epoch > -M $post->out_path) ) {
				push @to_update, $post->id;
			}
		} else {
			push @to_create, $post->id;
		}
	}

	for (@to_create, @to_update) {
		my $post = $miril->store->get_post($_);
		
		my $output = $miril->tmpl->load(
			name => $post->type->template, 
			params => {
				post  => $post,
				cfg   => $cfg,
				title => $post->title,
				id    => $post->id,
		});

		_file_write($post->out_path, $output);
	}

	foreach my $list ($cfg->lists->list) 
	{
		my @posts;

		# accept ids
		if ( $list->match->id )
		{
			push @posts, $miril->store->get_post($_) for $list->match->id->list;
		}
		else 
		{
			my @params = qw(
				author
				type
				status
				topic
				created_before
				created_on
				created_after
				updated_before
				updated_on
				updated_after
				published_before
				published_on
				published_after
				last
			);
		
			my %params;

			foreach my $param (@params) {
				if ( exists $list->match->{$param} ) {
					$params{$param} = $list->match->{$param};
				}
			}

			@posts = $miril->store->get_posts(%params);
		}

		if ($list->group) {

		
			my $list_main = Miril::List->new( 
				posts => \@posts, 
				title => $list->name,
				sort  => $cfg->sort,
				id    => $list->id,
			);
			
			my $group_key = $list->group; 
			foreach my $list_group ($list_main->group($group_key))
			{
				
				my ($f_args, $tag_url_id);

				if ($group_key eq 'topic')
				{
					$f_args = { topic => $list_group->key->id };
					$tag_url_id = $list->id . '/' . $list_group->key->id;
				}
				elsif ($group_key eq 'type')
				{
					$f_args = { type => $list_group->key->id };
					$tag_url_id = $list->id . '/' . $list_group->key->id;
				}
				elsif ($group_key eq 'author')
				{
					$f_args = { author => $list_group->key};
					$tag_url_id = $list->id . '/' . $list_group->key;
				}
				else
				{	
					$f_args = { 
						year  => $list_group->key->strftime('%Y'), 
						month => $list_group->key->strftime('%m'), 
						date  => $list_group->key->strftime('%d'), 
					};
				}

				my $formatter = Text::Sprintf::Named->new({fmt => $list->location});
				my $location = $formatter->format({args => $f_args});
				$list_group->{url} = $miril->util->inflate_list_url($tag_url_id, $list->location);
					
				my $output = $miril->tmpl->load(
					name => $list->template,
					params => {
						list  => $list_group,
						cfg   => $cfg,
						title => $list_group->title,
						id    => $list->id,
				});
		
				my $new_filename = catfile($cfg->output_path, $location);
				_file_write($new_filename, $output);
			}
		}
		elsif ($list->page)
		{
			my $pager = Data::Page->new;
			my $posts_no = scalar @posts;
			$pager->total_entries($posts_no);
			$pager->entries_per_page($list->page);
			foreach my $page_no ($pager->first_page .. $pager->last_page)
			{
				my $current_pager = Data::Page->new;
				$current_pager->total_entries($posts_no);
				$current_pager->entries_per_page($list->page);
				$current_pager->current_page($page_no);
				my @current_posts = $pager->splice(\@posts);
					
				my $formatter = Text::Sprintf::Named->new({fmt => $list->location});
				my $location = $formatter->format({args => { page => $page_no }});
					
				my $list_page = Miril::List->new(
					posts => \@current_posts,
					pager => $current_pager,
					title => $list->name,
					url   => $miril->util->inflate_list_url(undef, $location),
					sort  => $cfg->sort,
					id    => $list->id,
				);

				my $output = $miril->tmpl->load(
					name => $list->template,
					params => {
						list  => $list_page,
						cfg   => $cfg,
						title => $list_page->title,
						id    => $list->id,
				});
		
				my $new_filename = catfile($cfg->output_path, $location);
				_file_write($new_filename, $output);
			}
		}	
		else
		{
			my $output = $miril->tmpl->load(
				name => $list->template,
				params => {
					list => Miril::List->new( 
						posts => \@posts,
						title => $list->name,
						url   => $miril->util->inflate_list_url($list->id, $list->location),
						id    => $list->id,
						sort  => $cfg->sort,
					),
					cfg   => $cfg,
					title => $list->name,
					id    => $list->id,
				}
			);
		
			my $new_filename = catfile($cfg->output_path, $list->location);
			_file_write($new_filename, $output);
		}
	}
}

sub _file_write {
	my ($filename, $data) = @_;
	my ($volume, $directories, $file) = splitpath($filename);
	my $path = $volume . $directories;
	try {
		make_path($path);
		my $fh = IO::File->new($filename, ">") or die $!;
		$fh->print($data);
		$fh->close;
	} catch {
		Miril::Exception->throw(
			errorvar => $_,
			message  => 'Could not save information',
		);
	}
	#my $post_fh = IO::File->new($filename, "<") or die $!;
	#while (<$post_fh>)
	#{
#		warn "BOM before write!" if /\x{FEFF}/;
	#}
}

1;



