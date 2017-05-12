package JenaRuleEngineBuild;
use strict;
use warnings;
use Data::Dumper;
use Pod::Readme;
use Pod::Select;
use LWP::UserAgent;
use Archive::Extract;
use POSIX;
use Path::Class;
use File::Temp qw(tempfile);

use base qw( Module::Build );

my $JENA_URL = 'http://sourceforge.net/projects/jena/files/Jena/Jena-2.6.4/jena-2.6.4.zip/download';

sub clean_JENAROOT_share {
    my $self = shift;
    warn "Emptying " . $self->{properties}{JENAROOT_share};
    # warn -w $self->{properties}{JENAROOT_share};
    unlink $self->{properties}{JENAROOT_share};
    open my $fh_out, ">", $self->{properties}{JENAROOT_share}
        or die "Can't open JENAROOT share file: $@";
    print {$fh_out} "";
    close $fh_out;
}

# http://odyniec.net/blog/2011/11/github-friendly-readme-files-with-extutils-makemaker-and-module-build/
sub ACTION_docs {
    my $self = shift;

    unlink 'README';
    unlink 'README.pod';
    podselect({ -output => 'README.pod' }, $self->dist_version_from);

    my $parser = Pod::Readme->new();
    $parser->parse_from_file('./README.pod', 'README');
    warn "Built README";

    return $self->SUPER::ACTION_docs;
}

sub ACTION_clean {
    my $self = shift;

    $self->clean_JENAROOT_share;

    return $self->SUPER::ACTION_docs;
}

sub ACTION_code {
    my $self = shift;

    open my $fh, "<:utf8", $self->{properties}{JENAROOT_share} or die "Couldn't open shared file: $@";
    my $JENAROOT_file = <$fh>;
    close $fh;

    unless ($JENAROOT_file) {
        warn "Trying to detect JENAROOT to stash away in a shared file.";
        my $JENAROOT_prompt;
        if ($ENV{JENAROOT}) {
            $JENAROOT_prompt = $ENV{JENAROOT};
        }
        else {
            $JENAROOT_prompt = $self->prompt(
                "Enter path to Jena dist (JENAROOT), e.g. '~/Downloads/Jena-2.6.4': ",
                ""
            );
            if ( ! $JENAROOT_prompt || ! -e $JENAROOT_prompt ) {
                my $should_download = $self->y_n(
                    "No JENAROOT set and nothing in share/JENAROOT. Do you want to download Jena?",
                    "n"
                );
                if ($should_download) {
                    $JENAROOT_prompt = $self->download_jena_dialog;
                }
            }
        }
        if ( $JENAROOT_prompt ) {
            open my $fh_out, ">:utf8", $self->{properties}{JENAROOT_share};
            print $fh_out $JENAROOT_prompt;
            close $fh_out;
        }
    }

    return $self->SUPER::ACTION_code;
}

sub download_jena_dialog {
    my $self = shift;
    my $extract_path = $self->prompt(
        "Enter path to extract Jena to: ",
        ""
    );
    unless ( $extract_path
        || -e $extract_path
        || -d $extract_path
        || -w $extract_path )
    {
        warn "Invalid directory: '$extract_path'";
        return;
    }
    return $self->download_jena( $extract_path );
    warn "Failed to download Jena :(";
    return;
}

sub ACTION_distdir {
    my $self = shift;

    $self->clean_JENAROOT_share;
    return $self->SUPER::ACTION_distdir;
}

sub download_jena {
    my $self = shift;
    my ($extract_path) = @_;
    my ($temp_fh, $temp_fname) = tempfile;

    warn "Downloading Jena from $JENA_URL";
    my $ua = LWP::UserAgent->new;
    my $total = 0;
    my $percent_before = 0;
    my $content_callback = sub {
        my( $data, $response, $proto ) = @_;
        my $size = $response->header('Content-Length');
        $total+= length($data);
        print $temp_fh "$data"; # write data to file

        my ($size_in_mb, $total_in_mb) = map { sprintf "%5.2f", $_ /1024**2 } $size, $total;
        my $percent = sprintf "%5.2f", ($total/$size)*100;
        if (int $percent > $percent_before ) {
            $percent_before = int $percent;
            unless ( $percent_before % 5 ) {
                print "$percent% downloaded [ $total_in_mb MB / $size_in_mb MB ] mb\n"; # print percent downloaded
            }
        }
    };
    my $resp = $ua->get($JENA_URL, ':content_cb' => $content_callback);

    if ($resp->is_success) {
        warn "Extracting archive.";
        my $ae = Archive::Extract->new( archive => $temp_fname, type => 'zip' );
        my $extract_ok = $ae->extract( to => $extract_path );
        unless ($extract_ok) {
            warn "Couldn't extract $temp_fname to $extract_path.";
            return;
        }
        my $return_path = dir($extract_path)->file($ae->files->[0]);
        return "$return_path";
    }
    warn "Couldn't download jena: " . $resp->status;
}

1;
