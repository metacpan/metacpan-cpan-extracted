=head1 NAME

TAP::Formatter::HTML - TAP Test Harness output delegate for html output

=head1 SYNOPSIS

 ##
 ## command-line usage (alpha):
 ##
 prove -m -Q -P HTML=outfile:out.html,css_uri:style.css,js_uri:foo.js,force_inline_css:0

 # backwards compat usage:
 prove -m -Q --formatter=TAP::Formatter::HTML >output.html

 # for more detail:
 perldoc App::Prove::Plugin::HTML

 ##
 ## perl usage:
 ##
 use TAP::Harness;

 my @tests = glob( 't/*.t' );
 my $harness = TAP::Harness->new({ formatter_class => 'TAP::Formatter::HTML',
                                   merge => 1 });
 $harness->runtests( @tests );
 # prints HTML to STDOUT by default

 # or if you really don't want STDERR merged in:
 my $harness = TAP::Harness->new({ formatter_class => 'TAP::Formatter::HTML' });

 # to use a custom formatter:
 my $fmt = TAP::Formatter::HTML->new;
 $fmt->css_uris([])->inline_css( $my_css )
     ->js_uris(['http://mysite.com/jquery.js', 'http://mysite.com/custom.js'])
     ->inline_js( '$(div.summary).hide()' );

 my $harness = TAP::Harness->new({ formatter => $fmt, merge => 1 });

 # to output HTML to a file[handle]:
 $fmt->output_fh( $fh );
 $fmt->output_file( '/tmp/foo.html' );

 # you can use your own customized templates too:
 $fmt->template('custom.tt2')
     ->template_processor( Template->new )
     ->force_inline_css(0)
     ->force_inline_js(0);

=cut

package TAP::Formatter::HTML;

use strict;
use warnings;

use URI;
use URI::file;
use Template;
use POSIX qw( ceil );
use IO::File;
use File::Temp qw( tempfile tempdir );
use File::Spec::Functions qw( catdir catfile file_name_is_absolute rel2abs );

use TAP::Formatter::HTML::Session;

# DEBUG:
#use Data::Dumper 'Dumper';

use base qw( TAP::Base );
use accessors qw( verbosity stdout output_fh escape_output tests session_class sessions
		  template_processor template html html_id_iterator minify color
		  css_uris js_uris inline_css inline_js abs_file_paths force_inline_css force_inline_js );

use constant default_session_class => 'TAP::Formatter::HTML::Session';
use constant default_template      => 'TAP/Formatter/HTML/default_report.tt2';
use constant default_js_uris       => ['file:TAP/Formatter/HTML/jquery-1.4.2.min.js',
				       'file:TAP/Formatter/HTML/jquery.tablesorter-2.0.3.min.js',
				       'file:TAP/Formatter/HTML/default_report.js'];
use constant default_css_uris      => ['file:TAP/Formatter/HTML/default_page.css',
				       'file:TAP/Formatter/HTML/default_report.css'];

use constant severity_map => {
			      ''          => 0,
			      'very-low'  => 1,
			      'low'       => 2,
			      'med'       => 3,
			      'high'      => 4,
			      'very-high' => 5,
			      0 => '',
			      1 => 'very-low',
			      2 => 'low',
			      3 => 'med',
			      4 => 'high',
			      5 => 'very-high',
			     };

our $VERSION = '0.13';
our $FAKE_WIN32_URIS = 0; # for testing only

