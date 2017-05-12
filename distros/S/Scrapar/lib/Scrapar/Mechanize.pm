package WWW::Mechanize::Cached;

use strict;
use warnings FATAL => 'all';

use vars qw( $VERSION );
$VERSION = '1.33';

use base qw( WWW::Mechanize );
use Carp qw( carp croak );
use Storable qw( freeze thaw );
use Compress::Zlib;
require Scrapar::Util;
use File::Find::Rule;

my $cache_key = __PACKAGE__;

sub _recycle_cache {
    my $self = shift;
    my $namespace = shift;

    # recycle cache files
    #
    # 1. tmp disk usage is more than 50%
    if (Scrapar::Util::disk_usage('/tmp') > 50) {
	$ENV{SCRAPER_LOGGER}->info("Recycling cache files in $namespace");
	
	# 2. older than 30 days
	for my $file (File::Find::Rule->file()
		      ->mtime("<" . (time - 30*86400))
		      ->in('/tmp/FileCache/' . $namespace)) {
	    unlink $file;
	}

	$ENV{SCRAPER_LOGGER}->info("Recycling done");
    }
}

sub new {
    my $class = shift;
    my %mech_args = @_;

    my $cache = delete $mech_args{cache};
    if ( $cache ) {
        my $ok = (ref($cache) ne "HASH") && $cache->can("get") && $cache->can("set");
        if ( !$ok ) {
            carp "The cache parm must be an initialized cache object";
            $cache = undef;
        }
    }

    my $self = $class->SUPER::new( %mech_args );

    if ( !$cache ) {
        require Cache::FileCache;
	my $cache_namespace = $ENV{SCRAPER_BACKEND} ?
	    'www-mechanize-cached-' . $ENV{SCRAPER_BACKEND} :
	    'www-mechanize-cached';
        my $cache_parms = {
            default_expires_in => ($self->{cache_expires_in} || "1d"),
            namespace => $cache_namespace,
        };
        $cache = Cache::FileCache->new( $cache_parms );
	$self->_recycle_cache($cache_namespace);
    }

    $self->{$cache_key} = $cache;

    return $self;
}

sub is_cached {
    my $self = shift;

    return $self->{_is_cached};
}

sub _make_request {
    my $self = shift;
    my $request = shift;

    my $req = $request->as_string;
    my $cache = $self->{$cache_key};
    my $response = $cache->get( $req );
    $ENV{SCRAPER_REQUESTS}++;
    if ( $response ) {

	# display the cache file
	require Cache::FileBackend;
	print("Cache key: " . Cache::FileBackend::_Build_Unique_Key($req) 
	      . "\n");

	print "[Cache hit!] " . $request->uri() . "\n";
        $response = thaw uncompress $response;
        $self->{_is_cached} = 1;
	$ENV{SCRAPER_CACHE_HITS}++;
    } 
    else {
        $response = $self->SUPER::_make_request( $request, @_ );
        
        # http://rt.cpan.org/Public/Bug/Display.html?id=42693
        $response->decode();
        delete $response->{handlers};
        
        $cache->set( $req, compress freeze($response) );
        $self->{_is_cached} = 0;
    }

    # An odd line to need.
    $self->{proxy} = {} unless defined $self->{proxy};

    return $response;
}

# Add an filter output
package HTML::Element;

use lib qw(lib);
use Scrapar::Util;
use Digest::MD5 qw(md5_hex);

my $text_tag = '_text_' . md5_hex time;

sub as_filtered_text {
    my $self = shift;
    my $sub_ref = shift;

    my $text = $self->as_text;
    
    return $text if ref($sub_ref) ne 'CODE';

    return $sub_ref->($text);
}

# text_objectified should be overridden, but somehow overriding causes the module not to be loaded.... 
# to be investigated.
sub text_objectified {
  my (@stack) = ($_[0]);

  my ($this);
  while (@stack) {
      foreach my $c (@{( $this = shift @stack )->{'_content'}}) {
	  if (ref($c)) {
	      unshift @stack, $c;
	  } 
	  else {
	      # pure text
	      my $text = $c;
	      $c = ( $this->{'_element_class'} || __PACKAGE__ )
		->new($text_tag, '_parent' => $this);
	      $c->push_content($text);
	  }
      }
  }
  return;
}

sub as_deobjectified_HTML {
    my $self = shift;
    my $html = $self->as_HTML(@_);
    $html =~ s[<$text_tag>(.+?)</$text_tag>][$1]sg;
    return $html;
}

sub as_headtrimmed_text {
    my $self = shift;
    my $regex = shift;

    return trim_head($self->as_text, $regex);
}

sub as_tailtrimmed_text {
    my $self = shift;
    my $regex = shift;

    return trim_tail($self->as_text, $regex);
}

sub innerHTML {
    my $self = shift;

    my $html = $self->as_HTML;
    $html =~ s[\A[\n\r\s]*<[^>]+?>(.+)<[^>]+?>[\n\r\s]*\z][$1]s;

    return $html;
}

