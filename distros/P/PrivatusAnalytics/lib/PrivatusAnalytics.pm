package PrivatusAnalytics;

use 5.020;
use strict;
use warnings;

use Carp                          qw(croak);
use Exporter                      qw(import);
use PrivatusAnalytics::Attributes qw(
  event_data event_attrs click_data click_attr valid_click_name html_escape
  normalize_key props_pairs
);
use PrivatusAnalytics::PageProps qw(page_props_json);

our $VERSION = '1.0.0';

our @EXPORT_OK = qw(
  event_data event_attrs click_data click_attr valid_click_name html_escape
  page_props_json inject_tag
);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use constant {
    DEFAULT_HOST   => 'https://privatusstats.com',
    PROPS_FUNCTION => 'privatusPageProps',
    MARKER         => '/js/pa.js',
    QUEUE_STUB     => q~window.privatus=window.privatus||{q:[]};['track','pageview','props','optOut','optIn','ready']~
      . q~.forEach(function(m){window.privatus[m]=window.privatus[m]||function(){window.privatus.q.push(~
      . q~[m,Array.prototype.slice.call(arguments)])}})~,
};

our @SPA_MODES = qw(auto history hash off);
our @MODULES   = qw(engage auto vitals clicks ask);

my @SETTINGS = qw(
  site_id script_host modules excluded_paths domains spa manual enabled
  enabled_environments environment auto_inject extra_attributes props
  queue_stub nonce
);
my %IS_SETTING = map { $_ => 1 } @SETTINGS;

my @LIST_OPTIONS =
  ( [ modules => 'data-modules' ], [ excluded_paths => 'data-exclude' ], [ domains => 'data-domains' ], );

sub _defaults {
    return (
        site_id              => undef,
        script_host          => undef,
        modules              => undef,
        excluded_paths       => [],
        domains              => undef,
        spa                  => undef,
        manual               => 0,
        enabled              => undef,
        enabled_environments => ['production'],
        environment          => undef,
        auto_inject          => 0,
        extra_attributes     => {},
        props                => {},
        queue_stub           => 0,
        nonce                => undef,
    );
}

sub new {
    my ( $class, @args ) = @_;
    my %args = @args == 1 && ref $args[0] eq 'HASH' ? %{ $args[0] } : @args;
    for my $name ( sort keys %args ) {
        croak "Unknown PrivatusAnalytics setting '$name'" unless $IS_SETTING{$name};
    }
    return bless { _defaults(), %args }, ref $class || $class;
}

# Plain get/set accessors for every setting.
for my $name (@SETTINGS) {
    next if $name eq 'site_id' || $name eq 'script_host' || $name eq 'environment';
    no strict 'refs';    ## no critic (ProhibitNoStrict)
    *{$name} = sub {
        my $self = shift;
        $self->{$name} = shift if @_;
        return $self->{$name};
    };
}

sub _trimmed {
    my ($value) = @_;
    return '' unless defined $value;
    $value = "$value";
    $value =~ s/\A\s+|\s+\z//g;
    return $value;
}

# The site id (starts with pa_). Falls back to $ENV{PRIVATUS_SITE_ID}.
sub site_id {
    my $self = shift;
    $self->{site_id} = shift if @_;
    my $value = _trimmed( $self->{site_id} );
    $value = _trimmed( $ENV{PRIVATUS_SITE_ID} ) if $value eq '';
    return $value eq '' ? undef : $value;
}

# Where /js/pa.js is served. Falls back to $ENV{PRIVATUS_SCRIPT_HOST}, then the default.
sub script_host {
    my $self = shift;
    $self->{script_host} = shift if @_;
    my $value = _trimmed( $self->{script_host} );
    $value = _trimmed( $ENV{PRIVATUS_SCRIPT_HOST} ) if $value eq '';
    $value = DEFAULT_HOST                           if $value eq '';
    $value =~ s{/\z}{};
    return $value;
}

