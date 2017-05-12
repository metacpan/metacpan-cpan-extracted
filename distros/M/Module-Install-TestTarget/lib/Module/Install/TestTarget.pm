package Module::Install::TestTarget;
use 5.006_002;
use strict;
#use warnings; # XXX: warnings.pm produces a lot of 'redefine' warnings!
our $VERSION = '0.19';

use base qw(Module::Install::Base);
use Config;
use Carp qw(croak);

our($ORIG_TEST_VIA_HARNESS);

our $TEST_DYNAMIC = {
    env                => '',
    includes           => '',
    load_modules       => '',
    insert_on_prepare  => '',
    insert_on_finalize => '',
    run_on_prepare     => '',
    run_on_finalize    => '',
};

# override the default `make test`
sub default_test_target {
    my ($self, %args) = @_;
    my %test = _build_command_parts(%args);
    $TEST_DYNAMIC = \%test;
}

# create a new test target
sub test_target {
    my ($self, $target, %args) = @_;
    croak 'target must be spesiced at test_target()' unless $target;
    my $alias = "\n";

    if($args{alias}) {
        $alias .= qq{$args{alias} :: $target\n\n};
    }
    if($Module::Install::AUTHOR && $args{alias_for_author}) {
        $alias .= qq{$args{alias_for_author} :: $target\n\n};
    }

    my $test = _assemble(_build_command_parts(%args));

    $self->postamble(
          $alias
        . qq{$target :: pure_all\n}
        . qq{\t} . $test
    );
}

sub _build_command_parts {
    my %args = @_;

    #XXX: _build_command_parts() will be called first, so we put it here
    unless(defined $ORIG_TEST_VIA_HARNESS) {
        $ORIG_TEST_VIA_HARNESS = MY->can('test_via_harness');
        no warnings 'redefine';
        *MY::test_via_harness = \&_test_via_harness;
    }

    for my $key (qw/includes load_modules run_on_prepare run_on_finalize insert_on_prepare insert_on_finalize tests/) {
        $args{$key} ||= [];
        $args{$key} = [$args{$key}] unless ref $args{$key} eq 'ARRAY';
    }
    $args{env} ||= {};

    my %test;
    $test{includes} = @{$args{includes}} ? join '', map { qq|"-I$_" | } @{$args{includes}} : '';
    $test{load_modules}  = @{$args{load_modules}}  ? join '', map { qq|"-M$_" | } @{$args{load_modules}}  : '';

    $test{tests} =  @{$args{tests}}
        ? join '', map { qq|"$_" | } @{$args{tests}}
        : '$(TEST_FILES)';

    for my $key (qw/run_on_prepare run_on_finalize/) {
        $test{$key} = @{$args{$key}} ? join '', map { qq|do { local \$@; do '$_'; die \$@ if \$@ }; | } @{$args{$key}} : '';
        $test{$key} = _quote($test{$key});
    }
    for my $key (qw/insert_on_prepare insert_on_finalize/) {
        my $codes = join '', map { _build_funcall($_) } @{$args{$key}};
        $test{$key} = _quote($codes);
    }
    $test{env} = %{$args{env}} ? _quote(join '', map {
        my $key = _env_quote($_);
        my $val = _env_quote($args{env}->{$_});
        sprintf "\$ENV{q{%s}} = q{%s}; ", $key, $val
    } keys %{$args{env}}) : '';

    return %test;
}

my $bd;
sub _build_funcall {
    my($code) = @_;
    if(ref $code eq 'CODE') {
        $bd ||= do { require B::Deparse; B::Deparse->new() };
        $code = $bd->coderef2text($code);
    }
    return qq|sub { $code }->(); |;
}

sub _quote {
    my $code = shift;
    $code =~ s/\$/\\\$\$/g;
    $code =~ s/"/\\"/g;
    $code =~ s/\n/ /g;
    if ($^O eq 'MSWin32') {
        $code =~ s/\\\$\$/\$\$/g;
        if ($Config{make} =~ /dmake/i) {
            $code =~ s/{/{{/g;
            $code =~ s/}/}}/g;
        }
    }
    return $code;
}

sub _env_quote {
    my $val = shift;
    $val =~ s/}/\\}/g;
    return $val;
}

