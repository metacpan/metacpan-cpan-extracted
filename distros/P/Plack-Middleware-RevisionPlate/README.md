[![Build Status](https://travis-ci.org/astj/p5-Plack-Middleware-RevisionPlate.svg?branch=master)](https://travis-ci.org/astj/p5-Plack-Middleware-RevisionPlate)
# NAME

Plack::Middleware::RevisionPlate - Serves an endpoint returns application's `REVISION`.

# SYNOPSIS

    use Plack::Builder;
    use Plack::Middleware::RevisionPlate;

    builder {
        # Default revision_filename is ./REVISION.
        enable 'Plack::Middleware::RevisionPlate',
            path => '/site/sha1';

        # Otherwise you can specify revision_filename.
        enable 'Plack::Middleware::RevisionPlate',
            path => '/site/sha1/somemodule', revision_filename => './modules/hoge/REVISION';

        sub {
            my $env = shift;
            return [ 200, [], ['Hello! Plack'] ];
        };
    };

# DESCRIPTION

Plack::Middleware::RevisionPlate returns content of file `REVISION` (or the file specified by `revision_filename` option) on GET/HEAD request to path specified `path` option.
Content of endpoint don't changes even if `REVISION` file changed, but returns 404 if `REVISION` file removed.

# LICENSE

MIT License

# AUTHOR

Asato Wakisaka <asato.wakisaka@gmail.com>

This module is a perl port of ruby gem [RevisionPlate](https://github.com/sorah/revision_plate) by sorah.
