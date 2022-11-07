#!perl

use Mojolicious::Lite -signatures;

plugin 'HTMX';

get '/'      => 'index';
get '/boost' => 'boost';

get '/confirm-and-prompt' => 'confirm-and-prompt';
get '/prompt'             => sub ($c) {
    $c->render(text => "You entered: " . $c->htmx->req->prompt);
};
get '/confirm' => sub ($c) {
    $c->render(text => "Confirmed");
};

get '/trigger' => 'trigger';
post '/trigger' => sub ($c) {

    state $count = 0;
    $count++;

    $c->htmx->res->trigger(showMessage => 'Here Is A Message');
    $c->render(text => "Triggered $count times");

};

get '/click-to-edit'           => 'click-to-edit/index';
get '/click-to-edit/contact/1' => 'click-to-edit/contact';
put '/click-to-edit/contact/1' => 'click-to-edit/contact';
get '/click-to-edit/contact/1/edit' => 'click-to-edit/contact-edit';

get '/refresh' => 'refresh';
post '/refresh' => sub ($c) {
    $c->htmx->res->refresh;
    $c->rendered(200);
};

app->start;

__DATA__
@@ layouts/default.html.ep
<!doctype html>
<html lang="en">
<head>

    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">

    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@latest/dist/css/bootstrap.min.css">

    <title>Mojolicious::Plugin::HTMX - Test WebApp</title>

    <!--
    <script src="https://unpkg.com/htmx.org"></script>
    -->

    %= app->htmx->asset
    %= app->htmx->asset(ext => $_) for ('debug', 'event-header')

</head>
<body class="p-5" hx-ext="debug">
    %= content
</body>
</html>


@@ index.html.ep
% layout 'default';
%= include 'tests'


@@ tests.html.ep
<footer class="mt-5">
    <h6>Htmx Tests</h6>
    <ul>
        <li><a href="/click-to-edit">Click To Edit</a></li>
        <li><a href="/trigger">Trigger</a></li>
        <li><a href="/boost">Boosting</a></li>
        <li><a href="/refresh">Refesh</a></li>
        <li><a href="/confirm-and-prompt">Confirm &amp; Prompt</a></li>
    </ul>
</footer>


@@ boost.html.ep
% layout 'default';
<h1>Boosting</h1>

<div hx-boost="true">
    <a href="/click-to-edit">Click-To-Edit</a>
</div>


@@ trigger.html.ep
% layout 'default';
<h1>Trigger</h1>

<button class="btn btn-primary" hx-post="/trigger">Click Me</button>

<script>
document.body.addEventListener("showMessage", function(e){
    alert(e.detail.value);
});
</script>

%= include 'tests'


@@ click-to-edit/index.html.ep
% layout 'default';

<h1>Click To Edit</h1>

<p>
    The click to edit pattern provides a way to offer inline editing of all or part of a record without a page refresh.
</p>
%= include 'click-to-edit/contact'
%= include 'tests'


@@ click-to-edit/contact.html.ep
% layout 'default';

<div hx-target="this" hx-swap="outerHTML">
    <div><label>First Name</label>: Joe</div>
    <div><label>Last Name</label>: Blow</div>
    <div><label>Email</label>: joe@blow.com</div>
    <button hx-get="/click-to-edit/contact/1/edit" class="btn btn-primary">
        Click To Edit
    </button>
</div>


@@ click-to-edit/contact-edit.html.ep
% layout 'default';
<form hx-put="/click-to-edit/contact/1" hx-target="this" hx-swap="outerHTML">
    <div>
        <label>First Name</label>
        <input type="text" name="firstName" value="Joe">
    </div>
    <div class="form-group">
        <label>Last Name</label>
        <input type="text" name="lastName" value="Blow">
    </div>
    <div class="form-group">
        <label>Email Address</label>
        <input type="email" name="email" value="joe@blow.com">
    </div>
    <button class="btn btn-primary">Submit</button>
    <button class="btn btn-secondary" hx-get="/click-to-edit/contact/1">Cancel</button>
</form> 


@@ refresh.html.ep
% layout 'default';
<h1>Refresh</h1>

<button class="btn btn-primary" hx-post="/refresh">Refresh page</button>

%= include 'tests'


@@confirm-and-prompt.html.ep
% layout 'default';
<h1>Prompt & Confirm Tests</h1>

<button class="btn btn-primary" hx-get="/prompt" hx-prompt="Enter some text and it should be echoed in this button">Click For Prompt</button>
<p>&nbsp;</p>
<button class="btn btn-primary" hx-get="/confirm" hx-confirm="Confirm The Action">Click For Confirm</button>

%= include 'tests'
