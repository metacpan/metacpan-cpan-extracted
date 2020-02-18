package Test::Arrow;
use strict;
use warnings;
use Test::Builder::Module;
use Test::Name::FromLine;
use Text::MatchedPosition;

our $VERSION = '0.03';

our @ISA = qw/Test::Builder::Module/;

my $CLASS = __PACKAGE__;

sub new {
    bless {}, shift;
}

sub _reset {
    my ($self) = @_;

    delete $self->{_name};
    delete $self->{_expected};
    delete $self->{_got};

    $self;
}

sub pass {
    my $self = shift;

    Test::Arrow->builder->ok(1, @_);
}

sub fail {
    my $self = shift;

    Test::Arrow->builder->ok(0, @_);
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

sub expect { shift->expected(@_) }

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

    $CLASS->builder->ok($got, $test_name);

    $self->_reset;

    $value;
}

sub to_be {
    my ($self, $got, $name) = @_;

    my $expected = $self->{_expected};
    my $test_name = $self->_specific('_name', $name);

    my $ret = $CLASS->builder->is_eq($got, $expected, $test_name);

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
    my $ret = $CLASS->builder->$method($got, $expected, $test_name);

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

    my $ret = $CLASS->builder->unlike($got, $expected, $test_name);

    $self->_reset;

    return $ret if $ret eq '1';

    my $pos = Text::MatchedPosition->new($got, $expected);
    return $CLASS->builder->diag( sprintf <<'DIAGNOSTIC', $pos->line, $pos->offset );
          matched at line: %d, offset: %d
DIAGNOSTIC
}

sub diag {
    my $self = shift;

    $CLASS->builder->diag(@_);

    $self;
}

sub note {
    my $self = shift;

    $CLASS->builder->note(@_);

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
        $self->diag($CLASS->builder->explain($hash));
    }
    else {
        $self->diag($CLASS->builder->explain(@_));
    }

    $self;
}

sub done_testing {
    my $self = shift;

    $CLASS->builder->done_testing(@_);

    $self;
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


=head1 DESCRIPTION

The opposite DSL.

=head2 MOTIVATION

B<Test::Arrow> is a testing helper as object-oriented operation. Perl5 has a lot of testing libraries. These libraries have nice DSL ways. However, sometimes we hope the Object as similar to ORM. It may slightly sound strange. But it'd be better to clarify operations and it's easy to understand what/how it is. Although there are so many arrows.


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

=head3 pass

=head3 fail

Just pass or fail

=head3 ok

    $arr->got($true);

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

=head2 UTILITIES

You can call below utilities even without an instance.

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

If you call C<explain> method with arg, then C<explain> method dumps it.

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


=head1 REPOSITORY

=begin html

<a href="https://github.com/bayashi/Test-Arrow/blob/master/README.pod"><img src="https://img.shields.io/badge/Version-0.03-green?style=flat"></a> <a href="https://github.com/bayashi/Test-Arrow/blob/master/LICENSE"><img src="https://img.shields.io/badge/LICENSE-Artistic%202.0-GREEN.png"></a> <a href="https://github.com/bayashi/Test-Arrow/actions"><img src="https://github.com/bayashi/Test-Arrow/workflows/build/badge.svg?_t=1582048984&branch=master"/></a> <a href="https://coveralls.io/r/bayashi/Test-Arrow"><img src="https://coveralls.io/repos/bayashi/Test-Arrow/badge.png?_t=1582048984&branch=master"/></a>

=end html

Test::Arrow is hosted on github: L<http://github.com/bayashi/Test-Arrow>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Test::More>

L<Test::Kantan> - A behavior-driven development framework

L<Test::Builder::Module>

L<Test::Name::FromLine>


=head1 LICENSE

C<Test::Arrow> is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0. (Note that, unlike the Artistic License 1.0, version 2.0 is GPL compatible by itself, hence there is no benefit to having an Artistic 2.0 / GPL disjunction.) See the file LICENSE for details.

=cut
