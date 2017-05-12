use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More;
use Net::Fluidinfo;
use Net::Fluidinfo::Namespace;
use Net::Fluidinfo::Tag;
use Net::Fluidinfo::TestUtils;

my ($username, $password) = net_fluidinfo_dev_credentials;

unless (defined $username && defined $password) {
    plan skip_all => skip_all_message;
    exit 0;
}

skip_suite_unless_run_all;

use_ok('Net::Fluidinfo::Permission');

sub is_permission {
    ok shift->isa('Net::Fluidinfo::Permission');
}

sub check_perm {
    my $perm = shift;
    my $perm2 = Net::Fluidinfo::Permission->get($perm->fin, $perm->category, $perm->path, $perm->action);
    is_permission $perm2;
                
    ok $perm2->category eq $perm->category;
    ok $perm2->action  eq $perm->action;
    ok $perm2->policy eq $perm->policy;
    ok_sets_cmp $perm2->exceptions, $perm->exceptions;
}

my $fin = Net::Fluidinfo->_new_for_net_fluidinfo_test_suite;
$fin->username($username);
$fin->password($password);

# --- Predicates --------------------------------------------------------------

my $perm = Net::Fluidinfo::Permission->new(fin => $fin);

$perm->policy('open');
ok $perm->is_open;

$perm->policy('closed');
ok $perm->is_closed;

$perm->exceptions([]);
ok !$perm->has_exceptions;

$perm->exceptions(['test']);
ok $perm->has_exceptions;

# --- Close the top-level namespace -------------------------------------------

foreach my $action (@{Net::Fluidinfo::Permission->Actions->{namespaces}}) {
    my $perm = Net::Fluidinfo::Permission->get($fin, 'namespaces', $username, $action);
    $perm->policy('closed');
    $perm->exceptions([$username]);
    ok $perm->update;
}

# --- Seed data ---------------------------------------------------------------

my $path = "$username/" . random_name;
my $ns = Net::Fluidinfo::Namespace->new(
    fin         => $fin,
    description => random_description,
    path        => $path
);
ok $ns->create;

foreach my $action (@{Net::Fluidinfo::Permission->Actions->{namespaces}}) {
    my $perm = Net::Fluidinfo::Permission->get($fin, 'namespaces', $ns, $action);
    $perm->policy('closed');
    $perm->exceptions([$username]);
    ok $perm->update;
}

$path = "$username/" . random_name;
my $tag = Net::Fluidinfo::Tag->new(
    fin         => $fin,
    description => random_description,
    indexed     => 0,
    path        => $path
);
ok $tag->create;

foreach my $category (qw(tags tag-values)) {
    foreach my $action (@{Net::Fluidinfo::Permission->Actions->{$category}}) {
        my $perm = Net::Fluidinfo::Permission->get($fin, $category, $tag, $action);
        $perm->policy('closed');
        $perm->exceptions([$username]);
        ok $perm->update;
    }    
}

my %paths = (
    'namespaces' => $ns->path,
    'tags'       => $tag->path,
    'tag-values' => $tag->path,
);

# --- PUT except for control --------------------------------------------------

while (my ($category, $actions) = each %{Net::Fluidinfo::Permission->Actions}) {
    foreach my $action (@$actions) {
        next if $action eq 'control';
        foreach my $pname ('open', 'closed') {
            foreach my $exceptions ([], ['fxn'], ['net-fluiddb', 'test']) {
                my $perm = Net::Fluidinfo::Permission->get($fin, $category, $paths{$category}, $action);
                is_permission $perm;

                $perm->policy($pname);
                $perm->exceptions($exceptions);
                ok $perm->update;
                check_perm $perm;
            }
        }
    }
}

# --- PUT with control --------------------------------------------------------

foreach my $category (keys %{Net::Fluidinfo::Permission->Actions}) {
    foreach my $pname ('open', 'closed') {
        foreach my $exceptions ([], ['fxn'], ['net-fluiddb', 'test']) {
            my @e = @$exceptions;
            push @e, $username if $pname eq 'closed';
            my $perm = Net::Fluidinfo::Permission->get($fin, $category, $paths{$category}, 'control');
            is_permission $perm;

            $perm->policy($pname);
            $perm->exceptions(\@e);
            ok $perm->update;
            check_perm $perm;
        }
    }

    # Commit suicide, we have to test closing with an empty exception list somehow
    # and we won't be able to delete these $ns or $tag.
    my $perm = Net::Fluidinfo::Permission->get($fin, $category, $paths{$category}, 'control');
    is_permission($perm);
    
    $perm->policy('closed');
    $perm->exceptions([]);
    ok $perm->update;
    # can't read this back, when we implement exceptions we could try and catch here (TODO) 
}

done_testing;
