#!/usr/bin/perl

use lib '../lib' ;
use lib 'lib' ;

use warnings ;
use strict ;

use Data::Dumper ;

use Getopt::Long ;
use File::Slurp ;
use Benchmark qw(:hireswallclock cmpthese);

my $opts = parse_options() ;

my $template_info = [
	{
		name	=> 'basic',
		data	=> {
			name	=> 'bob',
		},
		expected => 'hehe bob',
		simple	=> 'hehe [% name %]',
		toolkit	=> 'hehe [% name %]',
		teeny	=> 'hehe [% name %]',
		tiny	=> 'hehe [% name %]',
	},
	{
		name	=> 'nested',
		data	=> {
			title	=> 'Bobs Blog',
			posts	=> [
				{
					title	=> 'hehe',
					date	=> 'Today'
				},
				{
					title	=> 'Something new',
					date	=> '3 Days ago',
				},
			],
		},
		expected => <<EXPECTED,
<html>
  <head><title>Bobs Blog</title></head>
  <body>
    <ul>
        <li>
            <h3>hehe</h3>
            <span>Today</span>
        </li>
        <li>
            <h3>Something new</h3>
            <span>3 Days ago</span>
        </li>
    </ul>
  </body>
</html>
EXPECTED

		simple	=> <<SIMPLE,
<html>
  <head><title>[% title %]</title></head>
  <body>
    <ul>[% START posts %]
        <li>
            <h3>[% title %]</h3>
            <span>[% date %]</span>
        </li>[% END posts %]
    </ul>
  </body>
</html>
SIMPLE

		toolkit	=> <<TOOLKIT,
<html>
  <head><title>[% title %]</title></head>
  <body>
    <ul>[% FOREACH post = posts %]
        <li>
            <h3>[% post.title %]</h3>
            <span>[% post.date %]</span>
        </li>[% END %]
    </ul>
  </body>
</html>
TOOLKIT

		tiny	=> <<TINY,
<html>
  <head><title>[% title %]</title></head>
  <body>
    <ul>[% FOREACH post IN posts %]
        <li>
            <h3>[% post.title %]</h3>
            <span>[% post.date %]</span>
        </li>[% END %]
    </ul>
  </body>
</html>
TINY

		teeny	=> <<TEENY,
<html>
  <head><title>[% title %]</title></head>
  <body>
    <ul>[% SECTION post %]
        <li>
            <h3>[% title %]</h3>
            <span>[% date %]</span>
        </li>[% END %]
    </ul>
  </body>
</html>

TEENY
	},
] ;

