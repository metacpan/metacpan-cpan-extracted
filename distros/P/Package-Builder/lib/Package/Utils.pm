package Package::Utils;
require      Exporter;
our @ISA       = qw(Exporter);
our @EXPORT    = qw(escapeSpecialChars getScriptFileContent getFileContents getUserMap getUserId getGroupMap getGroupId getUniqElement getInputFileLine trim);    # Symbols to be exported by default


use warnings;
use strict;

use Cwd;
use File::stat;
use File::Path;
use File::Find;
use File::Basename;
use File::Spec;

=head1 NAME

Package::Util - The great new Package::Util!

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Package::Util;

    my $foo = Package::Util->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 escapeSpecialChars
=cut

sub escapeSpecialChars {
    my $line = shift;
    $line =~ s/(\$)/\\$1/g;
    $line =~ s/(\()/\\$1/g;
    $line =~ s/(\))/\\$1/g;

    # since a bug with \\
    #$line=~s/(\&))/\\$1/g;
    #$line=~s/(\\)/\\\\/g;
    return $line;
}


=head2 getScriptFileContent
=cut

sub getScriptFileContent {
    my $filename = shift;
    return "" if $filename eq "";
    return "" unless -f $filename;
    my @lines = getFileContents($filename);

    # remove first line
    my $interp;
    if ( defined( $lines[0] ) && $lines[0] =~ /^#!/ ) {

        #$lines[0] =~ s/#!(.*)/$1 << SCRIPT_END/;
        $lines[0] = "";

        #push @lines, "SCRIPT_END";
    }

    return join '', @lines;
}

=head2 getFileContents

=cut
sub getFileContents {
    my $filename = shift;

    open( SOURCE, "< $filename" )
      or die "Couldn't open $filename for reading: $!\n";
    my @lines = <SOURCE>;

    close(SOURCE);
    return @lines;
}

=head2 getUserMap

=cut
sub getUserMap {
    my $file = "/etc/passwd";

    open( FD, $file ) or die "$file : $!";
    my @lines = <FD>;
    close(FD);
    my %localUserMap = ();
    foreach my $line (@lines) {
        chomp( $line = $line );
        my ( $user, $passwd, $uid, $gid, $desc, $home, $shell ) =
          split( ":", $line );
        next unless defined $user;
        $desc = 'default comment' if ( $desc eq '' );
        $localUserMap{$uid}{'name'}    = $user;
        $localUserMap{$uid}{'gid'}     = $gid;
        $localUserMap{$uid}{'uid'}     = $uid;
        $localUserMap{$uid}{'comment'} = $desc;
        $localUserMap{$uid}{'shell'}   = $shell;
        $localUserMap{$uid}{'home'}    = $home;
    }

    return %localUserMap;
}

=head2 getUserId

=cut
sub getUserId {
    my $search_name = shift;
    my $file        = "/etc/passwd";

    open( FD, $file ) or die "$file : $!";
    my @lines = <FD>;
    close(FD);
    my %localUserMap = ();
    foreach my $line (@lines) {
        chomp( $line = $line );
        my ( $user, $passwd, $uid, $gid, $desc, $home, $shell ) =
          split( ":", $line );
        next unless defined $user;
        return $uid if ( $user eq $search_name );
        return $uid if ( $uid  eq $search_name );
    }

    return 0;
}

=head2 getGroupMap

=cut
sub getGroupMap {
    my $file = "/etc/group";

    open( FD, $file ) or die "$file : $!";
    my @lines = <FD>;
    close(FD);
    my %localGroupMap = ();
    foreach my $line (@lines) {
        chomp( $line = $line );
        my ( $group, $passwd, $gid, $members ) = split( ":", $line );
        $localGroupMap{$gid}{'gid'}     = $gid;
        $localGroupMap{$gid}{'name'}    = $group;
        $localGroupMap{$gid}{'members'} = $members;
    }

    return %localGroupMap;
}


=head2 getGroupId

=cut
sub getGroupId {
    my $search_group = shift;
    my $file         = "/etc/group";

    open( FD, $file ) or die "$file : $!";
    my @lines = <FD>;
    close(FD);
    my %localGroupMap = ();
    foreach my $line (@lines) {
        chomp( $line = $line );
        my ( $group, $password, $gid, $members ) = split( ":", $line );
        return $gid if ( $group eq $search_group );
        return $gid if ( $gid   eq $search_group );
    }

    return 0;
}


=head2 getUniqElement

=cut
sub getUniqElement {
    my %seen = ();
    return grep { !$seen{$_}++ } shift;
}


=head2 getInputFileLine

=cut
sub getInputFileLine {
    my $directory = shift;
    my @result = ();
    my $line   = "";
    if ( defined($directory) && ( -d $directory ) ) {
        find sub {
            my $line = $File::Find::name;
            $line .= "/" if -d;
            push @result, $line;
        }, ($directory);
    }
    else {

        while ( defined( $line = <> ) ) {
            $line = trim($line);
            push @result, $line;
        }
    }
    return @result;
}

=head2 trim

=cut
sub trim {
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}


=head1 AUTHOR

Jean-Marie RENOUARD, C<< <jmrenouard at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-package-builder at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Package-Util>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Package::Util


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Package-Util>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Package-Util>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Package-Util>

=item * Search CPAN

L<http://search.cpan.org/dist/Package-Util>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2007 Jean-Marie RENOUARD, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Package::Util
