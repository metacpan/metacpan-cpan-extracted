package Pod::Webserver::Source;
# $Id: Source.pm,v 1.1 2005/01/05 12:26:39 cwest Exp $
use strict;
use vars qw[$LINK_PATH $PERLTIDY_ARGV $VERSION];
$PERLTIDY_ARGV = [qw[-html -npod -nnn]];
$VERSION = sprintf "%d.%02d", split m/\./, (qw$Revision: 1.1 $)[1];

sub _serve_thing {
    my ($self, $conn, $req) = @_;
    return $conn->send_error(405) unless $req->method eq 'GET';  # sanity

    my $path = $req->url;
    $path .= substr( ($ENV{PATH} ||''), 0, 0);  # to force-taint it.
  
    my $fs   = $self->{'__daemon_fs'};
    my $pods = $self->{'__modname2path'};
    my $resp = HTTP::Response->new(200);
    $resp->content_type( $fs->{"\e$path"} || 'text/html' );

    my $path = $req->url;
    $path .= substr( ($ENV{PATH} ||''), 0, 0);  # to force-taint it.
    $path =~ s{:+}{/}g;
    my $modname = $path;
       $modname =~ s{/+}{::}g;   $modname =~ s{^:+}{};
       $modname =~ s{:+$}{};     $modname =~ s{:+$}{::}g;

    $Pod::Webserver::Source::LINK_PATH = $req->url;
    return shift->_real_serve_thing(@_) unless $modname =~ /\.source$/;

    $modname =~ s/\.source$//;
    if ( $modname =~ m{^([a-zA-Z0-9_]+(?:::[a-zA-Z0-9_]+)*)$}s ) {
        $modname = $1;  # thus untainting
    } else {
        $modname = '';
    }
    Pod::Webserver::DEBUG() > 1 and print "Modname $modname source ($path)\n";

    if ( $pods->{$modname} ) {   # Is it known pod?
        $self->muse("I know $modname source as ", $pods->{$modname});
        __PACKAGE__->_serve_source($pods->{$modname}, $resp);
    } else {
        # If it's not known, look for it.
        #  This is necessary for indexless mode, and also useful just incase
        #  the user has just installed a new module (after the index was generated)
        my $fspath = $Pod::Simple::HTMLBatch::SEARCH_CLASS->new->find($modname);
    
        if( defined($fspath) ) {
            $self->muse("Found $modname source as $fspath");
            __PACKAGE__->_serve_source($fspath, $resp);
        } else {
            $resp = '';
            $self->muse("Can't find $modname in \@INC");
            unless( $self->{'httpd_has_noted_inc_already'} ++ ) {
                $self->muse("  \@INC = [ @INC ]");
            }
        }
    }
  
    $resp ? $conn->send_response( $resp ) : $conn->send_error(404);
    return;
}

sub _serve_source {
    my ($self, $fspath, $resp) = @_;
    
    my $output = '';
    if ( eval { require Perl::Tidy } ) {
        Perl::Tidy::perltidy(
            source      => $fspath,
            destination => \$output,
            argv        => $Pod::Webserver::Source::PERLTIDY_ARGV,
        );
    } else {
        $resp->header('Content-Type' => 'text/plain');
        local *PODFH;
        my $line   = 1;
        if ( open PODFH, "< $fspath" ) {
            $output .= sprintf "%5d  %s",
                               $line++,
                               $_ while <PODFH>;
            close PODFH;
        } else {
            $output = "Can't locate sources ($!)!\n";
        }
    }
    $resp->content($output);
    
    return;
}

sub _add_header_backlink {
  my $self = shift;
  return if $self->no_contents_links;
  my($page, $module, $infile, $outfile, $depth) = @_;
  $page->html_header_after_title( join '',
    $page->html_header_after_title || '',
    qq[<p class="backlinktop"><b><a name="___top" href="],
    $self->url_up_to_contents($depth),
    qq[" accesskey="1" title="All Documents">&lt;&lt;</a>],
    qq[ <a href="$Pod::Webserver::Source::LINK_PATH.source">Source</a>],
    qq[</b></p>\n],
  ) if $self->contents_file;
  return;
}

package Pod::Webserver;
no strict;

*_real_serve_thing   = \&_serve_thing;
*_serve_thing        = \&Pod::Webserver::Source::_serve_thing;
*add_header_backlink = \&Pod::Webserver::Source::_add_header_backlink;

1;

__END__

=head1 NAME

Pod::Webserver::Source - Plugin to Pod::Webserver for Viewing Source Code

=head1 SYNOPSIS

  use Pod::Webserver;
  use Pod::Webserver::Source; # Add this line to 'podwebserver' CLI.
  Pod::Webserver::httpd();

=head1 DESCRIPTION

This software adds source code viewing support to C<Pod::Webserver>.
Optional C<Perl::Tidy> support is included. If C<Perl::Tidy> has been
installed, the source code will be formatted using the following
C<Perl::Tidy> arguments: C<-html -npod -nnn>. You may override these
arguments by resetting the package variable
C<$Pod::Webserver::Source::PERLTIDY_ARGV> to a list reference or string
containing your personal preferences. Your F<~/.perltidyrc> file will be
honored in the same way C<Perl::Tidy> would honor it. If C<Perl::Tidy>
is not installed source code will be formatted in plain text and
prefixed with line numbers.

Viewing the source of a module is simple, just click on the link in the
header next to the back link called B<Source>.

Due to the nature of this code it is imperitive that
C<Pod::Webserver::Source> be loaded I<after> C<Pod::Webserver> as
demonstrated in the SYNOPSIS.

=head1 MODIFY F<podwebserver>

Here's a Perl-ish way to modify podwebserver as I know it, distributed
with version C<3.02> of C<Pod::Webserver>.

  perl -pi -e'eof and
    $_ .= "use Pod::Webserver::Source;\n"' `which podwebserver`

=head1 SEE ALSO

L<Pod::Webserver>,
C<Perl::Tidy>,
L<perl>.

=head1 THANKS

Much of this code was ripped from various pieces written by Sean Burke
who did all the hard work. I merely mutilated his code to produce this
functionality.

=head1 AUTHOR

Casey West, <F<casey@geeknest.com>>.

=head1 COPYRIGHT

  Copyright (c) 2005 Casey West.  All rights reserved.
  This module is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

=cut
