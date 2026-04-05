use strict;
use warnings;
use FindBin;
use File::Find;
use Test::More;
use File::Temp;
use File::Basename;
use File::Path;
use Module::CoreList;
use Menlo::CLI::Compat;

my $t_dir = "$FindBin::Bin/../../t";
my $local = "$FindBin::Bin/local";
my %installed;
my %dummy = map { ref $_ ? @$_ : ($_ => 1) } (
    "mojo_base/Mojo::BaseTestTest",
    "only/MyModule",
    "plack/Plack::Middleware::Foo",
    "plack/Foo",
    "test_class_most/My::Test::Class",
    "test_class_most/Tests::For::Foo",
    "test_class_most/Tests::For::Bar",
    "test_class_most/Some::Other::Class::For::Increased::Stupidity",
    "class_autouse/CGI",
    "package_variant/Data::Record::Serialize::Role::Base",
    "package_variant/TestImportableA",
    "moosex_declare/Foo",
    "moosex_declare/Foo::A",
    "moosex_declare/Foo::B",
    "moosex_declare/Foo::C",
    "moosex_declare/Foo::Z",
    "moosex_declare/Foo::Bar::Baz",
    "moosex_declare/Foo::Bar::Fnording",
    "moosex_declare/Foo::Baz",
    "moosex_declare/Corge",
    "moosex_declare/Role",
    "moosex_declare/SecondRole",
    "no_moose/Foo",
    "catalyst/Catalyst::Plugin::My::Module",
    "catalyst/Fully::Qualified::Plugin::Name",
    "catalyst/TestApp::Plugin::FullyQualified",
    "catalyst/Catalyst::Plugin::Test::Plugin",
    "20_parsers/Foo",
    "unless/POE::Kernel",
    "test_requires/Some::Optional::Test::Required::Modules",
    "inline/Tibco::Rv::Inline",
    ["core/class/Bar"                       => "use experimental 'class';\nclass Bar 999;\n1;\n"],
    ["core/class/Baz"                       => "use experimental 'class';\nrole Baz 999;\n1;\n"],
    ["core/class/Quux"                      => "use experimental 'class';\nrole Quux 999;\n1;\n"],
    ["object_pad/feature_compat_class/Bar"  => "use Feature::Compat::Class;\nclass Bar 999;\n1;\n"],
    ["object_pad/feature_compat_class/Baz"  => "use Feature::Compat::Class;\nrole Baz 999;\n1;\n"],
    ["object_pad/feature_compat_class/Quux" => "use Feature::Compat::Class;\nrole Quux 999;\n1;\n"],
    ["object_pad/isa_and_does/Bar"          => "use Object::Pad;\nclass Bar;\nour \$VERSION = 999;\n1;\n"],
    ["object_pad/isa_and_does/Baz"          => "use Object::Pad;\nrole Baz;\nour \$VERSION = 999;\n1;\n"],
    ["object_pad/isa_and_does/Quux"         => "use Object::Pad;\nrole Quux;\nour \$VERSION = 999;\n1;\n"],
    ["object_pad/attr/Bar"                  => "use Object::Pad;\nclass Bar;\nour \$VERSION = 999;\n1;\n"],
    ["object_pad/attr/Baz"                  => "use Object::Pad;\nrole Baz;\nour \$VERSION = 999;\n1;\n"],
    ["object_pad/attr/Quux"                 => "use Object::Pad;\nrole Quux;\nour \$VERSION = 999;\n1;\n"],
);

my %ok = map { $_ => 1 } qw(
    10_use
    11_require
    12_no
    15_eval
    20_parsers
    aliased
    autouse
    begin_exit
    catalyst
    class_autouse
    class_load
    core/base
    core/builtin
    core/class
    core/experimental
    core/feature
    core/if
    core/parent
    later
    minimum_version
    mixin
    module_runtime
    mojo_base
    moosex_declare
    moose/any_moose
    moose/class_accessor
    moose/extends_inner_package
    moose/moose
    moose/no_moose
    moose/todo
    moose/with_variable
    object_pad/attr
    object_pad/basic
    object_pad/feature_compat_class
    object_pad/isa_and_does
    only
    package_variant
    plack
    prefork
    syntax_collector
    test_class_most
    test_more
    test_requires
    universal_version
    unless
);

my %testing = map { $_ => 1 } qw(
);

my %skip = map { $_ => 1 } qw(
    00_load
    inline
);

