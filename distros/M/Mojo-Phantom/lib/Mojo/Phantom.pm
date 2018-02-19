package Mojo::Phantom;

use Mojo::Base -base;

our $VERSION = '0.11';
$VERSION = eval $VERSION;

use Mojo::Phantom::Process;

use Mojo::File;
use Mojo::JSON;
use Mojo::Template;
use Mojo::URL;
use JavaScript::Value::Escape;

use constant DEBUG => $ENV{MOJO_PHANTOM_DEBUG};

use constant CAN_CORE_DIE  => !! CORE->can('die');
use constant CAN_CORE_WARN => !! CORE->can('warn');

has arguments => sub { [] };
has base    => sub { Mojo::URL->new };
has bind    => sub { {} };
has cookies => sub { [] };
has package => 'main';
has 'setup';
has sep     => '--MOJO_PHANTOM_MSG--';
has no_exit => 0;
has note_console => 0;
has 'exe';

has template => <<'TEMPLATE';
  % my ($self, $url, $js) = @_;

  // Setup perl function
  function perl() {
    var system = require('system');
    var args = Array.prototype.slice.call(arguments);
    system.stdout.writeLine(JSON.stringify(args));
    system.stdout.writeLine('<%== $self->sep %>');
    system.stdout.flush();
  }

  // Setup error handling
  var onError = function(msg, trace) {
    var msgStack = ['PHANTOM ERROR: ' + msg];
    if (trace && trace.length) {
      msgStack.push('TRACE:');
      trace.forEach(function(t) {
        msgStack.push(' -> ' + (t.file || t.sourceURL) + ': ' + t.line + (t.function ? ' (in function ' + t.function +')' : ''));
      });
    }

    //phantom.exit isn't exitting immediately, so let Perl kill us
    perl('CORE::die', msgStack.join('\n'));
    //phantom.exit(1);
  };
  phantom.onError = onError;

  // Setup bound functions
  % my $bind = $self->bind || {};
  % foreach my $func (keys %$bind) {
    % my $target = $bind->{$func} || $func;
    perl.<%= $func %> = function() {
      perl.apply(this, ['<%== $target %>'].concat(Array.prototype.slice.call(arguments)));
    };
  % }

  // Setup Cookies
  % foreach my $cookie (@{ $self->cookies }) {
    % my $name = $cookie->name;
    phantom.addCookie({
      name: '<%== $name %>',
      value: '<%== $cookie->value %>',
      domain: '<%== $cookie->domain || $self->base->host %>',
    }) || perl.diag('Failed to import cookie <%== $name %>');
  % }

  // Requst page and inject user-provided javascript
  var page = require('webpage').create();
  page.onError = onError;

  % if($self->note_console) {

    // redirect browser console log to TAP
    page.onConsoleMessage = function(msg) {
      perl.note('js console: ' + msg);
    };

    // redirect console log to TAP
    (function() {
      var old = console.log;
      console.log = function(msg) {
        perl.note('phantom console: ' + msg);
        old.apply(this, Array.prototype.slice.call(arguments));
      };
    }());

  % }

  // Additional setup
  <%= $self->setup || '' %>;

  page.open('<%== $url %>', function(status) {

    <%= $js %>;

    % unless($self->no_exit) {
      phantom.exit();
    % }
  });
TEMPLATE

sub execute_file {
  my ($self, $file, $cb) = @_;
  # note that $file might be an object that needs to have a strong reference

  my $arguments = $self->arguments // [];

  my $proc = Mojo::Phantom::Process->new(arguments => $arguments);
  $proc->exe($self->exe) if $self->exe;

  my $sep = $self->sep;
  my $package = $self->package;
  my $buffer = '';
  my $error;

  $proc->on(read => sub {
    my ($proc, $bytes) = @_;
    warn "\nPerl <<<< Phantom: $bytes\n" if DEBUG;
    $buffer .= $bytes;
    while ($buffer =~ s/^(.*)\n$sep\n//) {
      my ($function, @args) = @{ Mojo::JSON::decode_json $1 };
      local *CORE::die  = sub { die  @_ } unless CAN_CORE_DIE;
      local *CORE::warn = sub { warn @_ } unless CAN_CORE_WARN;
      eval "package $package; no strict 'refs'; &{\$function}(\@args)";
      if ($@) { $error = $@; return $proc->kill }
    }
  });

  $proc->on(close => sub {
    my ($proc) = @_;
    undef $file;
    $self->$cb($error || $proc->error, $proc->exit_status) if $cb;
  });

  return $proc->start($file);
}

