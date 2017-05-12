package Pod::Cpandoc;
use 5.8.1;
use strict;
use warnings;
use base 'Pod::Perldoc';
use HTTP::Tiny;
use File::Temp 'tempfile';
use JSON::PP ();

our $VERSION = '0.16';

sub opt_c { shift->_elem('opt_c', @_) }

sub live_cpan_url {
    my $self   = shift;
    my $module = shift;

    if ($self->opt_c) {
        my $module_json = $self->fetch_url("https://fastapi.metacpan.org/v1/module/$module?fields=distribution");
        if (!$module_json) {
            die "Unable to fetch changes for $module";
        }
        my $module_details = JSON::PP::decode_json($module_json);
        my $dist = $module_details->{distribution};
        return "https://fastapi.metacpan.org/v1/changes/$dist?fields=content";
    }
    elsif ($self->opt_m) {
        return "https://fastapi.metacpan.org/v1/source/$module";
    }
    else {
        return "https://fastapi.metacpan.org/v1/pod/$module?content-type=text/x-pod";
    }
}

sub unlink_tempfiles {
    my $self = shift;
    return $self->opt_l ? 0 : 1;
}

sub fetch_url {
    my $self = shift;
    my $url  = shift;

    $self->aside("Going to query $url\n");

    if ($ENV{CPANDOC_FETCH}) {
        print STDERR "Fetching $url\n";
    }

    my $ua = HTTP::Tiny->new(
        agent      => "cpandoc/$VERSION",
        verify_SSL => 1,
    );

    my $response = $ua->get($url);

    if (!$response->{success}) {
        $self->aside("Got a $response->{status} error from the server\n");
        return;
    }

    $self->aside("Successfully received " . length($response->{content}) . " bytes\n");
    return $response->{content};
}

sub query_live_cpan_for {
    my $self   = shift;
    my $module = shift;

    my $url = $self->live_cpan_url($module);
    my $content = $self->fetch_url($url);

    if ($self->opt_c) {
        $content = JSON::PP::decode_json($content)->{content};
        $content = "=pod\n\n$content";
    }

    return $content;
}

sub scrape_documentation_for {
    my $self   = shift;
    my $module = shift;

    my $content;
    if ($module =~ m{^https?://}) {
        die "Can't use -c on arbitrary URLs, only module names"
            if $self->opt_c;
        $content = $self->fetch_url($module);
    }
    else {
        $content = $self->query_live_cpan_for($module);
    }
    return if !defined($content);

    $module =~ s{.*/}{}; # directories and/or URLs with slashes anger File::Temp
    $module =~ s/::/-/g;
    my ($fh, $fn) = tempfile(
        "${module}-XXXX",
        SUFFIX => ($self->opt_c ? ".txt" : ".pm"),
        UNLINK => $self->unlink_tempfiles,
        TMPDIR => 1,
    );
    print { $fh } $content;
    close $fh;

    return $fn;
}

our $QUERY_CPAN;
sub grand_search_init {
    my $self = shift;

    if ($self->opt_c) {
        return $self->scrape_documentation_for($_[0][0]);
    }

    local $QUERY_CPAN = 1;
    return $self->SUPER::grand_search_init(@_);
}

sub searchfor {
    my $self = shift;
    my ($recurse,$s,@dirs) = @_;

    my @found = $self->SUPER::searchfor(@_);

    if (@found == 0 && $QUERY_CPAN) {
        $QUERY_CPAN = 0;
        return $self->scrape_documentation_for($s);
    }

    return @found;
}

sub opt_V {
    my $self = shift;

    print "Cpandoc v$VERSION, ";

    return $self->SUPER::opt_V(@_);
}

1;

__END__

=head1 NAME

Pod::Cpandoc - perldoc that works for modules you don't have installed

=head1 SYNOPSIS

    cpandoc File::Find
        -- shows the documentation of your installed File::Find

    cpandoc Acme::BadExample
        -- works even if you don't have Acme::BadExample installed!

    cpandoc -c Text::Xslate
        -- shows the changelog file for Text::Xslate

    cpandoc -v '$?'
        -- passes everything through to regular perldoc

    cpandoc -m Acme::BadExample | grep system
        -- options are respected even if the module was scraped

    vim `cpandoc -l Web::Scraper`
        -- getting the idea yet?

    cpandoc http://darkpan.org/Eval::WithLexicals::AndGlobals
        -- URLs work too!

=head1 DESCRIPTION

C<cpandoc> is a perl script that acts like C<perldoc> except that
if it would have bailed out with
C<No documentation found for "Uninstalled::Module">, it will instead
scrape a CPAN index for the module's documentation.

One important feature of C<cpandoc> is that it I<only> scrapes the
live index if you do not have the module installed. So if you use
C<cpandoc> on a module you already have installed, then it will
just read the already-installed documentation. This means that the
version of the documentation matches up with the version of the
code you have. As a fringe benefit, C<cpandoc> will be fast for
modules you've installed. :)

All this means that you should be able to drop in C<cpandoc> in
place of C<perldoc> and have everything keep working. See
L</SNEAKY INSTALL> for how to do this.

If you set the environment variable C<CPANDOC_FETCH> to a true value,
then we will print a message to STDERR telling you that C<cpandoc> is
going to make a request against the live CPAN index.

=head1 TRANSLATIONS

=over 4

=item Japanese

    Japanese documentation can be found at
    L<http://perldoc.jp/docs/modules/Pod-Cpandoc-0.09/Cpandoc.pod>,
    contributed by @bayashi.

=back

=head1 SNEAKY INSTALL

    cpanm Pod::Cpandoc

    then: alias perldoc=cpandoc
    or:   function perldoc () { cpandoc "$@" }

    Now `perldoc Acme::BadExample` works!

C<perldoc> should continue to work for everything that you're used
to, since C<cpandoc> passes all options through to it. C<cpandoc>
is merely a subclass that falls back to scraping a CPAN index when
it fails to find your queried file in C<@INC>.

=head1 SEE ALSO

The sneaky install was inspired by L<https://github.com/defunkt/hub>.

L<http://tech.bayashi.jp/archives/entry/perl-module/2011/003305.html>

L<http://perladvent.org/2011/2011-12-15.html>

L<http://sartak.org/talks/yapc-na-2011/cpandoc/>

=head1 AUTHOR

Shawn M Moore C<code@sartak.org>

=head1 COPYRIGHT

Copyright 2011-2013 Shawn M Moore.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

