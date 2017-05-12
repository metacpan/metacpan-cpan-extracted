package Pinwheel::TestHelper;

use strict;
use warnings;

use Cwd qw(getcwd);
use Exporter;
use Test::More;

use Pinwheel::Controller qw(url_for);
use Pinwheel::Model::Date;
use Pinwheel::Model::Time;
use Pinwheel::TagSelect;

=head1 NAME

Pinwheel::TestHelper

=head1 SYNOPSIS

    use Pinwheel::TestHelper;

    get('/radio4/schedule');
    is(get_template_name(), 'schedule/day.tmpl');

=head1 DESCRIPTION

This is a replacement for the Pinwheel::Controller module, it is invoked in tests and overrides 
the Pinwheel::Controller. See L<Pinwheel::Controller>.

=head1 ROUTINES

=over 4

=cut

our @ISA = qw(Exporter);
our @EXPORT = qw(
    is_response
    is_template
    is_redirected_to
    is_content
    is_generated
    is_recognised
    is_route
    set_time
    set_format
    get_template_name
    get
    find_nodes
    content
    url_for
    localise_test_state
);

our ($template, $headers, $content, $tagselect, $time_now);

sub localise_test_state(&)
{
    local $template = $template;
    local $headers = $headers;
    local $content = $content;
    local $tagselect = $tagselect;
    local $time_now = $time_now;
    my $sub = shift; &$sub;
}

=item ($headers, $content) = get($path)

Invokes C<Pinwheel::Controller::dispatch> to fetch the given page, and returns the headers 
and content.

Updates the C<$template, $headers, $content> variables.  Most of the rest of
the routines in this module then examine those variables, so generally you'll
want to always call C<get> first.

=cut

sub get
{
    my ($path) = @_;
    my ($query, $request, $page);

    ($path, $query) = split(/\?/, $path, 2);

    $template = undef;
    $tagselect = undef;
    $request = {
        method => 'GET',
        host => '127.0.0.1',
        path => $path,
        query => $query || '',
        base => '',
        time => $time_now ? $time_now->timestamp : undef,
    };
    ($headers, $page) = Pinwheel::Controller::dispatch($request);
    Pinwheel::Context::get('render')->{format} = ['html'];
    $headers = {map { @$_ } values(%$headers)};
    $content = $page;
    return ($headers, $page);
}

sub find_nodes
{
    my ($selector) = (shift);
    my ($nodes);

    _initialise_tagselect();
    return $tagselect->select($selector, \@_);
}

=item $strings = content($selector, @selector_args)

Selects nodes from C<$content> (so you probably want to call C<get> first), and
returns an array ref of their C<string_value>s.

See also C<is_content>.

=cut

sub content
{
    my ($selector) = (shift);
    my ($nodes);

    _initialise_tagselect();
    $nodes = $tagselect->select($selector, \@_);
    return [map { $_->string_value } $nodes->get_nodelist];
}

=item is_response($expect[, $name])

Tests the 'Status' header (from C<$headers>, so you'll probably want to call
C<get> first) against C<$expect>, and runs one test (via L<Test::More>).  The
C<$name> is passed in as the test name.

Allowed values for C<$expect>:

  'success' (an alias for '200')
  'redirect' (tests that the status matches /^3\d\d$/)
  'missing' (an alias for '404')
  'error' (tests that the status matches /^5\d\d$/)
  otherwise: exact match (e.g. '406')

=cut

sub is_response
{
    my ($expect, $name) = @_;
    my $test = _get_test_builder();
    my $n = $headers->{'Status'};

    return $test->is_num($n, 200, $name) if ($expect eq 'success');
    return $test->like($n, qr/^3\d\d$/, $name) if ($expect eq 'redirect');
    return $test->is_num($n, 404, $name) if ($expect eq 'missing');
    return $test->like($n, qr/^5\d\d$/, $name) if ($expect eq 'error');
    return $test->is_num($n, $expect, $name);
}

=item is_template($expect[, $name])

Tests that C<$template> (as updated by C<get>) equals C<$expect>.  Runs one
L<Test::More> test, using C<$name> if supplied.

=cut

sub is_template
{
    my ($expect, $name) = @_;
    my $test = _get_test_builder();
    $test->is_eq($template, $expect, $name);
}

=item is_redirected_to

C<is_redirected_to> checks the "Location" header:

   # Absolute URL
   is_redirected_to("http://....");

   # Anything else containing a slash is prefixed by "http://127.0.0.1"
   is_redirected_to("/some/url"); # anything else containing a 

   # Anything else calls url_for with only_path=0
   is_redirected_to('some_params', for => 'url_for')

C<is_redirected_to> also checks that the "Status" header is some 3xx value.
If you want more fine-grained checking than that, use C<is_response>.

=cut

