use strict;
use warnings;
use Test::Base 'no_plan';

use_ok('Template');
use_ok('Template::Plugin::AddTime');

sub apply_template {
    my $template = $_;
    my $tt = Template->new;
    $tt->process( \$template, {}, \my $out )
        or do { fail $tt->error; next };
    return $out;
}

run_like 'input' => 'expected';

__END__
=== absolute
--- SKIP
--- input apply_template chomp
[% USE AddTime -%]
[% AddTime('/path/to/addtime.t') -%]
--- expected regexp
/path/to/addtime\.t\?[0-9]{10}

=== relative
--- input apply_template chomp
[% USE AddTime -%]
[% AddTime('t/addtime.t') -%]
--- expected regexp
t/addtime\.t\?[0-9]{10}

=== filter
--- input apply_template chomp
[% USE AddTime -%]
[% 't/addtime.t' | addtime -%]
--- expected regexp
t/addtime\.t\?[0-9]{10}

=== filter2
--- input apply_template chomp
[% USE AddTime('t') -%]
[% '/addtime.t' | addtime -%]
--- expected regexp
/addtime\.t\?[0-9]{10}

=== filter3
--- SKIP
--- input apply_template chomp
[% USE AddTime('/home/homepage/path/to/root') -%]
[% '/js/index.js' | addtime -%]
--- expected regexp
/js/index\.js\?[0-9]{10}
