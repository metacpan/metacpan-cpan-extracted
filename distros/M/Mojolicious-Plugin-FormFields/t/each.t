use Mojo::Base -strict;
use Mojolicious::Lite;

use Test::More tests => 13;
use Test::Mojo;

use TestHelper;

plugin 'FormFields';

my $users = [ user(name => 'user_a'), user(name => 'user_b') ];

get '/overload' => sub {
    my $self = shift;
    my $text = join '', map $_->text('name'), @{$self->field('users', $users)};
    $self->render(text => $text);
};

get '/overload_without_arrayref' => sub {
    my $self = shift;
    my @name = @{$self->field('user.name', user())};
    $self->render(text => scalar @name)
};

get '/each' => sub {
    my $self = shift;
    my $text = '';
    $self->field('users', $users)->each(sub { $text .= $_->text('name') });
    $self->render(text => $text);
};

sub match_elements
{
    my $t = shift;
    is_field_count($t, 'input', 2);
    $t->element_exists('input[name="users.0.name"][id="users-0-name"][value="user_a"]');
    $t->element_exists('input[name="users.1.name"][id="users-1-name"][value="user_b"]');
}

my $t = Test::Mojo->new;
$t->get_ok('/overload')->status_is(200);
match_elements($t);

$t->get_ok('/overload_without_arrayref')
    ->status_is(200)
    ->content_is(0);

$t = Test::Mojo->new;
$t->get_ok('/each')->status_is(200);
match_elements($t);

__DATA__
@@ exception.html.ep
%= stash('exception')