find({
        wanted => sub {
            my $file = $File::Find::name;
            return unless -f $file && $file =~ /\.t$/;
            return if $file =~ m!t/(?:app|bin|compat|scan)!;
            my ($basename) = $file =~ m!\bt/(.+?)\.t$!;
            return if $skip{$basename};    # TODO: needs finer control
            if (!$ENV{TEST_VERBOSE} && $ok{$basename}) {
                pass $basename;
                return;
            }
            return if $ENV{TEST_ONLY} && $ENV{TEST_ONLY} ne $basename;
            subtest "$basename" => sub {
                open my $fh, '<', $file;
                my $flag;
                my $code       = '';
                my $test_count = 1;
                my $expected;
                my $expected_nothing;
                my $skip;

                while (<$fh>) {
                    if ($flag) {
                        if (/^END$/) {
                            my $tmp = File::Temp->new(DIR => "$FindBin::Bin/local", UNLINK => 0);
                            print $tmp "use feature ':all';\n" unless $basename eq 'minimum_version';
                            print $tmp "$code\n;\n1;";
                            my $filename = $tmp->filename;
                            close $tmp;
                            note "TEST CODE:" . "-" x 30 . "\n$code\n" . "-" x 40 . "\n\n";
                            my $result = `$^X -I$local/$basename/lib/perl5 -c $filename 2>&1`;
                        SKIP: {
                                skip $skip, 1 if $skip;
                                if ($expected_nothing) {
                                    ok !$result, "$file: expected nothing" or note "RESULT: $result";
                                } elsif ($expected) {
                                    # probably an erroneous output
                                    ok $result =~ /$expected/, "$file: expected result" or note "RESULT: $result";
                                } else {
                                    ok $result =~ /syntax OK/, "$file: test $test_count" or note "RESULT: $result";
                                }
                            }
                            $flag = 0;
                            $test_count++;
                            $code = $expected = $expected_nothing = $skip = '';
                        } else {
                            $code .= $_;
                        }
                    } else {

                        last if /^done_testing/;
                        if (/^#SKIP: (.*)$/) {
                            $skip = $1;
                            next;
                        }
                        if (/^#SKIP_IF: (.*)$/) {
                            my $condition = $1;
                            $skip = $condition if eval $condition;
                            next;
                        }
                        if (/^#SKIP_ALL_IF: (.*)$/) {
                            my $condition = $1;
                            if (eval $condition) {
                            TODO: {
                                    local $TODO = $condition;
                                    fail "skipped";
                                }
                                return;
                            }
                            next;
                        }
                        if (/^#EXPECTED: (.*)$/) {
                            $expected = $1;
                            next;
                        }
                        if (/^#EXPECTED_NOTHING$/) {
                            $expected_nothing = 1;
                            next;
                        }
                        if (/^#EXPECTED_NOTHING_IF: (.*)$/) {
                            my $condition = $1;
                            $expected_nothing = 1 if eval $condition;
                            next;
                        }
                        if (/^#REQUIRES: (.*)$/) {
                            my $module = $1;
                            my $menlo  = Menlo::CLI::Compat->new;
                            $menlo->parse_options(('-L', "$local/$basename", '-n', ($ENV{TEST_VERBOSE} ? '-v' : ()), $module));
                            $menlo->run;
                            $module =~ s!\@.+$!!;
                            $installed{"$basename/$module"} = 1;
                            next;
                        }
                        if (/^test\(/) {
                            $flag = 1;
                            my ($requires, $recommends, $suggests) = $_ =~ /<<'END',\s*(\{.*?\})(?:,\s*(\{.*?\}))?(?:,\s*(\{.*?\}))?/;
                            my $packages = eval $requires;
                            if ($recommends) {
                                %$packages = (%{ eval($recommends) }, %$packages);
                            }
                            if ($suggests) {
                                %$packages = (%{ eval($suggests) }, %$packages);
                            }
                            for my $module (keys %$packages) {
                                next if $module eq 'perl';
                                next if Module::CoreList::is_core($module);
                                next if $installed{"$basename/$module"};
                                if (my $content = $dummy{"$basename/$module"}) {
                                    my $dummy_file = "$local/$basename/lib/perl5/$module.pm";
                                    $dummy_file =~ s!::!/!g;
                                    my $parent = dirname($dummy_file);
                                    mkpath $parent unless -d $parent;
                                    open my $out, '>', $dummy_file or die "$!: $dummy_file";
                                    if ($content ne "1") {
                                        print $out $content;
                                    } else {
                                        print $out "package $module; our \$VERSION = '9999.99'\n; 1;\n";
                                    }
                                    close $out;
                                } else {
                                    my $menlo = Menlo::CLI::Compat->new;
                                    $menlo->parse_options(('-L', "$local/$basename", '-n', ($ENV{TEST_VERBOSE} ? '-v' : ()), $module));
                                    $menlo->run;
                                    $installed{"$basename/$module"}++;
                                }
                            }
                        }
                    }
                }
            }
        },
        no_chdir => 1,
    },
    $t_dir
);

done_testing;
