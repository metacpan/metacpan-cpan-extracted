package Test::BrewBuild::Plugin::TestAgainst;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.06';

my $state = bless {}, __PACKAGE__;

sub brewbuild_exec{
    shift; # throw away class
    my $log = shift;
    my $module = shift;
    return _cmd($module);
}    
sub _cmd {
    my $module = shift;

    #FIXME: we have to do the below nonsense, because DATA can't
    # be opened twice if we get called more than once per run

    if (! defined $state->{raw}){
        @{ $state->{raw} } = <DATA>;
    }

    my @cmd = @{ $state->{raw} };

    for (@cmd){
        s/%\[MODULE\]%/$module/g;
    }

    return @cmd;
}

1;

=head1 NAME

Test::BrewBuild::Plugin::TestAgainst - Test external modules against current
builds of the one being tested

=head1 SYNOPSIS

    brewbuild --plugin Test::BrewBuild::Plugin::TestAgainst --args Module::Name

=head1 DESCRIPTION

This is a plugin for L<Test::BrewBuild>. The plugin sub takes the name of a
module, and after testing and installing of the revision of the local module, 
it'll run the test suite of the external module to ensure it passes with the
current prerequisite codebase.

Useful mainly for testing reverse dependencies of the module you're currently
working on.

=head1 FUNCTIONS

=head2 brewbuild_exec($module_name);

Takes the name of the module, and returns back the appropriate configuration
commands to L<Test::Brewbuild>.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Same as L<Test::BrewBuild>

=cut

__DATA__
cpan App::cpanminus
cpanm --installdeps .
cpanm .
cpanm --test-only %[MODULE]%
