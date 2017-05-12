package TAP::Parser::SourceHandler::Validator::W3C::HTML;
{
  $TAP::Parser::SourceHandler::Validator::W3C::HTML::VERSION = '0.02';
}

use warnings;
use strict;

# ABSTRACT: TAP source handler for validating HTML via W3C validator

use LWP::UserAgent;
use Test::Builder;
use URI;
use TAP::Parser::IteratorFactory;
use WebService::Validator::HTML::W3C;
use WWW::Robot;

use base 'TAP::Parser::SourceHandler';

TAP::Parser::IteratorFactory->register_handler(__PACKAGE__);

use constant VALIDATOR => 'http://validator.w3.org/check';

# options and their defaults
my $crawl			= $ENV{TEST_W3C_HTML_CRAWL}			|| 0;
my $validator_uri	= $ENV{TEST_W3C_HTML_VALIDATOR_URI}	|| VALIDATOR;
my $timeout			= $ENV{TEST_W3C_HTML_TIMEOUT}		|| 5;
my $use_children	= $ENV{TEST_W3C_HTML_CHILDREN}		|| 0;

# given a type of test, attempt to parse it and let TAP::Harness know
# that we can handle it if it is a valid HTTP URI.

sub can_handle
{
	my $self	= shift;
	my $source	= shift;

	my $meta = $source->meta;

	return 0 unless $meta->{is_scalar};

	# If the extension is htm or html, there's no reason to believe
	# the content is not markup.  If the first line contains the text
	# "html", it could be markup.  If it's any other file, we don't
	# know what to do with it.

	if ($meta->{is_file}) {
		my $file	= $meta->{file};

		return 0.9 if $file->{lc_ext} =~ /^\.html?$/;
		return 0.5 if $file->{shebang} =~ /html/i;
		return 0;
	}

	# If it's not a file, try to parse it as a URI.  If it's a valid
	# URI, we'll accept the burden of handling it.

	my $name	= ${ $source->raw };
	my $uri		= new URI ${ $source->raw };

	return 1 if $uri->isa('URI::http');

	return 0;
}

sub make_iterator
{
	my $self	= shift;
	my $source	= shift;

	# TODO: Asynchronous validation with forking iterator...

	my $tap		= $self->_check_source($source);
	my $iter	= new TAP::Parser::Iterator::Array [ split /\n+/, $tap ];

	return $iter;
}

sub _check_source
{
	my $self	= shift;
	my $source	= shift;

	my $meta	= $source->meta;
	my $raw		= ${ $source->raw };
	my $builder	= Test::Builder->create;
	my $buffer	= '';
	my $trash	= '';

	$builder->output(\$buffer);
	$builder->failure_output(\$trash);

	if ($meta->{is_file}) {
		$self->_check_file($builder, $raw)
	} else {
		$self->_check_uri($builder, new URI ${ $source->raw });
	}

	$builder->done_testing;

	return $buffer;
}

sub _check_file
{
	my $self = shift;
	my $test = shift;
	my $file = shift;

	my $io = new IO::File;

	$io->open($file)
		or $self->_croak("error opening HTML source file '$file': $!");

	$self->_check_content($test, $file, join '', $io->getlines);
}

sub _check_uri
{
	my $self	= shift;
	my $builder	= shift;
	my $root	= shift;

	# Setup the user agent.

	my $ua = new LWP::UserAgent;

	$ua->timeout($timeout);

	# Setup the spider, using any attributes from the environment.  I'm
	# not a huge fan of passing stuff in from the environment, but it's
	# the way things are typically done inside of test harnesses...

	my $spider	= new WWW::Robot USERAGENT => $ua;
	my $spattrs	= { map { /^TEST_W3C_HTML_SPIDER_(.*)/ ? ($1 => $ENV{$_}) : () } keys %ENV };

	$spattrs->{NAME}	||= __PACKAGE__;		# default
	$spattrs->{VERSION}	||= '1.0';				# default
	$spattrs->{EMAIL}	||= 'root@localhost';	# default

	$spider->setAttribute($_ => $spattrs->{$_}) foreach keys %$spattrs;

	# Setup the required hooks.  I planned on using the invoke-after-get
	# hook, but the absence of an invoke-on-* handler makes WWW::Robot
	# croak.  So, we'll just use the same damn handler for both content
	# and error...

	$spider->addHook('follow-url-test'		=> sub { $self->_spider_follow_url_test($root, @_) });
	$spider->addHook('invoke-on-contents'	=> sub { $self->_spider_handle_response($builder, @_) });
	$spider->addHook('invoke-on-get-error'	=> sub { $self->_spider_handle_response($builder, @_) });

	# DO EET

	$spider->run($root);
}