sub execute_url {
  my ($self, $url, $js, $cb) = @_;

  $js = Mojo::Template
    ->new(escape => \&javascript_value_escape)
    ->render($self->template, $self, $url, $js);

  die $js if ref $js; # Mojo::Template returns Mojo::Exception objects on failure

  warn "\nPerl >>>> Phantom:\n$js\n" if DEBUG;
  my $tmp = Mojo::File::tempfile(SUFFIX => '.js')->spurt($js);

  return $self->execute_file($tmp, $cb);
}

1;

=encoding utf8

=head1 NAME

Mojo::Phantom - Interact with your client side code via PhantomJS

=head1 SYNOPSIS

  use Mojolicious::Lite;

  use Test::More;
  use Test::Mojo::WithRoles qw/Phantom/;

  any '/' => 'index';

  my $t = Test::Mojo::WithRoles->new;
  $t->phantom_ok('/' => <<'JS');
    var text = page.evaluate(function(){
      return document.getElementById('name').innerHTML;
    });
    perl.is(text, 'Bender', 'name changed after loading');
  JS

  done_testing;

  __DATA__

  @@ index.html.ep

  <!DOCTYPE html>
  <html>
    <head></head>
    <body>
      <p id="name">Leela</p>
      <script>
        (function(){ document.getElementById('name').innerHTML = 'Bender' })();
      </script>
    </body>
  </html>

=head1 DESCRIPTION

L<Mojo::Phantom> is the transport backbone for L<Test::Mojo::Role::Phantom>.
Currently it is used to evaluate javascript tests using PhantomJS, though more is possible.
Please note that this class is not yet as stable as the public api for the test role.

=head1 WARNING

The upstream phantom.js has been retired in favor of headless chrome.
A L<Mojo::Chrome> (and related L<Test::Mojo::Role::Chrome>) is planned and is already in the works (perhaps it is released already who knows?!).
While this module will continue to function, just know that it depends on a project that is defunct.

=head1 ATTRIBUTES

L<Mojo::Phantom> inherits the attributes from L<Mojo::Base> and implements the following new ones.

=head2 arguments

An array reference containing command-line arguments to be passed directly to the PhantomJS process.

=head2 base

An instance of L<Mojo::URL> used to make relative urls absolute.
This is used, for example, in setting cookies

=head2 bind

A hash reference used to bind JS methods and Perl functions.
Keys are methods to be created in the C<perl> object in javascript.
Values are functions for those methods to invoke when the message is received by the Perl process.
The functions may be relative to the L<package> or are absolute if they contain C<::>.
If the function is false, then the key is used as the function name.

=head2 cookies

An array reference containing L<Mojo::Cookie::Response> objects.

=head2 package

The package for binding relative function names.
Defaults to C<main>

=head2 setup

An additional string of javascript which is executed after the page object is created but before the url is opened.

=head2 sep

A string used to separate messages from the JS side.
Defaults to C<--MOJO_PHANTOM_MSG-->.

=head2 template

A string which is used to build a L<Mojo::Template> object.
It takes as its arguments the instance, a target url, and a string of javascript to be evaluated.

The default handles much of what this module does, you should be very sure of why you need to change this before doing so.

=head2 no_exit

Do not automatically call C<phantom.exit()> after the provided JavaScript code.  This is useful
when testing asynchronous events.

=head2 note_console

Redirect C<console.log> output to TAP as note events.  This is usually helpful when writing tests.  The default is
off for Mojo::Phantom and on for L<Test::Mojo::Role::Phantom>.

=head2 exe

The executable name or path to call PhantomJS.  You may substitute a compatible platform, for example using C<casperjs> to use
CasperJS.

Note that while you can use this to specify the full path of an alternate version of PhantomJS, during the install of
Mojo::Phantom you I<must> have phantomjs in your C<PATH> for configuration and testing.

=head1 METHODS

L<Mojo::Phantom> inherits all methods from L<Mojo::Base> and implements the following new ones.

=head2 execute_file

A lower level function which handles the message passing etc.
You probably want L<execute_url>.
Takes a file path to start C<phantomjs> with and a callback.

Returns a pre-initialized instance of L<Mojo::Phantom::Process>.
The end user likely does not need to worry about this object, though it might be useful if the process needs to be killed or the stream timeout needs to be lengthened.

=head2 execute_url

Builds the template for PhantomJS to execute and starts it.
Takes a target url, a string of javascript to be executed in the context that the template provides and a callback.
By default this is the page context.
The return value is the same as L</execute_file>.

The executable name or path to call PhantomJS.  You may substitute a compatible platform, for example using C<casperjs> to use
CasperJS.

=head1 NOTES

NOTE that if your Perl version does not provide C<CORE::die> and C<CORE::warn>, they will be monkey-patched into the C<CORE> namespace before executing the javascript.

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Test-Mojo-Phantom>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 CONTRIBUTORS

Graham Ollis (plicease)

Sebastian Paaske Tørholm (Eckankar)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by L</AUTHOR> and L</CONTRIBUTORS>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
