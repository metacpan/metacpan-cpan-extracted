package Test::Mojo::Role::Phantom;

use Role::Tiny;

use Test::More ();

use Mojo::Phantom;

sub phantom_ok {
  my $t = shift;
  my $opts = ref $_[-1] ? pop : {};
  my $js = pop;

  my $base = $t->ua->server->nb_url;

  my $url = $t->app->url_for(@_);
  unless ($url->is_abs) {
    $url = $url->to_abs($base);
  }

  my $phantom = $opts->{phantom} || do {
    my %bind = (
      ok    => 'Test::More::ok',
      is    => 'Test::More::is',
      diag  => 'Test::More::diag',
      note  => 'Test::More::note',
      fail  => 'Test::More::fail',
      %{ $opts->{bind} || {} },
    );

    Mojo::Phantom->new(
      base    => $base,
      bind    => \%bind,
      cookies => $t->ua->cookie_jar->all,
      setup   => $opts->{setup},
      package => $opts->{package} || caller,
      no_exit => $opts->{no_exit},
      note_console => $opts->{note_console} // 1,
      arguments => $opts->{phantom_args} // [],
    );
  };

  my $name = $opts->{name} || 'all phantom tests successful';
  my $block = sub {
    Test::More::plan(tests => $opts->{plan}) if $opts->{plan};
    Mojo::IOLoop->delay(
      sub { $phantom->execute_url($url, $js, shift->begin) },
      sub {
        my ($delay, $err, $status) = @_;
        if ($status) {
          my $exit = $status >> 8;
          my $sig  = $status & 127;
          my $msg  = $exit ? "status: $exit" : "signal: $sig";
          Test::More::diag("phantom exitted with $msg");
        }
        die $err if $err;
      },
    )->catch(sub{ Test::More::fail(pop) })->wait;
  };
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  return $t->success(Test::More::subtest($name => $block));
}

1;

=head1 NAME

Test::Mojo::Role::Phantom - Adds phantom_ok to Test::Mojo

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

L<Test::Mojo::Role::Phantom> is a L<Role::Tiny> role which adds a L<phantom_ok> method to L<Test::Mojo> or a L<Test::Mojo> instance.
This method tests the javascript behavior of the app via an external L<PhantomJS|http://phantomjs.org/> process.
You must install that program and it must be in your C<PATH> in order to use this method.

The author recommends using L<Test::Mojo::WithRoles> to manage the role application.
The low level interaction is handled by a L<Mojo::Phantom> instance, but for the most part that is transparent to the test method.

=head1 WARNING

The upstream phantom.js has been retired in favor of headless chrome.
A L<Mojo::Chrome> (and related L<Test::Mojo::Role::Chrome>) is planned and is already in the works (perhaps it is released already who knows?!).
While this module will continue to function, just know that it depends on a project that is defunct.

=head1 METHODS

=head2 phantom_ok

 $t = $t->phantom_ok(@url_for, $js, \%opts)

The arguments are as follows

=head3 url specification

L<phantom_ok> takes a url or arguments for L<Mojolicious::Controller/url_for>, a required string of javascript and and optional hash reference of additional arguments.

=head3 javascript

The javascript string will be executed once the phantom object has loaded the page in question.
At this point, it will have access to all the symbols of a typical phantom process as well as

=over

=item page

The page object.

=item status

The page request status, should be C<success>.

=item perl

A function which takes the name of a perl function and arguments for that function.
The function name and the arguments are serialized as JSON and then executed on the perl side.

If the function dies (or is L<CORE::die>), the test fails.

=back

Since it would be prohibitively expensive to start up a new phantom process for each test in the string, the entire string is executed as a subtest.
The test result will be success if the entire subtest is a success.

If there is a javascript error, the subtest will fail.

=head3 options

The method also takes a hashreference of additional options.
They are as follows:

=over

=item name

The name of the subtest

=item plan

The number of tests that are expected.
While not required, this is more useful than most plans in L<Test::More> since the transport of the commands is volatile.
By specifying a plan in this way, if the process exits (status zero) early or never starts, the test will still fail rather than silently pass assuming there were no tests.

=item package

The package that is searched for Perl functions if the function name is not fully qualified.

=item bind

A hash reference of key-value pairs which then have shortcuts built in the phantom process.
The pairs passed are merged into

  {
    ok    => 'Test::More::ok',
    is    => 'Test::More::is',
    diag  => 'Test::More::diag',
    note  => 'Test::More::note',
    fail  => 'Test::More::fail',
  }

In the phantom process you may then use the shortcut as

  perl.ok(@args)

Which is handy if you are using a certain function often.

Note that if the value is falsey, the key name is use as the target.

=item setup

A pass-through option specifying javascript to be run after the page object is created but before the url is opened.

=item phantom

If you need even more control, you may pass in an instance of L<Mojo::Phantom> and it will be used.

=item no_exit

Do not automatically call C<phantom.exit()> after the provided JavaScript code.  This is useful when testing asynchronous events.

=item note_console

Redirect C<console.log> output to TAP as note events.  This is usually helpful, but can be turned off if it becomes too
verbose.

=item phantom_args

Specifies an array reference of command-line arguments passed directly to the PhantomJS process.

=back

=head1 DESIGN GOALS

Not enough people test their client-side javascript.
The primary goal is make testing js in you L<Mojolicious> app that you actually DO IT.
To accomplish this, I make the following goals:

=over

=item  *

Have the test script not depend on a running mojolicious server (i.e. start one, like L<Test::Mojo> scripts can), whether that be from a js or perl file doesn't matter

=item *

Emit tap in a normal way in a manner that prove -l can collect tests

=item *

Not have to reimplement a large chunk of the test methods in either L<Test::More> or L<Test::Mojo>.
Note: if some javascript library has functionality like Test::* (that emits tap and can be collected subject to the previous goals) then that would be sufficient.

=back

This module is the result of those goals and my limited design ability.
I encourage contribution, whether to this implementation or some other implementation which meets these goals!

=head1 NOTES

The C<phantom_ok> test itself mimics a C<subtest>.
While this outer test behaves correctly, individual tests do not report the correct line and file, instead emitting from inside the IOLoop.
It is hoped that future versions of L<Test::More> will make correct reporting possible, but it is not yet.

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Test-Mojo-Phantom>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
