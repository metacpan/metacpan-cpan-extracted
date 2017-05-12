package Test::AllModules;
use strict;
use warnings;
use Module::Pluggable::Object;
use Test::More ();

our $VERSION = '0.15';

my $USE_OK = sub {
    eval "use $_[0];"; ## no critic
    if (my $e = $@) {
        Test::More::note($e);
        return;
    }
    return 1;
};
my $USE_NO_IMPORT_OK = sub {
    eval "use $_[0] qw//;"; ## no critic
    if (my $e = $@) {
        Test::More::note($e);
        return;
    }
    return 1;
};


my $REQUIRE_OK = sub {
    eval "require $_[0];"; ## no critic
    if (my $e = $@) {
        Test::More::note($e);
        return;
    }
    return 1;
};

sub import {
    my $class = shift;

    my $caller = caller;

    no strict 'refs'; ## no critic
    for my $func (qw/ all_ok /) {
        *{"${caller}::$func"} = \&{"Test::AllModules::$func"};
    }
}

sub all_ok {
    my %param = @_;

    my $search_path = delete $param{search_path};
    my $use_ok      = delete $param{use}     || $param{use_ok};
    my $require_ok  = delete $param{require} || $param{require_ok};
    my $check       = delete $param{check};
    my $checks      = delete $param{checks};
    my $except      = delete $param{except};
    my $lib         = delete $param{lib};
    my $fork        = delete $param{fork};
    my $shuffle     = delete $param{shuffle};
    my $show_version = delete $param{show_version};
    my $no_import   = delete $param{no_import};
    my $before_hook = delete $param{before_hook};
    my $after_hook  = delete $param{after_hook};

    if ( _is_win() && $fork ) {
        Test::More::plan skip_all => 'The "fork" option is not supported in Windows';
        exit;
    }

    my @checks;
    push @checks, +{ test => $no_import ? $USE_NO_IMPORT_OK : $USE_OK, name => 'use: ' } if $use_ok;
    push @checks, +{ test => $REQUIRE_OK, name => 'require: ' } if $require_ok;

    if (ref($check) eq 'CODE') {
        push @checks, +{ test => $check, name => '', };
    }
    else {
        for my $code ( $check, @{ $checks || [] } ) {
            my ($name) = keys %{$code || +{}};
            my $test   = $name ? $code->{$name} : undef;
            if (ref($test) eq 'CODE') {
                push @checks, +{ test => $test, name => "$name: ", };
            }
        }
    }

    unless ($search_path) {
        Test::More::plan skip_all => 'no search path';
        exit;
    }

    Test::More::plan('no_plan');
    my @exceptions = @{ $except || [] };

    if ($fork) {
        require Test::SharedFork;
        Test::More::note("Tests run under forking. Parent PID=$$");
    }

    my $count = 0;
    for my $class (
        grep { !_is_excluded( $_, @exceptions ) }
            _classes($search_path, $lib, $shuffle) ) {
        $count++;
        for my $code (@checks) {
            next if $before_hook && $before_hook->($code, $class, $count);
            my $ret = _exec_test($code, $class, $count, $fork, $show_version);
            $after_hook && $after_hook->($ret, $code, $class, $count);
        }

    }

    Test::More::note( "total: $count module". ($count > 1 ? 's' : '') );
}

sub _exec_test {
    my ($code, $class, $count, $fork, $show_version) = @_;

    my $ret;

    unless ($fork) {
        $ret = _ok($code, $class, $count, undef, $show_version);
        return $ret;
    }

    my $pid = fork();
    die 'could not fork' unless defined $pid;

    if ($pid) {
        waitpid($pid, 0);
    }
    else {
        $ret = _ok($code, $class, $count, $fork, $show_version);
        exit;
    }

    return $ret;
}

sub _ok {
    my ($code, $class, $count, $fork, $show_version) = @_;

    my $test_name = "$code->{name}$class". ($fork && $fork == 2 ? "(PID=$$)" : '');

    my $ret;
    eval {
        $ret = $code->{test}->($class, $count);
    };

    if (my $e = $@) {
        Test::More::fail($test_name);
        Test::More::note("The Test failed: $e");
        return;
    }

    if ( Test::More::ok($ret, $test_name) ) {
        if ($show_version) {
            no strict 'refs'; ## no critic
            if ( my $version = ${"$class\::VERSION"} ) {
                Test::More::note("$class $version");
            }
        }
        return 1; # ok
    }
    else {
        my $got = defined $ret ? $ret : '';
        Test::More::note("The Test did NOT return true value. got: $got");
    }

    return;
}

