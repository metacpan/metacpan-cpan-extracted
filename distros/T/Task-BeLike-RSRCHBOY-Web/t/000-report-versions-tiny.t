use strict;
use warnings;
use Test::More 0.88;
# This is a relatively nice way to avoid Test::NoWarnings breaking our
# expectations by adding extra tests, without using no_plan.  It also helps
# avoid any other test module that feels introducing random tests, or even
# test plans, is a nice idea.
our $success = 0;
END { $success && done_testing; }

my $v = "\n";

eval {                     # no excuses!
    # report our Perl details
    my $want = '5.006';
    my $pv = ($^V || $]);
    $v .= "perl: $pv (wanted $want) on $^O from $^X\n\n";
};
defined($@) and diag("$@");

# Now, our module version dependencies:
sub pmver {
    my ($module, $wanted) = @_;
    $wanted = " (want $wanted)";
    my $pmver;
    eval "require $module;";
    if ($@) {
        if ($@ =~ m/Can't locate .* in \@INC/) {
            $pmver = 'module not found.';
        } else {
            diag("${module}: $@");
            $pmver = 'died during require.';
        }
    } else {
        my $version;
        eval { $version = $module->VERSION; };
        if ($@) {
            diag("${module}: $@");
            $pmver = 'died during VERSION check.';
        } elsif (defined $version) {
            $pmver = "$version";
        } else {
            $pmver = '<undef>';
        }
    }

    # So, we should be good, right?
    return sprintf('%-45s => %-10s%-15s%s', $module, $pmver, $wanted, "\n");
}

eval { $v .= pmver('Catalyst::Controller::REST','any version') };
eval { $v .= pmver('Catalyst::Devel','any version') };
eval { $v .= pmver('Catalyst::Model::DBIC::Schema','0.59') };
eval { $v .= pmver('Catalyst::Plugin::Authentication','any version') };
eval { $v .= pmver('Catalyst::Plugin::Authorization::ACL','any version') };
eval { $v .= pmver('Catalyst::Plugin::Authorization::Roles','any version') };
eval { $v .= pmver('Catalyst::Plugin::AutoCRUD','1.112560') };
eval { $v .= pmver('Catalyst::Plugin::RedirectAndDetach','any version') };
eval { $v .= pmver('Catalyst::Plugin::Session','any version') };
eval { $v .= pmver('Catalyst::Plugin::Session::State::Cookie','any version') };
eval { $v .= pmver('Catalyst::Plugin::Session::Store::File','any version') };
eval { $v .= pmver('Catalyst::Runtime','5.9') };
eval { $v .= pmver('Catalyst::TraitFor::Request::BrowserDetect','any version') };
eval { $v .= pmver('Catalyst::TraitFor::Request::REST::ForBrowsers','any version') };
eval { $v .= pmver('Catalyst::View::Haml','any version') };
eval { $v .= pmver('Catalyst::View::TT','any version') };
eval { $v .= pmver('CatalystX::RoleApplicator','any version') };
eval { $v .= pmver('CatalystX::SimpleLogin','any version') };
eval { $v .= pmver('Dancer','any version') };
eval { $v .= pmver('ExtUtils::MakeMaker','6.30') };
eval { $v .= pmver('File::Find','any version') };
eval { $v .= pmver('File::Temp','any version') };
eval { $v .= pmver('HTML::Builder','0.006') };
eval { $v .= pmver('HTML::FormHandler','any version') };
eval { $v .= pmver('MooseX::MethodAttributes::Role','any version') };
eval { $v .= pmver('Plack','any version') };
eval { $v .= pmver('Plack::Middleware::Debug','any version') };
eval { $v .= pmver('Plack::Middleware::MethodOverride','0.10') };
eval { $v .= pmver('Plack::Middleware::SetAccept','any version') };
eval { $v .= pmver('Starlet','any version') };
eval { $v .= pmver('Starman','any version') };
eval { $v .= pmver('Task::BeLike::RSRCHBOY','0.002') };
eval { $v .= pmver('Task::Catalyst','any version') };
eval { $v .= pmver('Template','any version') };
eval { $v .= pmver('Template::Plugin::JSON::Escape','any version') };
eval { $v .= pmver('Test::More','0.88') };
eval { $v .= pmver('Text::Haml','any version') };
eval { $v .= pmver('strict','any version') };
eval { $v .= pmver('warnings','any version') };



# All done.
$v .= <<'EOT';

Thanks for using my code.  I hope it works for you.
If not, please try and include this output in the bug report.
That will help me reproduce the issue and solve you problem.

EOT

diag($v);
ok(1, "we really didn't test anything, just reporting data");
$success = 1;

# Work around another nasty module on CPAN. :/
no warnings 'once';
$Template::Test::NO_FLUSH = 1;
exit 0;
