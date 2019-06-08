package Test::BrewBuild::Regex;
use strict;
use warnings;

use Carp qw(croak);
use Exporter qw(import);

our $VERSION = '2.21';

our @EXPORT = qw(
    re_brewbuild
    re_brewcommands
    re_dispatch
    re_git
);

my %brewbuild = (

    check_failed => qr{failed.*?See\s+(.*?)\s+for details},

    check_result => qr{
        [Pp]erl-\d\.\d+\.\d+(?:_\w+)?
        \s+===.*?
        (?=(?:[Pp]erl-\d\.\d+\.\d+(?:_\w+)?\s+===|$))
    }xs,

    extract_dzil_dist_name => qr{^name\s+=\s+(.*)$},

    extract_dzil_dist_version => qr{^version\s+=\s+(.*)$},

    extract_errors => qr{
        cpanm\s+\(App::cpanminus\)
        .*?
        (?=(?:cpanm\s+\(App::cpanminus\)|$))
    }xs,

    extract_error_perl_ver => qr{cpanm.*?perl\s(5\.\d+)\s},

    extract_result => qr{
        ([Pp]erl-\d\.\d+\.\d+(?:_\w+)?\s+=+?)
        (\s+.*?)
        (?=(?:[Pp]erl-\d\.\d+\.\d+(?:_\w+)?\s+===|$))
    }xs,

    extract_perl_version => qr{^([Pp]erl-\d\.\d+\.\d+(_\d{2})?)},
);

my %brewcommands = (

    available_berrybrew => qr{(\d\.\d+\.\d+_\d+)},

    available_perlbrew => qr{(?<!c)(perl-\d\.\d+\.\d+(?:-RC\d+)?)},

    installed_berrybrew => qr{(\d\.\d{2}\.\d(?:_\d{2}))(?!=_)\s+\[installed\]}i,

    installed_perlbrew => qr{i\s+(perl-\d\.\d+\.\d+)},

    using_berrybrew => qr{(\d\.\d{2}\.\d(?:_\d{2}))(?!=_)\s+\[installed\]\s+\*}i,
);

my %dispatch = (

    extract_short_results => qr{(5\.\d{1,2}\.\d{1,2} :: \w{4})},
);

my %git = (

    extract_repo_name => qr{.*/(.*?)(?:\.git)*$},

    extract_commit_csum => qr{([A-F0-9]{40})\s+HEAD}i,
);

sub re_brewbuild {
    my $re = shift;
    _check(\%brewbuild, $re);
    return $brewbuild{$re};
}
sub re_brewcommands {
    my $re = shift;
    _check(\%brewcommands, $re);
    return $brewcommands{$re};
}
sub re_dispatch {
    my $re = shift;
    _check(\%dispatch, $re);
    return $dispatch{$re};
}
sub re_git {
    my $re = shift;
    _check(\%git, $re);
    return $git{$re};
}
sub _check {
    my ($module, $re) = @_;
    croak "regex '$re' doesn't exist for re_${module}()"
      if ! exists $module->{$re};
}

1;

=head1 NAME

Test::BrewBuild::Regex - Various regexes for the Test::BrewBuild platform

=head1 SYNOPSIS

    use Test::BrewBuild::Regex;

    my $results = ...;

    my $re = re_brewbuild('extract_perl_version');

    if ($results =~ /$re/){
        ...
    }

    # or, use the call inline with the deref trick

    if ($results =~ /${ re_brewbuild('extract_perl_version') }/){
        ...
    }

=head1 DESCRIPTION

Single location for all regexes used throughout Test::BrewBuild.

=head1 FUNCTIONS

All functions are exported by default.

=head2 re_brewbuild($re_name)

Provides regexes for the L<Test::BrewBuild> library.

Available regexes are:

    check_failed
    check_result
    extract_dist_name
    extract_dist_version
    extract_errors
    extract_error_perl_ver
    extract_result
    extract_perl_version

=head2 re_brewcommands($re_name)

Provides regexes for the L<Test::BrewBuild::BrewCommands> library.

Available regexes are:

    available_berrybrew
    available_perlbrew
    installed_berrybrew
    installed_perlbrew
    using_berrybrew

=head2 re_dispatch($re_name)

Provides regexes for the L<Test::BrewBuild::Dispatch> library.

Available regexes are:

    extract_short_results

=head2 re_git($re_name)

Provides regexes for the L<Test::BrewBuild::Git> library.

Available regexes are:

    extract_repo_name
    extract_commit_csum

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
