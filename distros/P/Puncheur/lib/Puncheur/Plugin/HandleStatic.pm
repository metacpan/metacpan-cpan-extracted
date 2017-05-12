package Puncheur::Plugin::HandleStatic;
use 5.010;
use strict;
use warnings;

use MIME::Base64;
use Encode;

our @EXPORT = qw/to_psgi/;

sub to_psgi {
    my ($self, %opts) = @_;
    $self = $self->new unless ref $self;

    my $app = $self->Puncheur::to_psgi;
    if (delete $opts{handle_static} || $self->{handle_static}) {
        my $vpath = sub {
            for my $dir (@{ $self->template_dir }) {
                return $dir if ref $dir eq 'HASH';
            }
        }->();
        require Plack::App::File;
        my $orig_app = $app;
        my $app_file_1;
        my $app_file_2;

        my $asset_dir = $self->asset_dir;
        my $static_dir = File::Spec->catdir( $asset_dir, 'static' );
        $app = sub {
            my $env = shift;
            my $path_info = $env->{PATH_INFO};
            if ($vpath and my $content = $vpath->{$path_info} and $path_info =~ m{^/}) {
                my $ct = Plack::MIME->mime_type($path_info);

                my $app_name = $self->app_name;
                my $is_text = qr/\b(?:text|xml|javascript|json)\b/;
                state $cache = {};
                if ($cache->{$app_name}{$path_info}) {
                    $content = $cache->{$app_name}{$path_info};
                }
                else {
                    if ($ct =~ $is_text) {
                        $content = encode($self->encoding, $content);
                    }
                    else {
                        $content = decode_base64($content);
                    }
                    $cache->{$app_name}{$path_info} = $content;
                }

                if ($ct =~ $is_text) {
                    my $encoding = $self->encoding;
                    $encoding = lc $encoding->mime_name if ref $encoding;
                    $ct .= "; charset=$encoding";
                }
                return [200, ['Content-Type' => $ct, 'Content-Length' => length($content)], [$content]];
            }
            elsif ($path_info =~ qr{^(?:/robots\.txt|/favicon\.ico)$}) {
                $app_file_1 ||= Plack::App::File->new({ root => $static_dir });
                return $app_file_1->call($env);
            }
            elsif ($path_info =~ m{^/static/}) {
                $app_file_2 ||= Plack::App::File->new({ root => $asset_dir });
                return $app_file_2->call($env);
            }
            else {
                return $orig_app->($env);
            }
        };
    }
    $app;
}

1;