sub _initialize {
    my ($self, $args) = @_;

    $args ||= {};
    $self->SUPER::_initialize($args);

    my $stdout_fh = IO::File->new_from_fd( fileno(STDOUT), 'w' )
      or die "Error opening STDOUT for writing: $!";

    $self->verbosity( 0 )
         ->stdout( $stdout_fh )
         ->output_fh( $stdout_fh )
	 ->minify( 1 )
	 ->escape_output( 0 )
         ->abs_file_paths( 1 )
         ->abs_file_paths( 1 )
         ->force_inline_css( 1 )
         ->force_inline_js( 0 )
         ->session_class( $self->default_session_class )
         ->template_processor( $self->default_template_processor )
         ->template( $self->default_template )
         ->js_uris( $self->default_js_uris )
         ->css_uris( $self->default_css_uris )
         ->inline_js( '' )
	 ->inline_css( '' )
	 ->sessions( [] );

    $self->check_for_overrides_in_env;

    # Laziness...
    # trust the user knows what they're doing with the args:
    foreach my $key (keys %$args) {
	$self->$key( $args->{$key} ) if ($self->can( $key ));
    }

    $self->html_id_iterator( $self->create_iterator( $args ) );

    return $self;
}

sub check_for_overrides_in_env {
    my $self = shift;

    if (my $file = $ENV{TAP_FORMATTER_HTML_OUTFILE}) {
	$self->output_file( $file );
    }

    my $force_css = $ENV{TAP_FORMATTER_HTML_FORCE_INLINE_CSS};
    if (defined( $force_css )) {
	$self->force_inline_css( $force_css );
    }

    my $force_js = $ENV{TAP_FORMATTER_HTML_FORCE_INLINE_JS};
    if (defined( $force_js )) {
	$self->force_inline_js( $force_js );
    }

    if (my $uris = $ENV{TAP_FORMATTER_HTML_CSS_URIS}) {
	my $list = [ split( ':', $uris ) ];
	$self->css_uris( $list );
    }

    if (my $uris = $ENV{TAP_FORMATTER_HTML_JS_URIS}) {
	my $list = [ split( ':', $uris ) ];
	$self->js_uris( $list );
    }

    if (my $file = $ENV{TAP_FORMATTER_HTML_TEMPLATE}) {
	$self->template( $file );
    }

    return $self;
}

sub default_template_processor {
    my $path = __FILE__;
    $path =~ s/.TAP.Formatter.HTML.pm$//;
    return Template->new(
        # arguably shouldn't compile as this is only used once
        COMPILE_DIR  => catdir( tempdir( CLEANUP => 1 ), 'TAP-Formatter-HTML' ),
        COMPILE_EXT  => '.ttc',
        INCLUDE_PATH => $path,
    );
}


sub output_file {
    my ($self, $file) = @_;
    my $fh = IO::File->new( $file, 'w' )
      or die "Error opening '$file' for writing: $!";
    $self->output_fh( $fh );
}

sub create_iterator {
    my $self = shift;
    my $args = shift || {};
    my $prefix = $args->{html_id_prefix} || 't';
    my $i = 0;
    my $iter = sub { return $prefix . $i++ };
}

sub verbose {
    my $self = shift;
    # emulate a classic accessor for compat w/TAP::Formatter::Console:
    if (@_) { $self->verbosity(1) }
    return $self->verbosity >= 1;
}

sub quiet {
    my $self = shift;
    # emulate a classic accessor for compat w/TAP::Formatter::Console:
    if (@_) { $self->verbosity(-1) }
    return $self->verbosity <= -1;
}

sub really_quiet {
    my $self = shift;
    # emulate a classic accessor for compat w/TAP::Formatter::Console:
    if (@_) { $self->verbosity(-2) }
    return $self->verbosity <= -2;
}

sub silent {
    my $self = shift;
    # emulate a classic accessor for compat w/TAP::Formatter::Console:
    if (@_) { $self->verbosity(-3) }
    return $self->verbosity <= -3;
}

# Called by Test::Harness before any test output is generated.
sub prepare {
    my ($self, @tests) = @_;
    # warn ref($self) . "->prepare called with args:\n" . Dumper( \@tests );
    $self->info( 'running ', scalar @tests, ' tests' );
    $self->tests( [@tests] );
}

