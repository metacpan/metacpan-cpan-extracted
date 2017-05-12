# NAME

OrePAN2::Server - DarkPAN Server

# SYNOPSIS

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

# DESCRIPTION

OrePAN2::Server is DarkPAN server, or [OrePAN2](http://search.cpan.org/perldoc?OrePAN2) Uploader that use API provided by OrePAN2.

Like uploading to cpan, you can upload to your DarkPAN by http post request.

If you set your DarkPAN url in options([cpanm](http://search.cpan.org/perldoc?cpanm) --mirror, [carton](http://search.cpan.org/perldoc?carton)  PERL\_CARTON\_MIRROR), you can easily install and manage your modules in your project.

You should set up DarkPAN in private space. If you upload your modules to DarkPAN on public space, you consider to upload your modules to cpan. 

# USAGE

## launch OrePAN2 server instantly

See [orepan2-server.pl](http://search.cpan.org/perldoc?orepan2-server.pl)

## attach your plack app.

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

## attach your plack with Basic Auth

If your need only DarkPAN Uploader and add Basic Auth with `Plack::Middleware::Auth::Basic`, you code this.

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



## upload by minil release.

There is three step.

### minil.toml

    [release]
    pause_config="/path/to/your-module/.pause"

If you want to know other options,  See [Minilla](http://search.cpan.org/perldoc?Minilla).

### /path/to/your-module/.pause

    upload_uri http://orepan2-server/authenquery
    user hirobanex
    password password

If you want to know other options,  See [CPAN::Uploader](http://search.cpan.org/perldoc?CPAN::Uploader).

You must pay attention to set your DarkPAN uri as upload\_uri.If you don't, you will upload to cpan!

### upload command

minil release

# SEE ALSO

[orepan2-server.pl](http://search.cpan.org/perldoc?orepan2-server.pl), [OrePAN2](http://search.cpan.org/perldoc?OrePAN2), [Minilla](http://search.cpan.org/perldoc?Minilla)

# LICENSE

Copyright (C) Hiroyuki Akabane.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Hiroyuki Akabane <hirobanex@gmail.com>

Songmu <y.songmu@gmail.com>
