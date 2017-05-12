package Module::EnforceLoad;

my %LOAD_TREE;
my %RELOADS;
our $DEBUG = 0;

BEGIN {
    our $MOD;

    sub file_to_mod {
        my $mod = shift;
        $mod =~ s{/}{::}g;
        $mod =~ s{.pm$}{};
        return $mod;
    }

    *CORE::GLOBAL::require = sub {
        my $file = shift;
        return CORE::require($file) if $file =~ m/^[0-9\.]+$/;

        my $mod = file_to_mod($file);

        my @stack = ($mod);
        while (my $m = shift @stack) {
            $RELOADS{$m}++;
            push @stack => keys %{$LOAD_TREE{$m}};
        }
        $LOAD_TREE{$mod} = {};
        $LOAD_TREE{$MOD}->{$mod} = $LOAD_TREE{$mod} if $MOD;
        local $MOD = $mod;
        CORE::require($file);
    };
}

use strict;
use warnings;
use Sub::Util qw/prototype set_prototype subname/;
use List::Util qw/first/;

our $VERSION = '0.000002';

our $ENFORCE = 0;
my %OVERRIDE = (
    __PACKAGE__,      1,
    'UNIVERSAL'    => 1,
    'CORE'         => 1,
    'CORE::GLOBAL' => 1,
);

sub import {
    my $class = shift;
    my $caller = caller;
    no strict 'refs';
    *{"$caller\::enforce"} = \&enforce;
}

sub enforce {
    %RELOADS = ();
    replace_subs(scalar caller);
    replace_subs(file_to_mod($_)) for keys %LOAD_TREE;
    $ENFORCE = 1;
}

sub replace_subs {
    my $mod = shift;
    return if $OVERRIDE{$mod}++;
    local $ENFORCE = 0;

    my $stash;
    {
        no strict 'refs';
        $stash = \%{"$mod\::"};
    }

    for my $i (keys %$stash) {
        my $orig = $mod->can($i) or next;
        next if $OVERRIDE{"$mod\::$i"}++;
        next if $i eq 'DESTROY';
        next if $i eq 'can';
        my $prototype = prototype($orig);

        my $new = sub {
            if ($ENFORCE && !$RELOADS{$mod}) {
                $ENFORCE = 0;

                my ($pkg, $file, $line) = caller;
                my $name = subname($orig);
                my $pname = $name =~ s/::[^:]+$//r;
                my $str = "Tried to use $name without loading $pname at $file line $line.\n";
                my $l = 1;
                while (my @caller = caller($l++)) {
                    $str .= "    $caller[3] called at $caller[1] line $caller[2].\n";
                }

                if ($DEBUG) {
                    require Data::Dumper;
                    $str .= Data::Dumper::Dumper({
                        LOAD_TREE => \%LOAD_TREE,
                        RELOADS   => \%RELOADS,
                    });
                }

                die $str;
            }
            goto &$orig;
        };
        set_prototype($prototype, $new);

        no strict 'refs';
        no warnings 'redefine';
        *{"$mod\::$i"} = $new;
    }
}

1;

__END__


=pod

=encoding UTF-8

=head1 NAME

Module::EnforceLoad - Make sure your modules load their deps in preload
environments.

=head1 DESCRIPTION

Unit tests are good. Unit tests can also be slow. Unit tests run faster if you
preload all your modules and then fork for each test. This scenario will fail
to catch when you forget to load a dependancy as the preload will satisfy it.
This can lead to errors you find in production instead of tests.

This module helps with the problem in the last paragraph. You load this module
B<FIRST> then load your preloads, then call C<enforce()>. From that point on
the code will die if you use a sub defined in one of your preloads, unless
something uses C<use> or C<require> to try to load the module after you call
C<enforce()>.

=head1 SYNOPSIS

    package My::Preloader;
    use Module::EnforceLoad;

    # Preloads
    use Moose;
    use Scalar::Util;
    use Data::Dumper;

    enforce();

    do 'my_test.pl';

my_test.pl

    # Will die, despite being preloaded
    # (we use eval to turn it into a warning for this example)
    eval { print Data::Dumper::Dumper('foo'); 1 } or warn $@;

    require Data::Dumper;

    # Now this will work fine.
    print Data::Dumper::Dumper('foo');

=head1 HOW IT WORKS

This module replaces C<CORE::GLOBAL::require> at which point anything that is
loaded via C<use> or C<require> will be added to a dependancy tree structure.
Once you run C<enforce()> it will walk the symbol table and replace all defined
subs with wrapper that call the original. This will also start recording a list
of modules that get required AFTER C<enforce()>. If you call any function
without first loading the module it was defined in, an exception is thrown.
Because of the tree initially built we can also track indirect loading.

=head1 SOURCE

The source code repository for Test2 can be found at
F<http://github.com/exodist/Module-EnforceRequire>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2016 Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