# Called to create a new test session. A test session looks like this:
#
#    my $session = $formatter->open_test( $test, $parser );
#    while ( defined( my $result = $parser->next ) ) {
#        $session->result($result);
#        exit 1 if $result->is_bailout;
#    }
#    $session->close_test;
sub open_test {
    my ($self, $test, $parser) = @_;
    #warn ref($self) . "->open_test called with args: " . Dumper( [$test, $parser] );
    my $session = $self->session_class->new({ test => $test,
					      parser => $parser,
					      formatter => $self });
    push @{ $self->sessions }, $session;
    return $session;
}

# $str = $harness->summary( $aggregate );
#
# C<summary> produces the summary report after all tests are run.  The argument is
# an aggregate.
sub summary {
    my ($self, $aggregate) = @_;
    #warn ref($self) . "->summary called with args: " . Dumper( [$aggregate] );

    # farmed out to make sub-classing easy:
    my $report = $self->prepare_report( $aggregate );
    $self->generate_report( $report );

    # if silent is set, only print HTML if we're not printing to stdout
    if (! $self->silent or $self->output_fh->fileno != fileno(STDOUT)) {
	print { $self->output_fh } ${ $self->html };
	$self->output_fh->flush;
    }

    return $self;
}

sub generate_report {
    my ($self, $r) = @_;

    $self->check_uris;
    if($self->force_inline_css) {
        $self->slurp_css;
        $self->css_uris([]);
    }
    if($self->force_inline_js) {
        $self->slurp_js;
        $self->js_uris([]);
    }

    my $params = {
		  report => $r,
		  js_uris  => $self->js_uris,
		  css_uris => $self->css_uris,
		  inline_js  => $self->inline_js,
		  inline_css => $self->inline_css,
		  formatter => { class => ref( $self ),
				 version => $self->VERSION },
		 };

    my $html = '';
    $self->template_processor->process( $self->template, $params, \$html )
      || die $self->template_processor->error;

    $self->html( \$html );
    $self->minify_report if $self->minify;

    return $self;
}

# try and reduce the size of the report
sub minify_report {
    my $self = shift;
    my $html_ref = $self->html;
    $$html_ref =~ s/^\t+//mg;
    return $self;
}

# convert all uris to URI objs
# check file uris (if relative & not found, try & find them in @INC)
sub check_uris {
    my ($self) = @_;

    foreach my $uri_list ($self->js_uris, $self->css_uris) {
	# take them out of the list to verify, push them back on later
	my @uris = splice( @$uri_list, 0, scalar @$uri_list );
	foreach my $uri (@uris) {
	    if (($^O =~ /win32/i or $FAKE_WIN32_URIS)
		and $uri =~ /^(?:(?:file)|(?:\w:)?\\)/) {
		$uri = URI::file->new($uri, 'win32');
	    } else {
	        $uri = URI->new( $uri );
    	    }
	    if ($uri->scheme && $uri->scheme eq 'file') {
		my $path = $uri->path;
		unless (file_name_is_absolute($path)) {
		    my $new_path;
		    if (-e $path) {
			$new_path = rel2abs( $path ) if ($self->abs_file_paths);
		    } else {
			$new_path = $self->find_in_INC( $path );
		    }
                    if ($new_path) {
                        if (($^O =~ /win32/i or $FAKE_WIN32_URIS)) {
                            $uri = URI::file->new("file://$new_path", 'win32');
                        } else {
                            $uri->path( $new_path );
                        }
                    }
		}
	    }
	    push @$uri_list, $uri;
	}
    }

    return $self;
}