sub query_first {
    my $self = shift;
    my $query = shift || return;

    my @r = $self->query($query);
    if (defined $r[0] && ref $r[0]) {
	return $r[0];
    }
    else {
	return HTML::Element->new('span');
    }
}

package Scrapar::Mechanize;

use strict;
use warnings;
use DB_File;
use Digest::MD5 qw(md5);
use URI;
use Data::Dumper;
use Scrapar::HTMLQuery 'query';
use HTML::TreeBuilder;
use HTML::Element;
use HTTP::Cookies;
use Scrapar::Util;

our @ISA;

BEGIN {
    if ($ENV{SCRAPER_CACHE}) {
	eval "push \@ISA, 'WWW::Mechanize::Cached';";
    }
    else {
	eval "use base qw(WWW::Mechanize)";
    }
    die $@ if $@;
}

my $history_filename = $ENV{PWD} . '/scraper-history';
END {
    unlink $history_filename;
}
tie my %history, 
    'DB_File', $history_filename, O_CREAT | O_RDWR, 0644, $DB_BTREE ;

sub visited {
    my $key = md5(Dumper(URI->new($_[0])));
    return 1 if $history{$key};
}

sub cache_expires_in {
    my $self = shift;
    $self->{cache_expires_in} = shift || $self->{cache_expires_in} || '1d';

    return $self->{cache_expires_in};
}

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->stack_depth(0);
    $self->{fetch_count} = 0;

    my $cookie_folder = "$ENV{HOME}/.scraper-cookies";
    mkdir $cookie_folder;
    my $cookie_jar = HTTP::Cookies->new(
	file => ($ENV{SCRAPER_BACKEND} ?
		 "$cookie_folder/$ENV{SCRAPER_BACKEND}.dat" :
		 "$cookie_folder/hq-cookies.dat"),
	autosave => 1
	);
    $self->cookie_jar($cookie_jar);
    $self->agent_alias('Windows IE 6');
    $self->proxy([ 'http' ], $ENV{SCRAPER_PROXY}) if $ENV{SCRAPER_PROXY};

    $self;
}

sub referer {
    my $self = shift;
    $self->add_header(Referer => shift);
}

sub no_referer {
    my $self = shift;
    $self->delete_header('Referer');
}

sub get {
    my $self = shift;
    my $u;
    if (ref $_[0]) {
	if (ref $_[0] eq 'WWW::Mechanize::Link') {
	    $u = URI->new($_[0]->url_abs);
	}
    }
    else {
	$u = URI->new($_[0]);
    }
    my $key = md5(Dumper($u));

    sleep(int rand 10) if $ENV{SCRAPER_TIME_INTERVAL};

    $self->{_html_tree_cache} = undef;

    my ($caller_sub) = (caller(1))[3];

    if (!$history{$key}) {
	$self->{fetch_count}++;
	if (exists $ENV{SCRAPER_MAX_LINKS} 
	    && $self->{fetch_count} >= $ENV{SCRAPER_MAX_LINKS}) {
	    print "Max link is reached. Exiting ...\n";
	    exit;
	}

	print "\n-- $caller_sub --\n\n[$self->{fetch_count}][Mechanize] Getting " . ($u ? $u->as_string : '--- url ---') . "\n";

	$ENV{SCRAPER_LOGGER}->info("($self->{fetch_count}) Get " .($u ? $u->as_string : '--- url ---') . " $caller_sub");

#	print Scrapar::Util::free_mem_ratio(), $/;
	if (Scrapar::Util::free_mem_ratio() < 0.2) {
	    $ENV{SCRAPER_LOGGER}->warning("Free memory ratio less then 0.2. Aborting");
	    exit;
	}

	$self->SUPER::get(@_);
	$history{$key}++;
    }
}

sub html_tree {
    my $self = shift;
    my $args_ref = shift;

    # memoize html tree
    if (!$self->{_html_tree_cache}) {
        my $tree = $self->{_html_tree_cache} = HTML::TreeBuilder->new;

        $tree->parse($self->content);

	if ($args_ref->{objectify_text}) {
	    $tree->text_objectified;
	    $tree->{_is_text_objectified} = 1;
	}
    }

    return $self->{_html_tree_cache};
}

sub query {
    my $self = shift;
    my $query = shift || return;
    my $args_ref = shift || {};

    my @results = $self->html_tree($args_ref)->query($query);

    return wantarray ? @results : \@results;
}

sub query_first {
    my $self = shift;
    my $query = shift || return;
    my $args_ref = shift;

    my @r = $self->query($query, $args_ref);
    if (defined $r[0] && ref $r[0]) {
	return $r[0];
    }
    else {
	return HTML::Element->new('span');
    }
}

sub bulk_query_first {
    my $self = shift;
    my $r = shift;

    for my $req (@_) {
	my ($field, $query, $render, $render_arg) = @{$req};
	$r->{$field} = $self->query_first($query)->$render($render_arg);
    }
}

sub find_email {
    my $self = shift;
    return Scrapar::Util::find_email($self->content);
}

1;

