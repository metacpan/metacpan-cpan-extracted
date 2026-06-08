#!/usr/bin/perl
use 5.00503;
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;

use PSGI::Handy;
use HTTP::Handy;
use HP::Handy;

# Inject HP::Handy through a CODE renderer (see Step 8 for the reason).
my $hp = HP::Handy->new( template_dir => 'templates', auto_escape => 1 );
my $renderer = sub {
    my ($name, $vars) = @_;
    return $hp->render_file($name, $vars);
};

my $app = PSGI::Handy->new( renderer => $renderer );

# Index page so the step is runnable from "/": list every user as a link
# to its own detail page.
$app->get('/', sub {
    my $c = shift;
    my @rows = ();
    if (open(IN, "data.csv")) {
        while (my $line = <IN>) {
            $line =~ s/\r?\n\z//;
            my @cols = split(/,/, $line);
            push @rows, { id => $cols[0], name => $cols[1] };
        }
        close(IN);
    }
    return $c->render('step13_list.html', { users => \@rows });
});

# Capture part of the URL as the :id variable.
$app->get('/user/:id', sub {
    my $c = shift;
    my $target_id = $c->param('id');
    my $found_user = undef;

    if (open(IN, "data.csv")) {
        while (my $line = <IN>) {
            $line =~ s/\r?\n\z//;
            my @cols = split(/,/, $line);
            if ($cols[0] eq $target_id) {
                $found_user = { id => $cols[0], name => $cols[1], age => $cols[2] };
                last; # stop once found
            }
        }
        close(IN);
    }

    if ($found_user) {
        return $c->render('step13_detail.html', { user => $found_user });
    } else {
        return $c->text("User Not Found", 404);
    }
});

my $psgi_app = $app->to_app;
print "Starting server on http://127.0.0.1:8080/ (Step 13: Read One)\n";
HTTP::Handy->run(app => $psgi_app, host => '127.0.0.1', port => 8080);
