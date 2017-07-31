package Module::CheckDep::Version;

use 5.006;
use strict;
use warnings;
use version;

our $VERSION = '0.08';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(check_deps);

use MetaCPAN::Client;

my $mc = MetaCPAN::Client->new;

sub check_deps {
    my ($author, %args) = @_;

    die "check_deps() requires an \"AUTHOR\" param\n" if ! $author;

    my $module = $args{module};
    my $all = $args{all};
    my $custom_handler = $args{handler};
    my $return = $args{return};
    my $ignore_any = defined $args{ignore_any} ? $args{ignore_any} : 1;
   
    my $author_modules = _author_modules($author);

    my %needs_attention;

    for my $dist (keys %{ $author_modules }){
        next if $module && ($module ne $dist);

        $dist =~ s/::/-/g;

        my $release = $mc->release($dist);
        my $deps = $release->{data}{dependency};

        for my $dep (@$deps){
            my $dep_mod = $dep->{module};
            my $dep_ver = $dep->{version};

            next if $dep_mod eq 'perl';
            
            if ($ignore_any && $dep_ver == 0){
                next;
            }

            $dep_ver .= '.00' if $dep_ver !~ /\./;

            next if ! $all && ! $author_modules->{$dep_mod};

            my $cur_ver;

            if ($author_modules->{$dep_mod}){
                $cur_ver = $author_modules->{$dep_mod};
            }
            else {
                my $dep_mod_normalized = $dep_mod;
                $dep_mod_normalized =~ s/::/-/g;
                my $dep_dist;

                my $dist_found_ok = eval {
                    $dep_dist = $mc->release($dep_mod_normalized);
                    1;
                };

                next if ! $dist_found_ok;
                $cur_ver = $dep_dist->{data}{version};
            }

            $dep_ver = version->parse($dep_ver);
            $cur_ver = version->parse($cur_ver);

            if ($dep_ver != $cur_ver){
                $needs_attention{$dist}{$dep_mod}{cur_ver} = $cur_ver;
                $needs_attention{$dist}{$dep_mod}{dep_ver} = $dep_ver;
            }
        }
    }

    if (defined $custom_handler){
       $custom_handler->(\%needs_attention);
    }
    else {
        _display(\%needs_attention) if ! $return;
    }

    return \%needs_attention;
}
sub _author_modules {
    my ($author) = @_;

    my $query = {
        all => [
            { author => $author },
            { status => 'latest' },
        ],
    };

    my $limit = { 
        '_source' => [
            qw(distribution version)
        ] 
    };

    my $releases = $mc->release($query, $limit);

    my %rel_info;

    while (my $rel = $releases->next){
        my $dist = $rel->distribution;
        $dist =~ s/-/::/g;
        $rel_info{$dist} = $rel->version;
    }

    return \%rel_info;
}
sub _display {
    my $dists = shift;

    for my $dist (keys %$dists){
        print "$dist:\n";
        for (keys %{ $dists->{$dist} }){
            print "\t$_:\n" .
                  "\t\t$dists->{$dist}{$_}{dep_ver} -> " .
                  "$dists->{$dist}{$_}{cur_ver}\n";
        }
        print "\n";
    }
}
sub __placeholder {} # vim folds

1;
__END__

=head1 NAME

Module::CheckDep::Version - Compare the required version of a distribution's
prerequisites against their most recent release

Module::CheckDep::Version - Compare v

=for html
<a href="http://travis-ci.org/stevieb9/module-checkdep-version"><img src="https://secure.travis-ci.org/stevieb9/module-checkdep-version.png"/>
<a href='https://coveralls.io/github/stevieb9/module-checkdep-version?branch=master'><img src='https://coveralls.io/repos/stevieb9/module-checkdep-version/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

    use Module::CheckDep::Version qw(check_deps);

    # list only the author's own prereqs that have newer versions

    check_deps('STEVEB');
    
    # list all prereqs that have newer versions by all authors

    check_deps('STEVEB', all => 1);

    # check only a single distribution

    check_deps('STEVEB', module => 'RPi::WiringPi');

    # return the data within a hash reference instead of printing

    check_deps('STEVEB', return => 1);

    # send in your own custom function to manage the data

    check_deps('STEVEB', handler => \&my_handler);

    sub my_handler {
        # this is the actual code from the default
        # handler

        my $dists = shift;
        
        for my $dist (keys %$dists){
            print "$dist:\n";
            for my $dep (keys %{ $dists->{$dist} }){
                print "\t$_:\n" .
                      "\t\t$dists->{$dist}{$dep}{dep_ver} -> " .
                      "$dists->{$dist}{$dep}{cur_ver}\n";
            }
            print "\n";
        }
    }

    # by default, we skip over dependencies that are listed with a version of
    # 0 (zero). This version value means 'any version of this prereq is fine'.
    # You can include these in your listing if you wish

    check_deps('STEVEB', ignore_any => 0);

=head1 DESCRIPTION

WARNING: It is prudent to only increase the required version of a prerequisite
distribution when absolutely necessary. Please don't arbitrarily bump prereq
version numbers just because newer versions of a software have been released.

This module was originally designed so that I could easily track prereqs that I
wrote that my other distributions require. Again... please don't arbitrarily
bump prerequisite version numbers unless there is a functional requirement to do
so.

For example, my L<RPi::WiringPi> distribution uses about a dozen other C<RPI::>
distributions. If I update some of those (they are all stand-alone),
periodically I want to check C<RPi::WiringPi> to ensure I'm requiring the most
up-to-date functionality of the individual component distributions within the
top level one that includes them all.

See L</checkdep> for a binary script that you can use directly instead of
using this API. You can also run C<perldoc checkdep> at the command line after
installation to read its manual.

This module retrieves all L<CPAN|http://cpan.org> distributions for a single
author, extracts out all of the dependencies for each distribution, then lists
all dependencies that have updated versions so you're aware which prerequisite
distributions have newer releases than what is currently being required.

Can list only the prerequisites that are written by the same author, or
optionally all prerequisite distributions by all authors.

=head1 EXPORT_OK

We export only a single function upon request: C<check_deps()>.

=head1 FUNCTIONS

=head2 check_deps($author, [%args])

Fetches a list of a CPAN author's distributions using L<MetaCPAN::Client>,
extracts out the list of each distribution's prerequisite distributions,
compares the required version listed against the currently available version
and either returns or prints to the screen a list of each dependency that
has had newer versions published.

Parameters:

    $author

Mandatory, String: A valid CPAN author's user name.

    module => 'Some::Module'

Optional, String. The name of a valid CPAN distribution by the author
specified. We'll only look up the results for this single distribution if this
param is sent in.

    all => 1

Optional, Bool. By default, we'll only list prerequisites by the same
C<$author>. Setting this to true will list prereq version bumps required for
all listed prerequisite distributions. Defaults to off/false.

    return => 1

Optional, Bool. By default we print results to C<STDOUT>. Set this to true to
have the data in hash reference form returned to you instead. Default is
off/false.

    ignore_any => 0

Optional, Bool. By default, we skip over any prerequisite modules that are
listed with a version of 0 (zero). This says that any version of the
prerequisite module will do. Set this parameter to a false value to have those
distributions listed as well. Defaults to on/true.

    handler => \&function

Optional, code reference. You can send in a reference to a function you create
to handle the data. See L</SYNOPSIS> for an example of the format of the
single hash reference we pass into your function.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