sub _assemble {
    my %args = @_;
    my $command = MY->$ORIG_TEST_VIA_HARNESS($args{perl} || '$(FULLPERLRUN)', $args{tests});

    # inject includes and modules before the first switch
    $command =~ s/("- \S+? ")/$args{includes}$args{load_modules}$1/xms;

    # inject snipetts in the one-liner
    $command =~ s{
        ( "-e" \s+ ")          # start the one liner
        ( (?: [^"] | \\ . )+ ) # body of the one liner
        ( " )                  # end the one liner
     }{
        join '', $1,
            $args{env},
            $args{run_on_prepare},
            $args{insert_on_prepare},
            "$2; ",
            $args{run_on_finalize},
            $args{insert_on_finalize},
            $3,
    }xmse;
    return $command;
}

sub _test_via_harness {
    my($self, $perl, $tests) = @_;

    $TEST_DYNAMIC->{perl} = $perl;
    $TEST_DYNAMIC->{tests} ||= $tests;
    return _assemble(%$TEST_DYNAMIC);
}

1;
__END__

=head1 NAME

Module::Install::TestTarget - Assembles Custom Test Targets For `make`

=head1 SYNOPSIS

inside Makefile.PL:

  use inc::Module::Install;
  tests 't/*t';

  # override the default `make test`
  default_test_target
      includes           => ["$ENV{HOME}/perl5/lib"],
      load_modules       => [qw/Foo Bar/],
      run_on_prepare     => [qw/before.pl/],
      run_on_finalize    => [qw/after.pl/],
      insert_on_prepare  => ['print "start -> ", scalar localtime, "\n"'],
      insert_on_finalize => ['print "end   -> ", scalar localtime, "\n"'],
      tests              => ['t/baz/*t'],
      env                => { PERL_ONLY => 1 },
  ;

  # create a new test target (allows `make foo`)
  test_target foo => (
      includes           => ["$ENV{HOME}/perl5/lib"],
      load_modules       => [qw/Foo Bar/],
      run_on_prepare     => [qw/before.pl/],
      run_on_finalize    => [qw/after.pl/],
      insert_on_prepare  => ['print "start -> ", scalar localtime, "\n"'],
      insert_on_finalize => ['print "end   -> ", scalar localtime, "\n"'],
      tests              => ['t/baz/*t'],
      env                => { PERL_ONLY => 1 },
      alias              => 'testall', # make testall is run the make foo
  );

  # above target 'foo' will turn into something like:
  perl "-MExtUtils::Command::MM" "-I/home/xaicron/perl5/lib" "-MFoo" "-MBar" "-e" "do { local \$@; do 'before.pl'; die \$@ if $@ }; sub { print \"start -> \", scalar localtime, \"\n\" }->(); test_harness(0, 'inc'); do { local \$@; do 'after.pl'; die \$@ if \$@ }; sub { print \"end -> \", scalar localtime, \"\n\" }->();" t/baz/*t

=head1 DESCRIPTION

Module::Install::TestTarget creates C<make test> variations with code snippets.
This helps module developers to test their distributions with various conditions.

=head1 EXAMPLES

=head2 TEST A MODULE WITH XS/PP BACKENDS

Suppose your XS module can load a PurePerl backend by setting the PERL_ONLY
environment variable. You can force your tests to use this environment
flag using this construct:

    test_target test_pp => (
        env => { PERL_ONLY => 1 },
    );

=head2 TEST AN APP USING DATABASES

Suppose you want to instantiate a mysqld instance using Test::mysqld, but you
don't want to start/stop mysqld for every test script. You can start mysqld
once using this module.

First create a script like this:

    # t/start_mysqld.pl
    use Test::mysqld;
    my $mysqld = Test::mysqld->new( ... );

Then in your Makefile.PL, simply specify that you want to run this script before executing any tests.

    test_target test_db => (
        run_on_prepare => [ 't/start_mysqld.pl' ]
    );

Since the script is going to be executed in global scope, $mysqld will stay
active during the execution of your tests -- the mysqld instance that came
up will shutdown automatically after the tests are executed.

You can use this trick to run other daemons, such as memcached (maybe via
Test::Memcached)

=head1 FUNCTIONS

=head2 test_target($target, %args)

Defines a new test target with I<%args>.

I<%args> are:

=over

=item C<< includes => \@include_paths >>

Sets include paths.

  test_target foo => (
      includes => ['/path/to/inc'],
  );

  # `make foo` will be something like this:
  perl -I/path/to/inc  -MExtUtils::Command::MM -e "test_harness(0, 'inc')" t/*t

=item C<< load_modules => \@module_names >>

Sets modules which are loaded before running C<test_harness()>.

  test_target foo => (
      load_modules => ['Foo', 'Bar::Baz'],
  );

  # `make test` will be something like this:
  perl -MFoo -MBar::Baz -MExtUtils::Command::MM -e "test_harness(0, 'inc')" t/*t

=item C<< run_on_prepare => \@scripts >>

Sets scripts to run before running C<test_harness()>.

  test_target foo => (
      run_on_prepare => ['tool/run_on_prepare.pl'],
  );

  # `make foo` will be something like this:
  perl -MExtUtils::Command::MM -e "do { local \$@; do 'tool/run_on_prepare.pl; die \$@ if \$@ }; test_harness(0, 'inc')" t/*t

=item C<< run_on_finalize => \@scripts >>

Sets scripts to run after running C<test_harness()>.

  use inc::Module::Install;
  tests 't/*t';
  test_target foo => (
      run_on_finalize => ['tool/run_on_after.pl'],
  );

  # `make foo` will be something like this:
  perl -MExtUtils::Command::MM -e "test_harness(0, 'inc'); do { local \$@; do 'tool/run_on_after.pl; die \$@ if \$@ };" t/*t

=item C<< insert_on_prepare => \@codes >>

Sets perl codes to run before running C<test_harness()>.

  use inc::Module::Install;
  tests 't/*t';
  test_target foo => (
      insert_on_prepare => ['print scalar localtime , "\n"', sub { system qw/cat README/ }],
  );

  # `make foo` will be something like this:
  perl -MExtUtils::Command::MM "sub { print scalar localtme, "\n" }->(); sub { system 'cat', 'README' }->(); test_harness(0, 'inc')" t/*t

The perl codes runs run_on_prepare runs later.

=item C<< insert_on_finalize => \@codes >>

Sets perl codes to run after running C<test_harness()>.

  use inc::Module::Install;
  tests 't/*t';
  test_target foo => (
      insert_on_finalize => ['print scalar localtime , "\n"', sub { system qw/cat README/ }],
  );

  # `make foo` will be something like this:
  perl -MExtUtils::Command::MM "test_harness(0, 'inc'); sub { print scalar localtme, "\n" }->(); sub { system 'cat', 'README' }->();" t/*t

The perl codes runs run_on_finalize runs later.

=item C<< alias => $name >>

Sets an alias of the test.

  test_target test_pp => (
      run_on_prepare => 'tool/force-pp.pl',
      alias          => 'testall',
  );

  # `make test_pp` and `make testall` will be something like this:
  perl -MExtUtils::Command::MM -e "do { local \$@; do 'tool/force-pp.pl'; die \$@; if \$@ }; test_harness(0, 'inc')" t/*t

=item C<< alias_for_author => $name >>

The same as C<alias>, but only enabled if it is in author's environment.

=item C<< env => \%env >>

Sets environment variables.

  test_target foo => (
      env => {
          FOO => 'bar',
      },
  );

  # `make foo` will be something like this:
  perl -MExtUtils::Command::MM -e "\$ENV{q{FOO}} = q{bar}; test_harness(0, 'inc')" t/*t

=item C<< tests => \@test_files >>

Sets test files to run.

  test_target foo => (
      tests  => ['t/foo.t', 't/bar.t'],
      env    => { USE_FOO => 1 },
  );

  # `make foo` will be something like this:
  perl -MExtUtils::Command::MM -e "$ENV{USE_FOO} = 1 test_harness(0, 'inc')" t/foo.t t/bar.t

=back

=head2 default_test_target(%args)

Override the default `make test` with I<%args>.

Same argument as C<test_target()>, but `target` and `alias` are not allowed.

=head1 AUTHOR

Yuji Shimada E<lt>xaicron {at} cpan.orgE<gt>

Goro Fuji (gfx) <gfuji at cpan.org>

Maki Daisuke (lestrrat)

=head1 SEE ALSO

L<Module::Install>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
