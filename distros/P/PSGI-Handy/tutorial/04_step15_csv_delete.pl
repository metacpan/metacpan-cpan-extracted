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

# Read every row of the CSV (shared by the landing page and the delete).
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

# Landing page so the step is runnable from "/": current rows + delete form.
$app->get('/', sub {
    my $c = shift;
    return $c->render('step15_list.html', { users => _read_rows() });
});

$app->post('/delete', sub {
    my $c = shift;
    my $target_id = $c->param('id');
    $target_id = defined $target_id ? $target_id : '';

    my @lines = ();

    if (open(IN, "data.csv")) {
        while (my $line = <IN>) {
            $line =~ s/\r?\n\z//;
            my @cols = split(/,/, $line);
            # Keep only the rows that do not match the target id.
            if ($cols[0] ne $target_id) {
                push @lines, $line;
            }
        }
        close(IN);
    }

    if (open(OUT, "> data.csv")) {
        my $line;
        foreach $line (@lines) {
            print OUT "$line\n";
        }
        close(OUT);
    }

    # Re-render the list so the change is visible immediately.
    return $c->render('step15_list.html', { users => _read_rows() });
});

my $psgi_app = $app->to_app;
print "Starting server on http://127.0.0.1:8080/ (Step 15: Delete)\n";
HTTP::Handy->run(app => $psgi_app, host => '127.0.0.1', port => 8080);
