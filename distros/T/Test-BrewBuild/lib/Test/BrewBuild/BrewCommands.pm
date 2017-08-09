package Test::BrewBuild::BrewCommands;
use strict;
use warnings;

use version;

our $VERSION = '2.19';

my $log;

sub new {
    my ($class, $plog) = @_;

    my $self = bless {}, $class;

    $self->{min_perl_version} = '5.8.1';

    $self->{log} = $plog->child('BrewCommands');
    $log = $self->{log};

    $log->child('new')->_7("instantiating new object");

    $self->brew;

    return $self;
}
sub brew {
    my $self = shift;

    return $self->{brew} if $self->{brew};

    my $brew;

    if ($self->is_win){
        for (split /;/, $ENV{PATH}){
            if (-x "$_/berrybrew.exe"){
                $brew = "$_/berrybrew.exe";
                last;
            }
        }
    }
    else {
        $brew = 'perlbrew';
    }

    $log->child('brew')->_6("*brew cmd is: $brew") if $brew;
    $self->{brew} = $brew;

    return $brew;
}
sub info {
    my $self = shift;

    return $self->is_win
        ? `$self->{brew} available 2>nul`
        : `perlbrew available 2>/dev/null`;
}
sub installed {
    my ($self, $legacy, $info) = @_;

    $log->child('installed')->_6("cleaning up perls installed");

    return if ! $info;

    my @installed = $self->is_win
        ? $info =~ /(\d\.\d{2}\.\d(?:_\d{2}))(?!=_)\s+\[installed\]/ig
        : $info =~ /i.*?(perl-\d\.\d+\.\d+)/g;

    @installed = $self->_legacy_perls($legacy, @installed);

    return @installed;
}
sub using {
    my ($self, $info) = @_;

    $log->child( 'using' )->_6( "checking for which ver we're using" );

    if ($self->is_win) {
        my @installed
            = $info =~ /(\d\.\d{2}\.\d(?:_\d{2}))(?!=_)\s+\[installed\]\s+\*/ig;
        return $installed[0];
    }
    else {
        my $using = version->parse($])->normal;
        $using =~ s/v//;
        $using = "perl-$using";
        return $using;
    }
}
sub available {
    my ($self, $legacy, $info) = @_;

    $log->child('available')->_6("determining available perls");

    my @avail = $self->is_win
        ? $info =~ /(\d\.\d+\.\d+_\d+)/g
        : $info =~ /(?<!c)(perl-\d\.\d+\.\d+(?:-RC\d+)?)/g;

    @avail = $self->_legacy_perls($legacy, @avail);

    my %seen;
    $seen{$_}++ for @avail;
    return keys %seen;
}
sub install {
    my $self = shift;

    my $install_cmd = $self->is_win
        ? "$self->{brew} install"
        : 'perlbrew install --notest -j 4';

    $log->child('install')->_6("install cmd is: $install_cmd");

    return $install_cmd;
}
sub remove {
    my $self = shift;

    my $remove_cmd = $self->is_win
        ? "$self->{brew} remove"
        : 'perlbrew --yes uninstall';

    $log->child('remove')->_6("remove cmd is: $remove_cmd");

    return $remove_cmd;
}
sub is_win {
    my $is_win = ($^O =~ /Win/) ? 1 : 0;
    return $is_win;
}
sub info_cache {
    my ($self, $reset) = @_;

    if ($reset){
        $log->child('info_cache')->_7("resetting info_cache");
        $self->{info_cache} = 0;
    }

    if (! $self->{info_cache}){
        $self->{info_cache} = $self->is_win
            ? `$self->{brew} available 2>nul`
            : `perlbrew available 2>/dev/null`;

        $log->child('info_cache')->_7("cached availability info");
    }

    $log->child('info_cache')->_6("using cached availability info");

    return $self->{info_cache};
}
sub _legacy_perls {
    my ($self, $legacy, @perls) = @_;

    if ($legacy) {
        $log->child('_legacy_perls')->_7(
            "legacy is enabled, using perls older than 5.8.9"
        );
        return @perls if $legacy;
    }
    else {
        $log->child('_legacy_perls')->_7(
            "legacy is disabled, ignoring perls older than 5.8.9"
        );
    }

    my @avail;

    for my $ver_string (@perls){
        my ($ver) = $ver_string =~ /(5\.\d+\.\d+)/;

        if (version->parse($ver) > version->parse($self->{min_perl_version})){
            push @avail, $ver_string;
        }
    }
    return @avail;
}
1;

=head1 NAME

Test::BrewBuild::BrewCommands - Provides Windows/Unix *brew command
translations for Test::BrewBuild

=head1 METHODS

=head2 new

Returns a new Test::BrewBuild::BrewCommands object.

=head2 brew

Returns C<perlbrew> if on Unix, and the full executable path for
C<berrybrew.exe> if on Windows.

=head2 info

Returns the string result of C<*brew available>.

=head2 info_cache($reset)

Fetches, then caches the results of '*brew available'. This is due to the fact
that perlbrew does an Internet lookup for the information, and berrybrew will
shortly as well.

The cache is rebuilt on each new program run.

Parameters:

    $reset

Bool, optional. Set to a true value to flush out the cache so it will be
re-initialized.

=head2 installed($info)

Takes the output of C<*brew available> in a string form. Returns the currently
installed versions, formatted in a platform specific manner.

=head2 using($info)

Returns the current version of perl we're using. C<$info> is the output from
C<info()>.

=head2 available($legacy, $info)

Similar to C<installed()>, but returns all perls available. If C<$legacy> is
false, we'll only return C<perl> versions C<5.8.0+>.

=head2 install

Returns the current OS's specific C<*brew install> command.

=head2 remove

Returns the current OS's specific C<*brew remove> command.

=head2 is_win

Returns 0 if on Unix, and 1 if on Windows.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut
 
