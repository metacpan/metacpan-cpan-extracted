package QuadPres::Url;
$QuadPres::Url::VERSION = '0.28.0';
use strict;
use warnings;

use List::MoreUtils qw( notall );
use Carp ();

use parent 'QuadPres::Base';
use Data::Dumper qw/ Dumper /;

__PACKAGE__->mk_acc_ref(
    [
        qw(
            is_dir
            mode
            url
            )
    ]
);

sub _init
{
    $Carp::RefArgFormatter = sub {
        Dumper( [ $_[0] ], );
    };
    my $self = shift;

    my $url = shift;

    if ( !defined($url) )
    {
        Carp::confess("URL passed undef.");
    }

    if ( ref($url) eq 'ARRAY' )
    {
        if ( notall { defined } @$url )
        {
            Carp::confess("URL passed FOOundef.");
        }
        $self->url( [@$url] );
    }
    else
    {
        $self->url( [ split( /\//, $url ) ] );
    }
    $self->is_dir( shift || 0 );
    $self->mode( shift   || 'server' );

    return 0;
}

sub get_url
{
    my $self = shift;

    return [ @{ $self->url } ];
}

sub get_relative_url
{
    my $base = shift;

    my $url = $base->_get_url_worker(@_);

    return ( ( $url eq "" ) ? "./" : $url );
}

sub _get_url_worker
{
    my $base             = shift;
    my $to               = shift;
    my $slash_terminated = shift;

    my $prefix = "";

    my @this_url  = @{ $base->get_url() };
    my @other_url = @{ $to->get_url() };

    my $ret;

    my @this_url_bak  = @this_url;
    my @other_url_bak = @other_url;

    while (scalar(@this_url)
        && scalar(@other_url)
        && ( $this_url[0] eq $other_url[0] ) )
    {
        shift(@this_url);
        shift(@other_url);
    }

    if ( ( !@this_url ) && ( !@other_url ) )
    {
        if ( ( !$base->is_dir() ) ne ( !$to->is_dir() ) )
        {
            Carp::confess("Two identical URLs with non-matching is_dir()'s");
        }
        if ( !$base->is_dir() )
        {
            if ( scalar(@this_url_bak) )
            {
                return $prefix . $this_url_bak[-1];
            }
            else
            {
                die "Root URL is not a directory";
            }
        }
    }

    if ( ( $base->mode eq "harddisk" ) && ( $to->is_dir() ) )
    {
        push @other_url, "index.html";
    }

    $ret = "";

    if ($slash_terminated)
    {
        if ( ( scalar(@this_url) == 0 ) && ( scalar(@other_url) == 0 ) )
        {
            $ret = $prefix;
        }
        else
        {
            if ( !$base->is_dir() )
            {
                pop(@this_url);
            }
            $ret .= join( "/", ( map { ".." } @this_url ), @other_url );
            if ( $to->is_dir() && ( $base->mode ne "harddisk" ) )
            {
                $ret .= "/";
            }
        }
    }
    else
    {
        $ret .= $prefix;

        my @components;
        push @components,
            ( ("..") x ( $base->is_dir ? @this_url : @this_url - 1 ) );
        push @components, @other_url;
        $ret .= join( "/", @components );
        if (   ( $to->is_dir() )
            && ( $base->mode ne "harddisk" )
            && scalar(@components) )
        {
            $ret .= "/";
        }
    }

    #if (($to->is_dir()) && (scalar(@other_url) || $slash_terminated))

    return $ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

QuadPres::Url

=head1 VERSION

version 0.28.0

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/QuadPres>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/QuadPres>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=QuadPres>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/QuadPres>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/QuadPres>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/QuadPres>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/Q/QuadPres>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=QuadPres>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=QuadPres>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-quadpres at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=QuadPres>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/quad-pres>

  git clone https://github.com/shlomif/quad-pres.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/quadpres/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