# The current environment. Falls back to $ENV{PLACK_ENV}, then 'development'.
sub environment {
    my $self = shift;
    $self->{environment} = shift if @_;
    my $value = $self->{environment};
    $value = $value->() if ref $value eq 'CODE';
    $value = $ENV{PLACK_ENV} unless defined $value && $value ne '';
    return defined $value && $value ne '' ? $value : 'development';
}

# Whether the tag is on: `enabled` forces it, otherwise the environment decides.
sub is_enabled {
    my ( $self, $environment ) = @_;
    return $self->{enabled} ? 1 : 0 if defined $self->{enabled};
    $environment = $self->environment unless defined $environment;
    my $list = $self->{enabled_environments};
    my @on   = ref $list eq 'ARRAY' ? @{$list} : defined $list ? ($list) : ();
    return ( grep { defined && $_ eq $environment } @on ) ? 1 : 0;
}

# Whether a tag prints at all: there is a site id and the tag is on.
sub should_render {
    my ($self) = @_;
    return defined $self->site_id && $self->is_enabled ? 1 : 0;
}

# A copy of the settings with some of them changed.
sub with {
    my ( $self, %changes ) = @_;
    return $self->new( %{$self}, %changes );
}

# The configured props for one request, with per call props merged on top.
# A per call prop set to undef removes a configured one.
sub page_props {
    my ( $self, $request, $extra ) = @_;
    my $configured = $self->{props};
    $configured = $configured->($request) if ref $configured eq 'CODE';
    my @pairs = map { [ normalize_key( $_->[0] ), $_->[1] ] } @{ _pairs_or_empty($configured) },
      @{ _pairs_or_empty($extra) };

    my ( @keys, %values );
    for my $pair (@pairs) {
        next if $pair->[0] eq '';
        push @keys, $pair->[0] unless exists $values{ $pair->[0] };
        $values{ $pair->[0] } = $pair->[1];
    }
    return [ map { ( $_ => $values{$_} ) } @keys ];
}

sub _pairs_or_empty {
    my ($props) = @_;
    return [] unless ref $props eq 'HASH' || ref $props eq 'ARRAY';
    return props_pairs($props);
}

sub _list {
    my ($value) = @_;
    return undef unless defined $value;    ## no critic (ProhibitExplicitReturnUndef)
    my @items = ref $value eq 'ARRAY' ? @{$value} : ($value);
    return [ grep { $_ ne '' } map { _trimmed($_) } map { split /,/, ( defined $_ ? "$_" : '' ) } @items ];
}

# The tracker tag attributes, as an ordered list of name => value pairs.
# A value of undef prints the name alone (like defer).
sub attributes {
    my ( $self, $nonce ) = @_;
    my @attrs = ( [ defer => undef ], [ src => $self->script_host . MARKER ], [ 'data-site' => $self->site_id ], );
    for my $option (@LIST_OPTIONS) {
        my ( $name, $attribute ) = @{$option};
        my $values = _list( $self->{$name} );

        # undef keeps the tracker default. An empty modules list loads none.
        push @attrs, [ $attribute => join ',', @{$values} ]
          if $values && ( $name eq 'modules' || @{$values} );
    }
    my $spa = _trimmed( $self->{spa} );
    push @attrs, [ 'data-spa'    => $spa ]   if $spa ne 'auto' && grep { $_ eq $spa } @SPA_MODES;
    push @attrs, [ 'data-manual' => 'true' ] if $self->{manual};

    my $extra = $self->{extra_attributes};
    my $pairs = ref $extra eq 'HASH' || ref $extra eq 'ARRAY' ? props_pairs($extra) : [];
    for my $pair ( @{$pairs} ) {
        my ( $name, $value ) = @{$pair};
        next unless defined $value;
        _set_attr( \@attrs, "$name", "$value" );
    }
    _set_attr( \@attrs, nonce => $nonce ) if defined $nonce && $nonce ne '';
    return @attrs;
}

