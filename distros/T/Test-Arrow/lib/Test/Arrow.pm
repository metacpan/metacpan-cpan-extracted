package Test::Arrow;
use strict;
use warnings;
use Test::Builder::Module;
use Test::Name::FromLine;
use Text::MatchedPosition;

our $VERSION = '0.11';

our @ISA = qw/Test::Builder::Module/;

sub PASS { 1 }
sub FAIL { 0 }

sub import {
    my $pkg  = shift;
    my %args = map { $_ => 1 } @_;

    $pkg->_import_option_no_strict(\%args);
    $pkg->_import_option_no_warnings(\%args);
    $pkg->_import_option_binary(\%args);

    if ($] < 5.014000) {
        require IO::Handle;
        IO::Handle->import;
    }
}

sub _import_option_no_strict {
    my ($pkg, $args) = @_;

    my $no_strict = delete $args->{no_strict} or delete $args->{'-strict'};
    if (!$no_strict) {
        strict->import;
    }
}

sub _import_option_no_warnings {
    my ($pkg, $args) = @_;

    my $no_warnings = delete $args->{no_warnings} or delete $args->{'-warnings'};
    if (!$no_warnings) {
        warnings->import;
    }
}

sub _import_option_binary {
    my ($pkg, $args) = @_;

    my $binary = delete $args->{binary} or delete $args->{binary_mode}
                    or delete $args->{not_utf8} or delete $args->{'-utf8'} or delete $args->{'-utf'};
    if (!$binary) {
        binmode $pkg->builder->$_, ':utf8' for qw(failure_output todo_output output);
        require utf8;
        utf8->import;
    }
}

sub new {
    bless {}, shift;
}

sub _tb { __PACKAGE__->builder }

sub _reset {
    my ($self) = @_;

    delete $self->{_name};
    delete $self->{_expected};
    delete $self->{_got};

    $self;
}

sub pass { shift; _tb->ok(PASS, @_) }
sub fail { shift; _tb->ok(FAIL, @_) }

sub BAIL_OUT {
    _tb->BAIL_OUT(scalar @_ == 1 ? $_[0] : $_[1]);
}

sub name {
    my ($self, $name) = @_;

    if (defined $name) {
        $self->{_name} = $name;
    }

    $self;
}

sub expected {
    my ($self, $value) = @_;

    $self->{_expected} = $value;

    $self;
}

sub got {
    my ($self, $value) = @_;

    $self->{_got} = $value;

    $self;
}

sub _specific {
    my ($self, $key, $value) = @_;

    if (defined $value && exists $self->{$key} && defined $self->{$key}) {
        $key =~ s/^_//;
        $self->diag("You set '$key' also in args.");
    }

    return exists $self->{$key} && defined $self->{$key} ? $self->{$key} : $value;
}

sub ok {
    my ($self, $value, $name) = @_;

    my $got = $self->_specific('_got', $value);
    my $test_name = defined $name ? $name : $self->{_name};

    _tb->ok($got, $test_name);

    $self->_reset;

    $value;
}

sub to_be {
    my ($self, $got, $name) = @_;

    my $expected = $self->{_expected};
    my $test_name = $self->_specific('_name', $name);

    my $ret = _tb->is_eq($got, $expected, $test_name);

    $self->_reset;

    $ret;
}

sub _test {
    my $self   = shift;
    my $method = shift;

    my $got = $self->_specific('_got', $_[0]);
    my $expected = $self->_specific('_expected', $_[1]);
    my $test_name = $self->_specific('_name', $_[2]);

    local $Test::Builder::Level = 2;
    my $ret = _tb->$method($got, $expected, $test_name);

    $self->_reset;

    $ret;
}

sub is { shift->_test('is_eq', @_) }

sub isnt { shift->_test('isnt_eq', @_) }

sub is_num { shift->_test('is_num', @_) }

sub isnt_num { shift->_test('isnt_num', @_) }

sub like { shift->_test('like', @_) }

sub unlike {
    my $self = shift;

    my $got = $self->_specific('_got', $_[0]);
    my $expected = $self->_specific('_expected', $_[1]);
    my $test_name = $self->_specific('_name', $_[2]);

    my $ret = _tb->unlike($got, $expected, $test_name);

    $self->_reset;

    return $ret if $ret eq '1';

    my $pos = Text::MatchedPosition->new($got, $expected);
    return _tb->diag( sprintf <<'DIAGNOSTIC', $pos->line, $pos->offset );
          matched at line: %d, offset: %d
DIAGNOSTIC
}

sub diag {
    my $self = shift;

    _tb->diag(@_);

    $self;
}

sub note {
    my $self = shift;

    _tb->note(@_);

    $self;
}