sub prepare_report {
    my ($self, $a) = @_;

    my $r = {
	     tests => [],
	     start_time => '?',
	     end_time => '?',
	     elapsed_time => $a->elapsed_timestr,
	    };


    # add aggregate test info:
    for my $key (qw(
		    total
		    has_errors
		    has_problems
		    failed
		    parse_errors
		    passed
		    skipped
		    todo
		    todo_passed
		    wait
		    exit
		   )) {
	$r->{$key} = $a->$key;
    }

    # do some other handy calcs:
    if ($r->{total}) {
	$r->{percent_passed} = sprintf('%.1f', $r->{passed} / $r->{total} * 100);
    } else {
	$r->{percent_passed} = 0;
    }

    # estimate # files (# sessions could be different?):
    $r->{num_files} = scalar @{ $self->sessions };

    # add test results:
    my $total_time = 0;
    foreach my $s (@{ $self->sessions }) {
	my $sr = $s->as_report;
	push @{$r->{tests}}, $sr;
	$total_time += $sr->{elapsed_time} || 0;
    }
    $r->{total_time} = $total_time;

    # estimate total severity:
    my $smap = $self->severity_map;
    my $severity = 0;
    $severity += $smap->{$_->{severity} || ''} for @{$r->{tests}};
    my $avg_severity = 0;
    if (scalar @{$r->{tests}}) {
	$avg_severity = ceil($severity / scalar( @{$r->{tests}} ));
    }
    $r->{severity} = $smap->{$avg_severity};

    # TODO: coverage?

    return $r;
}

# adapted from Test::TAP::HTMLMatrix
# always return abs file paths if $self->abs_file_paths is on
sub find_in_INC {
    my ($self, $file) = @_;

    foreach my $path (grep { not ref } @INC) {
	my $target = catfile($path, $file);
	if (-e $target) {
	    $target = rel2abs($target) if $self->abs_file_paths;
	    return $target;
	}
    }

    # non-fatal
    $self->log("Warning: couldn't find $file in \@INC");
    return;
}

# adapted from Test::TAP::HTMLMatrix
# slurp all 'file' uris, if possible
# note: doesn't remove them from the css_uris list, just in case...
sub slurp_css {
    my ($self) = shift;
    $self->info("slurping css files inline");

    my $inline_css = '';
    $self->_slurp_uris( $self->css_uris, \$inline_css );

    # append any inline css so it gets interpreted last:
    $inline_css .= "\n" . $self->inline_css if $self->inline_css;

    $self->inline_css( $inline_css );
}

sub slurp_js {
    my ($self) = shift;
    $self->info("slurping js files inline");

    my $inline_js = '';
    $self->_slurp_uris( $self->js_uris, \$inline_js );

    # append any inline js so it gets interpreted last:
    $inline_js .= "\n" . $self->inline_js if $self->inline_js;

    $self->inline_js( $inline_js );
}

sub _slurp_uris {
    my ($self, $uris, $slurp_to_ref) = @_;

    foreach my $uri (@$uris) {
	my $scheme = $uri->scheme;
	if ($scheme && $scheme eq 'file') {
	    my $path = $uri->path;
	    if (-e $path) {
		if (open my $fh, $path) {
		    local $/ = undef;
		    $$slurp_to_ref .= <$fh>;
		    $$slurp_to_ref .= "\n";
		} else {
		    $self->log("Warning: couldn't open $path: $!");
		}
	    } else {
		$self->log("Warning: couldn't read $path: file does not exist!");
	    }
	} else {
	    $self->log("Warning: can't include $uri inline: not a file uri");
	}
    }

    return $slurp_to_ref;
}



sub log {
    my $self = shift;
    push @_, "\n" unless grep {/\n/} @_;
    $self->_output( @_ );
    return $self;
}

sub info {
    my $self = shift;
    return unless $self->verbose;
    return $self->log( @_ );
}

sub log_test {
    my $self = shift;
    return if $self->really_quiet;
    return $self->log( @_ );
}

sub log_test_info {
    my $self = shift;
    return if $self->quiet;
    return $self->log( @_ );
}