sub _set_attr {
    my ( $attrs, $name, $value ) = @_;
    for my $attr ( @{$attrs} ) {
        if ( $attr->[0] eq $name ) {
            $attr->[1] = $value;
            return;
        }
    }
    push @{$attrs}, [ $name => $value ];
    return;
}

sub _inline_script {
    my ( $code, $nonce ) = @_;
    my $open = defined $nonce && $nonce ne '' ? sprintf( '<script nonce="%s">', html_escape($nonce) ) : '<script>';
    return "$open$code</script>";
}

# The tag HTML. Takes any setting as a per call override, plus
# request (passed to a props or nonce code ref) and props (merged over the
# configured props). When the tag is off it returns only the queue stub (when
# queue_stub is on) or ''.
sub tag {
    my ( $self, @args ) = @_;
    my %options = @args == 1 && ref $args[0] eq 'HASH' ? %{ $args[0] } : @args;
    my $request = delete $options{request};
    my $props   = delete $options{props};
    my $config  = %options ? $self->with(%options) : $self;

    my $nonce = $config->{nonce};
    $nonce = $nonce->($request) if ref $nonce eq 'CODE';

    # When the tag is off, only the queue stub prints (if it is on), so
    # privatus.track calls never fail. The props code ref is not called.
    unless ( $config->should_render ) {
        return $config->{queue_stub} ? _inline_script( QUEUE_STUB, $nonce ) : '';
    }

    my $props_json = page_props_json( $config->page_props( $request, $props ) );
    my @attrs      = $config->attributes($nonce);
    push @attrs, [ 'data-props' => PROPS_FUNCTION ] if defined $props_json;

    my @html;
    push @html, _inline_script( QUEUE_STUB, $nonce ) if $config->{queue_stub};
    push @html, _inline_script( 'window.' . PROPS_FUNCTION . "=function(){return $props_json}", $nonce )
      if defined $props_json;
    push @html,
        '<script '
      . join( ' ', map { defined $_->[1] ? sprintf( '%s="%s"', $_->[0], html_escape( $_->[1] ) ) : $_->[0] } @attrs )
      . '></script>';
    return join "\n", @html;
}