sub explain {
    my $self = shift;

    if (scalar @_ == 0) {
        my $hash = {
            got      => $self->{_got},
            expected => $self->{_expected},
            name     => $self->{_name},
        };
        $self->diag(_tb->explain($hash));
    }
    else {
        $self->diag(_tb->explain(@_));
    }

    $self;
}

sub done_testing {
    my $self = shift;

    _tb->done_testing(@_);

    $self;
}

# Mostly copied from Test::More::can_ok
sub can_ok {
    my($self, $proto, @methods) = @_;

    my $class = ref $proto || $proto;

    unless($class) {
        my $ok = _tb->ok(FAIL, "->can(...)");
        _tb->diag('    can_ok() called with empty class or reference');
        return $ok;
    }

    unless(@methods) {
        my $ok = _tb->ok(FAIL, "$class->can(...)");
        _tb->diag('    can_ok() called with no methods');
        return $ok;
    }

    my @nok = ();
    for my $method (@methods) {
        _tb->_try(sub { $proto->can($method) }) or push @nok, $method;
    }

    my $name = scalar @methods == 1 ? "$class->can('$methods[0]')" : "$class->can(...)";

    my $ok = _tb->ok(!@nok, $name);

    _tb->diag(map "    $class->can('$_') failed\n", @nok);

    return $ok;
}

# Mostly copied from Test::More::isa_ok
sub isa_ok {
    my $self = shift;

    my $got = $self->_specific('_got', $_[0]);
    my $expected = $self->_specific('_expected', $_[1]);
    my $test_name = $self->_specific('_name', $_[2]);

    my $whatami = 'class';
    if (!defined $got) {
        $whatami = 'undef';
    }
    elsif (ref $got) {
        $whatami = 'reference';

        local($@, $!);
        require Scalar::Util;
        if(Scalar::Util::blessed($got)) {
            $whatami = 'object';
        }
    }

    # We can't use UNIVERSAL::isa because we want to honor isa() overrides
    my ($result, $error) = _tb->_try(sub { $got->isa($expected) });

    if ($error) {
        die <<WHOA unless $error =~ /^Can't (locate|call) method "isa"/;
WHOA! I tried to call ->isa on your $whatami and got some weird error.
Here's the error.
$error
WHOA
    }

    # Special case for isa_ok( [], "ARRAY" ) and like
    if ($whatami eq 'reference') {
        $result = UNIVERSAL::isa($got, $expected);
    }

    my ($diag, $name) = $self->_get_isa_diag_name($whatami, $got, $expected, $test_name);

    my $ok;
    if ($result) {
        $ok = _tb->ok(PASS, $name);
    }
    else {
        $ok = _tb->ok(FAIL, $name);
        _tb->diag("    $diag\n");
    }

    $self->_reset;

    return $ok;
}

sub _get_isa_diag_name {
    my ($self, $whatami, $got, $expected, $test_name) = @_;

    my ($diag, $name);

    if (defined $test_name) {
        $name = "'$test_name' isa '$expected'";
        $diag = defined $got ? "'$test_name' isn't a '$expected'" : "'$test_name' isn't defined";
    }
    elsif ($whatami eq 'object') {
        my $my_class = ref $got;
        $test_name = qq[An object of class '$my_class'];
        $name = "$test_name isa '$expected'";
        $diag = "The object of class '$my_class' isn't a '$expected'";
    }
    elsif ($whatami eq 'reference') {
        my $type = ref $got;
        $test_name = qq[A reference of type '$type'];
        $name = "$test_name isa '$expected'";
        $diag = "The reference of type '$type' isn't a '$expected'";
    }
    elsif ($whatami eq 'undef') {
        $test_name = 'undef';
        $name = "$test_name isa '$expected'";
        $diag = "$test_name isn't defined";
    }
    elsif($whatami eq 'class') {
        $test_name = qq[The class (or class-like) '$got'];
        $name = "$test_name isa '$expected'";
        $diag = "$test_name isn't a '$expected'";
    }
    else {
        die;
    }

    return($diag, $name);
}

sub throw_ok {
    my $self = shift;

    eval { shift->() };

    _tb->ok(!!$@, $self->_specific('_name', $_[0]));

    $self->_reset;

    $self;
}

