package Search::ESsearcher;

use 5.006;
use base Error::Helper;
use strict;
use warnings;
use Getopt::Long;
use JSON;
use Template;
use Search::Elasticsearch;
use Term::ANSIColor;
use Time::ParseDate;

=head1 NAME

Search::ESsearcher - Provides a handy system for doing templated elasticsearch searches.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';


=head1 SYNOPSIS


    use Search::ESsearcher;

    my $ess = Search::ESsearcher->new();

=head1 METHODS

=head2 new

This initiates the object.

    my $ss=Search::ESsearcher->new;

=cut

sub new{

	my $self = {
				perror=>undef,
				error=>undef,
				errorString=>"",
				base=>undef,
				search=>'syslog',
				search_template=>undef,
				search_filled_in=>undef,
				search_usable=>undef,
				output=>'syslog',
				output_template=>undef,
				options=>'syslog',
				options_array=>undef,
				elastic=>'default',
				elastic_hash=>{
						  nodes => [
								   '127.0.0.1:9200'
								   ]
						  },
				errorExtra=>{
							 flags=>{
									 '1'=>'IOerror',
									 '2'=>'NOfile',
									 '3'=>'nameInvalid',
									 '4'=>'searchNotUsable',
									 '5'=>'elasticNotLoadable',
									 '6'=>'notResults',
									 }
							 },
				};
    bless $self;

	# finds the etc base to use
	if ( -d '/usr/local/etc/essearch/' ) {
		$self->{base}='/usr/local/etc/essearch/';
	} elsif ( -d '/etc/essearch/' ) {
		$self->{base}='/etc/essearch/';
	} elsif ( $0 =~ /bin\/essearcher$/ ) {
		$self->{base}=$0;
		$self->{base}=~s/\/bin\/essearcher$/\/etc\/essearch\//;
	}

	# inits Template
	$self->{t}=Template->new({
							  EVAL_PERL=>1,
							  INTERPOLATE=>1,
							  POST_CHOMP=>1,
							  });

	# inits JSON
	$self->{j}=JSON->new;
	$self->{j}->pretty(1); # make the output sanely human readable
	$self->{j}->relaxed(1); # make writing search templates a bit easier

	return $self;
}

=head elastic_get

This returns what Elasticsearch config will be used.

    my $elastic=$ess->elastic_get;

=cut

sub elastic_get{
	my $self=$_[0];
	my $name=$_[1];

	if ( ! $self->errorblank ) {
        return undef;
    }

	return $self->{elastic};
}

=head elastic_set

This sets the name of the config file to use.

One option is taken and name of the config file to load.

Undef sets it back to the default, "default".

    $ess->elastic_set('foo');

    $ess->elastic_set(undef);

=cut

sub elastic_set{
	my $self=$_[0];
	my $name=$_[1];

	if ( ! $self->errorblank ) {
        return undef;
    }

	if (! $self->name_validate( $name ) ){
		$self->{error}=3;
		$self->{errorString}='"'.$name.'" is not a valid name';
		$self->warn;
		return undef;
	}

	if( !defined( $name ) ){
		$name='default';
	}

	$self->{elastic}=$name;

	return 1;
}

=head2 fetch_help

This fetches the help for the current search and returns it.
Failsure to find one, results in a empty message being returned.

    my $help=$ess->fetch_help;

=cut

sub fetch_help{
	my $self=$_[0];

	if ( ! $self->errorblank ) {
        return undef;
    }

	my $file=undef;
	my $data=undef;

	# ~/ -> etc -> module -> error
	if (
		( defined( $ENV{'HOME'} ) ) &&
		( -f $ENV{'HOME'}.'/.config/essearcher/help/'.$self->{search} )
		) {
		$file=$ENV{'HOME'}.'/.config/essearcher/help/'.$self->{search};
	} elsif (
			 ( defined( $self->{base} ) ) &&
			 ( -f $self->{base}.'/etc/essearcher/help/'.$self->{search} )
			 ) {
		$file=$self->{base}.'/etc/essearcher/help/'.$self->{search};
	} else {
		# do a quick check of making sure we have a valid name before trying a module...
		# not all valid names are perl module name valid, but it will prevent arbitrary code execution
		if ( $self->name_validate( $self->{search} ) ) {
			my $to_eval='use Search::ESsearcher::Templates::'.$self->{search}.
			'; $data=Search::ESsearcher::Templates::'.$self->{search}.'->help;';
			eval( $to_eval );
		}
		# if undefined, it means the eval failed
		if ( ! defined( $data ) ) {
			$self->{error}=2;
			$self->{errorString}='No help file with the name "'.$self->{search}.'" was found';
			$self->warn;
			return '';
		}
	}

	if ( ! defined( $data ) ) {
		my $fh;
		if (! open($fh, '<', $file ) ) {
			$self->{error}=1;
			$self->{errorString}='Failed to open "'.$file.'"',
			$self->warn;
			return '';
		}
		# if it is larger than 2M bytes, something is wrong as the template
		# it takes is literally longer than all HHGTTG books combined
		if (! read($fh, $data, 200000000 )) {
			$self->{error}=1;
			$self->{errorString}='Failed to read "'.$file.'"',
			$self->warn;
			return '';
		}
		close($fh);
	}

	return $data;
}