my $benches = [
	{
		name	=> 'T::S',
		template_key => 'simple',
		load	=> sub {
			return eval { require Template::Simple } ;
		},
		setup	=> sub {
			my( $bench, $info ) = @_ ;

			my $template = $info->{$bench->{template_key}} ;
			my $data = $info->{data} ;
			my $name = $info->{name} ;

			my $obj = Template::Simple->new(
				templates => { $name => $template }
			) ;

			$bench->{render} =
				sub { $obj->render( $name, $data ) } ;
		},
		verify	=> sub {
			my( $bench, $info ) = @_ ;
			my $result = $bench->{render}->() ;
			$bench->{result} = ${$result} ;
		},
	},
	{
		name	=> 'T::S compiled',
		template_key => 'simple',
		load	=> sub {
			return eval { require Template::Simple } ;
		},
		setup	=> sub {
			my( $bench, $info ) = @_ ;

			my $template = $info->{$bench->{template_key}} ;
			my $data = $info->{data} ;
			my $name = $info->{name} ;

			my $obj = Template::Simple->new(
				templates => { $name => $template }
			) ;
			$obj->compile( $name ) ;

			$bench->{render} =
				sub { $obj->render( $name, $data ) } ;
		},
		verify	=> sub {
			my( $bench, $info ) = @_ ;
			my $result = $bench->{render}->() ;
			$bench->{result} = ${$result} ;
		},
	},
	{
		name	=> 'Teeny',
		template_key => 'teeny',
		load	=> sub {
			return eval {
				require Template::Teeny ;
				require Template::Teeny::Stash ;
			} ;
		},
		setup	=> sub {
			my( $bench, $info ) = @_ ;

			my $template = $info->{$bench->{template_key}} ;
			my $data = $info->{data} ;
			my $name = $info->{name} ;

			my $results ;
#			open my $fh, '>', \$results or
#			open my $fh, '>', '/dev/null' or
#				die "can't open string for output" ;

			mkdir 'tpl' ;
			write_file( "tpl/$name.tpl", $template ) ;
			my $obj = Template::Teeny->new(
				{ include_path => ['tpl'] }
			) ;

			my $stash ;
			if ( my $posts = $data->{posts} ) {
			
				$stash = Template::Teeny::Stash->new(
					{ title => $data->{title} }
				) ;

				foreach my $post ( @{$posts} ) {

					my $substash =
						Template::Teeny::Stash->new(
							$post
					) ;
					$stash->add_section('post', $substash );
				}
			}
			else {
				$stash = Template::Teeny::Stash->new(
					$data
				) ;

			}

#print Dumper $stash ;
			$bench->{render} =
				sub { $obj->process("$name.tpl", $stash ); }

		},
		verify	=> sub {
			my( $bench, $info ) = @_ ;
			$bench->{result} = $bench->{render}->() ;
		},
	},
	{
		name	=> 'toolkit',
		template_key => 'toolkit',
		load	=> sub { return eval { require Template } ; },
		setup	=> sub {
			my( $bench, $info ) = @_ ;

			my $template = $info->{$bench->{template_key}} ;
			my $data = $info->{data} ;

			my $obj = Template->new() ;

			$bench->{render} = sub {
				my $output ;
				$obj->process(\$template, $data, \$output );
				return $output ;
			},

		},
		verify	=> sub {
			my( $bench, $info ) = @_ ;
			$bench->{result} = $bench->{render}->() ;
		},
	},
	{
		name	=> 'tiny',
		template_key => 'tiny',
		load	=> sub { return eval { require Template::Tiny } ; },
		setup	=> sub {
			my( $bench, $info ) = @_ ;

			my $template = $info->{$bench->{template_key}} ;
			my $data = $info->{data} ;

			my $obj = Template::Tiny->new() ;

			$bench->{render} = sub {
				my $output ;
				$obj->process( \$template, $data, \$output );
				return $output ;
			},
		},
		verify	=> sub {
			my( $bench, $info ) = @_ ;
			$bench->{result} = $bench->{render}->() ;
		},
	},
] ;

run_benchmarks() ;

sub run_benchmarks {

	foreach my $info ( @{$template_info} ) {

		my %compares ;

		foreach my $bench ( @{$benches} ) {

			my $loaded = $bench->{load}->() ;
			unless( $loaded ) {
				print <<BAD ;
Skipping $bench->{name} as it didn't load
BAD
				next ;
			}

			$bench->{setup}->( $bench, $info ) ;

			if ( $opts->{verify} ) {
				$bench->{verify}->( $bench, $info ) ;

				if ( $bench->{result} ne $info->{expected} ) {

					print <<BAD ;
Skipping $bench->{name} as it doesn't have verified results.
RESULT [$bench->{result}]\nEXPECTED [$info->{expected}]
BAD
					next ;
				}
				else {
					print <<GOOD ;
'$bench->{name}' rendering of '$info->{name}' is verified
GOOD
				}
			}

			$compares{ $bench->{name} } = $bench->{render} ;
		}

		print "\nBenchmark of '$info->{name}' template\n" ;
		cmpthese( $opts->{iterations}, \%compares ) ;
		print "\n" ;
	}
}

sub parse_options {

	GetOptions( \my %opts,
		'verify|v',
		'iterations|i',
		'templaters|t',
		'help|?',
	) ;

	usage( '' ) if $opts{ 'help' } ;

	$opts{iterations} ||= -2 ;

	$opts{templaters} = [split /,/, $opts{templaters}]
		if $opts{templaters} ;

	return \%opts ;
}

sub usage {

	my $err_msg = shift || '' ;

	my $usage = <<'=cut' ;

bench_templates.pl - Benchmark Multiple Templaters

=head1 SYNOPSIS

load_menus.pl [--verify | -v] [--iterations | -i <iter>]
	[--templaters| -t <templaters>] [--help]

=head1 DESCRIPTION

	--verify | -v			Verify rendered output is correct
	--iterations | -i <iter>	Iteration count passed to cmpthese
					Default is -2 (seconds of cpu time)
	--templaters | -t <templaters>	Comma separated list of templaters
					to run in this benchmark

	[--help | ?]			Print this help text

=cut

	$usage =~ s/^=\w+.*$//mg ;

	$usage =~ s/\n{2,}/\n\n/g ;
	$usage =~ s/\A\n+// ;

	die "$err_msg\n$usage" ;
}