sub _output {
    my $self = shift;
    return if $self->silent;
    if (ref($_[0]) && ref( $_[0]) eq 'SCALAR') {
	# DEPRECATED: printing HTML:
	print { $self->stdout } ${ $_[0] };
    } else {
	unshift @_, '# ' if $self->escape_output;
	print { $self->stdout } @_;
    }
}


1;


__END__

=head1 DESCRIPTION

This module provides HTML output formatting for L<TAP::Harness> (a replacement
for L<Test::Harness>.  It is largely based on ideas from
L<TAP::Test::HTMLMatrix> (which was built on L<Test::Harness> and thus had a
few limitations - hence this module).  For sample output, see:

L<http://www.spurkis.org/TAP-Formatter-HTML/test-output.html>

This module is targeted at all users of automated test suites.  It's meant to
make reading test results easier, giving you a visual summary of your test suite
and letting you drill down into individual failures (which will hopefully make
testing more likely to happen at your organization ;-).

The design goals are:

=over 4

=item *

I<easy to use>

Once you've got your test report, it should be obvious how to use it.

=item *

I<helpful>

It should be helpful by pointing out I<where> & I<why> your test suite is
breaking.  If you've written your tests well, it should give you enough info to
start tracking down the issue.

=item *

I<easy to install>

Eg: should be a clean install from CPAN, and you shouldn't need to modify your
existing test suite to get up & running, though I<you will need to stop using
L<Test::Harness> unfortunately>.

=item *

I<work out of the box>

You shouldn't need to do any custom-coding to get it working - the default
configuration & templates should be enough to get started with.  Once installed
it should be a matter of running:

 % prove -m -Q --formatter=TAP::Formatter::HTML >output.html

From your project's home dir, and opening the resulting file.

=item *

I<easy to configure>

You should be able to configure & customize it to suit your needs.  As such,
css, javascript and templates are all configurable.

=back

=head1 METHODS

=head2 CONSTRUCTOR

=head3 new

  my $fmt = $class->new({ %args });

=head2 ACCESSORS

All chaining L<accessors>:

=head3 verbosity

  $fmt->verbosity( [ $v ] )

Verbosity level, as defined in L<TAP::Harness/new>:

     1   verbose        Print individual test results (and more) to STDOUT.
     0   normal
    -1   quiet          Suppress some test output (eg: test failures).
    -2   really quiet   Suppress everything to STDOUT but the HTML report.
    -3   silent         Suppress all output to STDOUT, including the HTML report.

Note that the report is also available via L</html>.  You can also provide a
custom L</output_fh> (aka L</output_file>) that will be used instead of
L</stdout>, even if I<silent> is on.

=head3 stdout

  $fmt->stdout( [ \*FH ] );

An L<IO::Handle> filehandle for catching standard output.  Defaults to C<STDOUT>.

=head3 output_fh

  $fmt->output_fh( [ \*FH ] );

An L<IO::Handle> filehandle for printing the HTML report to.  Defaults to the
same object as L</stdout>.

B<Note:> If L</verbosity> is set to C<silent>, printing to C<output_fh> will
still occur.  (that is, assuming you've opened a different file, B<not>
C<STDOUT>).

=head3 output_file

  $fmt->output_file( $file_name )

Not strictly an accessor - this is a shortcut for setting L</output_fh>,
equivalent to:

  $fmt->output_fh( IO::File->new( $file_name, 'w' ) );

You can set this with the C<TAP_FORMATTER_HTML_OUTFILE=/path/to/file>
environment variable

=head3 escape_output

  $fmt->escape_output( [ $boolean ] );

If set, all output to L</stdout> is escaped.  This is probably only useful
if you're testing the formatter.
Defaults to C<0>.

=head3 html

  $fmt->html( [ \$html ] );

This is a reference to the scalar containing the html generated on the last
test run.  Useful if you have L</verbosity> set to C<silent>, and have not
provided a custom L</output_fh> to write the report to.

=head3 tests

  $fmt->tests( [ \@test_files ] )

A list of test files we're running, set by L<TAP::Parser>.

=head3 session_class

  $fmt->session_class( [ $class ] )

Class to use for L<TAP::Parser> test sessions.  You probably won't need to use
this unless you're hacking or sub-classing the formatter.
Defaults to L<TAP::Formatter::HTML::Session>.

=head3 sessions

  $fmt->sessions( [ \@sessions ] )

Test sessions added by L<TAP::Parser>.  You probably won't need to use this
unless you're hacking or sub-classing the formatter.

=head3 template_processor

  $fmt->template_processor( [ $processor ] )

The template processor to use.
Defaults to a TT2 L<Template> processor with the following config:

  COMPILE_DIR  => catdir( tempdir(), 'TAP-Formatter-HTML' ),
  COMPILE_EXT  => '.ttc',
  INCLUDE_PATH => parent directory TAP::Formatter::HTML was loaded from

Note: INCLUDE_PATH used to be set to: C<join(':', @INC)> but this was causing
issues on systems with > 64 dirs in C<@INC>.  See RT #74364 for details.

=head3 template

  $fmt->template( [ $file_name ] )

The template file to load.
Defaults to C<TAP/Formatter/HTML/default_report.tt2>.

You can set this with the C<TAP_FORMATTER_HTML_TEMPLATE=/path/to.tt> environment
variable.

=head3 css_uris

  $fmt->css_uris( [ \@uris ] )

A list of L<URI>s (or strings) to include as external stylesheets in <style>
tags in the head of the document.
Defaults to:

  ['file:TAP/Formatter/HTML/default_report.css'];

You can set this with the C<TAP_FORMATTER_HTML_CSS_URIS=/path/to.css:/another/path.css>
environment variable.

If you're using Win32, please see L</WIN32 URIS>.

=head3 js_uris

  $fmt->js_uris( [ \@uris ] )

A list of L<URI>s (or strings) to include as external stylesheets in <script>
tags in the head of the document.
Defaults to:

  ['file:TAP/Formatter/HTML/jquery-1.2.6.pack.js'];

You can set this with the C<TAP_FORMATTER_HTML_JS_URIS=/path/to.js:/another/path.js>
environment variable.

If you're using Win32, please see L</WIN32 URIS>.

=head3 inline_css

  $fmt->inline_css( [ $css ] )

If set, the formatter will include the CSS code in a <style> tag in the head of
the document.

=head3 inline_js

  $fmt->inline_js( [ $javascript ] )

If set, the formatter will include the JavaScript code in a <script> tag in the
head of the document.

=head3 minify

  $fmt->minify( [ $boolean ] )

If set, the formatter will attempt to reduce the size of the generated report,
they can get pretty big if you're not careful!  Defaults to C<1> (true).

B<Note:> This currently just means... I<remove tabs at start of a line>.  It
may be extended in the future.

=head3 abs_file_paths

  $fmt->abs_file_paths( [ $ boolean ] )

If set, the formatter will attempt to convert any relative I<file> JS & css
URI's listed in L</css_uris> & L</js_uris> to absolute paths.  This is handy if
you'll be sending moving the HTML output around on your harddisk, (but not so
handy if you move it to another machine - see L</force_inline_css>).
Defaults to I<1>.