sub throw {
    my $self = shift;
    my $code = shift;

    die 'The `throw` method expects code ref.' unless ref $code eq 'CODE';

    eval { $code->() };

    if (my $e = $@) {
        if (defined $_[0]) {
            _tb->like($e, $_[0], $_[1] || 'Thrown correctly');
            $self->_reset;
        }
        else {
            $self->got($e);
        }
    }
    else {
        _tb->ok(FAIL);
        $self->diag(q|Failed, because it's expected to throw an exeption, but not.|);
    }

    $self;
}

sub catch {
    my $self  = shift;
    my $regex = shift;

    my $ret = _tb->like(
        $self->_specific('_got', undef),
        $regex,
        $self->_specific('_name', $_[0]),
    );

    $self->_reset;

    $ret;
}

sub warnings_ok {
    my ($self, $code, $name) = @_;

    my $warn = 0;
    eval {
        local $SIG{__WARN__} = sub { $warn++ };
        $code->();
    };
    if (my $e = $@) {
        _tb->ok(FAIL);
        $self->diag("An exception happened: $e");
    }

    _tb->ok($warn > 0, $self->_specific('_name', $name));

    $self->_reset;

    $self;
}

sub warnings {
    my ($self, $code, $regex, $name) = @_;

    die 'The `warn` method expects code ref.' unless ref $code eq 'CODE';

    my @warns;
    eval {
        local $SIG{__WARN__} = sub { push @warns, shift };
        $code->();
    };
    if (my $e = $@) {
        _tb->ok(FAIL);
        $self->diag("An exception happened: $e");
    }

    if (scalar @warns > 0) {
        my $warn = join "\t", @warns;
        if (defined $regex) {
            _tb->like($warn, $regex, $self->_specific('_name', $name));
            $self->_reset;
        }
        else {
            $self->got($warn);
        }
    }
    else {
        _tb->ok(FAIL);
        $self->diag(q|Failed, because there is no warnings.|);
    }

    $self;
}

{
    no warnings 'once';
    *expect = *expected;

    *warn_ok    = *warnings_ok;
    *warning_ok = *warnings_ok;

    *warning = *warnings;

    *done = *done_testing;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Test::Arrow - Object-Oriented testing library


=head1 SYNOPSIS

    use Test::Arrow;

    my $arr = Test::Arrow->new;

    $arr->ok(1);
    $arr->got(1)->ok;

    $arr->expect(uc 'foo')->to_be('FOO');

    $arr->name('Test Name')
        ->expected('FOO')
        ->got(uc 'foo')
        ->is;

    $arr->expected(6)
        ->got(2 * 3)
        ->is_num;

    $arr->expected(qr/^ab/)
        ->got('abc')
        ->like;

    # `unlike` shows where a place could have matched if it's failed
    $arr->name('Unlike Fail example')
        ->expected(qr/b/)
        ->got('abc')
        ->unlike;
    #   Failed test 'Unlike Fail example'
    #   at t/unlike.t line 12.
    #                   'abc'
    #           matches '(?^:b)'
    #           matched at line: 1, offset: 2

    $arr->warnings(sub { warn 'Bar' })->catch(qr/^Ba/);
    $arr->throw(sub { die 'Baz' })->catch(qr/^Ba/);


=head1 DESCRIPTION

The opposite DSL.

=head2 MOTIVATION

B<Test::Arrow> is a testing helper as object-oriented operation. Perl5 has a lot of testing libraries. These libraries have nice DSL ways. However, sometimes we hope the Object as similar to ORM. It may slightly sound strange. But it'd be better to clarify operations and it's easy to understand what/how it is. Although there are so many arrows.


=head1 IMPORT OPTIONS

=head2 no_strict / no_warnings

By default, C<Test::Arrow> imports C<strict> and C<warnings> pragma automatically. If you don't want it, then you should pass 'no_strict' or 'no_warnings' option on use.

    use Test::Arrow; # Just use Test::Arrow, automatically turn on 'strict' and 'warnings'

Turn off 'strict' and 'warnings';

    use Test::Arrow qw/no_strict no_warnings/;

=head2 binary

By default, C<Test::Arrow> sets utf8 pragma globally to avoid warnings such as "Wide charactors". If you don't want it, then you should pass 'binary' option on use.

    use Test::Arrow qw/binary/; # utf8 pragma off


=head1 METHODS

=head3 new

The constructor.

    my $arr = Test::Arrow->new;

=head2 SETTERS

=head3 expected($expected)

The setter of expected value. $expected will be compared with $got

=head3 expect($expected)

The alias of C<expected> method.

=head3 got($got)

The setter of got value. $got will be compared with $expected

=head3 name($test_name)

The setter of the test name. If you ommit to set the test name, then it's automatically set.

B<Note> that the test name automatically set by L<Test::Name::FromLine>.

If you write one test as multiple lines like below,

    L5:  $arr->expected('FOO')
    L6:      ->got(uc 'foo')
    L7:      ->is;

then the output of test will be like below

    ok 1 - L5: $arr->expected('FOO')

You might expect the test name like below, however, it's actually being like above.

    ok 1 - L7:     ->is;

The test name is taken from the first line of each test.


=head2 TEST EXECUTERS

=head3 pass($test_name)

=head3 fail($test_name)

Just pass or fail

=head3 ok

    $arr->got($true)->ok;

More easy,

    $arr->ok($true);

=head3 is

=head3 isnt

Similar to C<is> and C<isnt> compare values with C<eq> and C<ne>.

    $arr->expect('FOO')->got(uc 'foo')->is;

=head3 is_num

=head3 isnt_num

Similar to C<is_num> and C<isnt_num> compare values with C<==> and C<!=>.

    $arr->expect(6)->got( 2 * 3 )->is_num;

=head3 to_be($got)

The $got will be compare with expected value.

    $arr->expect(uc 'foo')->to_be('FOO');

=head3 like

=head3 unlike

C<like> matches $got value against the $expected regex.

    $arr->expect(qr/b/)->got('abc')->like;

=head3 can_ok($class, @methods)

Checks to make sure the $class or $object can do these @methods
(works with functions, too).

    Test::Arrow->can_ok($class, @methods);
    Test::Arrow->can_ok($object, @methods);

=head3 isa_ok

    $arr->got($got_object)->expected($class)->isa_ok;

Checks to see if the given C<$got_object-E<gt>isa($class)>. Also checks to make sure the object was defined in the first place.

It works on references, too:

    $arr->got($array_ref)->expected('ARRAY')->isa_ok;


=head2 EXCEPTION TEST

=head3 throw_ok($code_ref)

It makes sure that $code_ref gets an exception.

    $arr->throw_ok(sub { die 'oops' });

=head3 throw($code_ref)

=head3 catch($regex)

The C<throw> method invokes $code_ref, and if it's certenly thrown an exception, then an exception message will be set as $got and the $regex in C<catch> method will be evaluated to $got.

    $arr->throw(sub { die 'Baz' })->catch(qr/^Ba/);

Above test is equivalent to below

    $arr->throw(sub { die 'Baz' })->expected(qr/^Ba/)->like;

Actually, you can execute a test even only C<throw> method

    $arr->throw(sub { die 'Baz' }, qr/^Ba/);

=head3 warnings_ok($code_ref)

It makes sure that $code_ref gets warnings.

    $arr->warnings_ok(sub { warn 'heads up' });

There are aliases of C<warnings_ok> method: C<warning_ok>, C<warn_ok>.

=head3 warnings($code_ref)

C<warnings> method is called like below:

    $arr->warnings(sub { warn 'heads up' })->catch(qr/^heads/);

C<warning> is an alias of C<warnings>.

=head2 BAIL OUT

=head3 BAIL_OUT($why)

Terminates tests.

=head2 UTILITIES

You can call below utilities methods even without an instance.

=head3 diag

Output message to STDERR

    $arr->diag('some messages');
    Test::Arrow->diag('some message');

=head3 note

Output message to STDOUT

    $arr->note('some messages');
    Test::Arrow->note('some message');

=head3 explain

If you call C<explain> method without args, then C<explain> method outputs object info (expected, got and name) as hash.

    $arr->name('foo')->expected('BAR')->got(uc 'bar')->explain->is;
    # {
    #   'expected' => 'BAR',
    #   'got' => 'BAR',
    #   'name' => 'foo'
    # }
    ok 1 - foo

If you call C<explain> method with arg, then C<explain> method just dumps it.

    $arr->expected('BAR')->got(uc 'bar')->explain({ baz => 123 })->is;
    # {
    #   'baz' => 123
    # }
    ok 1 - foo

=head3 done_testing

Declare of done testing.

    $arr->done_testing($number_of_tests_run);
    Test::Arrow->done_testing;

B<Note> that you must never put C<done_testing> inside an C<END { ... }> block.

=head3 done

Alias of C<done_testing>

=head2 CONSTANTS

=head3 PASS = 1

=head3 FAIL = 0


=head1 REPOSITORY

=begin html

<a href="https://github.com/bayashi/Test-Arrow/blob/master/README.pod"><img src="https://img.shields.io/badge/Version-0.11-green?style=flat"></a> <a href="https://github.com/bayashi/Test-Arrow/blob/master/LICENSE"><img src="https://img.shields.io/badge/LICENSE-Artistic%202.0-GREEN.png"></a> <a href="https://github.com/bayashi/Test-Arrow/actions"><img src="https://github.com/bayashi/Test-Arrow/workflows/master/badge.svg?_t=1582822443"/></a> <a href="https://coveralls.io/r/bayashi/Test-Arrow"><img src="https://coveralls.io/repos/bayashi/Test-Arrow/badge.png?_t=1582822443&branch=master"/></a>

=end html

Test::Arrow is hosted on github: L<http://github.com/bayashi/Test-Arrow>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Test::More>

L<Test::Kantan> - A behavior-driven development framework

L<Test::Builder>

L<Test::Name::FromLine>


=head1 LICENSE

C<Test::Arrow> is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0. (Note that, unlike the Artistic License 1.0, version 2.0 is GPL compatible by itself, hence there is no benefit to having an Artistic 2.0 / GPL disjunction.) See the file LICENSE for details.

=cut