# Whether a response should get the tag added (used by the auto inject hooks).
sub wants_inject {
    my ( $self, %response ) = @_;
    return 0 unless $self->{auto_inject};
    return 0 unless ( $response{status}         // 0 ) == 200;
    return 0 unless lc( $response{content_type} // '' ) =~ m{\A\s*text/html};
    return 0 if defined $response{content_encoding} && $response{content_encoding} ne '';
    return 0 if lc( $response{requested_with} // '' ) eq 'xmlhttprequest';
    return $self->should_render;
}

# Puts the tag just before the first </head>. Leaves the HTML alone when there is
# no </head> or the page already loads /js/pa.js.
sub inject_tag {
    my ( $html, $tag ) = @_;
    return $html unless defined $html && defined $tag && $tag ne '';
    return $html if index( $html, MARKER ) >= 0;
    $html =~ s{</head>}{$tag\n</head>}i;
    return $html;
}

1;

__END__

=encoding utf8

=head1 NAME

PrivatusAnalytics - add the cookieless Privatus Analytics script to Perl web apps

=head1 SYNOPSIS

  use PrivatusAnalytics qw(event_attrs click_attr);

  my $privatus = PrivatusAnalytics->new(
      site_id     => 'pa_YOURSITEID',
      environment => 'production',
  );
  print $privatus->tag;
  # <script defer src="https://privatusstats.com/js/pa.js" data-site="pa_YOURSITEID"></script>

  print event_attrs('Report exported', { format => 'csv' });
  # data-privatus-event="Report exported" data-privatus-prop-format="csv"

  print click_attr('pricing.cta');
  # data-privatus-click="pricing.cta"

=head1 DESCRIPTION

Adds the cookieless L<Privatus Analytics|https://privatusanalytics.com>
tracking script to your Perl web app. There is a plugin for Mojolicious
(L<Mojolicious::Plugin::PrivatusAnalytics>), a plugin for Dancer2
(L<Dancer2::Plugin::PrivatusAnalytics>), a Plack middleware for any PSGI app
(L<Plack::Middleware::PrivatusAnalytics>), and this plain module you can use
anywhere.

Privatus Analytics counts visits, sources, pages and conversions without
cookies, local storage or fingerprinting, so analytics does not need a consent
banner by itself. Check with your own counsel for your country.

This distribution only prints the browser script and a few HTML attributes. It
never sends events from your server and sets no cookies. You need a Privatus
Analytics account to see reports, and there is a free plan. Sign up at
L<https://privatusanalytics.com>.

=head1 REQUIREMENTS

Perl 5.20 or later. Optional: Mojolicious 9 or later, Dancer2 0.400000 or
later, or Plack. A Privatus Analytics site id (it starts with C<pa_>). You find
it under Site settings, Tracking.

=head1 INSTALL

  cpanm PrivatusAnalytics

For the full setup guide and every tracker option, see the
L<Privatus Analytics docs|https://privatusanalytics.com/docs>.

Set your site id with the C<PRIVATUS_SITE_ID> environment variable, or pass it
as the C<site_id> setting.

=head1 ADD THE TAG

=head2 Mojolicious

  plugin PrivatusAnalytics => { site_id => 'pa_YOURSITEID' };

  <head>
    %= privatus_analytics_tag
  </head>

=head2 Dancer2

  # config.yml
  plugins:
    PrivatusAnalytics:
      site_id: pa_YOURSITEID

  use Dancer2::Plugin::PrivatusAnalytics;

  <head>
    [% privatus_analytics_tag() %]
  </head>

=head2 Plack (any PSGI app)

  builder {
      enable 'PrivatusAnalytics', site_id => 'pa_YOURSITEID';
      $app;
  };

=head2 What it prints

In production it prints:

  <script defer src="https://privatusstats.com/js/pa.js" data-site="pa_YOURSITEID"></script>

The tag prints nothing when there is no site id, and nothing outside
production. If your app uses a Content Security Policy nonce (a random code
that lets a script run), pass it as the C<nonce> setting.

=head2 Or let it add the tag for you

Set C<< auto_inject => 1 >> in the Mojolicious or Dancer2 plugin. The Plack
middleware always does it. It adds the tag just before C<< </head> >> in
uncompressed C<text/html> responses with status 200. It skips Ajax requests,
pages without a C<< <head> >>, and pages that already have the tag. Responses
with a C<Content-Encoding> header are left alone. The C<Content-Length> header
is fixed for you.

=head1 CONFIGURATION

Every setting is optional except the site id.

=over 4

=item site_id

The C<data-site> attribute. Falls back to C<$ENV{PRIVATUS_SITE_ID}>. Nothing
prints without it.

=item script_host

Where C</js/pa.js> is served. Falls back to C<$ENV{PRIVATUS_SCRIPT_HOST}>, then
C<https://privatusstats.com>. A trailing slash is removed.

=item modules

The C<data-modules> attribute, for example C<[qw(engage auto)]>. C<undef>
keeps the tracker default (C<engage>). C<[]> loads none.

=item excluded_paths

The C<data-exclude> attribute. Path patterns the tracker never counts.

=item domains

The C<data-domains> attribute. Count only these hostnames.

=item spa

C<auto>, C<history>, C<hash> or C<off>. Only values other than C<auto> print.

=item manual

True prints C<data-manual="true"> and turns off the automatic pageview.

=item enabled

C<1> or C<0> forces the tag on or off in every environment. C<undef> uses
C<enabled_environments>.

=item enabled_environments

Environments that get the tag. Default C<['production']>. The Plack middleware
uses C<['deployment', 'production']>.

=item environment

The current environment. The plugins set it from the framework. Otherwise it
falls back to C<$ENV{PLACK_ENV}>, then C<development>. May be a code ref.

=item auto_inject

Adds the tag to the head of HTML pages. On by default in the Plack middleware.

=item extra_attributes

Any other C<data-*> attribute, as a hash ref or an array ref of pairs.

=item props

Page props sent with every pageview and event. A hash ref, an array ref of
pairs, or a code ref that gets the request. See L</"Page props">.

=item queue_stub

True prints a small script first, so C<privatus.track> calls made before the
tracker loads are kept and sent later. It still prints when the tag is off
(then nothing else prints), so those calls never fail.

=item nonce

The Content Security Policy nonce. A string, or a code ref that gets the
request.

=back

Lists can be array refs or comma separated text. Each tracker attribute is
explained in the L<script attributes
reference|https://privatusanalytics.com/docs/tracker/attributes>.

=head2 Development and test

Development and test requests are not counted by default. The tag is on when
the Mojolicious mode is C<production>, the Dancer2 environment is
C<production>, or C<PLACK_ENV> is C<deployment> or C<production> for the Plack
middleware. To see the tag while you build, set C<< enabled => 1 >>. The
tracker also ignores C<localhost> unless you pass C<data-allow-local> or
C<data-debug> with C<extra_attributes>.

=head2 Leaving people out

Use C<excluded_paths> for admin areas. To leave out signed-in staff, print the
helper only for other people.

=head1 METHODS

=over 4

=item new(%settings)

Makes a settings object. Unknown settings are an error. Every setting has a
get and set accessor of the same name.

=item tag(%options)

The tag HTML. When the tag is off it is only the queue stub (when
C<queue_stub> is on) or an empty string. Takes any setting as a per call override,
plus C<request> (passed to the C<props> and C<nonce> code refs) and C<props>
(merged over the configured props; C<undef> removes one).

=item is_enabled($environment)

Whether the tag is on in that environment (default: the current one).

=item should_render

Whether a tag prints at all: there is a site id and the tag is on.

=item page_props($request, $extra)

The configured props for one request with C<$extra> merged on top, as an array
ref of pairs.

=item wants_inject(%response)

Used by the auto inject hooks. Takes C<status>, C<content_type>,
C<content_encoding> and C<requested_with>.

=back

=head1 FUNCTIONS

Exported on request (C<:all> for every one).

=over 4

=item event_attrs($name, \%props)

Event attributes as escaped HTML. Props can be a hash ref (keys sorted), an
array ref of pairs or a list of pairs.

=item event_data($name, \%props)

The same attributes as a list of pairs.

=item click_attr($name)

The click map attribute as HTML, or an empty string when the name is not valid.

=item click_data($name)

The click map attribute as a list of pairs.

=item valid_click_name($name)

Whether a click map name is valid.

=item page_props_json(\%props)

Page props as JSON that is safe inside a script tag, or C<undef>.

=item inject_tag($html, $tag)

Puts the tag before the first C<< </head> >>, unless the page already loads
C</js/pa.js>.

=item html_escape($text)

Escapes C<& E<lt> E<gt> " '>.

=back

=head1 PRODUCT ANALYTICS: SEE WHICH FEATURES PEOPLE USE

Privatus can show which buttons, forms and features people really use. You
add a few attributes to your HTML. The tracker reads them in the browser and
sends the events. Your server still sends nothing.

=head2 Name events well

Use a short "Noun verb" name, like C<Report exported> or C<Invite sent>. Put
the details in props, not in the name. So write C<Report exported> with
C<< format => 'csv' >>, not C<Report exported as CSV>. Then all exports add up
in one place, and you can split them by format.

=head2 Events on buttons, links and forms

  <button <%= privatus_event 'Report exported', { format => 'csv', source => 'toolbar' } %>>Export</button>

prints

  <button data-privatus-event="Report exported" data-privatus-prop-format="csv" data-privatus-prop-source="toolbar">Export</button>

On a C<< <form> >>, the event is sent when the form is submitted. The rules:

=over 4

=item *

The name is trimmed and cut to 120 characters. An empty name prints nothing.

=item *

Prop keys are made lowercase. Anything that is not a letter, a digit or C<_>
becomes C<_>, so C<"Report Type"> becomes C<report_type>. Keys are cut to 64
characters.

=item *

At most 30 props. Values become text: numbers as written, lists joined with
commas, C<\1> and C<\0> (or C<JSON::PP::true> and C<JSON::PP::false>) become
C<true> and C<false>. C<undef> values are left out. Values are cut to 500
characters.

=item *

Everything is escaped for HTML.

=item *

The attributes print in every environment, even when the tag is off.

=back

=head2 Click maps

A click map shows where people click on a page. Give the important parts a
name: C<< <a href="/pricing" <%= privatus_click 'pricing.cta' %>> >>. A name
may use letters, digits and C<_ . : ->, up to 100 characters. Anything else
prints nothing.

=head2 Page props

Page props are sent with every pageview and event on the page. Use them to
split your reports by plan, role, app version, feature flag or account tier.

  props => sub { my ($request) = @_; { plan => 'pro', role => 'admin' } }

The tag then prints a small script before the tracker and points the tracker
at it:

  <script>window.privatusPageProps=function(){return {"plan":"pro","role":"admin"}}</script>
  <script defer src="https://privatusstats.com/js/pa.js" data-site="pa_YOURSITEID" data-props="privatusPageProps"></script>

Keys follow the same rules as event props. Numbers and true or false stay as
they are, and lists stay lists (up to 30 items). The props are escaped so they
are safe inside a script.

B<Never put names, emails, user ids or anything that points to one person in
props.> Privatus counts visitors without any id. Put groups (like the plan or
the role), not people. The server also removes emails and long ids it finds.

=head2 Track from your own JavaScript

  privatus.track("Feature used", { feature: "export" })

If your code may run before the tracker has loaded, set C<< queue_stub => 1 >>.
It prints this tiny script before the tracker:

  <script>window.privatus=window.privatus||{q:[]};['track','pageview','props','optOut','optIn','ready'].forEach(function(m){window.privatus[m]=window.privatus[m]||function(){window.privatus.q.push([m,Array.prototype.slice.call(arguments)])}})</script>

The stub prints even where the tag is off (in development, with
C<< enabled => 0 >>, or with no site id). Then only the stub prints, so you can
always call C<privatus.track(...)>. In development the calls just wait in the
queue and are never sent.

See the L<JavaScript API docs|https://privatusanalytics.com/docs/tracker/javascript-api>.

=head2 See the results

L<Funnels|https://privatusanalytics.com/docs/features/funnels>,
L<Click maps|https://privatusanalytics.com/docs/features/click-maps>,
L<Goals|https://privatusanalytics.com/docs/features/goals> and
L<Events|https://privatusanalytics.com/docs/events>.

=head1 PRIVACY

The script sets no cookies and stores nothing in the browser. This
distribution only prints HTML attributes and small scripts. Nothing here reads
IP addresses or browser details, and nothing is sent from your server. See the
L<privacy documentation|https://privatusanalytics.com/docs/privacy>.

=head1 SEE ALSO

L<Mojolicious::Plugin::PrivatusAnalytics>,
L<Dancer2::Plugin::PrivatusAnalytics>,
L<Plack::Middleware::PrivatusAnalytics>,
L<https://privatusanalytics.com/docs>

=head1 CONTRIBUTING

Bug reports and pull requests are welcome at
L<https://github.com/Privatus-Analytics/perl>.

=head1 AUTHOR

Two Phase LLC, Wyoming, USA.

=head1 LICENSE

MIT. Copyright (c) 2026 Two Phase LLC. See the F<LICENSE> file.

=cut