=head3 force_inline_css

  $fmt->force_inline_css( [ $boolean ] )

If set, the formatter will attempt to slurp in any I<file> css URI's listed in
L</css_uris>, and append them to L</inline_css>.  This is handy if you'll be
sending the output around - that way you don't have to send a CSS file too.
Defaults to I<1>.

You can set this with the C<TAP_FORMATTER_HTML_FORCE_INLINE_CSS=0|1> environment
variable.

=head3 force_inline_js( [ $boolean ] )

If set, the formatter will attempt to slurp in any I<file> javascript URI's listed in
L</js_uris>, and append them to L</inline_js>.  This is handy if you'll be
sending the output around - that way you don't have to send javascript files too.

Note that including jquery inline doesn't work with some browsers, haven't
investigated why.  Defaults to I<0>.

You can set this with the C<TAP_FORMATTER_HTML_FORCE_INLINE_JS=0|1> environment
variable.

=head3 color

This method is for C<TAP::Harness> API compatibility only.  It does nothing.

=head2 API METHODS

=head3 summary

  $html = $fmt->summary( $aggregator )

C<summary> produces a summary report after all tests are run.  C<$aggregator>
should be a L<TAP::Parser::Aggregator>.

This calls:

  $fmt->template_processor->process( $params )

Where C<$params> is a data structure containing:

  report      => %test_report
  js_uris     => @js_uris
  css_uris    => @js_uris
  inline_js   => $inline_js
  inline_css  => $inline_css
  formatter   => %formatter_info