=head2 get_options

This fetches the options for use later
when filling in the search template.

    $ess->get_options;

=cut

sub get_options{
	my $self=$_[0];

	if ( ! $self->errorblank ) {
        return undef;
    }

	my %parsed_options;

	GetOptions( \%parsed_options, @{ $self->{options_array} } );


	$self->{parsed_options}=\%parsed_options;

	return 1;
}

=head2 load_options

This loads the currently set options.

    $ess->load_options;

=cut

sub load_options{
	my $self=$_[0];

	if ( ! $self->errorblank ) {
        return undef;
    }

	my $file;
	my $data;

	# ~/ -> etc -> module -> error
	if (
		( defined( $ENV{'HOME'} ) ) &&
		( -f $ENV{'HOME'}.'/.config/essearcher/options/'.$self->{options} )
		) {
		$file=$ENV{'HOME'}.'/.config/essearcher/options/'.$self->{options};
	} elsif (
			 ( defined( $self->{base} ) ) &&
			 ( -f $self->{base}.'/etc/essearcher/options/'.$self->{options} )
			 ) {
		$file=$self->{base}.'/etc/essearcher/options/'.$self->{options};
	} else {
		# do a quick check of making sure we have a valid name before trying a module...
		# not all valid names are perl module name valid, but it will prevent arbitrary code execution
		if ( $self->name_validate( $self->{options} ) ){
			my $to_eval='use Search::ESsearcher::Templates::'.$self->{options}.
			'; $data=Search::ESsearcher::Templates::'.$self->{options}.'->options;';
			eval( $to_eval );
		}
		# if undefined, it means the eval failed
		if ( ! defined( $data ) ){
			$self->{error}=2;
			$self->{errorString}='No options file or module with the name "'.$self->{options}.'" was found';
			$self->warn;
			return undef;
		}
	}

	if ( defined( $file ) ) {
		my $fh;
		if (! open($fh, '<', $file ) ) {
			$self->{error}=1;
			$self->{errorString}='Failed to open "'.$file.'"',
			$self->warn;
			return undef;
		}
		# if it is larger than 2M bytes, something is wrong as the options
		# it takes is literally longer than all HHGTTG books combined
		if (! read($fh, $data, 200000000 )) {
			$self->{error}=1;
			$self->{errorString}='Failed to read "'.$file.'"',
			$self->warn;
			return undef;
		}
		close($fh);
	}

	# split it appart and remove comments and blank lines
	my @options=split(/\n/,$data);
	@options=grep(!/^#/, @options);
	@options=grep(!/^$/, @options);

	# we have now completed with out error, so save it
	$self->{options_array}=\@options;

	return 1;
}

=head2 load_elastic

This loads the currently specified config file
containing the Elasticsearch config JSON.

    $ess->load_elastic;

=cut

sub load_elastic{
	my $self=$_[0];

	if ( ! $self->errorblank ) {
        return undef;
    }

	my $file=undef;

	# ~/ -> etc -> error
	if (
		( defined( $ENV{'HOME'} ) ) &&
		( -f $ENV{'HOME'}.'/.config/essearcher/elastic/'.$self->{elastic} )
		) {
		$file=$ENV{'HOME'}.'/.config/essearcher/elastic/'.$self->{elastic};
	} elsif (
			 ( defined( $self->{base} ) ) &&
			 ( -f $self->{base}.'/etc/essearcher/elastic/'.$self->{elastic} )
			 ) {
		$file=$self->{base}.'/etc/essearcher/elastic/'.$self->{elastic};
	} else {
		$self->{elastic_hash}={
								nodes => [
										  '127.0.0.1:9200'
										  ]
							   };
	}

	if (defined( $file )) {
		my $fh;
		if (! open($fh, '<', $file ) ) {
			$self->{error}=1;
			$self->{errorString}='Failed to open "'.$file.'"',
			$self->warn;
			return undef;
		}
		my $data;
		# if it is larger than 2M bytes, something is wrong as the template
		# it takes is literally longer than all HHGTTG books combined
		if (! read($fh, $data, 200000000 )) {
			$self->{error}=1;
			$self->{errorString}='Failed to read "'.$file.'"',
			$self->warn;
			return undef;
		}
		close($fh);

		eval {
			my $decoded=$self->{j}->decode( $data );
			$self->{elastic_hash}=$decoded;
		};
		if ( $@ ){
			$self->{error}=5;
			$self->{errorString}=$@;
			$self->warn;
			return undef;
		}

	}

	eval{
		$self->{es}=Search::Elasticsearch->new( $self->{elastic_hash} );
		};
	if ( $@ ){
		$self->{error}=5;
		$self->{errorString}=$@;
		$self->warn;
		return undef;
	}

	return 1;
}

=head2 load_output

This loads the currently specified output template.

While this is save internally, the template is also
returned as a string.

    my $outpot_template=$ess->load_output;

=cut

sub load_output{
	my $self=$_[0];

	if ( ! $self->errorblank ) {
        return undef;
    }

	my $file=undef;
	my $data=undef;

	# ~/ -> etc -> module -> error
	if (
		( defined( $ENV{'HOME'} ) ) &&
		( -f $ENV{'HOME'}.'/.config/essearcher/output/'.$self->{output} )
		) {
		$file=$ENV{'HOME'}.'/.config/essearcher/output/'.$self->{output};
	} elsif (
			 ( defined( $self->{base} ) ) &&
			 ( -f $self->{base}.'/etc/essearcher/output/'.$self->{output} )
			 ) {
		$file=$self->{base}.'/etc/essearcher/outpot/'.$self->{output};
	} else {
		# do a quick check of making sure we have a valid name before trying a module...
		# not all valid names are perl module name valid, but it will prevent arbitrary code execution
		if ( $self->name_validate( $self->{options} ) ) {
			my $to_eval='use Search::ESsearcher::Templates::'.$self->{output}.
			'; $data=Search::ESsearcher::Templates::'.$self->{output}.'->output;';
			eval( $to_eval );
		}
		# if undefined, it means the eval failed
		if ( ! defined( $data ) ) {
			$self->{error}=2;
			$self->{errorString}='No options file with the name "'.$self->{output}.'" was found';
			$self->warn;
			return '';
		}
	}

	if ( ! defined( $data ) ) {
		my $fh;
		if (! open($fh, '<', $file ) ) {
			$self->{error}=1;
			$self->{errorString}='Failed to open "'.$file.'"',
			$self->warn;
			return '';
		}
		# if it is larger than 2M bytes, something is wrong as the template
		# it takes is literally longer than all HHGTTG books combined
		if (! read($fh, $data, 200000000 )) {
			$self->{error}=1;
			$self->{errorString}='Failed to read "'.$file.'"',
			$self->warn;
			return '';
		}
		close($fh);
	}

	# we have now completed with out error, so save it
	$self->{output_template}=$data;

	return $data;
}

=head2 load_search

This loads the currently specified search template.

While this is save internally, the template is also
returned as a string.

    my $search_template=$ess->load_search;

=cut

sub load_search{
	my $self=$_[0];

	if ( ! $self->errorblank ) {
        return undef;
    }

	my $file=undef;
	my $data;

	# ~/ -> etc -> module -> error
	if (
		( defined( $ENV{'HOME'} ) ) &&
		( -f $ENV{'HOME'}.'/.config/essearcher/search/'.$self->{search} )
		) {
		$file=$ENV{'HOME'}.'/.config/essearcher/search/'.$self->{search};
	} elsif (
			 ( defined( $self->{base} ) ) &&
			 ( -f $self->{base}.'/etc/essearcher/search/'.$self->{search} )
			 ) {
		$file=$self->{base}.'/etc/essearcher/search/'.$self->{search};
	} else {
		# do a quick check of making sure we have a valid name before trying a module...
		# not all valid names are perl module name valid, but it will prevent arbitrary code execution
		if ( $self->name_validate( $self->{options} ) ){
			my $to_eval='use Search::ESsearcher::Templates::'.$self->{options}.
			'; $data=Search::ESsearcher::Templates::'.$self->{options}.'->search;';
			eval( $to_eval );
		}
		# if undefined, it means the eval failed
		if ( ! defined( $data ) ){
			$self->{error}=2;
			$self->{errorString}='No template file with the name "'.$self->{search}.'" was found';
			$self->warn;
			return undef;
		}
	}

	if ( ! defined( $data ) ) {
		my $fh;
		if (! open($fh, '<', $file ) ) {
			$self->{error}=1;
			$self->{errorString}='Failed to open "'.$file.'"',
			$self->warn;
			return undef;
		}
		# if it is larger than 2M bytes, something is wrong as the template
		# it takes is literally longer than all HHGTTG books combined
		if (! read($fh, $data, 200000000 )) {
			$self->{error}=1;
			$self->{errorString}='Failed to read "'.$file.'"',
			$self->warn;
			return undef;
		}
		close($fh);
	}

	# we have now completed with out error, so save it
	$self->{search_template}=$data;

	return 1;
}

=head2 name_valide

This validates a config name.

One option is taken and that is the name to valid.

The returned value is a perl boolean based on if it
it is valid or not.

    if ( ! $ess->name_validate( $name ) ){
        print "Name is not valid.\n";
    }

=cut

sub name_validate{
	my $self=$_[0];
	my $name=$_[1];

	if ( ! $self->errorblank ) {
        return undef;
    }

	if (! defined( $name ) ){
		return 1;
	}

	$name=~s/[A-Z0-9a-z\:\-\=\_+\ ]+//;

	if ( $name !~ /^$/ ){
		return undef;
	}

	return 1;
}

=head options_get

This returns the currently set options
config name.

    my $options=$ess->options_get;

=cut

sub options_get{
	my $self=$_[0];

	if ( ! $self->errorblank ) {
        return undef;
    }

	return $self->{options};
}

=head options_set

This sets the options config name to use.

One option is taken and this is the config name.
If it is undefiend, then the default is used.

    $ess->options_set( $name );

=cut

sub options_set{
	my $self=$_[0];
	my $name=$_[1];

	if ( ! $self->errorblank ) {
        return undef;
    }

	if (! $self->name_validate( $name ) ){
		$self->{error}=3;
		$self->{errorString}='"'.$name.'" is not a valid name';
		$self->warn;
		return undef;
	}

	if( !defined( $name ) ){
		$name='syslog';
	}

	$self->{options}=$name;

	return 1;
}

=head output_get

This returns the currently set output
template name.

    my $output=$ess->output_get;

=cut

sub output_get{
	my $self=$_[0];
	my $name=$_[1];

	if ( ! $self->errorblank ) {
        return undef;
    }

	return $self->{output};
}

=head output_set


This sets the output template name to use.

One option is taken and this is the template name.
If it is undefiend, then the default is used.

    $ess->output_set( $name );

=cut

sub output_set{
	my $self=$_[0];
	my $name=$_[1];

	if ( ! $self->errorblank ) {
        return undef;
    }

	if (! $self->name_validate( $name ) ){
		$self->{error}=3;
		$self->{errorString}='"'.$name.'" is not a valid name';
		$self->warn;
		return undef;
	}

	if( !defined( $name ) ){
		$name='syslog';
	}

	$self->{output}=$name;

	return 1;
}

=head2 results_process

This processes the results from search_run.

One option is taken and that is the return from search_run.

The returned value from this is array of each document found
after it has been formated using the set output template.

    my $results=$ess->search_run;
    my @formated=$ess->results_process( $results );
    @formated=reverse(@formated);
    print join("\n", @formated)."\n";

=cut

sub results_process{
	my $self=$_[0];
	my $results=$_[1];

	if ( ! $self->errorblank ) {
        return undef;
    }

	#make sure we have a sane object passed to us
	if (
		( ref( $results ) ne 'HASH' ) ||
		( !defined( $results->{hits} ) )||
		( !defined( $results->{hits}{hits} ) )
		){
		$self->{error}=6;
		$self->{errorString}='The passed results variable does not a appear to be a search results return';
		$self->warn;
		return undef;
	}

	#use Data::Dumper;
	#print Dumper( $results->{hits}{hits} );

	my $vars={
			  o=>$self->{parsed_options},
			  r=>$results,
			  c=>sub{ return color( $_[0] ); },
			  pd=>sub{
				  if( $_[0] =~ /^raw\:/ ){
					  $_[0] =~ s/^raw\://;
					  return $_[0];
				  }
				  $_[0]=~s/m$/minutes/;
				  $_[0]=~s/M$/months/;
				  $_[0]=~s/d$/days/;
				  $_[0]=~s/h$/hours/;
				  $_[0]=~s/h$/weeks/;
				  $_[0]=~s/y$/years/;
				  $_[0]=~s/([0123456789])$/$1seconds/;
				  $_[0]=~s/([0123456789])s$/$1seconds/;
				  my $secs="";
				  eval{ $secs=parsedate( $_[0] ); };
				  return $secs;
			  },
			  };

	my @formatted;
	foreach my $doc ( @{ $results->{hits}{hits} } ){
		$vars->{doc}=$doc;
		$vars->{f}=$doc->{_source};

		my $processed;
		$self->{t}->process( \$self->{output_template}, $vars , \$processed );
		chomp($processed);

		push(@formatted,$processed);
	}

	@formatted=reverse(@formatted);

	return @formatted;
}

=head search_get

This returns the currently set search
template name.

    my $search=$ess->search_get;


=cut

sub search_get{
	my $self=$_[0];
	my $name=$_[1];

	if ( ! $self->errorblank ) {
        return undef;
    }

	return $self->{search};
}

=head2 search_fill_in

This fills in the loaded search template.

The results are saved internally as well as returned.

    my $filled_in=$ess->search_fill_in;

=cut

sub search_fill_in{
	my $self=$_[0];
	my $name=$_[1];

	if ( ! $self->errorblank ) {
        return undef;
    }

	my $vars={
			  o=>$self->{parsed_options},
			  aon=>sub{
				  $_[0]=~s/\+/\ AND\ /;
				  $_[0]=~s/\,/\ OR\ /;
				  $_[0]=~s/\!/\ NOT\ /;
				  return $_[0];
			  },
			  pd=>sub{
				  if( $_[0] =~ /^u\:/ ){
					  $_[0] =~ s/^u\://;
					  $_[0]=~s/m$/minutes/;
					  $_[0]=~s/M$/months/;
					  $_[0]=~s/d$/days/;
					  $_[0]=~s/h$/hours/;
					  $_[0]=~s/h$/weeks/;
					  $_[0]=~s/y$/years/;
					  $_[0]=~s/([0123456789])$/$1seconds/;
					  $_[0]=~s/([0123456789])s$/$1seconds/;
					  my $secs="";
					  eval{ $secs=parsedate( $_[0] ); };
					  return $secs;
				  }elsif( $_[0] =~ /^\-/ ){
					  return 'now'.$_[0];
				  }
				  return $_[0];
			  },
			  };

	my $processed;
	$self->{t}->process( \$self->{search_template}, $vars , \$processed );

	$self->{search_filled_in}=$processed;

	$self->{search_usable}=undef;

	eval {
		my $decoded=$self->{j}->decode( $processed );
		$self->{search_hash}=$decoded;
		 };
	if ( $@ ){
		$self->{error}=4;
		$self->{errorString}='The returned filled in search template does not parse as JSON... '.$@;
		$self->warn;
		return $processed;
	}

	return $processed;
}

=head2 search_run

This is used to run the search after search_fill_in
has been called.

The returned value is of the type that would be returned
by L<Search::Elasticsearch>->search.

    my $results=$ess->search_run;

=cut

sub search_run{
	my $self=$_[0];
	my $name=$_[1];

	if ( ! $self->errorblank ) {
        return undef;
    }

	my $results;
	eval{
		$results=$self->{es}->search( $self->{search_hash} );
	};

	return $results;
}

=head search_set

This sets the search template name to use.

One option is taken and this is the template name.
If it is undefiend, then the default is used.

    $ess->search_sets( $name );

=cut

sub search_set{
	my $self=$_[0];
	my $name=$_[1];

	if ( ! $self->errorblank ) {
        return undef;
    }

	if (! $self->name_validate( $name ) ){
		$self->{error}=3;
		$self->{errorString}='"'.$name.'" is not a valid name';
		$self->warn;
		return undef;
	}

	if( !defined( $name ) ){
		$name='syslog';
	}

	$self->{search}=$name;

	return 1;
}

=head1 Configuration And Usage

Configs, help, and templates are looked for in the following manner and order,
with the following of the elasticsearch config.

   $ENV{HOME}."/.config/essearcher/".$item."/".$name
   $base.'/etc/essearcher/".$item."/".$name
   Search::ESsearcher::Templates::$name->$item
   ERROR

Item can be any of the following.

    elastic
    help
    output
    options
    search

The basic idea is you have matching output, options
and search that you can use to perform queries and
print the results.

Each template/config is its own file under the directory
named after its purpose. So the options template fail2ban
would be 'options/fail2ban'.

=head2 elastic

This directory contains JSON formatted config files
for use with connecting to the Elasticsearch server.

This is then read in and converted to a hash and feed
to L<Search::Elasticsearch>->new.

By default it will attempt to connect to it on
"127.0.0.1:9200". The JSON equivalent would be...

    { "nodes": [ "127.0.0.1:9200" ] }

=head2 options

This is a file that will be used as a string for with
L<Getopt::Long>. They will be passed to the templates
as a hash.

=head2 help

This contains information on the options the search uses.

This is just a text file containing information and is not
required.

If you are writing a module, it should definitely be present.

=head2 search

This is a L<Template> template that will be filled in using
the data from the passed command line options and used
to run the search.

The end result should be valid JSON that can be turned
into a hash for feeding L<Search::Elasticsearch>->search.

When writing search templates, it is highly suggested
to use L<Template::Plugin::JSON> for when inserting variables
as it will automatically escape them.

=head2 output

This is a L<Template> template that will be filled in using
the data from the passed command line options and the returned
results.

It will be used for each returned document. bin/essearcher will
then join the array with "\n".

=head1 TEMPLATES

=head2 o

This is a hash that contains the parsed options.

Below is a example with the option --program and
transforming it a JSON save value.

    [% USE JSON ( pretty => 1 ) %]
    [% DEFAULT o.program = "*" %]
    
    {"query_string": {
        "default_field": "program",
        "query": [% o.program.json %]
        }
    },

=head2 aon

This is AND, OR, or NOT sub that handles
the following in a string, transforming them
from the punctuation to the logic.

    , OR
    + AND
    ! NOT

So the string "postfix,spamd" would become
"postfix OR spamd".

Can be used like below.

    [% USE JSON ( pretty => 1 ) %]
    [% DEFAULT o.program = "*" %]
    
    {"query_string": {
        "default_field": "program",
        "query": [% aon( o.program ).json %]
        }
    },

This function is only available for the search template.

=head2 c

This wraps L<Term::ANSIColor>->color.

    [% c("cyan") %][% f.timestamp %] [% c("bright_blue") %][% f.logsource %]

This function is only available for the output template.

=head2 pd

This is a time helper.

/^-/ appends "now" to it. So "-5m" becomes "now-5m".

/^u\:/ takes what is after ":" and uses Time::ParseDate to convert
it to a unix time value.

Any thing not matching maching any of the above will just be passed on.

    [% IF o.dgt %]
        {"range": {
            "@timestamp": {
                "gt": [% pd( o.dgt ).json %]
            }
        }
        },
    [% END %]


=head1 Modules

Additonal modules bundling help, options, search, and output
can be made. The requirement for these are as below.

They need to exist below Search::ESsearcher::Templates.

Provide the following functions that return strings.

    help
    options
    search
    output

Basic information as to what is required to make it work in logstash
or the like is also good as well.

=head1 ERROR CODES/FLAGS

All error handling is done via L<Error::Helper>.

=head2 1 / IOerror

Failed to perform some sort of file operation.

=head2 2 / NOfile

The specified template/config does not exist.

=head2 3 / nameIsInvalid

Invalid name specified.

=head2 4 / searchNotUsable

Errored while processing the template.

For more information on writing templates, see L<Template>.

=head2 5 / elasticnotloadable

The Elasticsearch config does not parse as JSON, preventing
it from being loaded.

=head2 6 / notResults

The return value passed to results_process deos not appear to
be a results return. Most likely the search errored and returned
undef or a blank value.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-essearcher at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-ESsearcher>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::ESsearcher


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-ESsearcher>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-ESsearcher>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Search-ESsearcher>

=item * Search CPAN

L<https://metacpan.org/release/Search-ESsearcher>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;								# End of Search::ESsearcher