sub is_redirected_to
{
    my $test = _get_test_builder();
    my $location = $headers->{'Location'};
    my $url;

    if (scalar(@_) == 1 && $_[0] =~ /\//) {
        $url = shift;
        $url = "http://127.0.0.1$url" if ($url !~ /^\w+:\/\//);
    } else {
        $url = url_for(@_, only_path => 0);
    }

    # Because of the way that is_redirected_to is called, it's not easy to
    # just add an optional $name on the end.  Rather than not doing names at
    # all, we always generate a name.
    my $name = "is_redirected_to $url";

    if ($location ne $url)
    {
        $test->is_eq($location, $url, $name);
    } else {
        is_response('redirect', $name);
    }
}

=item is_content

  is_content($selector, @selector_args, $text)
  # or
  is_content($selector, @selector_args, %opts)

Finds nodes matching C<$selector, @selector_args>, then tests those nodes
against C<%opts>.

The first form is equivalent to the second where C<%opts = (text =E<gt> $text)>.

Effectively there are two ways of using C<is_content>: text matching, or node counting.
Text matching does an implicit node count first, as it happens.  The text is
matched against the nodes' C<string_value>s.

  # Check that exactly one item is selected, and that its string value is "this text"
  is_content($selector, @selector_args, "this text")

  # Check that exactly two items are selected, and their string values (in order) are "One" and "Two"
  is_content($selector, @selector_args, ["One", "Two"])

  # Check that exactly two items are selected, and the first node's string
  # value matches the given regex, and the second node's string value is
  # "Exact".
  is_content($selector, @selector_args, [qr/first.pattern/, "Exact"])

  # Check that at least one item is selected
  is_content($selector, @selector_args)

  # Check that at least 2 items are selected
  is_content($selector, @selector_args, minimum => 2)

  # Check that at least 1 and at most 7 items are selected
  is_content($selector, @selector_args, minimum => 1, maximum => 7)

  # Check that exactly 5 items are selected
  is_content($selector, @selector_args, count => 5)

The C<text> option can be <\@text> or C<$text>.  The latter case is
equivalent to C<[$text]>.  In either case, a C<count> option is implied, with
its value as the number of items in C<@text>.

If no C<%opts> are given, C<minimum =E<gt> 1> is assumed.

Tests are then run in the following order.  The first failed test, if any,
'wins':

=over 4

=item count

Tests the number of found nodes against C<count> (exact match).

=item minimum

Tests the number of found nodes against C<minimum>.

=item maximum

Tests the number of found nodes against C<maximum>.

=item text

(If we get this far, we know that there are the same number of nodes as
C<text> items).

Each found node's C<string_value> is tested against its corresponding C<text>
item.  Each text item can be either a plain string or a Regexp.

=back

=cut

sub is_content
{
    my ($selector) = shift;
    my ($test, $nodes, %opts, $textfn, $t);

    _initialise_tagselect();
    $test = _get_test_builder();
    $nodes = $tagselect->select($selector, \@_);

    # Because of the way that is_content is called, it's not easy to
    # just add an optional $name on the end.  Rather than not doing names at
    # all, we always generate a name.
    my $name = "is_content $selector";

    if (scalar(@_) == 1) {
        $opts{text} = shift;
    } else {
        %opts = @_;
        $name = delete $opts{name}
            if defined $opts{name};
    }
    if (exists($opts{text})) {
        $t = $opts{text};
        if (ref($t) eq 'ARRAY') {
            $opts{count} = scalar(@$t);
            $textfn = sub { shift @{$opts{text}} };
        } else {
            $opts{count} = 1;
            $textfn = sub { $opts{text} };
        }
    } elsif (scalar(keys(%opts)) == 0) {
        $opts{minimum} = 1;
    }

    if (exists($opts{count}) && $nodes->size != $opts{count}) {
        $test->ok(0, $name);
        $test->diag(
            '    found ' . $nodes->size . ' nodes,' .
            ' expected ' . $opts{count}
        );
    } elsif (exists($opts{minimum}) && $nodes->size < $opts{minimum}) {
        $test->ok(0, $name);
        $test->diag(
            '    found ' . $nodes->size . ' nodes,' .
            ' expected at least ' . $opts{minimum}
        );
    } elsif (exists($opts{maximum}) && $nodes->size > $opts{maximum}) {
        $test->ok(0, $name);
        $test->diag(
            '    found ' . $nodes->size . ' nodes,' .
            ' expected at most ' . $opts{maximum}
        );
    } elsif ($textfn) {
        foreach ($nodes->get_nodelist) {
            $t = &$textfn();
            if (ref($t) eq 'Regexp') {
                return $test->like($_->string_value, $t, $name)
                    unless ($_->string_value =~ /$t/);
            } elsif ($_->string_value ne $t) {
                return $test->is_eq($_->string_value, $t, $name);
            }
        }
        $test->ok(1, $name);
    } else {
        $test->ok(1, $name);
    }
}

=item is_generated

TODO, document me.

=cut

sub is_generated
{
    my ($path, $opts, $name) = @_;
    my $test = _get_test_builder();
    $test->is_eq($Pinwheel::Controller::map->generate(%$opts), $path, $name);
}

=item is_recognised

TODO, document me.

=cut

sub is_recognised
{
    my ($opts, $path, $name) = @_;
    my $test = _get_test_builder();
    _is_recognised($test, $path, $opts, $name);
}

=item is_route

TODO, document me.

=cut

sub is_route
{
    my ($path, $opts, $name) = @_;
    my ($test, $x);

    $test = _get_test_builder();
    $x = $Pinwheel::Controller::map->generate(%$opts);
    return $test->is_eq($x, $path, $name) if ($x ne $path);
    _is_recognised($test, $path, $opts, $name);
}

# Not exported

sub _is_recognised
{
    my ($test, $path, $opts, $name) = @_;
    my ($x, $v1, $v2);

    local $Test::Builder::Level = 2;
    $x = $Pinwheel::Controller::map->match($path);
    foreach (keys(%$opts)) {
        if (!exists($x->{$_})) {
            $test->ok(0, $name);
            $test->diag("    missing key '$_' in match params");
            return;
        }
        $v1 = $x->{$_};
        $v2 = $opts->{$_};
        if ($v1 ne $v2) {
            $test->ok(0, $name);
            $test->diag("    key '$_' differs: '$v1' vs '$v2'");
            return;
        }
    }
    $test->ok(1, $name);
}

=item set_time(TIME)

Sets "now" to the time given by TIME (a L<Pinwheel::Model::Time> object).  Calls to
C<Pinwheel::Model::Date::now> and C<Pinwheel::Model::Time::now> will use TIME instead of the
system clock.

All that C<set_time> does is store TIME in C<$Pinwheel::TestHelper::time_now>.  If you
prefer, you can assign directly, perhaps using "local".

=cut

sub set_time
{
    $time_now = shift;
}

=item set_format

TODO, document me.

=cut

sub set_format
{
    my ($format) = @_;
    my ($ctx, $flist, $previous);

    $ctx = Pinwheel::Context::get('render');
    $flist = $ctx->{format};
    $flist = ['html'] if (!$flist || scalar(@$flist) == 0);
    $previous = $flist->[-1];
    $flist->[-1] = $format;
    $ctx->{format} = $flist;

    return $previous;
}

sub _get_date_now
{
    my $utc = shift;
    return real_date_now($utc) if (!defined($time_now));
    return Pinwheel::Model::Date->new($time_now->timestamp);
}

sub _get_time_now
{
    my $utc = shift;
    return real_time_now(CORE::time(), $utc) if (!defined($time_now));
    return Pinwheel::Model::Time->new($time_now->timestamp, $utc);
}

=item $template = get_template_name()

Returns the template name that is to be used to render the page in the framework.

=cut

sub get_template_name
{
    return $template;
}


sub _get_test_builder
{
    return Test::More->builder;
}

sub _initialise_tagselect
{
    if (!$tagselect) {
        my $s = $content;
        $s =~ s/<!DOCTYPE.*?>//s;
        $s =~ s/<!--#.*?-->//g;
        $s =~ s/&nbsp;/&#160;/g;
        $s =~ s/&laquo;/&#171;/g;
        $s =~ s/&raquo;/&#187;/g;
        $s =~ s/&ldquo;/&#8220;/g;
        $s =~ s/&rdquo;/&#8221;/g;
        $tagselect = Pinwheel::TagSelect->new();
        $tagselect->read($s);
    }
}


sub test_make_template_name
{
    my ($name, $ctx, $rendering);

    $name = real_make_template_name(@_);
    $ctx = Pinwheel::Context::get('*Pinwheel::Controller');
    $rendering = $ctx->{rendering};
    $template = $name if ($rendering++ == 1);

    return $name;
}


BEGIN
{
    # Trap the render functions
    *Pinwheel::TestHelper::real_render = *Pinwheel::Controller::render;
    *Pinwheel::TestHelper::real_make_template_name = *Pinwheel::Controller::_make_template_name;
    *Pinwheel::Controller::_make_template_name = *Pinwheel::TestHelper::test_make_template_name;

    # Intercept Pinwheel::Model::Date::now and Pinwheel::Model::Time::now
    *Pinwheel::TestHelper::real_date_now = *Pinwheel::Model::Date::now;
    *Pinwheel::TestHelper::real_time_now = *Pinwheel::Model::Time::now;
    *Pinwheel::Model::Date::now = *Pinwheel::TestHelper::_get_date_now;
    *Pinwheel::Model::Time::now = *Pinwheel::TestHelper::_get_time_now;

    # Pull in the application components
    require $_ foreach (glob('Config/*.pm'));
    require $_ foreach (glob('Models/*.pm'));
    require $_ foreach (glob('Helpers/*.pm'));
    require $_ foreach (glob('Controllers/*.pm'));

    # Initialise the controller (and anything hooked in)
    Pinwheel::Controller::initialise();

    # Set some defaults so url_for doesn't cause a warning without a get
    Pinwheel::Context::set('*Pinwheel::Controller',
        request => {
            method => 'GET',
            host => '127.0.0.1',
            path => '/',
            query => '',
            base => '',
        },
    );
}

=back

=head1 AUTHOR

A&M Network Publishing <DLAMNetPub@bbc.co.uk>

=cut

1;