sub _classes {
    my ($search_path, $lib, $shuffle) = @_;

    local @INC = @{ $lib || ['lib'] };
    my $finder = Module::Pluggable::Object->new(
        search_path => $search_path,
    );
    my @classes = ( $search_path, $finder->plugins );

    return $shuffle ? _shuffle(@classes) : sort(@classes);
}

# This '_shuffle' method copied
# from http://blog.nomadscafe.jp/archives/000246.html
sub _shuffle {
    map { $_[$_->[0]] } sort { $a->[1] <=> $b->[1] } map { [$_ , rand(1)] } 0..$#_;
}

# This '_any' method copied from List::MoreUtils.
sub _any (&@) { ## no critic
    my $f = shift;

    foreach ( @_ ) {
        return 1 if $f->();
    }
    return;
}

sub _is_excluded {
    my ( $module, @exceptions ) = @_;
    _any { $module eq $_ || $module =~ /$_/ } @exceptions;
}

sub _is_win {
    return ($^O && $^O eq 'MSWin32') ? 1 : 0;
}

1;

__END__

=head1 NAME

Test::AllModules - do some tests for modules in search path


=head1 SYNOPSIS

    use Test::AllModules;

    all_ok(
        search_path => 'MyApp',
        use => 1,
    );


Here is also same as above

    use Test::AllModules;

    all_ok(
        search_path => 'MyApp',
        check => sub {
            my $class = shift;
            eval "use $class;1;";
        },
    );


=head1 DESCRIPTION

Test::AllModules is do some tests for all modules in search path.


=head1 EXPORTED FUNCTIONS

=head2 all_ok(%args)

do C<check(s)> code as C<Test::More::ok()> for every module in search path.

=over 4

=item * B<search_path> => 'Class'

A namespace to look in. see: L<Module::Pluggable::Object>

=item * B<use> => boolean

If this option sets true value then do a load module(C<use>) test.

This parameter is optional.

=item * B<require> => boolean

If this option sets true value then do a load module(C<require>) test.

This parameter is optional.

=item * B<no_import> => boolean

If this option sets true value then do not import any function when a test module is loaded.

This parameter is optional.

=item * B<check> => \&test_code_ref or hash( TEST_NAME => \&test_code_ref )

=item * B<checks> => \@array: include hash( TEST_NAME => \&test_code_ref )

The code to execute each module. The code receives C<$class> and C<$count>. The result from the code will be passed to C<Test::More::ok()>. So, test codes must return true value if test is OK.

=item * B<except> => \@array: include scalar or qr//

Ignore modules.

This parameter is optional.

=item * B<lib> => \@array

Additional library paths.

This parameter is optional.

=item * B<fork> => 1:fork, 2:fork and show PID

If this option was set a value(1 or 2) then each check-code executes after forking.

This parameter is optional.

NOTE that this C<fork> option is NOT supported in Windows system.

=item * B<shuffle> => boolean

If this option was set the true value then modules will be sorted in random order.

This parameter is optional.

=item * B<show_version> => boolean

If this option was set the true value then the version of module will be shown if it's possible.

This parameter is optional.

=item * B<before_hook> => code ref

This code ref executes before test.

    before_hook => sub {
        my ($test_code, $class, $count) = @_;

        # ... do something ...

        return;
    },

B<NOTE> that if you return true value from before_hook, then the test will skip.

This parameter is optional.

=item * B<after_hook> => code ref

This code ref executes after test.

    after_hook  => sub {
        my ($ret, $test_code, $class, $count) = @_;

        # ... do something ...
    },

This parameter is optional.

=back


=head1 EXAMPLES

If you need the name of test, then you can use B<check> parameter: C<check => { test_name => sub { 'test' } }>

    use Test::AllModules;

    all_ok(
        search_path => 'MyApp',
        check => +{
            'use_ok' => sub {
                my ($class, $test_count) = @_;
                eval "use $class;1;";
            },
        },
    );

more tests, all options

    use Test::AllModules;

    all_ok(
        search_path => 'MyApp',
        use     => 1,
        require => 1,
        checks  => [
            +{
                'use_ok' => sub {
                    my $class = shift;
                    eval "use $class; 1;";
                },
            },
        ],
        except => [
            'MyApp::Role',
            qr/MyApp::Exclude::.*/,
        ],
        lib => [
            'lib',
            't/lib',
        ],
        shuffle   => 1,
        fork      => 1,
        no_import => 1,
    );


=head1 REPOSITORY

Test::AllModules is hosted on github
<http://github.com/bayashi/Test-AllModules>


=head1 AUTHOR

dann

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Test::LoadAllModules>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