The C<report> is the most complicated data structure, and will sooner or later
be documented in L</CUSTOMIZING>.

=head1 CUSTOMIZING

This section is not yet written.  Please look through the code if you want to
customize the templates, or sub-class.

You can use environment variables to customize the behaviour of TFH:

  TAP_FORMATTER_HTML_OUTFILE=/path/to/file
  TAP_FORMATTER_HTML_FORCE_INLINE_CSS=0|1
  TAP_FORMATTER_HTML_FORCE_INLINE_JS=0|1
  TAP_FORMATTER_HTML_CSS_URIS=/path/to.css:/another/path.css
  TAP_FORMATTER_HTML_JS_URIS=/path/to.js:/another/path.js
  TAP_FORMATTER_HTML_TEMPLATE=/path/to.tt

This should save you from having to write custom code for simple cases.

=head1 WIN32 URIS

This module tries to do the right thing when fed Win32 File I<paths> as File
URIs to both L</css_uris> and L</js_uris>, eg:

  C:\some\path
  file:///C:\some\path

While I could lecture you what a valid file URI is and point you at:

http://blogs.msdn.com/ie/archive/2006/12/06/file-uris-in-windows.aspx

Which basically says the above are invalid URIs, and you should use:

  file:///C:/some/path
  # ie: no backslashes

I also realize it's convenient to chuck in a Win32 file path, as you can on
Unix.  So if you're running under Win32, C<TAP::Formatter::HTML> will look for
a signature C<'X:\'>, C<'\'> or C<'file:'> at the start of each URI to see if
you are referring to a file or another type of URI.

Note that you must use 'C<file:///C:\blah>' with I<3 slashes> otherwise 'C<C:>'
will become your I<host>, which is probably not what you want.  See
L<URI::file> for more details.

I realize this is a pretty basic algorithm, but it should handle most cases.
If it doesn't work for you, you can always construct a valid File URI instead.

=head1 BUGS

Please use http://rt.cpan.org to report any issues.  Patches are welcome.

=head1 CONTRIBUTING

Use github:

L<https://github.com/spurkis/TAP-Formatter-HTML>

=head1 AUTHOR

Steve Purkis <spurkis@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2008-2012 Steve Purkis <spurkis@cpan.org>, S Purkis Consulting Ltd.
All rights reserved.

This module is released under the same terms as Perl itself.

=head1 SEE ALSO

Examples in the C<examples> directory and here:

L<http://www.spurkis.org/TAP-Formatter-HTML/test-output.html>,
L<http://www.spurkis.org/TAP-Formatter-HTML/DBD-SQLite-example.html>,
L<http://www.spurkis.org/TAP-Formatter-HTML/Template-example.html>

L<prove> - L<TAP::Harness>'s new cmdline utility.  It's great, use it!

L<App::Prove::Plugin::HTML> - the prove interface for this module.

L<Test::TAP::HTMLMatrix> - the inspiration for this module.  Many good ideas
were borrowed from it.

L<TAP::Formatter::Console> - the default TAP formatter used by L<TAP::Harness>

=cut

