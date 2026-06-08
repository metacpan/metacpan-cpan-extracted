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

# Read every row of the CSV (shared by the landing page and the update).
sub _read_rows {
    my @rows = ();
    if (open(IN, "data.csv")) {
        while (my $line = <IN>) {
            $line =~ s/\r?\n\z//;
            my @cols = split(/,/, $line);
            push @rows, { id => $cols[0], name => $cols[1], age => $cols[2] };
        }
        close(IN);
    }
    return \@rows;
}

# Landing page so the step is runnable from "/": current rows + update form.
$app->get('/', sub {
    my $c = shift;
    return $c->render('step14_list.html', { users => _read_rows() });
});

$app->post('/update', sub {
    my $c = shift;
    my $target_id = $c->param('id');
    my $new_name  = $c->param('name');
    my $new_age   = $c->param('age');
    $target_id = defined $target_id ? $target_id : '';
    $new_name  = defined $new_name  ? $new_name  : '';
    $new_age   = defined $new_age   ? $new_age   : '';

    my @lines = ();

    # Read all rows and replace the target row.
    if (open(IN, "data.csv")) {
        while (my $line = <IN>) {
            $line =~ s/\r?\n\z//;
            my @cols = split(/,/, $line);
            if ($cols[0] eq $target_id) {
                push @lines, "$target_id,$new_name,$new_age"; # rewrite
            } else {
                push @lines, $line; # keep as is
            }
        }
        close(IN);
    }

    # Overwrite all rows.
    if (open(OUT, "> data.csv")) {
        my $line;
        foreach $line (@lines) {
            print OUT "$line\n";
        }
        close(OUT);
    }

    # Re-render the list so the change is visible immediately.
    return $c->render('step14_list.html', { users => _read_rows() });
});

my $psgi_app = $app->to_app;
print "Starting server on http://127.0.0.1:8080/ (Step 14: Update)\n";
HTTP::Handy->run(app => $psgi_app, host => '127.0.0.1', port => 8080);
