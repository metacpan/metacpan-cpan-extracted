use strict;
use warnings;
use utf8;
use Test::More;
use Test::Module::Build::Pluggable;
use File::Spec;
use lib File::Spec->rel2abs('lib');

BEGIN { *describe = *it = *context = *Test::More::subtest }

describe 'debugging mode' => sub {
    context 'debugging' => sub {
        my $t = build_pl(q{ use Module::Build::Pluggable ( 'XSUtil' ); });
        $t->run_build_pl('-g');
        my $params = $t->read_file('_build/build_params');
        it 'enables -DXS_ASSERT option' => sub {
            like $params, qr/-DXS_ASSERT/;
        };
    };
    context 'non-debugging mode' => sub {
        my $t = build_pl(q{ use Module::Build::Pluggable ( 'XSUtil' ); });
        $t->run_build_pl();
        my $params = $t->read_file('_build/build_params');
        it 'is not enable -DXS_ASSERT option' => sub {
            unlike $params, qr/-DXS_ASSERT/;
        };
    };
};

describe 'ppport.h' => sub {
    context 'write file' => sub {
        my $t = build_pl(q! use Module::Build::Pluggable ( 'XSUtil' => { ppport => 1} ); !);
        $t->run_build_pl();
        it 'generates ppport.h' => sub {
            cmp_ok(-s 'ppport.h', '>', 0);
        };
    };
    context 'specify the filename' => sub {
        my $t = build_pl(q! use Module::Build::Pluggable ( 'XSUtil' => { ppport => 'lib/My/ppport.h'} ); !);
        $t->run_build_pl();
        it 'generates ppport.h' => sub {
            cmp_ok(-s 'lib/My/ppport.h', '>', 0);
        };
    };
};

describe 'xshelper.h' => sub {
    context 'write file' => sub {
        my $t = build_pl(q! use Module::Build::Pluggable ( 'XSUtil' => { xshelper => 1} ); !);
        $t->run_build_pl();
        it 'generates xshelper.h' => sub {
            cmp_ok(-s 'xshelper.h', '>', 0);
        };
        it 'also generates ppport.h' => sub {
            cmp_ok(-s 'ppport.h', '>', 0);
        };
    };
    context 'specify the filename' => sub {
        my $t = build_pl(q! use Module::Build::Pluggable ( 'XSUtil' => { xshelper => 'lib/My/xshelper.h'} ); !);
        $t->run_build_pl();
        it 'generates xshelper.h' => sub {
            cmp_ok(-s 'lib/My/xshelper.h', '>', 0);
        };
        it 'also generates ppport.h to same directory' => sub {
            cmp_ok(-s 'lib/My/ppport.h', '>', 0);
        };
    };
};

describe 'cc_warnings' => sub {
    context 'msvc' => sub {
        my $t = build_pl(q!
            use Module::Build::Pluggable ( 'XSUtil' => { cc_warnings => 1 } );
            use Module::Build::Pluggable::XSUtil;
            *Module::Build::Pluggable::XSUtil::_is_gcc  = sub { 0 };
            *Module::Build::Pluggable::XSUtil::_is_msvc = sub { 1 };
        !);
        $t->run_build_pl();
        my $params = $t->read_file('_build/build_params');
        it 'enables -DXS_ASSERT option' => sub {
            like $params, qr/-W3/;
        };
    };
    context 'gcc' => sub {
        my $t = build_pl(q!
            use Module::Build::Pluggable ( 'XSUtil' => { cc_warnings => 1 } );
            use Module::Build::Pluggable::XSUtil;
            *Module::Build::Pluggable::XSUtil::_is_gcc  = sub { 1 };
            *Module::Build::Pluggable::XSUtil::_is_msvc = sub { 0 };
        !);
        $t->run_build_pl();
        my $params = $t->read_file('_build/build_params');
        it 'enables -DXS_ASSERT option' => sub {
            like $params, qr/-Wall/;
        };
    };
};

done_testing;

sub build_pl {
    my $header = shift;
    my $t = Test::Module::Build::Pluggable->new();
    my $src = <<'...';
use strict;

<<HEADER>>

my $builder = Module::Build::Pluggable->new(
    dist_name => 'Eg',
    dist_version => 0.01,
    dist_abstract => 'test',
    dynamic_config => 0,
    module_name => 'Eg',
    requires => {},
    provides => {},
    author => 1,
    dist_author => 'test',
);
$builder->create_build_script();
...
    $src =~ s/<<HEADER>>/$header/;
    $t->write_file('Build.PL', $src);
    $t;
}

