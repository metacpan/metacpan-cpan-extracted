#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    plan skip_all => "IO::Scalar required for this test" unless eval { require IO::Scalar };
    plan 'no_plan';
}

use Path::Class;

use ok 'Template::Multipass';

{
    my $t = Template::Multipass->new(
        MULTIPASS => {
            VARS      => {
                one   => 1,
                two   => 2,
                three => 3,
            },
        },
    );

    my $tmpl = '<% one %>, {% two %}, [% three %]';

    ok( $t->process( \$tmpl, { one => "uno", two => "dos", three => "tres" }, \( my $out ) ), "process scalar ref" );

    is( $out, q/<% one %>, 2, tres/, "output" );
}

{
    my $t = Template::Multipass->new(
        START_TAG => "<%",
        END_TAG   => "%>",
        MULTIPASS => {
            START_TAG => undef,
            END_TAG   => undef,
            VARS      => {
                one   => 1,
                two   => 2,
                three => 3,
            },
        },
    );

    my $tmpl = '<% one %>, {% two %}, [% three %]';

    ok( $t->process( \$tmpl, { one => "uno", two => "dos", three => "tres" }, \( my $out ) ), "process" );

    is( $out, q/uno, {% two %}, 3/, "start and end tags" );
}

{
    my $t = Template::Multipass->new(
        MULTIPASS => {
            VARS      => {
                one   => 1,
                two   => 2,
                three => 3,
            },
        },
    );

    my $tmpl = '<% one %>, {% two %}, [% three %]';
    my $fh = IO::Scalar->new(\$tmpl);

    ok( $t->process( $fh, { one => "uno", two => "dos", three => "tres" }, \( my $out ) ), "process fh" );

    is( $out, q/<% one %>, 2, tres/, "output" );
    }


{

    my $t = Template::Multipass->new(
        INCLUDE_PATH => [ file(__FILE__)->parent->subdir("templates")->stringify ],
        MULTIPASS    => {
            VARS => {
                top_meta_var => "TopMeta",
                content_meta_var => "ContentMeta",
                include_meta_var => "IncludeMeta",
                process_meta_var => "ProcessMeta",
                wrapper_meta_var => "WrapperMeta",
            },
        }
    );

    my $out;
    ok( $t->process(
        "wrapper_test.tt",
        {
            content_var => "Content",
            content_meta_reg_var => "ContentMetaReg",
            top_var => "Top",
            wrapper_var => "Wrapper",
            process_var => "Process",
            include_var => "Include",
        },
        \$out
    ), "process template" ) || diag $t->error;

    is( $out, <<END, "wrapping, including etc in context of multipass" );
top=reg:Top,meta:TopMeta

null=

== wrapper reg ==

wrapper=reg:Wrapper,meta=WrapperMeta
content=Content
content_meta=
include_meta=reg:Include,meta:IncludeMeta

include=reg:Include,meta:IncludeMeta

process_meta=reg=Process,meta=ProcessMeta

process=reg=Process,meta=ProcessMeta





== wrapper meta reg body ==

wrapper=reg:Wrapper,meta=WrapperMeta
content=
content_meta=ContentMetaReg
include_meta=reg:Include,meta:IncludeMeta

include=reg:Include,meta:IncludeMeta

process_meta=reg=Process,meta=ProcessMeta

process=reg=Process,meta=ProcessMeta





== wrapper meta ==

wrapper=reg:Wrapper,meta=WrapperMeta
content=
content_meta=ContentMeta
include_meta=reg:Include,meta:IncludeMeta

include=reg:Include,meta:IncludeMeta

process_meta=reg=Process,meta=ProcessMeta

process=reg=Process,meta=ProcessMeta


END
}

{

    my $t = Template::Multipass->new(
        INCLUDE_PATH => [ file(__FILE__)->parent->subdir("templates")->stringify ],
        WRAPPER      => "wrapper2.tt",
    );

    my $out;
    ok( $t->process(
        \"content",
        {
        },
        \$out,
    ), "process template" ) || diag $t->error;

    is( $out, <<END, "config level wrapper" );
wrapper <
content
>
END
}
