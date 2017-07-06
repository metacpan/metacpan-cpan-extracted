# NAME

Sledge::Plugin::Private - plugin to add private HTTP response

# SYNOPSIS

    package Your::Pages;
    use Sledge::Plugin::Private;
    
    sub dispatch_foo {
        my $self = shift;
        $self->set_private;
    }

    # always private on POST request
    use Sledge::Plugin::Private 'POST';

# DESCRIPTION

Sledge::Plugin::Private is a Sledge plugin to be able to use `set_private()`
method on your Sledge based pages to append `Cache-Control: private` header
on HTTP response.

Most part of this module is made by copy and paste from
`Sledge::Plugin::NoCache`.

# AUTHOR

Koichi Taniguchi (a.k.a. nipotan) <taniguchi@cpan.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[Sledge](https://metacpan.org/pod/Sledge)
