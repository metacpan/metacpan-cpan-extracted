package Rex::Test::Spec;

use 5.006;
use strict;
use warnings FATAL => 'all';
my @EXPORT    = qw(describe context its it);
my @testFuncs = qw(ok is isnt like unlike is_deeply);
my @typeFuncs = qw(cron file gateway group iptables 
    pkg port process routes run service sysctl user);
push @EXPORT, @testFuncs, @typeFuncs, 'done_testing';

our ($obj, $msg);

use Test::More;

=head1 NAME

Rex::Test::Spec - Write Rex::Test like RSpec!

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';


=head1 SYNOPSIS

    use Rex::Test::Spec;
    describe "Nginx Test", sub {
        context run("nginx -t"), "nginx.conf testing", sub {
            like its('stdout'), qr/ok/;
        };
        context file("~/.ssh/id_rsa"), sub {
            is its('ensure'), 'file';
            is its('mode'), '0600';
            like its('content'), qr/name\@email\.com/;
        };
        context file("/data"), sub {
            is its('ensure'), 'directory';
            is its('owner'), 'www';
            is its('mounted_on'), '/dev/sdb1';
            isnt its('writable');
        };
        context service("nginx"), sub {
            is its('ensure'), 'running';
        };
        context pkg("nginx"), sub {
            is its('ensure'), 'present';
            is its('version'), '1.5.8';
        };
        context cron, sub {
            like its('www'), 'logrotate';
        };
        context gateway, sub {
            is it, '192.168.0.1';
        };
        context group('www'), sub {
            ok its('ensure');
        };
        context iptables, sub {
        };
        context port(80), sub {
            is its('bind'), '0.0.0.0';
            is its('proto'), 'tcp';
            is its('command'), 'nginx';
        };
        context process('nginx'), sub {
            like its('command'), qr(nginx -c /etc/nginx.conf);
            ok its('mem') > 1024;
        };
        context routes, sub {
            is_deeply its(1), {
                destination => $dest,
                gateway     => $gw,
                genmask     => $genmask,
                flags       => $flags,
                mss         => $mss,
                irtt        => $irtt,
                iface       => $iface,
            };
        };
        context sysctl, sub {
            is its('vm.swapiness'), 1;
        };
        context user('www'), sub {
            ok its('ensure');
            is its('home'), '/var/www/html';
            is its('shell'), '/sbin/nologin';
            is_deeply its('belong_to'), ['www', 'nogroup'];
        };
    };
    done_testing;

=head1 EXPORT FUNCTIONS

=head2 Spec definition functions

These are the functions you will use to define behaviors and run your specs:
I<describe> (and alias to I<context>), I<its> (alias to I<it>).

Normally suggest C<< describe "strings" >> and C<< context resource type object >>,
use C<< its(key) >> return value, C<< it >> return objects by default.

=cut

sub describe {
    my $code = pop;
    local $msg = '';
    local $obj;
    if ( defined $_[0] and ref($_[0]) =~ m/^Rex::Test::Spec::(\w+)$/ ) {
        $msg .= sprintf "%s(%s)", $1, $_[0]->{name};
        $obj = shift;
    };
    $msg .= join(' ', @_) if scalar @_;
    $code->();
}

BEGIN { *context = \&describe }

sub its {
    return $obj->getvalue(@_);
}

BEGIN { *it = \&its }

=head2 Test::More export functions

This now include I<is>, I<isnt>, I<ok>, I<is_deeply>, I<like>, I<unlike>, I<done_testing>.
You'll use these to assert correct behavior.

The resource type name will be automatic passed as testing message.

=cut

for my $func (@testFuncs) {
    no strict 'refs';
    no warnings;
    *$func = sub {
        Test::More->can($func)->(@_, $msg);
    };
};

BEGIN { *done_testing = \&Test::More::done_testing }

=head2 Rex resource type generation functions

Now support I<cron>, I<gateway>, I<iptables>, I<port>, I<routes>, I<service>,
I<user>, I<file>, I<group>, I<pkg>, I<process>, I<run>, I<sysctl>.

See L</"SYNOPSIS"> for more details.

=cut

sub AUTOLOAD {
    my ($method) = our $AUTOLOAD =~ /^[\w:]+::(\w+)$/;
    return if $method eq 'DESTROY';

    eval "use $AUTOLOAD";
    die "Error loading $AUTOLOAD." if $@;
    my @args = @_;
    unshift @args, 'name' if scalar @args == 1;
    return $AUTOLOAD->new(@args);
}

sub import {
    no strict 'refs';
    no warnings;
    for ( @EXPORT ) {
        *{"main::$_"} = \&$_;
    }
}

=head1 AUTHOR

Rao Chenlin(chenryn), C<< <rao.chenlin at gmail.com> >>

=head1 SEE ALSO
 
=over 4

=item 1. Rspec

L<http://rspec.info/>

=item 2. Serverspec

L<http://serverspec.org/>

=item 3. TDD (Test Driven Development)

L<http://en.wikipedia.org/wiki/Test-driven_development>

=item 4. BDD (Behavior Driven Development)

L<http://en.wikipedia.org/wiki/Behavior_Driven_Development>

=item 5. L<Test::More>

=item 6. L<Rex>

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-rex-test-spec at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rex-Test-Spec>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

Also accept pull requests and issue at L<https://github.com/chenryn/Rex--Test--Spec>.

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Rao Chenlin(chenryn).

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

L<http://www.apache.org/licenses/LICENSE-2.0/>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

1; # End of Rex::Test::Spec
