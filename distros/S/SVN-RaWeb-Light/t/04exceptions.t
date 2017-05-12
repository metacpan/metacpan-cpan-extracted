#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 3;

use lib './t/lib';

# We need to load the mocking modules first because they fill the
# namespaces and %INC. Otherwise, "use CGI" and "use SVN::*" will cause
# the real modules to be loaded.
use SVN::RaWeb::Light::Mock::CGI;
use SVN::RaWeb::Light::Mock::Svn;
use SVN::RaWeb::Light::Mock::Stdout;

use SVN::RaWeb::Light;

package SVN::RaWeb::Light::ThrowHash;

use base 'SVN::RaWeb::Light';

# Throw a hash reference without a 'callback' parameter.
sub _real_run
{
    die +{ 'one' => "two", 'shlomi' => "fish", };
}

package SVN::RaWeb::Light::ThrowArray;

use base 'SVN::RaWeb::Light';

# Throw a hash reference without a 'callback' parameter.
sub _real_run
{
    die [ "eenie", "meenie", "mynie", "mow"];
}

package SVN::RaWeb::Light::ThrowString;

use base 'SVN::RaWeb::Light';

# Throw a hash reference without a 'callback' parameter.
sub _real_run
{
    die "Hallelujah - an exception was thrown";
}

package main;

{
    my $obj = SVN::RaWeb::Light::ThrowHash->new(
        'url' => "http://svn-i.shlomifish.org/svn/myrepos/"
    );
    eval
    {
        $obj->run();
    };
    # TEST
    is_deeply($@, +{ 'one' => "two", 'shlomi' => "fish", },
        "Checking that hash thrown without a callback key is thrown further."
    );
}

{
    my $obj = SVN::RaWeb::Light::ThrowArray->new(
        'url' => "http://svn-i.shlomifish.org/svn/myrepos/"
    );
    eval
    {
        $obj->run();
    };
    # TEST
    is_deeply($@, [ "eenie", "meenie", "mynie", "mow"],
        "Checking that hash thrown without a callback key is thrown further."
    );
}

{
    my $obj = SVN::RaWeb::Light::ThrowString->new(
        'url' => "http://svn-i.shlomifish.org/svn/myrepos/"
    );
    eval
    {
        $obj->run();
    };
    # TEST
    like($@, qr{^Hallelujah},
        "Checking that a string thrown is thrown further."
    );
}