sub _spider_follow_url_test
{
	my $self	= shift;
	my $root	= shift;
	my $robot	= shift;
	my $hook	= shift;
	my $uri		= shift;

	return 1 if $uri eq $root;

	my $rel = $uri->rel($root);

	return 0 if not $crawl;
	return 0 if $rel->scheme;
	return 0 if $rel =~ /^\./;
	return 1;
}

sub _spider_handle_response
{
	my $self	= shift;
	my $builder	= shift;
	my $robot	= shift;
	my $hook	= shift;
	my $uri		= shift;
	my $res		= shift;

	# XXX: We probably need to deal with redirects...

	my $test = $use_children ? $builder->child($uri) : $builder;

	$test->plan('no_plan') if $use_children;

	$test->ok($res->is_success, "fetch content for $uri");

	$test->note('ERROR: ' . $res->status_line)			if $res->is_error;
	$self->_check_content($test, $uri, $res->content)	if $res->is_success;

	$test->finalize if $use_children;
}

sub _check_content
{
	my $self	= shift;
	my $test	= shift;
	my $source	= shift;
	my $content	= shift;

	my $validator = new WebService::Validator::HTML::W3C
		validator_uri	=> $validator_uri,
		detailed		=> 1;

	my $checked = $validator->validate(string => $content);

	$test->note('ERROR: ' . $validator->validator_error)
		if not $checked;

	$test->ok($checked, "validate content from $source");
	$test->ok($checked && $validator->is_valid, "markup is valid for $source");

	my $errors = $checked ? $validator->errors : [];

	$test->ok(0, sprintf "L%d:C%d %s", $_->line, $_->col, $_->msg)
		foreach @$errors;

	return $checked;
}

1;

__END__

=head1 NAME

TAP::Parser::SourceHandler::Validator::W3C::HTML - validate HTML content

=head1 SYNOPSIS

 $ prove --source Validator::W3C::HTML http://example.com/some/page.html /path/to/some/file.html

=head1 DESCRIPTION

Unit testing is awesome.  L<App::Prove> is awesome.  HTML validation is
awesome.  Thus, the Validator::W3C::HTML SourceHandler was born.

This SourceHandler provides L<TAP::Harness> with TAP output generated as
the result of HTML validation via the W3C validator.  Both remote URIs
and local HTML files are supported depending upon the type of source
passed to the harness.

If the source is a file with a .html or .htm extension or a file which
contains text matching /html/i in the first line, then the source will
be handled by this SourceHandler as raw HTML content.

If the source is an HTTP or HTTPS URI, the source will be handled by
this SourceHandler via <WWW::Robot>.  When operating in URI mode, a few
extra options are available.  See below for configuration.

=head1 CONFIGURATION

Configuration is done via the environment as is pretty common with perl
testing.  The supported configuration options are as follows:

=over 4

=item TEST_W3C_HTML_CRAWL (default: no)

When in URI mode, crawl the site and recursively test all URIs below the
hierarchy of the root URI.

=item TEST_W3C_HTML_VALIDATOR_URI (default: http://validator.w3.org/check)

The location of the W3C validator instance you wish to use.  Please do
not use the default if you're going to be using the validator for any
volume.

=item TEST_W3C_HTML_TIMEOUT (default: 5)

The timeout for the L<LWP::UserAgent> instance used by L<WWW::Robot>.

=item TEST_W3C_HTML_CHILDREN (default: no)

When recursively crawling a site, use a L<Test::Builder> child for each
URI.  This indents the TAP output for each URI, but can be less readable
when using non-TAP formatters such as JUnit.

=back

Any environment variables beginning with B<TEST_W3C_HTML_SPIDER_> will
be interpreted as attributes to be passed on to the WWW::Robot instance
after stripping the leading portion.

=head1 CAVEATS

This is my first experience with L<TAP::Harness>.  TAP::Harness is quite
abstract and I am probably abusing it horribly.  Please let me know if
you have any suggestions for improvement.

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013 by Infinity Interactive, Inc.

http://www.iinteractive.com

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
