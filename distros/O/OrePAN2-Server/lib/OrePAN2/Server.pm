package OrePAN2::Server;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.04";

use File::Copy ();
use File::Spec;
use File::Temp ();
use Plack::Request;
use OrePAN2::Injector;
use OrePAN2::Indexer;

sub uploader {
    my ($class, %args) = @_;
    my $directory      = $args{directory} || 'orepan';
    my $compress_index = 1;
    $compress_index = $args{compress_index} if exists $args{compress_index};

    return sub {
        my $env = shift;
        my $req = Plack::Request->new($env);
        return [404, [], ['NOT FOUND']] if $req->path_info !~ m!\A/?\z!ms;

        if ($req->method eq 'POST') {
            eval {
                my ($module, $author);

                my $tempdir = File::Temp::tempdir( CLEANUP => 1 );
                if (my $upload = $req->upload('pause99_add_uri_httpupload')) {
                    # request from CPAN::Uploader
                    $module = File::Spec->catfile($tempdir, $upload->filename);
                    File::Copy::move $upload->tempname, $module;
                    $author = $req->param('HIDDENNAME');
                }
                else {
                    $module = $req->param('module'); # can be a git repo.
                    $author = $req->param('author') || 'DUMMY';
                }
                return [404, [], ['NOT FOUND']] if !$module && !$author;
                $author = uc $author;

                my $injector = OrePAN2::Injector->new(
                    directory => $directory,
                    author    => $author,
                );
                $injector->inject($module);

                OrePAN2::Indexer->new(directory => $directory)->make_index(
                    no_compress => !$compress_index,
                );
            };

            if (my $err = $@) {
                warn $err . '';
                return [500, [], [$err.'']];
            }
        }
        else {
            return [405, [], ['Method Not Allowed']];
        }

        return [200, [], ['OK']];
    }
}


1;
__END__

=encoding utf-8

=head1 NAME

OrePAN2::Server - DarkPAN Server

=head1 SYNOPSIS

    #launch orepan2 standalone server http://localhost:5888/
    % orepan2-server.pl -p 5888

    #upload git managed module to my orepan2 by curl 
    curl --data-urlencode 'module=git@github.com:Songmu/p5-App-RunCron.git' --data-urlencode 'author=SONGMU' http://localhost:5888/
    curl --data-urlencode 'module=git+ssh://git@mygit/home/git/repos/MyModule.git' --data-urlencode 'author=SONGMU' http://localhost:5888/
    curl --data-urlencode 'module=git+file:///home/hirobanex/project/MyModule.git' --data-urlencode 'author=SONGMU' http://localhost:5888/

    #install by cpanm
    cpanm --mirror=http://localhost:5888/orepan Your::Module

    #install by carton install
    PERL_CARTON_MIRROR=http://localhost:5888/orepan carton install

=head1 DESCRIPTION

OrePAN2::Server is DarkPAN server, or L<OrePAN2> Uploader that use API provided by OrePAN2.

Like uploading to cpan, you can upload to your DarkPAN by http post request.

If you set your DarkPAN url in options(L<cpanm> --mirror, L<carton>  PERL_CARTON_MIRROR), you can easily install and manage your modules in your project.

You should set up DarkPAN in private space. If you upload your modules to DarkPAN on public space, you consider to upload your modules to cpan. 

=head1 USAGE

=head2 launch OrePAN2 server instantly

See L<orepan2-server.pl>

=head2 attach your plack app.

    use Plack::Builder;
    use OrePAN2::Server::CLI;
    use Your::App;

    my $orepan = OrePAN2::Server::CLI->new_with_options(
        delivery_dir     => "orepan",
        delivery_path    => "/",
        authenquery_path => "/authenquery",
        compress_index   => 1,
    );

    builder {
        mount '/'       => Your::App->to_app();
        mount '/orepan' => $orepan->app;
    };

=head2 attach your plack with Basic Auth

If your need only DarkPAN Uploader and add Basic Auth with C<Plack::Middleware::Auth::Basic>, you code this.

    use Plack::Builder;
    use OrePAN2::Server;
    use Your::App;

    my $orepan_uploader = OrePAN2::Server->uploader(
        directory        => "orepan",
        compress_index   => 1,
    );

    builder {
        mount '/'            => Your::App->to_app();
        mount '/authenquery' => builder {
            enable "Auth::Basic", authenticator => sub { return ($_[0] eq 'userid' && $_[1] eq 'password') };
            $orepan_uploader;
        }
    };


=head2 upload by minil release.

There is three step.

=head3 minil.toml

    [release]
    pause_config="/path/to/your-module/.pause"

If you want to know other options,  See L<Minilla>.

=head3 /path/to/your-module/.pause

    upload_uri http://orepan2-server/authenquery
    user hirobanex
    password password

If you want to know other options,  See L<CPAN::Uploader>.

You must pay attention to set your DarkPAN uri as upload_uri.If you don't, you will upload to cpan!

=head3 upload command

minil release

=head1 SEE ALSO

L<orepan2-server.pl>, L<OrePAN2>, L<Minilla>

=head1 LICENSE

Copyright (C) Hiroyuki Akabane.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hiroyuki Akabane E<lt>hirobanex@gmail.comE<gt>

Songmu E<lt>y.songmu@gmail.comE<gt>

=for stopwords OrePAN DarkPAN

=cut

