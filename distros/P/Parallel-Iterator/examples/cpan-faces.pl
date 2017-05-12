#!/usr/bin/perl

use strict;
use warnings;
use HTML::Tiny;
use LWP::UserAgent;
use File::Spec;
use File::Path;
use PerlIO::gzip;
use YAML qw<DumpFile LoadFile>;
use Getopt::Long;
use Parallel::Iterator qw( iterate );

$| = 1;

use constant MAIL_RC   => 'http://cpan.perl.org/authors/01mailrc.txt.gz';
use constant ICON_BASE => 'http://search.cpan.org/gravatar';
use constant AUTHOR    => 'http://search.cpan.org/~';
use constant OUTPUT    => 'cpan-faces';
use constant STATE     => File::Spec->catfile( OUTPUT, 'work.yml' );
use constant SIZE      => 80;

my $UPDATE = 0;

GetOptions( 'update' => \$UPDATE ) or die "cpan-gravatar.pl [--update]\n";

my $ua = LWP::UserAgent->new;

mkpath( OUTPUT );

my $icons = -f STATE ? LoadFile( STATE ) : {};

$SIG{INT} = sub {
    print "Got SIGINT, stopping\n";
    exit;
};

my $pid = $$;

END {
    if ( $$ == $pid ) {
        print "Saving ", STATE, "\n";
        DumpFile( STATE, $icons );

        my $index = File::Spec->catfile( OUTPUT, 'index.html' );
        open my $ih, '>', $index or die "Can't write $index ($!)\n";
        print $ih build_page( $icons );
        close $ih;
    }
}

update(
    $icons,
    $UPDATE
    ? sub {
        my ( $icons, $id ) = @_;
        return 0;
      }
    : sub {
        my ( $icons, $id ) = @_;
        return exists $icons->{$id}
          && $icons->{$id}->{state} eq 'done';
    }
);

sub update {
    my ( $icons, $skip_if ) = @_;
    print "Getting ", MAIL_RC, "\n";
    my $authors = get_authors( MAIL_RC );
    open my $ah, '<:gzip', $authors or die "Can't read $authors ($!)\n";

    my $iter = iterate(
        { workers => 20 },
        sub {
            my ( $id, undef ) = @_;
            print "Checking $id\n";
            return save_icon( lc( $id ) );
        },
        sub {
            while ( defined( my $line = <$ah> ) ) {
                next unless $line =~ /^alias\s+(\S+)/;
                return $1;
            }
            return;
        }
    );

    while ( my ( $id, $icon ) = $iter->() ) {
        $icons->{$id} = $icon;
        print "Icon saved as ", $icon->{name}, "\n"
          if $icon && $icon->{name};
    }
}

sub build_page {
    my $icons = shift;
    my $h     = HTML::Tiny->new;
    my @pic   = ();
    for my $id ( sort keys %$icons ) {
        my $icon = $icons->{$id};

        if ( my $img = $icon->{name} ) {
            push @pic,
              (
                $h->div(
                    { class => 'icon' },
                    $h->a(
                        { href => user_home( $id ) },
                        $h->img(
                            {
                                src    => File::Spec->abs2rel( $img, OUTPUT ),
                                width  => SIZE,
                                height => SIZE,
                                alt    => $id
                            }
                        ),
                    ),
                )
              );
        }
    }
    return $h->html(
        [
            $h->head(
                [
                    $h->title( 'The Faces of CPAN' ),
                    $h->link(
                        {
                            rel   => 'stylesheet',
                            href  => 'style.css',
                            type  => 'text/css',
                            media => 'screen'
                        }
                    )
                ]
            ),
            $h->body( [@pic] )
        ]
    );
}

sub get_authors {
    my $url  = shift;
    my $resp = $ua->get( $url );
    if ( $resp->is_success ) {
        my $name = File::Spec->catfile( OUTPUT, '01mailrc.txt.gz' );
        open my $ah, '>', $name or die "Can't write $name ($!)\n";
        binmode $ah;
        print $ah $resp->content;
        close $ah;
        return $name;
    }
    else {
        die $resp->status_line;
    }
}

sub user_home {
    my $id = shift;
    return AUTHOR . lc( $id );
}

sub save_icon {
    my $id = shift;
    my %ext_map = ( jpeg => 'jpg' );
    my ( $data, $type ) = eval { get_icon( $id ) };

    if ( $@ ) {
        return {
            error => $@,
            state => 'error'
        };
    }

    # if ( $data && $data ne $default_image && $type =~ m{ ^image/(\S+) }x ) {
    if ( $data && $type =~ m{ ^image/(\S+) }x ) {
        my $ext = $ext_map{$1} || $1;
        my $name = make_name( $id, $ext );
        open my $ih, '>', $name
          or die "Can't write $name ($!)\n";
        binmode $ih;
        print $ih $data;
        close $ih;
        return {
            name  => $name,
            state => 'done'
        };
    }

    return { state => 'done' };
}

sub make_name {
    my ( $email, $ext ) = @_;
    my %enc = (
        '@' => '-AT-',
        '.' => '-DOT-'
    );
    $email =~ s/([@.])/$enc{$1}||$1/eg;
    return File::Spec->catfile( OUTPUT, "$email.$ext" );
}

sub get_icon {
    my $id = shift;
    $id =~ s{^(((.).).*)$}{$3/$2/$1};
    TRY: for my $ext ( qw( jpg png ) ) {
        my $url  = ICON_BASE . '/' . $id . '.' . $ext;
        my $resp = $ua->get( $url );
        if ( $resp->is_success ) {
            return ( $resp->content, $resp->header( 'Content-Type' ) );
        }
        elsif ( $resp->code == 404 ) {
            next TRY;
        }
        else {
            die join ' ', $resp->code, $resp->message;
        }
    }
    return;
}

