# NAME

Mojolicious::Plugin::JSONAPI - Mojolicious Plugin for building JSON API compliant applications

# VERSION

version 1.1

# SYNOPSIS

    # Mojolicious

    # Using route helpers

    sub startup {
        my ($self) = @_;

        $self->plugin('JSONAPI', {
            namespace => 'api',
            data_dir => '/path/to/data/dir',
        });

        $self->resource_routes({
            resource => 'post',
            relationships => ['author', 'comments', 'email-templates'],
        });

        # Now the following routes are available:

        # GET '/api/posts' -> to('api-posts#fetch_posts')
        # POST '/api/posts' -> to('api-posts#post_posts')
        # GET '/api/posts/:post_id -> to('api-posts#get_post')
        # PATCH '/api/posts/:post_id -> to('api-posts#patch_post')
        # DELETE '/api/posts/:post_id -> to('api-posts#delete_post')

        # GET '/api/posts/:post_id/relationships/author' -> to('api-posts#get_related_author')
        # POST '/api/posts/:post_id/relationships/author' -> to('api-posts#post_related_author')
        # PATCH '/api/posts/:post_id/relationships/author' -> to('api-posts#patch_related_author')
        # DELETE '/api/posts/:post_id/relationships/author' -> to('api-posts#delete_related_author')

        # GET '/api/posts/:post_id/relationships/comments' -> to('api-posts#get_related_comments')
        # POST '/api/posts/:post_id/relationships/comments' -> to('api-posts#post_related_comments')
        # PATCH '/api/posts/:post_id/relationships/comments' -> to('api-posts#patch_related_comments')
        # DELETE '/api/posts/:post_id/relationships/comments' -> to('api-posts#delete_related_comments')

        # GET '/api/posts/:post_id/relationships/email-templates' -> to('api-posts#get_related_email_templates')
        # POST '/api/posts/:post_id/relationships/email-templates' -> to('api-posts#post_related_email_templates')
        # PATCH '/api/posts/:post_id/relationships/email-templates' -> to('api-posts#patch_related_email_templates')
        # DELETE '/api/posts/:post_id/relationships/email-templates' -> to('api-posts#delete_related_email_templates')

        # If you're in development mode (e.g. MOJO_MODE eq 'development'), your $app->log will show the created routes. Useful!

        # You can use the following helpers too:

        $self->resource_document($dbic_row, $options);

        $self->compound_resource_document($dbic_row, $options);

        $self->resource_documents($dbic_resultset, $options);
    }

# DESCRIPTION

This module intends to supply the user with helper methods that can be used to build a JSON API
compliant Mojolicious server. It helps create routes for your resources that conform with the
specification, along with supplying helper methods to use when responding to requests.

See [http://jsonapi.org/](http://jsonapi.org/) for the JSON API specification. At the time of writing, the version was 1.0.

# OPTIONS

- `data_dir`

    Required; This should be a path to a directory which is not version controlled (if you use stuff like that). Used
    by `JSONAPI::Document` to store computed document types.

- `namespace`

    The prefix that's added to all routes, defaults to 'api'. You can also provided an empty string as the namespace,
    meaing no prefix will be added.

- `kebab_case_attrs`

    This is passed to the constructor of `JSONAPI::Document` which will kebab case the attribute keys of each
    record (i.e. '\_' to '-').

- `attributes_via`

    Also passed to the constructor of `JSONAPI::Document`. This is the method that will be used to get
    the attributes for a resource document. Should return a hash (not a hashref).

# HELPERS

## resource\_routes(_HashRef_ $spec)

Creates a set of routes for the given resource. `$spec` is a hash reference that can consist of the following:

    {
        resource        => 'post', # name of resource, required
        controller      => 'api-posts', # name of controller, defaults to "api-{resource_plural}"
        relationships   => ['author', 'comments'], # default is []
    }

- `resource _Str_`

    The resources name. Should be a singular noun, which will be turned into it's pluralised
    version (e.g. "post" -> "posts") automatically where necessary.

- `controller _Str_`

    The controller name where the actions are to be stored. Defaults to "api-{resource}", where
    resource is in its pluralised form.

    Routes will point to controller actions, the names of which follow the pattern `{http_method}_{resource}`, with
    dashes replaced with underscores (i.e. 'email-templates' -> 'email\_templates').

- `router _Mojolicious::Routes_`

    The parent route to use for the resource. Optional.

    Provide your own router if you plan to use [under](http://mojolicious.org/perldoc/Mojolicious/Routes/Route#under)
    for your resource.

    **NOTE**: Providing your own router assumes that the router is under the same namespace already, so the resource
    routes won't specify the namespace themselves.

    Usage:

        my $under_api = $r->under('/api')->to('OAuth#is_authenticated');
        $self->resource_routes({
            router => $under_api,
            resource => 'post',
        });

- `relationships _ArrayRef_`

    The relationships belonging to the resource. Defaults to an empty array ref.

    Specifying `relationships` will create additional routes that fall under the resource.

    **NOTE**: Your relationships should be in the correct form (singular/plural) based on the relationship in your
    schema management system. For example, if you have a resource called 'post' and it has many 'comments', make
    sure comments is passed in as a plural noun.

## render\_error(_Str_ $status, _ArrayRef_ $errors, _HashRef_ $data. _HashRef_ $meta)

Renders a JSON response under the required top-level `errors` key. `errors` is an array reference of error objects
as described in the specification. See [Error Objects](http://jsonapi.org/format/#error-objects).

Can optionally provide a reference to the primary data for the route as well as meta information, which will be added
to the response as-is. Use `resource_document` to generate the right structure for this argument.

## requested\_resources

Convenience helper for controllers. Takes the query param `include`, used to indicate what relationships to include in the
response, and splits it by ',' to return an ArrayRef.

    # GET /api/posts?include=comments,author
    my $include = $c->requested_resources(); # ['comments', 'author']

## resource\_document

Available in controllers:

    $c->resource_document($dbix_row, $options);

See [resource\_document](https://metacpan.org/pod/JSONAPI::Document#resource_document\(DBIx::Class::Row-$row,-HashRef-$options\)) for usage.

## compound\_resource\_document

Available in controllers:

    $c->compound_resource_document($dbix_row, $options);

See [compound\_resource\_document](https://metacpan.org/pod/JSONAPI::Document#compound_resource_document\(DBIx::Class::Row-$row,-HashRef-$options\)) for usage.

## resource\_documents

Available in controllers:

    $c->resource_documents($dbix_resultset, $options);

See [resource\_documents](https://metacpan.org/pod/JSONAPI::Document#resource_documents\(DBIx::Class::Row-$row,-HashRef-$options\)) for usage.
